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

require 'rest-client'
require 'ostruct'

module Wrappers
  class Addok < Wrapper
    def initialize(cache, url, search2steps = false, boundary = nil)
      super(cache, boundary)
      @search2steps = search2steps
      @url = url
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
          when 400
            raise response
          else
            response.return!(request, result, &block)
          end
        }
        json = JSON.parse(response, object_class: OpenStruct)
        @cache.write(key, json)
      end
      map_spec(json)
    end

    def geocodes(list_params)
      csv_string = CSV.generate { |csv|
        csv << ['q', 'r']
        list_params.each{ |params|
          csv << [flatten_query(params, false), params[:ref]]
        }
      }

      addok_geocodes('/search/csv', ['q'], csv_string)
    end

    def reverses(list_params)
      csv_string = CSV.generate { |csv|
        csv << ['lat', 'lng']
        list_params.each{ |params|
          csv << [params[:lat], params[:lng]]
        }
      }

      addok_geocodes('/reverse/csv', nil, csv_string)
    end

    def complete(params, limit = 10)
      addok_geocode(params, limit, true)
    end

    private

    def addok_geocode(params, limit, complete)
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
        }

        if @search2steps && !params[:query] && params[:city]
          p[:q0] = params[:city]
          p[:q] = [params[:housenumber], params[:street], params[:postcode]].select{ |i| not i.nil? }.join(' ')
          method = '/search2steps'
        else
          p[:q] = flatten_query(params, false)
          method = '/search'
        end
        p.compact!
        response = RestClient.get(@url + method, {params: p}) { |response, request, result, &block|
          case response.code
          when 200
            response
          when 400
            raise response
          else
            response.return!(request, result, &block)
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
          score: p['score'], # Not in spec
          type: p['type'] == 'housenumber' ? 'house' : p['type'], # Hack to match spec around addok return value
          # accuracy: p['accuracy'],
          label: p['label'],
          name: p['name'],
          housenumber: p['housenumber'],
          street: p['street'],
          postcode: p['postcode'],
          city: p['city'],
          district: p['district'],
          county: p['county'],
          state: p['state'],
          country: p['country'],
          admin: p['admin'],
          geohash: p['geohash'],
        }.select{ |k, v| not v.nil? }
      }

      json
    end

    def addok_geocodes(url_part, columns, csv)
      post = {
        delimiter: ',',
        encoding: 'utf-8',
        multipart: true,
        data: FakeFileStringIO.new(csv, 'r')
      }
      post[:columns] = 'q' if columns
      response = RestClient::Request.execute(method: :post, url: @url + url_part, timeout: nil, payload: post) { |response, request, result, &block|
        case response.code
        when 200
          response
        when 400
          raise response
        else
          response.return!(request, result, &block)
        end
      }
      result = []
      CSV.parse(response.force_encoding('utf-8'), headers: true) { |p|
        result << map_from_csv(p)
      }
      result
    end

    def map_from_csv(p)
      {
        properties: {
          geocoding: {
            ref: p['r'],
            score: p['result_score'], # Not in spec
            type: p['result_type'] == 'housenumber' ? 'house' : p['type'], # Hack to match spec around addok return value
            # accuracy: p['accuracy'],
            label: p['result_label'],
            name: p['result_name'],
            housenumber: p['result_housenumber'],
            street: p['result_street'],
            postcode: p['result_postcode'],
            city: p['result_city'],
            district: p['result_district'],
            county: p['result_county'],
            state: p['result_state'],
            country: p['result_country'],
            # admin: p['admin'],
            geohash: p['geohash'],
          },
        },
        geometry: (!p['longitude'].nil? && !p['latitude'].nil?) ? {
          type: 'Point',
          coordinates: [p['longitude'].to_f, p['latitude'].to_f]
        } : nil,
        type: 'Feature'
      }
    end
  end


  class FakeFileStringIO < StringIO
    def path
      ''
    end
  end
end
