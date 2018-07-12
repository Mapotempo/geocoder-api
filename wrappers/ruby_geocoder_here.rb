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

require 'geocoder'

module Wrappers
  class RubyGeocoderHere < Wrapper
    @@header = {
      type: 'FeatureCollection',
      geocoding: {
        licence: 'HERE',
        attribution: 'HERE',
        query: nil,
      },
      features: []
    }

    @@match_level = {
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

    def initialize(cache, boundary = nil)
      super(cache, boundary)
    end

    def geocode(params, limit = 10)
      here_geocoder(params, limit) { |params|
        flatten_query(params)
      }
    end

    def reverse(params)
      here_geocoder(params, 1) { |params|
        [params[:lat], params[:lng]]
      }
    end

    private

    def match_quality(mq)
      (mq['Country'] || 0) * 1000 + (mq['City'] || 0) * 100 + (mq['Street'] && mq['Street'][0] || 0) * 10 + (mq['HouseNumber'] || 0)
    end

    def here_geocoder(params, limit)
      key_params = {limit: limit}.merge(params).reject{ |k, v| k == 'api_key'}
      key = [:here, :geocode, Digest::MD5.hexdigest(Marshal.dump(key_params.to_a.sort_by{ |i| i[0].to_s }))]
      r = @cache.read(key)
      if !r
        Geocoder::Configuration.lookup = :here
        Geocoder::Configuration.use_https = true
        Geocoder::Configuration.api_key = ::GeocoderWrapper::config[:ruby_geocode][Geocoder::Configuration.lookup]
        q, response = streets_loop(params, ->(r) { r.size > 0 && match_quality(r[0].data['MatchQuality']) || 0 }) { |params|
          q = yield(params)
          #Geocoder.search(nil, params: {maxresults: limit, city: params[:city], district: params[:district], housenumber: params[:housenumber], postalcode: params[:postcode], state: params[:state], street: params[:street]})
          [q, Geocoder.search(q, params: {maxresults: limit})]
        }
        features = response.collect{ |r|
          a = r.data
          # https://developer.here.com/rest-apis/documentation/geocoder/topics/resource-type-response-geocode.html
          additional_data = parse_address_additional_data(a['Location']['Address']['AdditionalData'])
          {
            properties: {
              geocoding: {
                geocoder_version: version(q),
                score: a['Relevance'],
                type: @@match_level[a['MatchLevel']],
                label: a['Location']['Address']['Label'],
                name: a['Location']['Address']['Name'],
                housenumber: [a['Location']['Address']['HouseNumber'], a['Location']['Address']['Building']].select{ |i| i }.join(' '),
                street: a['Location']['Address']['Street'],
                postcode: a['Location']['Address']['PostalCode'],
                city: a['Location']['Address']['City'],
                #district: a['Location']['Address']['District'], # In HERE API district is a city district
                county: additional_data['CountyName'],
                state: additional_data['StateName'],
                country: additional_data['CountryName'],
              }.delete_if{ |k, v| v.nil? || v == '' }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                a['Location']['DisplayPosition']['Longitude'],
                a['Location']['DisplayPosition']['Latitude']
              ],
              type: 'Point'
            }
          }
        }

        r = @@header.dup
        r[:geocoding][:query] = q
        r[:features] = features
        @cache.write(key, r)
      end

      r
    end

    def parse_address_additional_data(additional_data)
      h = Hash.new{ |h, k| h[k] = nil }
      additional_data.each{ |ad|
        h[ad['key']] = ad['value']
      }
      h
    end

    protected

    def version(query = nil)
      if query != nil
        version_regexp = %r{\/\d+\.\d+\/}
        q = Geocoder::Query.new(query)
        full_url = Geocoder::Lookup.get(:here).query_url(q)
        "#{super} - here:#{full_url[version_regexp].tr('/', '')}"
      else
        "#{super} - here"
      end
    end
  end
end
