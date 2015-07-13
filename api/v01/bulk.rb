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

require './api/v01/entities/geocodes_request'
require './api/v01/entities/geocodes_result'
require './api/v01/entities/reverses_request'
require './api/v01/entities/reverses_result'

module Api
  module V01
    class Bulk < Grape::API
      version '0.1', using: :path
      format :json
      content_type :json, 'application/json; charset=UTF-8'
      default_format :json

      rescue_from :all do |error|
        message = {error: error.class.name, detail: error.message}
        if ['development'].include?(ENV['APP_ENV'])
          message[:trace] = error.backtrace
          STDERR.puts error.message
          STDERR.puts error.backtrace
        end
        error!(message, 500)
      end

      desc 'Geocode from bulk json address. From full text or splited in fields.', {
        nickname: 'geocodes',
        params: GeocodesRequest.documentation,
        entity: GeocodesResult,
        is_array: true
      }
      post '/geocodes' do
        results = AddokWrapper::wrapper_geocodes(params['geocodes'])
        if results
          results = {geocodes: results}
          status 200
          present results, with: GeocodesResult
        else
          error!('500 Internal Server Error', 500)
        end
      end


      desc 'Reverse geocode from bulk json address.', {
        nickname: 'reverses',
        params: ReversesRequest.documentation,
        entity: ReversesResult,
        is_array: true
      }
      post '/reverses' do
        params['reverses'].each{ |param|
          param[:lat] = param[:lat].to_f
          param[:lng] = param[:lng].to_f
        }
        results = AddokWrapper::wrapper_reverses(params['reverses'])
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
