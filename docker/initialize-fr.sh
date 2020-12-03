#!/bin/bash

PROJECT=$1
DEP=$2

if [ -z ${DEP} ]; then
  BAN="http://bano.openstreetmap.fr/data/full.sjson.gz"
else
  BAN="http://bano.openstreetmap.fr/data/bano-${DEP}.json.gz"
fi
wget $BAN -O ${GEOCODER_DATA_DIR}/addresses-fr/BAN_odbl.sjson.gz

echo "Creating Addok building service."

ADDOK_HOST=redis-server-fr
ADDOK_ATTRIBUTION=BANO
ADDOK_LICENCE=ODbL

docker service create \
  --restart-condition=none \
  --mount type=bind,source=${GEOCODER_DATA_DIR}/addok/addok.conf,target=/etc/addok/addok.conf \
  --mount type=bind,source=${GEOCODER_DATA_DIR}/addresses-fr,target=/addresses \
  --network ${PROJECT}_addok_fr \
  --network ${PROJECT}_redis_server_fr \
  --entrypoint /bin/bash \
  --name ${PROJECT}_build \
  --env ADDOK_HOST=${ADDOK_HOST} \
  --env ADDOK_ATTRIBUTION=${ADDOK_ATTRIBUTION} \
  --env ADDOK_LICENCE=${ADDOK_LICENCE} \
  ${REGISTRY}mapotempo/addok:${ADDOK_VERSION:-latest} \
  -c "zcat /addresses/BAN_odbl.sjson.gz | jq -c 'del(.housenumbers[]?.id)' | addok batch"


