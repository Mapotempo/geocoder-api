# Using Docker Compose to deploy Mapotempo Geocoder environment

## Building images

```
export REGISTRY='registry.mapotempo.com/'
docker-compose -f docker-compose.yml -f docker-compose-build.yml build
```

## Running services
This project uses swarm to launch

```
docker swarm init
```

**Deploy the services (Access it via http://localhost:8083)**

```
export PROJECT_NAME=geocoder
mkdir -p ./docker/redis
docker stack deploy -c ./docker/docker-compose.yml ${PROJECT_NAME}
```

## Initialization

After the first deployment, you need to initialize Addok database.

First, download and put json files in `data` directory. You may may to prefix them with numbers to ensure the order of the import.

Then run the initialization script:

```
./initialize.sh ${PROJECT_NAME}
```
