Download GeoJson from https://mapzen.com/data/borders/

## Convert to SQLite

Merge geojson admin level

    jq -s '.[0].features + .[1].features | {type: "FeatureCollection", features: .}' admin_level_8.geojson admin_level_6.geojson > admin_level_x.geojson

Convert to Spatialite

    ogr2ogr -sql "SELECT name, '' AS label, admin_level FROM admin_level_x" -f "SQLite" -dsco "SPATIALITE=YES" -nln admin_level_x admin_level_x.sqlite admin_level_x.geojson
    # ogr2ogr -sql "SELECT name, '' AS label, admin_level FROM ogrgeojson" -f "SQLite" -dsco "SPATIALITE=YES" -nln admin_level_x admin_level_x.sqlite admin_level_x.geojson

Extend the admin level 8 names with the admin level 6 names

    echo "
    UPDATE
      admin_level_x
    SET
      label = name || ', ' || (
        SELECT
          name
        FROM
          admin_level_x AS s
        WHERE
          s.admin_level = '6' AND
          ST_Within(ST_Centroid(admin_level_x.Geometry), s.Geometry) AND
          ROWID IN (
            SELECT
              ROWID FROM SpatialIndex
            WHERE
              f_table_name = 'admin_level_x' AND
              search_frame = ST_Centroid(admin_level_x.Geometry))
        LIMIT 1
    )
    WHERE
      admin_level = '8'
    ;" | spatialite admin_level_x.sqlite

Extract the admin level 8 only

    ogr2ogr -select name,label -sql "SELECT * FROM admin_level_x WHERE admin_level='8'" -f "SQLite" -dsco "SPATIALITE=YES" -lco SPATIAL_INDEX=YES -nln poly admin_level_8.sqlite admin_level_x.sqlite


## Request a point

    SELECT
        name,
        label
    FROM
        poly
    WHERE
        st_within(GeomFromText('POINT(6.1390 49.6139)'), Geometry) AND
        ROWID IN (SELECT ROWID FROM SpatialIndex WHERE f_table_name = 'poly' AND search_frame = GeomFromText('POINT(6.1390 49.6139)'))
    ;
