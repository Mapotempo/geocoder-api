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


    def initialize(boundary = nil)
      super(boundary)
    end

    def geocode(params, limit = 10)
      opencagedata_geocoder(flatten_query(params), limit)
    end

    def reverse(params)
      opencagedata_geocoder([params[:lat], params[:lng]], 1)
    end

    private

    def opencagedata_geocoder(q, limit)
      Geocoder::Configuration.lookup = :opencagedata
      Geocoder::Configuration.api_key = ::AddokWrapper::config[:ruby_geocode][Geocoder::Configuration.lookup]
      response = Geocoder.search(q, params: {limit: limit})
      features = response.collect{ |r|
        a = r.data
        # http://geocoder.opencagedata.com/api.html
        f = {
          properties: {
            geocoding: {
              score: a['confidence'] / 10.0,
              type: nil,
              label: a['formatted'],
              name: nil,
              housenumber: a['components']['house_number'],
              street: a['components']['road'],
              postcode: a['components']['postcode'],
              city: a['components']['town'] || a['components']['city'] || a['components']['state_district'],
              district: nil,
              county: a['components']['county'],
              state: a['components']['state'],
              country: a['components']['country'],
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
      r
    end
  end
end
