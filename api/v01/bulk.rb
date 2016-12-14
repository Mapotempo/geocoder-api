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
require './api/v01/entities/status'

module Api
  module V01
    module CSVParser
      def self.call(object, env)
        {geocodes: CSV.parse(object, headers: true).collect(&:to_h)}
      end
    end

    module CSVFormatter
      def self.call(object, env)
        if object[:geocodes].size > 0
          CSV.generate{ |csv|
            csv << object[:geocodes].first[:properties][:geocoding].keys + [:lat, :lng]
            object[:geocodes].each{ |o|
              csv << o[:properties][:geocoding].values + (o[:geometry] && o[:geometry][:coordinates] ? [o[:geometry][:coordinates][1], o[:geometry][:coordinates][0]] : [])
            }
          }
        else
         ''
        end
      end
    end

    class Bulk < APIBase
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      content_type :csv, 'text/csv; charset=UTF-8'
      parser :csv, CSVParser
      formatter :geojson, GeoJsonFormatter
      default_format :json
      formatter :csv, CSVFormatter
      version '0.1', using: :path

      resource :geocode do
        desc 'Geocode from bulk json address. From full text or splited in fields.', {
          nickname: 'geocodes',
          params: GeocodesRequest.documentation.deep_merge(
            geocodes: { required: true }
          ),
          success: GeocodesResult,
          failures: [
            {code: 400, model: Status}
          ],
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
            'text/csv; charset=UTF-8'
          ]
        }
        post do
          if !params.key?('geocodes') || !params['geocodes'].kind_of?(Array)
            error!({status: 'Missing or invalid field "geocodes".'}, 400)
          end
          results = AddokWrapper::wrapper_geocodes(APIBase.services(params[:api_key]), params[:geocodes])
          if results
            results = {geocodes: results}
            status 200
            if params['format'] != 'csv'
              present results, with: GeocodesResult
            else
              results
            end
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
          success: ReversesResult,
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
            'text/csv; charset=UTF-8'
          ]
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
