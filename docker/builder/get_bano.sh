#!/bin/bash
DEP=${1:-2A} # default Corsica 2A
PROJECT=${2:-geocoder-api}

set -e

echo "Your variables are : PROJECT : $PROJECT, DEPARTMENT: $DEP"

# Download and load BAN
if [ "${DEP}" == full ]; then
  BAN="http://bano.openstreetmap.fr/data/full.sjson.gz"
else
  BAN="http://bano.openstreetmap.fr/data/bano-${DEP}.json.gz"
fi
wget "$BAN" -O "./addresses/BAN_odbl.sjson.gz"
