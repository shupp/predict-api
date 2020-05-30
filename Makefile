API_IMAGE = predictphp/api
DB_IMAGE = predictphp/mariadb-timezone-data
DOCKER_CACHE_ARG := ${DOCKER_CACHE_ARG}

DB_HOST := mysql
DB_PORT := 3306
DB_DATABASE := predict-api
DB_USERNAME := root
DB_PASSWORD := password

help:
	@grep '^[^#[:space:]]\+:' Makefile \
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


## HELPERS ##
# Start the api contiainer on its own with just a shell
run-bash:
	docker run --entrypoint /bin/bash --rm -it $(API_IMAGE)

mysql-client:
	mysql -u $(DB_USERNAME) -p$(DB_PASSWORD) -P$(DB_PORT) -h 127.0.0.1 $(DB_DATABASE)

open-map:
	@echo "Opening leafletjs example ..."
	open examples/leafletjs/index.html

wait-until-api-ready:
	@echo "Waiting for API to be ready ..."
	@TRIES=60; \
	SLEEP=1;  \
	COUNT=0;  \
	OK=error; \
	while [ "$${OK}" != "ok" ] && [ $${COUNT} -lt $${TRIES} ]; do \
		OK=$$(curl -s http://localhost:8080/v2/healthcheck | jq -r .status 2>/dev/null); \
		COUNT=$$((COUNT + 1)); \
		if [ "$${OK}" != "ok" ]; then \
			sleep $${SLEEP}; \
			echo "Waiting ..."; \
		else \
			echo "Done."; \
		fi; \
	done; \
	if [ "$${OK}" != "ok" ]; then \
		echo "Timed out."; \
	fi

refresh-iss-tle:
	@echo "Refreshing the ISS tle from CelesTrak ..."
	curl -s -X POST http://localhost:8080/v2/satellites/25544/tle/refresh | jq -r .
