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
require './api/v01/entities/geocodes_result'
require './api/v01/entities/reverses_result'
require './api/v01/entities/status'

module Api
  module V01
    module CSVParser
      def self.call(object, env)
        {
          # TODO use encoding from Content-Type or detect it.
          geocodes: CSV.parse(object.force_encoding('utf-8'), headers: true).collect{ |row|
            r = row.to_h
            r['maybe_street'] = row.each.select{ |k, _| k == 'maybe_street' }.collect(&:last).select{ |t| t && t != '' }
            r
          }
        }
      end
    end

    module CSVFormatter
      def self.call(object, env)
        if object[:geocodes].size > 0
          keys = [:score, :type, :accuracy, :label, :name, :housenumber, :street, :locality, :postcode, :city, :district, :county, :state, :country, :admin, :geohash, :id]
          CSV.generate{ |csv|
            csv << (object[:geocodes].first[:properties][:geocoding][:source].keys - ['index']).collect{ |k| 'source_' + k.to_s } + keys + [:lat, :lng]
            object[:geocodes].each{ |o|
              o[:properties][:geocoding][:source][:maybe_street] = o[:properties][:geocoding][:source][:maybe_street].join('|')
              csv << o[:properties][:geocoding][:source].except('index').values.collect{ |v| v.to_s.encode('utf-8') } +
                keys.collect{ |k| o[:properties][:geocoding][k] } + (o[:geometry] && o[:geometry][:coordinates] ? [o[:geometry][:coordinates][1], o[:geometry][:coordinates][0]] : [])
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

      resource :geocode do
        desc 'Geocode from bulk json address. From full text or splited in fields.', {
          nickname: 'geocodes',
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

        params do
          requires :geocodes, type: Array, desc: 'Data to be geocoded.', documentation: {param_type: 'body'} do
            use :geocode_unitary_params, type: 'body'
          end
        end

        post do
          if !params.key?('geocodes') || !params['geocodes'].is_a?(Array)
            error!('Missing or invalid field "geocodes".', 400)
          end
          params_limit = APIBase.profile(params[:api_key])[:params_limit]
          if params_limit[:locations] && params[:geocodes].count > params_limit[:locations]
            error!({message: "Exceeded \"geocodes\" limit authorized for your account: #{params_limit[:locations]}. Please contact support or sales to increase limits."}, 413)
          end
          count :geocode, true, params[:geocodes].count
          results = GeocoderWrapper.wrapper_geocodes(APIBase.profile(params[:api_key]), params[:geocodes])
          if results
            count_incr :geocode, transactions: results.size
            results = { geocodes: results }
            status 200
            if params['format'] != :csv
              present results # No do not use "with: GeocodesResult"
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
          success: ReversesResult,
          produces: [
            'application/json; charset=UTF-8',
            'application/vnd.geo+json; charset=UTF-8',
            'application/xml',
            'text/csv; charset=UTF-8'
          ]
        }

        params do
          requires :reverses, type: Array, desc: 'Data to be reversed.', documentation: {param_type: 'body'} do
            use :reverse_unitary_params
          end
        end

        post do
          if !params.key?(:reverses) || !params[:reverses].is_a?(Array)
            error!('Missing or invalid field "reverses".', 400)
          end
          params_limit = APIBase.profile(params[:api_key])[:params_limit]
          if params_limit[:locations] && params[:reverses].count > params_limit[:locations]
            error!({message: "Exceeded \"reverses\" limit authorized for your account: #{params_limit[:locations]}. Please contact support or sales to increase limits."}, 413)
          end
          count :reverse, true, params[:reverses].count

          params[:reverses].each do |param|
            begin
              param[:lat] = param[:lat].is_a?(Float) ? param[:lat] : Float(param[:lat].gsub(',', '.'))
              param[:lng] = param[:lng].is_a?(Float) ? param[:lng] : Float(param[:lng].gsub(',', '.'))
            rescue
              param[:lat] = nil
              param[:lng] = nil
            end
          end
          results = GeocoderWrapper.wrapper_reverses(APIBase.profile(params[:api_key]), params[:reverses])
          if results
            count_incr :reverse, transactions: results.size
            results = { reverses: results }
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
