Addok Wrapper
================
Offers an unified API for multiple [Addok](https://github.com/etalab/addok) geocoder and other geocoders based on countries distribution.
Build in Ruby with a [Grape](https://github.com/intridea/grape) REST [swagger](http://swagger.io/) API compatible with [geocodejson-spec](https://github.com/yohanboniface/geocodejson-spec).

Installation
============

```
bundle install
# Download French boundaries
wget "http://polygons.openstreetmap.fr/get_geojson.py?id=2202162&params=0.004000-0.001000-0.001000" -O france.geojson
```


Configuration
=============

Adjust config/environments files.


Running
=======

```
bundle exec rake server
```
