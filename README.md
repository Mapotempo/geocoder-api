Geocoder API
============
Offers an unified API for multiple geocoders like [Addok](https://github.com/etalab/addok), OpenCageData, Here, Google based on countries distribution.
Build in Ruby with a [Grape](https://github.com/intridea/grape) REST [swagger](http://swagger.io/) API compatible with [geocodejson-spec](https://github.com/yohanboniface/geocodejson-spec).

Prerequisite
============

You need to install prerequisite packages :

```
apt-get install -y git build-essential zlib1g-dev gdal-bin zlib1g libsqlite3-mod-spatialite libsqlite3-dev libspatialite-dev
```

Installation
============

If you need to create a kml, install package containing ogr2ogr exec from system package (GDAL).

In geocoder-api as root directory:

```
bundle install
# Download and build French KML boundaries
(cd contrib && sh ./osm2france+dom-geojson.sh)
```


Configuration
=============

Adjust config/environments files.


Running
=======

```
bundle exec rake server
```

And in production mode:
```
APP_ENV=production bundle exec rake server
```

Usage
=====

The API is defined in Swagger format at
http://localhost:8558/swagger_doc
and can be tested with Swagger-UI
http://swagger.mapotempo.com/?url=http://geocode.mapotempo.com/swagger_doc

Geocoding and Address completion
---------------------------------
The search can be done by full text free form or by fields. Prefer fields form when you have an already splitted address. For any form, the country is a required field, use a simple country name or code in two or three chars.

Search can be guided by proximity. Set latitude and longitude of an close location.

Reverse geocoding
-----------------
Retrieve the closest address from latitude and longitude position by GET request.

Unitary request
---------------
Unitary requesting convert only one address or coordinates at once using GET request.

Geocoding:

```
http://localhost:8558/0.1/geocode.json?&api_key=demo&country=fr&query=2+Avenue+Pierre+Angot+64000+Pau
```

Returns geocodejson (and geojson) valid result:
```
{
  "type":"FeatureCollection",
  "geocoding":{
    "version":"draft",
    "licence":"ODbL",
    "attribution":"BANO",
    "query":"2 Avenue Pierre Angot 64000 Pau"
  },
  "features":[
    {
      "properties":{
        "geocoding":{
          "score":0.7223744186046511,
          "type":"house",
          "label":"2 Avenue du Président Pierre Angot 64000 Pau",
          "name":"2 Avenue du Président Pierre Angot",
          "housenumber":"2",
          "postcode":"64000",
          "city":"Pau"
        }
      },
      "type":"Feature",
      "geometry":{
        "coordinates":[
          -0.367199,
          43.319972
        ],
        "type":"Point"
      }
    }
  ]
}
```


Reverse:
```
http://geocode.mapotempo.com/0.1/reverse.json?api_key=demo&lat=44&lng=0
```

```
{
  "type": "FeatureCollection",
  "geocoding": {
    "version": "draft",
    "licence": "ODbL",
    "attribution": "BANO"
  },
  "features": [
    {
      "properties": {
        "geocoding": {
          "score": 0.9999613672785329,
          "type": "house",
          "label": "1905 Chemin de la Lanne 40310 Gabarret",
          "name": "1905 Chemin de la Lanne",
          "housenumber": "1905",
          "postcode": "40310",
          "city": "Gabarret"
        }
      },
      "type": "Feature",
      "geometry": {
        "coordinates": [
          0.001275,
          44.002642
        ],
        "type": "Point"
      }
    }
  ]
}
```

Batch request
-------------
Batch convert a list in json or CSV format using POST request.

```
curl -v -X POST -H "Content-Type: text/csv" --data-binary @in.csv http://localhost:8558/0.1/geocode.csv?api_key=demo > out.csv
```
