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
module Api
  module V01
    class GeocodesRequestFeature < Grape::Entity
      def self.entity_name
        'GeocodesRequestFeature'
      end

      expose(:ref, documentation: { type: String, desc: 'Row Ref for bulk request, returned in result.' })
      expose(:country, documentation: { type: String, desc: 'Simple country name, ISO 3166-alpha-2 or ISO 3166-alpha-3.' })
      expose(:housenumber, documentation: { type: String, desc: 'Row Ref from bulk request.' })
      expose(:street, documentation: { type: String, desc: 'Street of the place.' })
      expose(:locality, documentation: { type: String, desc: 'Locality of the place.' })
      expose(:maybe_street, documentation: { type: Array[String], desc: 'One undetermined entry of the array is the street, selects the good one for the geocoding process. Need to add an empty entry as alternative if you are unsure if there is a street in the list. Mutually exclusive field with street field.', is_array: true })
      expose(:postcode, documentation: { type: String, desc: 'Postcode of the place.' })
      expose(:city, documentation: { type: String, desc: 'City of the place.' })
      expose(:state, documentation: { type: String, desc: 'State of the place.' })
      expose(:query, documentation: { type: String, desc: 'Full text, free form, address search.' })
      expose(:type, documentation: { type: String, desc: 'Queried result type filter. One of "house", "street", "locality", "city", "region", "country".' })
      expose(:lat, documentation: { type: Float, desc: 'Prioritize results around this latitude.' })
      expose(:lng, documentation: { type: Float, desc: 'Prioritize results around this longitude.' })
    end
  end
end
