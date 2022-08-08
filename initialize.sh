#!/bin/bash

mkdir -p addresses

# shellcheck disable=SC1091
source ./docker/builder/get_bano.sh

docker-compose -p "${PROJECT}" run --rm --entrypoint /bin/bash addok -c "zcat ./addresses/BAN_odbl.sjson.gz | /usr/usr/local/bin/ban_filter.sh | addok batch"

# Patch BAN
docker-compose -p "${PROJECT}" run --rm --entrypoint /bin/bash addok -c "ls ./addresses/*.json | xargs cat | addok batch"

# Index
docker-compose -p "${PROJECT}" exec addok addok ngrams

# Save redis db into file
docker-compose -p "${PROJECT}" exec redis-server redis-cli BGSAVE
