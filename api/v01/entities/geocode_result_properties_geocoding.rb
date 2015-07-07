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
    class GeocodeResultPropertiesGeocoding < Grape::Entity
      def self.entity_name
        'GeocodeResultPropertiesGeocoding'
      end

      # Not in spec
      expose(:score, documentation: { type: Float, desc: 'Quality of result. 1 better, 0 worst.' })
      # Not in spec
      expose(:ref, documentation: { type: Float, desc: 'Row Ref from bulk request.' })

      # REQUIRED
      expose(:type, documentation: { type: String, desc: 'One of "house", "street", "locality", "city", "region", "country".' })
      # OPTIONAL
      expose(:accuracy, documentation: { type: Integer, desc: 'Result accuracy, in meters.' })
      # RECOMMENDED
      expose(:label, documentation: { type: String, desc: 'Suggested label for the result.' })
      # OPTIONAL
      expose(:name, documentation: { type: String, desc: 'Name of the place.' })
      # OPTIONAL.
      expose(:housenumber, documentation: { type: String, desc: 'Housenumber of the place.' })
      # OPTIONAL.
      expose(:street, documentation: { type: String, desc: 'Street of the place.' })
      # OPTIONAL.
      expose(:postcode, documentation: { type: String, desc: 'Postcode of the place.' })
      # OPTIONAL.
      expose(:city, documentation: { type: String, desc: 'City of the place.' })
      # OPTIONAL.
      expose(:district, documentation: { type: String, desc: 'District of the place.' })
      # OPTIONAL.
      expose(:county, documentation: { type: String, desc: 'County of the place.' })
      # OPTIONAL.
      expose(:state, documentation: { type: String, desc: 'State of the place.' })
      # OPTIONAL.
      expose(:country, documentation: { type: String, desc: 'Country of the place.' })
      # OPTIONAL.
      expose(:admin, documentation: { type: String, desc: 'Administratives boundaries the feature is included in as defined in http://wiki.osm.org/wiki/Key:admin_level#admin_level' })
      # OPTIONAL.
      expose(:geohash, documentation: { type: String, desc: 'Geohash encoding of coordinates (see http://geohash.org/site/tips.html).' })
    end
  end
end
