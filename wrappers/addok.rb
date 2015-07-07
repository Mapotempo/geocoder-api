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
    def initialize(url, boundary = nil)
      super(boundary)
      @url = url
    end

    def geocode(params, limit = 10)
      addok_geocode(params, limit)
    end

    def reverse(params)
      response = RestClient.get(@url + 'reverse/', {params: {lat: params[:lat], lon: params[:lng]}}) { |response, request, result, &block|
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
      map_spec(json)
    end

    def geocodes(list_params)
    end

    def reverses(list_params)
    end

    def complete(params, limit = 10)
      addok_geocode(params, limit)
    end

    private

    def addok_geocode(params, limit)
      q = flatten_query(params)
      type = params[:type]
      if not ['housenumber', 'street'].include?(type)
        type = nil
      end
      p = params.dup
      p.delete('api_key')
      p.delete('query')
      p.delete('country')
      p.merge!({q: q, type: type})
      p.select!{ |i| i }
      response = RestClient.get(@url + 'search/', {params: p}) { |response, request, result, &block|
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
      map_spec(json)
    end

    def map_spec(json)
      # Convert from geocodejson-spec to geocodejson-spec-namespace
      json['geocoding'] = {
        'licence': json['licence'],
        'attribution': json['attribution'],
        'query': json['query'],
      }.select{ |k, v| not v.nil? }

      json['features'].collect{ |features|
        p = features['properties']
        features['properties']['geocoding'] = {
          'score': p['score'], # Not in spec
          'type': p['type'],
          'accuracy': p['accuracy'],
          'label': p['label'],
          'name': p['name'],
          'housenumber': p['housenumber'],
          'street': p['street'],
          'postcode': p['postcode'],
          'city': p['city'],
          'district': p['district'],
          'county': p['county'],
          'state': p['state'],
          'country': p['country'],
          'admin': p['admin'],
          'geohash': p['geohash'],
        }.select{ |k, v| not v.nil? }
      }

      json
    end
  end
end
