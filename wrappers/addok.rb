# Copyright © Mapotempo, 2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require './wrappers/wrapper'

require 'csv'
require 'rest-client'
#RestClient.log = $stdout
require 'ostruct'

module Wrappers
  class Addok < Wrapper
    def initialize(cache, url, country, boundary = nil, point_in_polygon = nil)
      super(cache, boundary)
      @url = url
      @country = country
      @point_in_polygon = point_in_polygon
    end

    def geocode(params, limit = 10)
      addok_geocode(params, limit, false)
    end

    def reverse(params)
      key = [:addok, :reverse, Digest::MD5.hexdigest(Marshal.dump([@url, params.to_a.sort_by{ |i| i[0].to_s }]))]
      json = @cache.read(key)
      if !json
        response = RestClient.get(@url + '/reverse', {params: {lat: params[:lat], lon: params[:lng]}}) { |response, request, result, &block|
          case response.code
          when 200
            response
          else
            raise response
          end
        }
        json = JSON.parse(response, object_class: OpenStruct)

        # Fallback to point in polygon
        if json[:features].empty? && @point_in_polygon
          json = @point_in_polygon.pick(params[:lng], params[:lat])
        end

        @cache.write(key, json)
      end

      map_spec(json)
    end

    GEOCODES_SLICE_SIZE = 1000

    def geocodes(list_params)
      slice_number = list_params.size / GEOCODES_SLICE_SIZE

      list_params.each_slice(GEOCODES_SLICE_SIZE).each_with_index.collect{ |slice_params, slice|
        results = []
        csv_index_p = []
        csv_string = CSV.generate(quote_char: '"') { |csv|
          csv << ['q0', 'q', 'r']
          slice_params.each_with_index{ |params, index|
            p = flatten_param(params)

            key = [:addok, :geocode, Digest::MD5.hexdigest(Marshal.dump(p))]
            r = @cache.read(key)
            if !r
              csv << [p[:q0], p[:q], params[:ref]]
              csv_index_p << [index, p]
            else
              r[:ref] = params[:ref]
              results[index] = r
            end
          }
        }
        STDERR.puts "Addok Geocodes #{Thread.current.object_id}, slice #{slice}/#{slice_number}" if slice_number > 1

        if !csv_index_p.empty?
          search = ENV['APP_ENV'] != 'production' ? '/search' : '/search2steps'
          addok_geocodes("#{search}/csv", csv_string, ['q0'], ['q']).each{ |result|
            index, p = csv_index_p.shift
            results[index] = result
            @cache.write([:addok, :geocode, Digest::MD5.hexdigest(Marshal.dump(p))], result)
          }
        end

        results
      }.flatten(1)
    end

    def reverses(list_params)
      csv_string = CSV.generate { |csv|
        csv << ['lat', 'lng']
        list_params.each{ |params|
          csv << [params[:lat], params[:lng]]
        }
      }

      addok_geocodes('/reverse/csv', csv_string)
    end

    def complete(params, limit = 10)
      addok_geocode(params, limit, true)
    end

    private

    def flatten_param(params)
      if !params[:query] && params[:city]
        {
          q0: [params[:postcode], params[:city]].compact.join(' '),
          q: gen_streets(params).collect{ |street| [params[:housenumber], street].compact.join(' ') }.join('|')
        }
      else
        p = params.dup
        {
          q: gen_streets(params).collect{ |street|
            p[:street] = street
            flatten_query(p, false)
          }.join('|')
        }
      end
    end

    def addok_geocode(params, limit, complete)
      params = clean_params params
      key_params = {limit: limit, complete: complete}.merge(params).reject{ |k, v| k == 'api_key'}
      key = [:addok, :geocode, Digest::MD5.hexdigest(Marshal.dump([@url, key_params.to_a.sort_by{ |i| i[0].to_s }]))]

      json = @cache.read(key)
      if !json
        p = {
          limit: limit,
          autocomplete: complete ? 1 : 0,
          lat: params['lat'],
          lon: params['lng'],
          type: (params[:type] if ['house', 'street'].include?(params[:type]))
        }.merge(flatten_param(params))

        search = ENV['APP_ENV'] != 'production' ? '/search' : '/search2steps'
        response = RestClient.get(@url + search, {params: p}) { |response, request, result, &block|
          case response.code
          when 200
            response
          when 400
            return { error: true, response: response }
          else
            raise response
          end
        }
        json = JSON.parse(response, object_class: OpenStruct)
        @cache.write(key, json)
      end

      map_spec(json)
    end

    def map_spec(json)
      # Convert from geocodejson-spec to geocodejson-spec-namespace
      json['geocoding'] = {
        licence: json['licence'],
        attribution: json['attribution'],
        query: json['query'],
      }.select{ |k, v| not v.nil? }

      json['features'].collect{ |features|
        p = features['properties']
        features['properties']['geocoding'] = {
          version: json['version'],
          geocoder_version: version,
          score: p['score'], # Not in spec
          type: {'housenumber' => 'house', 'municipality' => 'city'}[p['type']] || p['type'], # Hack to match spec around addok return value
          # accuracy: p['accuracy'],
          label: p['label'],
          name: p['name'],
          housenumber: p['housenumber'],
          street: p['street'] || (['street', 'housenumber'].include?(p['type']) && p['name']) || nil,
          locality: p['locality'] || (p['type'] == 'locality' && p['name']) || nil,
          postcode: p['postcode'],
          city: p['city'] || p['municipality'], # Addok 0.5 (old BAN) / Addok 1.0 (new BAN)
          district: p['district'],
          county: p['county'],
          state: p['state'],
          country: p['country'] || @country,
          admin: p['admin'],
          geohash: p['geohash'],
          id: p['id'] || p['citycode'],
        }.delete_if{ |k, v| v.nil? || v == '' }
      }
      json
    end

    def addok_geocodes(url_part, csv, columns0 = nil, columns = nil)
      post = {
        delimiter: ',',
        quote: '"',
        encoding: 'utf-8',
        multipart: true,
        data: FakeFileStringIO.new(csv, 'r'),
        columns: columns && columns.join(','),
        columns0: columns0 && columns0.join(',')
      }.delete_if{ |k, v| v.nil? }

      response = RestClient::Request.execute(method: :post, url: @url + url_part, timeout: nil, payload: post) { |response, request, result, &block|
        case response.code
        when 200
          response
        else
          raise [response.code, response].select{ |t| t && t != '' }.join(' ')
        end
      }
      result = []
      CSV.parse(response.force_encoding('utf-8'), headers: true, quote_char: '"') { |p|
        map = map_from_csv(p)
        result << map
      }
      result
    end

    def map_from_csv(p)
      {
        properties: {
          geocoding: {
            geocoder_version: version,
            ref: p['r'],
            score: p['result_score'], # Not in spec
            type: {'housenumber' => 'house', 'municipality' => 'city'}[p['result_type']] || p['result_type'], # Hack to match spec around addok return value
            # accuracy: p['accuracy'],
            label: p['result_label'],
            name: p['result_name'],
            housenumber: p['result_housenumber'],
            street: p['result_street'] || (['street', 'housenumber'].include?(p['result_type']) && p['result_name']) || nil,
            locality: p['result_locality'] || (p['result_type'] == 'locality' && p['result_name']) || nil,
            postcode: p['result_postcode'],
            city: p['result_city'] || p['result_municipality'], # Addok 0.5 (old BAN) / Addok 1.0 (new BAN)
            district: p['result_district'],
            county: p['result_county'],
            state: p['result_state'],
            country: p['result_country'] || @country,
            # admin: p['admin'],
            geohash: p['geohash'],
            id: p['result_id'] || p['result_citycode'],
          }.delete_if{ |k, v| v.nil? || v == '' },
        },
        geometry: (!p['longitude'].nil? && !p['latitude'].nil?) ? {
          type: 'Point',
          coordinates: [p['longitude'].to_f, p['latitude'].to_f]
        } : nil,
        type: 'Feature'
      }
    end

    protected

    def version(query = nil)
      "#{super} - addok:1.1.0-rc1.1"
    end

  end


  class FakeFileStringIO < StringIO
    def path
      'a' # Addok require a non-empty name
    end
  end
end
