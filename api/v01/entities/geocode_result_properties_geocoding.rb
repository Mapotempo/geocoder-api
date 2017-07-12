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
require './api/v01/entities/entity'

module Api
  module V01
    class GeocodeResultPropertiesGeocoding < Grape::Entity
      def self.entity_name
        'GeocodeResultPropertiesGeocoding'
      end

      ## Spec from https://github.com/geocoders/geocodejson-spec

      # Not in spec
      expose_not_nil(:score, documentation: { type: Float, desc: 'Quality of result. 1 better, 0 worst.' })
      # Not in spec
      expose_not_nil(:ref, documentation: { type: Float, desc: 'Row Ref from bulk request.' })

      # REQUIRED
      expose_not_nil(:type, documentation: { type: String, desc: 'One of "house", "street", "locality", "city", "region", "country".' })
      # OPTIONAL
      expose_not_nil(:accuracy, documentation: { type: Integer, desc: 'Result accuracy, in meters.' })
      # RECOMMENDED
      expose_not_nil(:label, documentation: { type: String, desc: 'Suggested label for the result.' })
      # OPTIONAL
      expose_not_nil(:name, documentation: { type: String, desc: 'Name of the place.' })
      # OPTIONAL.
      expose_not_nil(:housenumber, documentation: { type: String, desc: 'Housenumber of the place.' })
      # OPTIONAL.
      expose_not_nil(:street, documentation: { type: String, desc: 'Street of the place.' })
      # Not in spec
      expose_not_nil(:locality, documentation: { type: String, desc: 'Locality of the place.' })
      # OPTIONAL.
      expose_not_nil(:postcode, documentation: { type: String, desc: 'Postcode of the place.' })
      # OPTIONAL.
      expose_not_nil(:city, documentation: { type: String, desc: 'City of the place.' })
      # OPTIONAL.
      expose_not_nil(:district, documentation: { type: String, desc: 'District of the place.' })
      # OPTIONAL.
      expose_not_nil(:county, documentation: { type: String, desc: 'County of the place.' })
      # OPTIONAL.
      expose_not_nil(:state, documentation: { type: String, desc: 'State of the place.' })
      # OPTIONAL.
      expose_not_nil(:country, documentation: { type: String, desc: 'Country of the place.' })
      # OPTIONAL.
      expose_not_nil(:admin, documentation: { type: String, desc: 'Administratives boundaries the feature is included in as defined in http://wiki.osm.org/wiki/Key:admin_level#admin_level' })
      # OPTIONAL.
      expose_not_nil(:geohash, documentation: { type: String, desc: 'Geohash encoding of coordinates (see http://geohash.org/site/tips.html).' })
      # Not in spec
      expose_not_nil(:id, documentation: { type: String, desc: 'ID of the place. Internal ID, uniq for each place or address number.' })
    end
  end
end
