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
      end
    end
  end
end
