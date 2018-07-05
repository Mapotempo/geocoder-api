#!/bin/bash

PROJECT=$1

die() {
    echo $*
    exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

docker-compose -p ${PROJECT} rm -sf redis-server-fr
rm -f data-fr/*
docker-compose -p ${PROJECT} up -d redis-server-fr

# Download and load BAN
wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O addresses-fr/BAN_odbl.json.bz2
docker-compose -p ${PROJECT} run --entrypoint /bin/bash addok-fr -c "bzcat addresses/BAN_odbl.json.bz2 | jq -c 'del(.housenumbers[]?.id)' | addok batch"

# Patch BAN
docker-compose -p ${PROJECT} run --entrypoint /bin/bash addok-fr -c "ls addresses/*.json | xargs cat | addok batch"

# Index
docker-compose -p ${PROJECT} exec addok-fr addok ngrams

# Save redis db into file
docker-compose -p ${PROJECT} exec redis-server-fr redis-cli BGSAVE
