#!/bin/bash

PROJECT=$1

die() {
  echo $*
  exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

rm -f ${GEOCODER_DATA_DIR}data-fr/*
docker service update ${PROJECT}_redis-server-fr

wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O ${GEOCODER_DATA_DIR}addresses-fr/BAN_odbl.json.bz2

echo "Creating Addok building service."
docker service create \
  --restart-condition=none \
  --mount type=bind,source=${GEOCODER_DATA_DIR}addok-fr.conf,target=/etc/addok/addok.conf \
  --mount type=bind,source=${GEOCODER_DATA_DIR}addresses-fr,target=/addresses \
  --network ${PROJECT}_addok_fr \
  --network ${PROJECT}_redis_server_fr \
  --entrypoint /bin/bash \
  --name ${PROJECT}_build \
  ${REGISTRY}mapotempo/addok:${ADDOK_VERSION:-latest} \
  -c "bzcat /addresses/BAN_odbl.json.bz2 | jq -c 'del(.housenumbers[]?.id)' | addok batch"

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
docker exec $(docker ps -q -f name=${PROJECT}_addok-fr.1) addok ngrams

echo "redis-cli"
docker exec $(docker ps -q -f name=${PROJECT}_redis-server-fr.1) redis-cli BGSAVE
