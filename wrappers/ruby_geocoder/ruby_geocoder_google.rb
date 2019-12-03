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
  class RubyGeocoderGoogle < Wrapper
    @@header = {
      type: 'FeatureCollection',
      geocoding: {
        licence: 'Google Maps',
        attribution: 'Google Maps',
        query: nil,
      },
      features: []
    }

    @@location_type = {
      'ROOFTOP' =>  1,
      'RANGE_INTERPOLATED' =>  0.95,
      'GEOMETRIC_CENTER' =>  0.9,
      'APPROXIMATE' =>  0.85,
    }

    @@type = {
      'street_address' => 'house',
      'route' => 'street',
      'intersection' => 'intersection',
      'political' => nil,
      'country' => 'country',
      'administrative_area_level_1' => 'state',
      'administrative_area_level_2' => 'county',
      'administrative_area_level_3' => 'district',
      'administrative_area_level_4' => nil,
      'administrative_area_level_5' => nil,
      'colloquial_area' => nil,
      'locality' => 'city',
      'ward' => nil,
      'sublocality' => nil,
      'neighborhood' => nil,
      'premise' => nil,
      'subpremise' => nil,
      'postal_code' => nil,
      'natural_feature' => nil,
      'airport indicates' => nil,
      'park indicates' => nil,
      'point_of_interest' => nil,
    }

    def initialize(cache, boundary = nil)
      super(cache, boundary)
    end

    def geocode(params, limit = 10)
      key_params = {limit: limit}.merge(params).reject{ |k, v| k == 'api_key'}
      key = [:google, :geocode, Digest::MD5.hexdigest(Marshal.dump(key_params.to_a.sort_by{ |i| i[0].to_s }))]

      r = @cache.read(key)
      if !r
        Geocoder::Configuration.lookup = :google
        Geocoder::Configuration.api_key = ::GeocoderWrapper::config[:ruby_geocode][Geocoder::Configuration.lookup]
        q, response = streets_loop(params, ->(r) { r.size > 0 && @@location_type[r[0].data['geometry']['location_type']] || 0 }) { | params|
          q = flatten_query(params)
          [q, Geocoder.search(q)]
        }
        features = response.collect{ |r|
          a = r.data
          # https://developers.google.com/maps/documentation/geocoding/
          address_components = parse_address_components(a['address_components'])
          {
            properties: {
              geocoding: {
                geocder_version: version,
                score: @@location_type[a['geometry']['location_type']],
                type: @@type[a['type']],
                label: a['formatted_address'],
                name: a['address_components'][0]['short_name'],
                housenumber: address_components['street_number'],
                street: address_components['route'],
                postcode: address_components['postal_code'],
                city: address_components['locality'],
                district: address_components['administrative_area_level_3'],
                county: address_components['administrative_area_level_2'],
                state: address_components['administrative_area_level_1'],
                country: address_components['country'],
              }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                a['geometry']['location']['lng'],
                a['geometry']['location']['lat']
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

    def version(query = nil)
      "#{super} - google"
    end

    private

    def parse_address_components(address_components)
      h = Hash.new{ |h, k| h[k] = nil }
      address_components.each{ |address_component|
        h[address_component['types'][0]] = address_component['short_name']
      }
      h
    end
  end
end
