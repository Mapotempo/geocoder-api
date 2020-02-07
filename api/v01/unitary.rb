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
require './api/v01/entities/geocode_result'

module Api
  module V01
    class Unitary < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      default_format :json

      resource :geocode do
        desc 'Geocode an address. From full text or splited in fields', {
          nickname: 'geocode',
          success: GeocodeResult
        }
        params do
          use :geocode_unitary_params
        end
        get do
          count :geocode
          params[:limit] = [params[:limit] || 10, 10].min
          results = GeocoderWrapper::wrapper_geocode(APIBase.profile(params[:api_key]), params)
          if results && results[:error]
            message = JSON.parse(results[:response].body)["description"]
            error!(message, results[:response].code)
          elsif results
            results[:geocoding][:version] = 'draft#namespace#score'
            count_incr :geocode, transactions: 1
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end

        desc 'Complete an address.', {
          nickname: 'complete',
          success: GeocodeResult
        }
        params do
          use :geocode_unitary_params, type: 'formData'
        end

        patch do
          count :complete
          params[:limit] = [params[:limit] || 10, 10].min
          results = GeocoderWrapper::wrapper_complete(APIBase.profile(params[:api_key]), params)
          if results
            results[:geocoding][:version] = 'draft#namespace#score'
            count_incr :complete, transactions: 1
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end

      resource :reverse do
        desc 'Reverse geocode an address.', {
          nickname: 'reverse',
          success: GeocodeResult
        }
        params { use :reverse_unitary_params }

        get do
          count :reverse
          results = GeocoderWrapper::wrapper_reverse(APIBase.profile(params[:api_key]), params)
          if results
            results[:geocoding][:version] = 'draft#namespace#score'
            count_incr :reverse, transactions: 1
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end
    end
  end
end
