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

require './api/v01/unitary'
require './api/v01/bulk'
require './api/v01/map'

require 'date'

class QuotaExceeded < StandardError
  attr_reader :data

  def initialize(msg, data)
    @data = data
    super(msg)
  end
end

module Api
  module V01
    class Api < Grape::API
      before do
        if !params || !::GeocoderWrapper.access(true).keys.include?(params[:api_key])
          error!('401 Unauthorized', 401)
        end
      end

      rescue_from :all, backtrace: ENV['APP_ENV'] != 'production' do |e|
        @error = e
        if ENV['APP_ENV'] != 'test'
          STDERR.puts "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
        end

        response = {message: e.message}
        if e.is_a?(RangeError) || e.is_a?(Grape::Exceptions::ValidationErrors)
          rack_response(format_message(response, e.backtrace), 400)
        elsif e.is_a?(Grape::Exceptions::MethodNotAllowed)
          rack_response(format_message(response, nil), 405)
        elsif e.is_a?(QuotaExceeded)
          headers = { 'Content-Type' => content_type,
                      'X-RateLimit-Limit' => e.data[:limit],
                      'X-RateLimit-Remaining' => e.data[:remaining],
                      'X-RateLimit-Reset' => if e.data[:reset] == :daily
                                             count_time.to_date.next_day
                                           elsif e.data[:reset] == :monthly
                                             count_time.to_date.next_month
                                           elsif e.data[:reset] == :yearly
                                             count_time.to_date.next_year
                                           end.to_time.to_i }
          rack_response(format_message(response, nil), 429, headers)
        else
          rack_response(format_message(response, e.backtrace), 500)
        end
      end

      mount Unitary
      mount Bulk
      mount Map
    end
  end
end
