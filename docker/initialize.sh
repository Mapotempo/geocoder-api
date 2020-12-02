#!/bin/bash

PROJECT=$1
COUNTRY=${2:-fr}
DEP=$3

die() {
  echo $*
  echo "your variables are : PROJECT : $PROJECT, COUNTRY : $COUNTRY, DEPARTMENT: $DEP"
  exit 1
}

set -e

[ -n $PROJECT ] || die "You must pass a project name in parameter. For example: $0 geocoder"
[ "$COUNTRY" == "fr" ] || [ "$COUNTRY" == "lu" ] || die "Country should be fr or lu"

export GEOCODER_DATA_DIR=$(dirname $(readlink -f $0))
rm -f ${GEOCODER_DATA_DIR}/data-${COUNTRY}/dump.rdb
docker service update ${PROJECT}_redis-server-${COUNTRY}

export ADDOK_VERSION=${ADDOK_VERSION:-1.1.0-rc1-2}
${GEOCODER_DATA_DIR}/initialize-${COUNTRY}.sh ${PROJECT} ${DEP}

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
docker exec $(docker ps -q -f name=${PROJECT}_addok-${COUNTRY}.1) addok ngrams

echo "redis-cli"
docker exec $(docker ps -q -f name=${PROJECT}_redis-server-${COUNTRY}.1) redis-cli BGSAVE

