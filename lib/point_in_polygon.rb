# Copyright © Mapotempo, 2017
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
require 'sqlite3'
require 'ostruct'


class PointInPolygon

  def initialize(sqlite)
    @db = SQLite3::Database.new(sqlite)
    @db.enable_load_extension(1)
    @db.load_extension('mod_spatialite.so')
    @db.enable_load_extension(0)
  end

  def finalize
    @db.close
  end

  def pick(lon, lat)
    sql = "
SELECT
    name,
    label
FROM
    poly
WHERE
    st_within(GeomFromText('POINT(#{lon} #{lat})'), Geometry) AND
    ROWID IN (SELECT ROWID FROM SpatialIndex WHERE f_table_name = 'poly' AND search_frame = GeomFromText('POINT(#{lon} #{lat})'))
LIMIT 1
"
    row = @db.execute(sql).first

    OpenStruct.new(
      type: 'FeatureCollection',
      licence: 'Data © OpenStreetMap contributors',
      attribution: 'ODbL',
      features: row ? [OpenStruct.new(
        properties: OpenStruct.new(
          score: 0.1,
          type: 'municipality',
          label: row[1],
          name: row[0],
          #postcode:
          city: row[0],
        ),
        type: 'Point',
        geometry: OpenStruct.new(
          coordinates: [lon, lat]
        )
      )] : []
    )
  end
end
