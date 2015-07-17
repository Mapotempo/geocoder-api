Addok Wrapper
================
Offers an unified API for multiple [Addok](https://github.com/etalab/addok) geocoder and other geocoders based on countries distribution.
Build in Ruby with a [Grape](https://github.com/intridea/grape) REST [swagger](http://swagger.io/) API compatible with [geocodejson-spec](https://github.com/yohanboniface/geocodejson-spec).

Installation
============

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
