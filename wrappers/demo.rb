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

module Wrappers
  class Demo < Wrapper
    @@header = {
      type: 'FeatureCollection',
      geocoding: {
        licence: 'ODbL',
        attribution: 'Demo Data',
        query: '24 allée de Bercy 75012 Paris',
      },
      features: []
    }

    @@feature = {
      properties: {
        geocoding: {
          geocoder_version: 'demo',
          score: 0, # Not in spec
          type: 'house',
          accuracy: 20,
          label: 'My Shoes Shop, 64 rue de Metz 59280 Armentières',
          name: 'My Shoes Shop',
          housenumber: '64',
          street: 'Rue de Metz',
          postcode: '59280',
          city: 'Armentières',
          district: nil,
          county: nil,
          state: nil,
          country: 'France',
          admin: {
            level2: 'France',
            level4: 'Nord-Pas-de-Calais',
            level6: 'Nord'
          },
          geohash: 'Ehugh5oofiToh9aWe3heemu7ighee8',
        }
      },
      type: 'Feature',
      geometry: {
        coordinates: [
          2.889957,
          50.687328
        ],
        type: 'Point'
      }
    }

    def geocode(params, limit = 10)
      r = @@header.dup
      r[:features] = ([@@feature] * limit).collect(&:dup)
      r
    end

    def reverse(params)
      r = @@header.dup
      r[:features] = [@@feature].collect(&:dup)
      r
    end

    def complete(params, limit = 10)
      r = @@header.dup
      r[:features] = ([@@feature] * limit).collect(&:dup)
      r
    end

    def version(query = nil)
      "#{super} - demo"
    end
  end
end
