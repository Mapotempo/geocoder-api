#!/bin/bash
wget https://bano.openstreetmap.fr/BAN_odbl/BAN_odbl.json.bz2 -O data/BAN_odbl.json.bz2
bzcat data/BAN_odbl.json.bz2 | docker-compose -p geocoder exec -T addok addok --config /etc/addok/config.py batch

ls data/*.json | xargs  cat | docker-compose -p geocoder exec -T addok addok --config /etc/addok/config.py batch

docker-compose -p geocoder exec addok addok --config /etc/addok/config.py ngrams

