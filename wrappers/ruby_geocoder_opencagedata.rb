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
  class RubyGeocoderOpencagedata < Wrapper
    @@header = {
      type: 'FeatureCollection',
      geocoding: {
        licence: 'CC-BY-SA, ODbL',
        attribution: 'Data OpenStreetMap and contributors under ODbL. GeoNames under CC-BY',
        query: nil,
      },
      features: []
    }


    def initialize(cache, boundary = nil)
      super(cache, boundary)
    end

    def geocode(params, limit = 10)
      opencagedata_geocoder(flatten_query(params), limit)
    end

    def reverse(params)
      opencagedata_geocoder([params[:lat], params[:lng]], 1)
    end

    private

    def opencagedata_geocoder(q, limit)
      key = [:opencagedata, :geocode, Digest::MD5.hexdigest(Marshal.dump({q: q, limit: limit}.to_a.sort_by{ |i| i[0].to_s }))]
      r = @cache.read(key)
      if !r
        Geocoder::Configuration.lookup = :opencagedata
        Geocoder::Configuration.api_key = ::AddokWrapper::config[:ruby_geocode][Geocoder::Configuration.lookup]
        response = Geocoder.search(q, params: {limit: limit})
        features = response.collect{ |r|
          a = r.data
          # http://geocoder.opencagedata.com/api.html
          c = a['components']
          f = {
            properties: {
              geocoding: {
                score: a['confidence'] / 10.0,
                type: c.key?('house_number') ? 'house' : c.key?('road') ? 'street' : c.key?('city') ? 'city' : c.key?('country') ? 'country' : nil,
                label: a['formatted'],
                name: nil,
                housenumber: c['house_number'],
                street: c['road'],
                postcode: c['postcode'],
                city: c['town'] || c['city'] || c['state_district'],
                district: nil,
                county: c['county'],
                state: c['state'],
                country: c['country'],
              }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                a['geometry']['lng'],
                a['geometry']['lat']
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
  end
end
