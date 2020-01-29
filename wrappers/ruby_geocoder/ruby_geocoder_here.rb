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
require 'geocoder'
require 'rest-client'
require './wrappers/ruby_geocoder/ruby_geocoder'
# RestClient.log = $stdout

# LIMIT 10 ADDRESSES
module Wrappers
  # https://developer.here.com/rest-apis/documentation/geocoder/topics/resource-type-response-geocode.html
  class RubyGeocoderHere < RubyGeocoder
    def initialize(cache, boundary = nil)
      super(cache, boundary)

      @MIN_LENGTH = 10

      @header = {
        type: 'FeatureCollection',
        geocoding: {
          licence: 'HERE',
          attribution: 'HERE',
          query: nil,
        },
        features: []
      }

      @match_level = {
        'country' => 'country',
        'state' => 'state',
        'county' => 'county',
        'city' => 'city',
        'district' => 'city', # HERE 'district' not at the rank in other geocoders
        'street' => 'street',
        'intersection' => 'intersection',
        'houseNumber' => 'house',
        'postalCode' => 'city',
        'landmark' => 'house'
      }

      @batch_url = 'https://batch.geocoder.api.here.com/6.2/jobs'
    end

    def reverses(params)
      # use unit geocode if bulk would be to slow
      return super(params) unless params.length > @MIN_LENGTH

      payload = ['recId|prox']
      # 250 magicnumber as default parameter for here api
      payload << params.each_with_index.map do |current, idx|
        "#{idx}|#{current[:lat]},#{current[:lng]},250"
      end

      here_geocoder_batch payload, 'reverse'
    end

    def geocodes(params)
      # use unit reverse if bulk would be to slow
      return super(params) unless params.length > @MIN_LENGTH

      payload = ['recId|searchText|country']
      payload << params.each_with_index.map do |current, idx|
        maybe_street = maybe_streets?(current)
        query_hash = build_request_query(current, maybe_street)

        if maybe_street
          query_hash.map { |query| "#{idx}|#{flatten_query query}|#{query[:country]}" }
        else
          "#{idx}|#{flatten_query query_hash}|#{query_hash[:country]}"
        end
      end

      here_geocoder_batch payload, 'geocode'
    end

    def complete(params, limit = 10)
      sleep 0.5
      super params, limit: limit
    end

    protected

    def max_by(result)
      !result.empty? && match_quality(result) || 0
    end

    def cache_key(key_params)
      [:here, :geocode, Digest::MD5.hexdigest(Marshal.dump(key_params.to_a.sort_by{ |i| i[0].to_s }))]
    end

    def read_cache(key_params)
      @cache.read cache_key(key_params)
    end

    def write_cache(key_params, features)
      @cache.write cache_key(key_params), features
    end

    def setup_geocoder
      Geocoder::Configuration.lookup = :here
      Geocoder::Configuration.use_https = true
      Geocoder::Configuration.api_key = GeocoderWrapper.config[:ruby_geocode][Geocoder::Configuration.lookup]
    end

    def build_features(query, data, options, bulk = false)
      if options && options[:complete]
        autocomplete_features(query, data)
      elsif bulk
        bulk_features(data)
      else
        features(query, data)
      end
    end

    def version(query = nil)
      if query.nil?
        "#{super} - here:6.2"
      else
        version_regexp = %r{\/\d+\.\d+\/}
        q = Geocoder::Query.new(query)
        full_url = Geocoder::Lookup.get(:here).query_url(q)
        "#{super} - here:#{full_url[version_regexp].tr('/', '')}"
      end
    end

    private

    def match_quality(r)
      mq = r[0].data['MatchQuality']
      return if mq.nil?
      (mq['Country'] || 0) * 1000 + (mq['City'] || 0) * 100 + (mq['Street'] && mq['Street'][0] || 0) * 10 + (mq['HouseNumber'] || 0)
    end

    def build_search_text_param(param)
      if param.key?(:query)
        param
      else
        p = param.dup
        gen_streets(param).collect{ |street| p[:street] = street }
        p
      end
    end

    def map_results(headers, results)
      headers = headers.split('|')
      results.map do |row|
        h = { 'MatchQuality' => {} }
        row_data = row.split('|')
        headers.each_with_index do |header, idx|
          if header.include?('matchQuality')
            key = header.sub('matchQuality', '').titleize.split.join
            h['MatchQuality'][key] = key == 'Street' ? [row_data[idx].to_f] : row_data[idx].to_f
          else
            h[header] = row_data[idx]
          end
        end
        h
      end
    end

    def parse_batch_additional_data(address_additional_data)
      address_additional_data.split('; ').each_with_object({}) do |current, acc|
        splited_data = current.split('=')
        acc[splited_data[0]] = splited_data[1]
        acc
      end
    end

    def here_geocoder_batch(payload, mode = nil)

      outcols = %w[
        displayLatitude
        displayLongitude
        locationLabel
        houseNumber
        street
        district
        city
        postalCode
        county
        state
        country
        relevance
        addressAdditionalData
        matchLevel
        addressDetailsBuilding
        matchQualityCountry
        matchQualityCity
        matchQualityHouseNumber
        matchQualityStreet
      ].join(',')

      app_id = ::GeocoderWrapper.config[:ruby_geocode][:here][0]
      app_code = ::GeocoderWrapper.config[:ruby_geocode][:here][1]

      params = {
        gen: 8,
        app_id: app_id,
        app_code: app_code,
        action: 'run',
        header: true,
        indelim: '|',
        outdelim: '|',
        outcols: outcols,
        outputCombined: true
      }

      params['mode'] = 'retrieveAddresses' if mode == 'reverse'

      RestClient::Request.execute(
        method: :post,
        url: @batch_url,
        payload: payload.flatten.join("\n"),
        headers: {
          params: params,
          content_type: '*'
        }
      ) do |response|
        case response.code
        when 200
            root = Document.new(response.body).root
            job_id = root.elements['Response/MetaInfo/RequestId'].text

            status_url = "#{@batch_url}/#{job_id}"
            status = nil

            until status && %w[completed failed].include?(status)
              response = RestClient::Request.execute(
                method: :get,
                url: status_url,
                headers: {
                  params: {
                    app_id: app_id,
                    app_code: app_code,
                    action: 'status'
                  }
                }
              )

              root = Document.new(response.body).root
              status = root.elements['Response/Status'].text
            end

            raise response if status == 'failed'

            result_url = "#{@batch_url}/#{job_id}/result"
            response = RestClient::Request.execute(
              method: :get,
              url: result_url,
              headers: {
                params: {
                  app_id: app_id,
                  app_code: app_code,
                  outputcompressed: false
                },
                content_type: 'application/octet-stream'
              }
            )

            results = response.body.split("\n")
            headers = results.shift

            results = map_results(headers, results)

            results = results.group_by { |result| result['recId'] }
                             .map do |_, value|
               value.max_by do |v|
                 max_by([OpenStruct.new(data: v)]) || []
               end
            end

            build_features(nil, results, nil, true)
        else
          raise response
        end
      end
    end

    def features(query, data)
      additional_data = parse_address_additional_data(data['Location']['Address']['AdditionalData'])
      house_number = [data['Location']['Address']['HouseNumber'], data['Location']['Address']['Building']].select{ |i| i }.join(' ')
      {
        properties: {
          geocoding: {
            geocoder_version: version(query),
            score: data['Relevance'],
            type: @match_level[data['MatchLevel']],
            label: data['Location']['Address']['Label'],
            name: "#{house_number} #{data['Location']['Address']['Street']}".strip,
            housenumber: house_number,
            street: data['Location']['Address']['Street'],
            postcode: data['Location']['Address']['PostalCode'],
            city: data['Location']['Address']['City'],
            #district: a['Location']['Address']['District'], # In HERE API district is a city district
            county: additional_data['CountyName'],
            state: additional_data['StateName'],
            country: additional_data['CountryName'],
          }.delete_if{ |_k, v| v.nil? || v == '' }
        },
        type: 'Feature',
        geometry: {
          coordinates: [
            data['Location']['DisplayPosition']['Longitude'],
            data['Location']['DisplayPosition']['Latitude']
          ],
          type: 'Point'
        }
      }
    end

    def parse_address_additional_data(additional_data)
      hash = Hash.new { |h, k| h[k] = nil }
      additional_data.each { |ad| hash[ad['key']] = ad['value'] }
      hash
    end

    def autocomplete_features(query, data)
      h = {}
      data['address'].each { |k, v| h[k] = v } if data.key?('address')
      name = "#{h['houseNumber'].nil? ?  '' : h['houseNumber']} #{h['street'].nil? ? '' : h['street']}".strip
      {
        properties: {
          geocoding: {
            geocoder_version: version(query),
            type: @match_level[data['matchLevel']],
            label: data['label'],
            name: name == '' ? nil : name,
            housenumber: h['houseNumber'],
            street: h['street'],
            postcode: h['postalCode'],
            city: h['city'],
            district: h['district'], # In HERE API district is a city district
            county: h['county'],
            state: h['stateName'],
            country: h['country'],
          }.delete_if { |_, v| v.nil? || v == '' }
        }
      }
    end

    def bulk_features(data)
      data.map do |result_data|
        if result_data['matchLevel'] == 'NOMATCH'
          {
            properties: {
              geocoding: {
              }
            }
          }
        else
          additional_data = parse_batch_additional_data result_data['addressAdditionalData']
          {
            properties: {
              geocoding: {
                geocoder_version: version,
                score: result_data['relevance'].to_f,
                type: @match_level[result_data['matchLevel']],
                label: result_data['locationLabel'],
                name: "#{result_data['houseNumber']} #{result_data['street']}".strip,
                housenumber: result_data['houseNumber'],
                postcode: result_data['postalCode'],
                city: result_data['city'],
                # district: result_data['district'],
                county: result_data['county'],
                state: result_data['state'],
                country: additional_data['countryName']
              }.delete_if{ |_k, v| v.nil? || v == '' }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                result_data['displayLongitude'].to_f,
                result_data['displayLatitude'].to_f
              ],
              type: 'Point'
            }
          }
        end
      end
    end
  end
end
