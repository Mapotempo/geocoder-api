Deploy geocoder using docker-compose
====================================

    # Copy production configuration file
    cp ../config/environments/production.rb
    # Customize production.rb with your settings
    # On line 31 change 'france.kml' to 'poly/france.kml' (or anything else.)
    # Get france.kml and put it in poly directory.

    # Build docker images
    docker-compose build

    # Run docker containers
    docker-compose -p geocoder up -d
