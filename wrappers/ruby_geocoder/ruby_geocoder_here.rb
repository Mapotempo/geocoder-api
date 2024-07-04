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
    def initialize(cache, boundary = nil, credentials = nil)
      super(cache, boundary)
      @credentials = credentials

      @MIN_LENGTH = 50

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
        'administrativeArea' => 'city',
        'place' => 'city',
        'locality' => 'house',
        'intersection' => 'intersection',
        'addressBlock' => 'street',
        'postalCodePoint' => 'street',
        'street' => 'street',
        'houseNumber' => 'house',
      }

      @batch_url = 'https://batch.search.hereapi.com/v1/batch/jobs'
    end

    def reverses(params)
      # use unit geocode if bulk would be to slow
      return super(params) unless params.length > @MIN_LENGTH

      payload = params.each_with_index.map do |current, idx|
        "#{idx}|#{current[:lat]},#{current[:lng]}|1"
      end

      here_geocoder_batch(
        'hrn:here:service::olp-here:search-revgeocode-7',
        'recId|at|limit',
        payload,
      )
    end

    def geocodes(params)
      # use unit reverse if bulk would be to slow
      return super(params) unless params.length > @MIN_LENGTH

      payload = params.each_with_index.map do |current, idx|
        maybe_street = maybe_streets?(current)
        query_hash = build_request_query(current, maybe_street)

        if maybe_street
          query_hash.map { |query| "#{idx}|#{flatten_query_non_empty(query)}|#{query[:country]}" }
        else
          "#{idx}|#{flatten_query_non_empty(query_hash)}|#{query_hash[:country]}"
        end
      end

      here_geocoder_batch(
        'hrn:here:service::olp-here:search-geocode-7',
        'recId|searchText|country',
        payload,
      )
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
      Geocoder::Configuration.api_key = @credentials || GeocoderWrapper.config[:ruby_geocode][Geocoder::Configuration.lookup]
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
        "#{super} - here:7.0"
      else
        version_regexp = %r{\/\d+\.\d+\/}
        q = Geocoder::Query.new(query)
        full_url = Geocoder::Lookup.get(:here).query_url(q)
        "#{super} - here:#{full_url[version_regexp]&.tr('/', '') || '7.0'}"
      end
    end

    private

    def match_quality(r)
      r[0].data['queryScore']
    end

    def flatten_query_non_empty(params, with_country = true)
      # Avoid empty string that shift bulk geocoding
      query = flatten_query(params, with_country)
      query.empty? ? 'a' : query
    end

    def here_geocoder_batch(mode, columns, payload)
      outcols = %w[
        recId
        accessLatitude
        accessLongitude
        positionLatitude
        positionLongitude
        queryScore
        resultType
        label
        houseNumber
        street
        postcode
        city
        district
        county
        state
        country
      ].join('|')

      api_key = ::GeocoderWrapper.config[:ruby_geocode][:here]
      params = {
        apiKey: api_key,
        serviceHrn: mode,
        outputColumns: outcols,
      }

      RestClient::Request.execute(
        method: :post,
        url: @batch_url,
        headers: {
          params: params,
          content_type: 'text/plain'
        },
        payload: ([columns] + payload).flatten.join("\n"),
      ) do |response|
        case response.code
        when 201
            job = JSON.parse(response.body)
            job_id = job['id']
            href = job['href']

            status = job['status']
            until status && %w[completed success failure deleted].include?(status)
              sleep(6)
              response = RestClient::Request.execute(
                method: :get,
                url: href,
                headers: {
                  params: {
                    apiKey: api_key
                  }
                }
              )

              job = JSON.parse(response.body)
              status = job['status']
              href = job['href']
              results_href = job['resultsHref']
              errors_href = job['errorsHref']
            end

            if status == 'failure'
              response = RestClient::Request.execute(
                method: :get,
                url: errors_href,
                headers: {
                  params: {
                    apiKey: api_key
                  }
                }
              )
              raise response.body
            end

            response = RestClient::Request.execute(
              method: :get,
              url: results_href,
              headers: {
                params: {
                  apiKey: api_key
                },
              }
            )

            results = response.body.split("\n")
            headers = results[0].split('|')
            results = results.drop(1).collect{ |row|
              headers.zip(row.split('|')).to_h
            }
            build_features(nil, results, nil, true)
        else
          raise response
        end
      end
    end

    def house_number(data)
      ['block', 'subblock', 'houseNumber', 'building'].collect{ |p| data[p] }.select{ |p| p }.join(' ')
    end

    def features(query, data)
      number = house_number(data['address'])
      {
        properties: {
          geocoding: {
            geocoder_version: version(query),
            score: data.dig('scoring', 'queryScore') || (data['distance'] == 0 ? 1 : [1, 100.0 / data['distance']].min ), # No score for reverse, use distance
            type: @match_level[data['resultType']],
            label: data['address']['label'],
            name: "#{number} #{data['address']['street']}".strip,
            housenumber: number,
            street: data['address']['street'],
            postcode: data['address']['postalCode'],
            city: data['address']['city'],
            district: data['address']['district'],
            county: data['address']['county'],
            state: data['address']['state'],
            country: data['address']['countryName'],
          }.delete_if{ |_k, v| v.nil? || v == '' }
        },
        type: 'Feature',
        geometry: {
          coordinates: [
            data.dig('access', 0, 'lng') || data['position']['lng'],
            data.dig('access', 0, 'lat') || data['position']['lat']
          ],
          type: 'Point'
        }
      }
    end

    def autocomplete_features(query, data)
      number = house_number(data['address'])
      {
        properties: {
          geocoding: {
            geocoder_version: version(query),
            type: @match_level[data['resultType']],
            label: data['address']['label'],
            name: "#{number} #{data['address']['street']}".strip,
            housenumber: number,
            street: data['address']['street'],
            postcode: data['address']['postalCode'],
            city: data['address']['city'],
            district: data['address']['district'],
            county: data['address']['county'],
            state: data['address']['state'],
            country: data['address']['countryName'],
          }.delete_if { |_, v| v.nil? || v == '' }
        }
      }
    end

    def bulk_features(bulk_data)
      bulk_data.map do |data|
        if !data['accessLongitude'] && !data['positionLongitude']
          {
            properties: {
              geocoding: {
              }
            }
          }
        else
          number = house_number(data)
          {
            properties: {
              geocoding: {
                geocoder_version: version,
                score: data['queryScore'],
                type: @match_level[data['resultType']],
                label: data['label'],
                name: "#{number} #{data['street']}".strip,
                housenumber: number,
                street: data['street'],
                postcode: data['postalCode'],
                city: data['city'],
                district: data['district'],
                county: data['county'],
                state: data['state'],
                country: data['countryName'],
              }.delete_if{ |_k, v| v.nil? || v == '' }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                data['accessLongitude'] == '' ?  data['positionLongitude'] : data['accessLongitude'],
                data['accessLatitude'] == '' ? data['positionLatitude'] : data['accessLatitude']
              ],
              type: 'Point'
            }
          }
        end
      end
    end
  end
end
