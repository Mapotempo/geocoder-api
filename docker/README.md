# Using Docker Compose to deploy Mapotempo Geocoder environment

## Building images

```
export REGISTRY='registry.mapotempo.com/'
```

### geocoder
```
docker build -f ./docker/Dockerfile -t ${REGISTRY}mapotempo-ce/geocoder-api:latest .
```

### addok
```
docker build -t ${REGISTRY}mapotempo/addok:latest ./docker/addok
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
