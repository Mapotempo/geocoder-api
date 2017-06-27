Deploy geocoder using docker-compose
####################################

    cp ../config/environments/production.rb
    docker-compose build
    docker-compose -p geocoder up -d
