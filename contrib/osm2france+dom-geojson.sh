#!/usr/sh

# Download French boundaries
IDS="1403916 1401835 1891495 1260551 1785276 1259885"
rm *.geojson
for ID in $IDS ; do
 wget "http://polygons.openstreetmap.fr/?id=$ID&params=0" -O /dev/null # Call the generator
 wget "http://polygons.openstreetmap.fr/get_geojson.py?id=$ID&params=0" -O $ID.geojson
done

# Merge geojson
cat 1*.geojson | \
  sed -e 's/^{"type":"GeometryCollection","geometries":\[{"type":"MultiPolygon","coordinates":\[//' -e 's/]}]}$/,/' >> france.tmp
echo '{"type":"GeometryCollection","geometries":[{"type":"MultiPolygon","coordinates":[' > france.geojson
cat france.tmp | tr -d '\n' | sed -e 's/,$//' >> france.geojson
echo ']}]}' >> france.geojson

# Convert ot KML
ogr2ogr -f "KML" ../france.kml france.geojson
