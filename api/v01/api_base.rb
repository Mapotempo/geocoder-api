# Copyright © Mapotempo, 2016
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

module Api
  module V01
    class APIBase < Grape::API

      def self.profile(api_key)
        raise 'Profile missing in configuration' unless ::GeocoderWrapper.config[:profiles].key? ::GeocoderWrapper.access[api_key][:profile]

        ::GeocoderWrapper.config[:profiles][::GeocoderWrapper.access[api_key][:profile]].deep_merge(
          ::GeocoderWrapper.access[api_key].except(:profile)
        )
      end

      helpers do
        params :geocode_unitary_params do |options|
          requires :country, type: String, desc: 'Simple country name, ISO 3166-alpha-2 or ISO 3166-alpha-3.'
          optional :housenumber, type: String
          optional :street, type: String, allow_blank: false
          optional :maybe_street, type: Array[String], desc: 'One undetermined entry of the array is the street, selects the good one for the geocoding process. Need to add an empty entry as alternative if you are unsure if there is a street in the list. Mutually exclusive field with street field.', documentation: { param_type: options[:type] || 'query'}
          mutually_exclusive :street, :maybe_street
          optional :postcode, type: String, allow_blank: false
          optional :city, type: String, allow_blank: false
          optional :state, type: String
          optional :query, type: String, allow_blank: false, desc: 'Full text, free form, address search.'
          at_least_one_of :query, :postcode, :city, :street
          mutually_exclusive :query, :street
          mutually_exclusive :query, :maybe_street
          mutually_exclusive :query, :postcode
          mutually_exclusive :query, :city
          optional :type, type: String, desc: 'Queried result type filter. One of "house", "street", "locality", "city", "region", "country".'
          optional :lat, type: Float, desc: 'Prioritize results around this latitude.'
          optional :lng, type: Float, desc: 'Prioritize results around this longitude.'
          optional :limit, type: Integer, desc: 'Max results numbers. (default and upper max 10)'
        end

        params :reverse_unitary_params do
          requires :lat, type: Float, desc: 'Latitude.'
          requires :lng, type: Float, desc: 'Longitude.'
        end

        def redis_count
          GeocoderWrapper.config[:redis_count]
        end

        def count_time
          @count_time ||= Time.now.utc
        end

        def count_base_key(operation, period = :daily)
          count_date = if period == :daily
            count_time.to_s[0..9]
          elsif period == :monthly
            count_time.to_s[0..6]
          elsif period == :yearly
            count_time.to_s[0..3]
          end
          [
            [:geocoder, operation, count_date].compact,
            [:key, params[:api_key]]
          ].map{ |a| a.join(':') }.join('_')
        end

        def count_key(operation)
          @count_key ||= count_base_key(operation) + '_' + [
            [:ip, (env['action_dispatch.remote_ip'] || request.ip).to_s],
            [:asset, params[:asset]]
          ].map{ |a| a.join(':') }.join('_')
        end

        def count(operation, raise_if_exceed = true, request_size = 1)
          return unless redis_count

          @count_val = redis_count.hgetall(count_key(operation)).symbolize_keys
          if @count_val.empty?
            @count_val = {hits: 0, transactions: 0}
            redis_count.mapped_hmset @count_key, @count_val
            redis_count.expire @count_key, 100.days
          end
          return unless raise_if_exceed

          APIBase.profile(params[:api_key])[:quotas]&.each do |quota|
            op = quota[:operation]
            next unless op.nil? || op == operation

            quota.slice(:daily, :monthly, :yearly).each do |k, v|
              count = redis_count.get(count_base_key(op, k)).to_i
              raise QuotaExceeded.new("Too many #{k} requests", limit: v, remaining: v - count, reset: k) if count + request_size > v
            end
          end
        end

        def count_incr(operation, options)
          return unless redis_count

          count operation, false unless @count_val
          incr = {hits: @count_val[:hits].to_i + 1}
          incr[:transactions] = @count_val[:transactions].to_i + options[:transactions] if options[:transactions]
          redis_count.mapped_hmset @count_key, incr
          return unless options[:transactions]

          APIBase.profile(params[:api_key])[:quotas]&.each do |quota|
            op = quota[:operation]
            next unless op.nil? || op == operation

            quota.slice(:daily, :monthly, :yearly).each do |k, _v|
              redis_count.incrby count_base_key(op, k), options[:transactions]
              redis_count.expire count_base_key(op, k), 366.days
            end
          end
        end
      end
    end
  end
end
