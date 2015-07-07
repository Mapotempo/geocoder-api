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
require 'rgeo'
require 'rgeo/geo_json'


module Wrappers
  class Wrapper
    def initialize(boundary = nil)
      if boundary
        json = File.open(boundary, "r").read
        @boundary = RGeo::GeoJSON.decode(json, json_parser: :json)
      end
    end

    def geocode(params, limit = 10)
      raise NotImplementedError
    end

    def reverse?(lat, lng)
      if @boundary
        contains?(lat, lng)
      else
        true
      end
    end

    def reverse(params)
      raise NotImplementedError
    end

    def geocodes(list_params)
      list_params.collect{ |params|
        features = geocode(params, limit = 1)[:features]
        if features.size > 0
          f = features[0]
          f[:properties][:geocoding][:ref] = params['ref']
          f
        end
      }.select{ |p|
        !p.nil?
      }
    end

    def reverses(list_params)
      list_params.collect{ |params|
        features = reverse(params)[:features]
        if features.size > 0
          f = features[0]
          f[:properties][:geocoding][:ref] = params['ref']
          f
        end
      }.select{ |p|
        !p.nil?
      }
    end

    def complete(params, limit = 10)
      raise NotImplementedError
    end

    private

    def flatten_query(params)
      if params[:query]
        params[:query]
      else
        [params[:housenumber], params[:street], params[:postcode], params[:city]].select{ |i| not i.nil? }.join(' ')
      end
    end

    def contains?(lat, lng)
      if !lat.nil? && !lng.nil?
        point = RGeo::Cartesian.factory.point(lng, lat)
        @boundary.contains?(point)
      end
    end
  end
end
