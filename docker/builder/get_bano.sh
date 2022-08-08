#!/bin/bash
DEP=${1:-2A} # default Corsica 2A
PROJECT=${2:-geocoder-api}

set -e

echo "Your variables are : PROJECT : $PROJECT, DEPARTMENT: $DEP"

# Download and load BAN
if [ "${DEP}" == full ]; then
  BAN="https://adresse.data.gouv.fr/data/ban/adresses/latest/addok/adresses-addok-france.ndjson.gz"
else
  BAN="https://adresse.data.gouv.fr/data/ban/adresses/latest/addok/adresses-addok-${DEP}.ndjson.gz"
fi
wget "$BAN" -O "./addresses/BAN_odbl.sjson.gz"
