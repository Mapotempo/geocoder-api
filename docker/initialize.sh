#!/bin/bash
wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O data/BAN_odbl.json.bz2
docker-compose -p geocoder run --volume $PWD/data:/data --entrypoint /bin/bash addok -c "bzcat data/BAN_odbl.json.bz2 | addok --config /etc/addok/config.py batch"

docker-compose -p geocoder run --volume $PWD/data:/data --entrypoint /bin/bash addok -c "ls data/*.json | xargs cat | addok --config /etc/addok/config.py batch"

docker-compose -p geocoder exec addok addok --config /etc/addok/config.py ngrams

