Using Docker Compose to deploy Mapotempo Router wrapper
=======================================================

Building images
---------------

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose build

Publishing images
-----------------

    docker login
    docker-compose push

Running on a docker host
------------------------

    git clone https://github.com/mapotempo/router-wrapper
    cd router-wrapper/docker
    docker-compose pull

    # Copy production configuration file
    cp ../config/environments/production.rb ./

    # Customize production.rb with your settings
    # On line 31 change `france.kml` to `poly/france.kml` (or anything else.)

    # Get france.kml and put it in `poly` directory.

    # Run docker containers
    docker-compose -p geocoder up -d
