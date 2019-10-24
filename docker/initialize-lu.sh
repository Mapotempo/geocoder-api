#!/bin/bash

PROJECT=$1

die() {
  echo $*
  exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

rm -f ${GEOCODER_DATA_DIR}data-lu/*
docker service update ${PROJECT}_redis-server-lu

wget https://download.data.public.lu/resources/adresses-georeferencees-bd-adresses/20170918-053115/addresses.geojson -O ${GEOCODER_DATA_DIR}addresses-lu/addresses.geojson

jq -c '.features |
map(.properties + {lon: .geometry.coordinates[0][0], lat: .geometry.coordinates[0][1]}) |
group_by(.code_postal, .localite, .id_caclr_rue, .rue) |
map({name: .[0].rue, city: .[0].localite, postcode: .[0].code_postal, housenumbers: map({(.numero): {lat: .lat, lon: .lon}}) | add }) |
.[] |
{type: "street", city: .city, name: .name, postcode: .postcode, lat: ((.housenumbers | map(.lat) | add) / (.housenumbers | length)), lon: ((.housenumbers | map(.lon) | add) / (.housenumbers | length)), importance: 0.2, housenumbers: .housenumbers} |
del(.housenumbers."")' ${GEOCODER_DATA_DIR}addresses-lu/addresses.geojson > ${GEOCODER_DATA_DIR}addresses-lu/streets.json

jq -s -c 'group_by(.city) |
map({name: .[0].city, postcode: map(.postcode) |
unique, lat: map(.lat) |
add, lon: map(.lon) |
add, size: length}) |
map({type: "municipality", name: .name, city: .name, postcode: .postcode, lat: (.lat / .size), lon: (.lon / .size), importance: [1, .size / 20 + 0.2] | min}) |
.[]' ${GEOCODER_DATA_DIR}addresses-lu/streets.json > ${GEOCODER_DATA_DIR}addresses-lu/cities.json

cat ${GEOCODER_DATA_DIR}addresses-lu/cities.json ${GEOCODER_DATA_DIR}addresses-lu/streets.json > ${GEOCODER_DATA_DIR}addresses-lu/addresses.json

echo "Creating Addok building service."
docker service create \
  --restart-condition=none \
  --mount type=bind,source=${GEOCODER_DATA_DIR}addok-lu.conf,target=/etc/addok/addok.conf \
  --mount type=bind,source=${GEOCODER_DATA_DIR}addresses-lu,target=/addresses \
  --network ${PROJECT}_addok_lu \
  --network ${PROJECT}_redis_server_lu \
  --entrypoint /bin/bash \
  --name ${PROJECT}_build \
  ${REGISTRY}mapotempo/addok:${ADDOK_VERSION:-latest} \
  -c 'addok batch /addresses/addresses.json'

echo "Waiting for Addok building service to finish."
while true;
do
  STATE=$(docker service ps -q ${PROJECT}_build --filter 'desired-state=Shutdown')
  if [ -n "${STATE}" ]; then break; fi
  sleep 1
done
echo "Cleanup Addok building service."
docker service rm ${PROJECT}_build >/dev/null 2>&1

echo "NGrams"
docker exec $(docker ps -q -f name=${PROJECT}_addok-lu.1) addok ngrams

echo "redis-cli"
docker exec $(docker ps -q -f name=${PROJECT}_redis-server-lu.1) redis-cli BGSAVE
