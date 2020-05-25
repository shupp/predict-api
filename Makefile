API_IMAGE = predictphp/api
DB_IMAGE = predictphp/mariadb-timezone-data
DOCKER_CACHE_ARG := ${DOCKER_CACHE_ARG}

DB_HOST := mysql
DB_PORT := 3306
DB_DATABASE := predict-api
DB_USERNAME := root
DB_PASSWORD := password

help:
	@grep '^[^#[:space:]].*:' Makefile \
		| awk -F: '{ print $$1 }' \
		| sort

# Build targets
build: build-api build-db
build-api:
	docker build $(DOCKER_CACHE_ARG) -t $(API_IMAGE) .
build-db:
	docker build $(DOCKER_CACHE_ARG) -f Dockerfile.mariadb-timezone-data -t $(DB_IMAGE) .
build-no-cache:
	$(MAKE) build DOCKER_CACHE_ARG=--no-cache

# Run targets
up:
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose up -d
down:
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose down
logs:
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose logs -f

# Debug targets
# Get a shell on the running api service container
bash:
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose exec api bash -o vi
# Start the api contiainer on its own with just a shell
run-bash:
	docker run --entrypoint /bin/bash --rm -it $(API_IMAGE)

mysql-client:
	mysql -u $(DB_USERNAME) -p$(DB_PASSWORD) -P$(DB_PORT) -h 127.0.0.1 $(DB_DATABASE)
