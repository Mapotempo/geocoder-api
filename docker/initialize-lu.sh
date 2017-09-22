#!/bin/bash

PROJECT=$1

die() {
    echo $*
    exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

docker-compose -p ${PROJECT} rm -sf redis-server-lu
docker volume rm ${PROJECT}_data-lu
docker-compose -p ${PROJECT} up -d redis-server-lu

wget https://download.data.public.lu/resources/adresses-georeferencees-bd-adresses/20170918-053115/addresses.geojson -O data-lu/addresses.geojson

jq -c '.features |
map(.properties + {lon: .geometry.coordinates[0][0], lat: .geometry.coordinates[0][1]}) |
group_by(.code_postal, .localite, .id_caclr_rue, .rue) |
map({name: .[0].rue, city: .[0].localite, postcode: .[0].code_postal, housenumbers: map({(.numero): {lat: .lat, lon: .lon}}) | add }) |
.[] |
{type: "street", city: .city, name: .name, postcode: .postcode, lat: ((.housenumbers | map(.lat) | add) / (.housenumbers | length)), lon: ((.housenumbers | map(.lon) | add) / (.housenumbers | length)), importance: 0.2, housenumbers: .housenumbers} |
del(.housenumbers."")' data-lu/addresses.geojson > data-lu/streets.json

jq -s -c 'group_by(.city) |
map({name: .[0].city, postcode: map(.postcode) |
unique, lat: map(.lat) |
add, lon: map(.lon) |
add, size: length}) |
map({type: "municipality", name: .name, city: .name, postcode: .postcode, lat: (.lat / .size), lon: (.lon / .size), importance: [1, .size / 20 + 0.2] | min}) |
.[]' data-lu/streets.json > data-lu/cities.json

cat data-lu/cities.json data-lu/streets.json > data-lu/addresses.json

docker-compose -p ${PROJECT} run --volume $PWD/data-lu:/data --volume $PWD/addok-lu.conf:/etc/addok/addok.conf --entrypoint /bin/bash addok-lu -c "cat data/addresses.json | addok batch"

docker-compose -p ${PROJECT} exec addok-lu addok ngrams

docker-compose -p ${PROJECT} exec redis-server-lu redis-cli BGSAVE
