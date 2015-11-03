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
require 'grape'
require 'grape-swagger'

require './api/geojson_formatter'
require './api/v01/entities/geocode_result'

module Api
  module V01
    class Unitary < Grape::API
      content_type :json, 'application/json; charset=UTF-8'
      content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
      content_type :xml, 'application/xml'
      formatter :geojson, GeoJsonFormatter
      default_format :json
      version '0.1', using: :path

      rescue_from :all do |error|
        message = {error: error.class.name, detail: error.message}
        if ['development'].include?(ENV['APP_ENV'])
          message[:trace] = error.backtrace
          STDERR.puts error.message
          STDERR.puts error.backtrace
        end
        error!(message, 500)
      end

      resource :geocode do
        desc 'Geocode an address. From full text or splited in fields', {
          nickname: 'geocode',
          entity: GeocodeResult
        }
        params {
          requires :country, type: String, desc: 'Simple country name, ISO 3166-alpha-2 or ISO 3166-alpha-3.'
          optional :street, type: String
          optional :postcode, type: String
          optional :city, type: String
          optional :query, type: String, desc: 'Full text, free form, address search.'
          at_least_one_of :query, :postcode, :city
          mutually_exclusive :query, :postcode
          mutually_exclusive :query, :city
          optional :type, type: String, desc: 'Queried result type filter. One of "house", "street", "locality", "city", "region", "country".'
          optional :lat, type: Float, desc: 'Prioritize results around this latitude.'
          optional :lng, type: Float, desc: 'Prioritize results around this longitude.'
          optional :limit, type: Integer, desc: 'Max results numbers. (default and upper max 10)'
        }
        get do
          params[:limit] = [params[:limit] || 10, 10].min

          results = AddokWrapper::wrapper_geocode(params)
          if results
            results[:geocoding][:version] = 'draft#namespace#score'
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end

        desc 'Complete an address.', {
          nickname: 'complete',
          entity: GeocodeResult
        }
        params {
          requires :country, type: String, desc: 'Simple country name, ISO 3166-alpha-2 or ISO 3166-alpha-3.'
          optional :housenumber, type: String
          optional :street, type: String
          optional :postcode, type: String
          optional :city, type: String
          optional :query, type: String, desc: 'Full text, free form, address search.'
          optional :type, type: String, desc: 'Queried result type filter. One of "house", "street", "locality", "city", "region", "country".'
          optional :lat, type: Float, desc: 'Prioritize results around this latitude.'
          optional :lng, type: Float, desc: 'Prioritize results around this longitude.'
          optional :limit, type: Integer, desc: 'Max results numbers. (default and upper max 10)'
        }
        patch do
          params[:limit] = [params[:limit] || 10, 10].min
          results = AddokWrapper::wrapper_complete(params)
          if results
            results[:geocoding][:version] = 'draft#namespace#score'
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end

      resource :reverse do
        desc 'Reverse geocode an address.', {
          nickname: 'reverse',
          entity: GeocodeResult
        }
        params {
          requires :lat, type: Float, desc: 'Latitude.'
          requires :lng, type: Float, desc: 'Longitude.'
        }
        get do
          results = AddokWrapper::wrapper_reverse(params)
          if results
            results[:geocoding][:version] = 'draft#namespace#score'
            present results, with: GeocodeResult
          else
            error!('500 Internal Server Error', 500)
          end
        end
      end
    end
  end
end
