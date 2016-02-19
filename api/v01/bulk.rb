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
require './api/v01/api_base'
require './api/geojson_formatter'
require './api/v01/entities/geocodes_request'
require './api/v01/entities/geocodes_result'
require './api/v01/entities/reverses_request'
require './api/v01/entities/reverses_result'

module Api
  module V01
    class Bulk < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      default_format :json
      version '0.1', using: :path

      resource :geocode do
        desc 'Geocode from bulk json address. From full text or splited in fields.', {
          nickname: 'geocodes',
          params: GeocodesRequest.documentation.deep_merge(
            geocodes: { required: true }
          ),
          entity: [GeocodesResult, GeocodesRequest],
        }
        post do
          if !params.key?('geocodes') || !params['geocodes'].kind_of?(Array)
            error!('400 Bad Request. Missing or invalid field "geocodes".', 400)
          end
          results = AddokWrapper::wrapper_geocodes(APIBase.services(params[:api_key]), params[:geocodes])
          if results
            results = {geocodes: results}
            status 200
            present results, with: GeocodesResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end

      resource :reverse do
        desc 'Reverse geocode from bulk json address.', {
          nickname: 'reverses',
          params: ReversesRequest.documentation.deep_merge(
            reverses: { required: true }
          ),
          entity: [ReversesResult, ReversesRequest],
        }
        post do
          if !params.key?('reverses') || !params['reverses'].kind_of?(Array)
            error!('400 Bad Request. Missing or invalid field "reverses".', 400)
          end
          params['reverses'].each{ |param|
            begin
              param[:lat] = Float(param[:lat].gsub(',', '.'))
              param[:lng] = Float(param[:lng].gsub(',', '.'))
            rescue
              param[:lat] = nil
              param[:lng] = nil
            end
          }
          results = AddokWrapper::wrapper_reverses(APIBase.services(params[:api_key]), params[:reverses])
          if results
            results = {reverses: results}
            status 200
            present results, with: ReversesResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end
    end
  end
end
