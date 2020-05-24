API_IMAGE = predictphp/api
DB_IMAGE = predictphp/mariadb-timezone-data
DOCKER_CACHE_ARG := ${DOCKER_CACHE_ARG}

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
	docker-compose up -d
down:
	docker-compose down
logs:
	docker-compose logs -f

# Debug targets
# Get a shell on the running api service container
bash:
	docker-compose exec api bash -o vi
# Start the api contiainer on its own with just a shell
run-bash:
	docker run --entrypoint /bin/bash --rm -it $(API_IMAGE)
