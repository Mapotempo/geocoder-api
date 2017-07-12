#!/bin/bash

PROJECT=$1

die() {
    echo $*
    exit 1
}

set -e

[[ -z "${PROJECT}" ]] && die "You must pass a project name in parameter. For example: $0 geocoder"

docker-compose -p ${PROJECT} rm -sf redis-server
docker volume rm ${PROJECT}_data
docker-compose -p ${PROJECT} up -d redis-server

wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O data/BAN_odbl.json.bz2
docker-compose -p ${PROJECT} run --volume $PWD/data:/data --entrypoint /bin/bash addok -c "bzcat data/BAN_odbl.json.bz2 | addok batch"

docker-compose -p ${PROJECT} run --volume $PWD/data:/data --entrypoint /bin/bash addok -c "ls data/*.json | xargs cat | addok batch"

docker-compose -p ${PROJECT} exec addok addok ngrams

docker-compose -p ${PROJECT} exec redis-server redis-cli BGSAVE
