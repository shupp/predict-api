API_IMAGE = predictphp/api
DB_IMAGE = predictphp/mariadb-timezone-data
DOCKER_CACHE_ARG := ${DOCKER_CACHE_ARG}

DB_HOST := mysql
DB_PORT := 3306
DB_DATABASE := predict-api
DB_USERNAME := root
DB_PASSWORD := password

help: ## Show this help
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "target" "help" ; \
	printf "%-30s %s\n" "------" "----" ; \
	for help_line in $${help_lines[@]}; do \
		IFS=$$':' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-30s %s" $$help_command ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done

# Build targets
build: build-api build-db ## Build all docker images
build-api: ## Build the predictphp/api image
	docker build $(DOCKER_CACHE_ARG) -t $(API_IMAGE) .
build-db: ## Build the predictphp/mariadb-timezone-data image
	docker build $(DOCKER_CACHE_ARG) -f Dockerfile.mariadb-timezone-data -t $(DB_IMAGE) .
build-no-cache: ## Build both containers with caching disabled
	$(MAKE) build DOCKER_CACHE_ARG=--no-cache

# Run targets
up: ## Docker "up" the containers
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose up -d
down: ## Docker "down" the containers
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose down
logs: ## View and follow docker logs for all containers
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose logs -f

# Debug targets
# Get a shell on the running api service container
bash:  ## Get a bash shell on a running api container
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	docker-compose exec api bash -o vi

bash-db: ## Get a bash shell on a running db container
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_DATABASE=$(DB_DATABASE) \
	DB_USERNAME=$(DB_USERNAME) \
	DB_PASSWORD=$(DB_PASSWORD) \
	SECRET_DB_PASS=$(DB_PASSWORD) \
	docker-compose exec mysql bash -o vi


# HELPERS
# Start the api contiainer on its own with just a shell
run-bash:  ## Run the api container with bash as the entrypoint
	docker run --entrypoint /bin/bash --rm -it $(API_IMAGE)

mysql-client: ## Run mysql and connect to the db container
	mysql -u $(DB_USERNAME) -p$(DB_PASSWORD) -P$(DB_PORT) -h 127.0.0.1 $(DB_DATABASE)

open-map: ## Open up the local leafletjs map example
	@echo "Opening leafletjs example ..."
	open examples/leafletjs/index.html

wait-until-api-ready: ## Wait until the api is ready and the db is loaded
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

refresh-iss-tle: ## Refresh the ISS TLE
	@echo "Refreshing the ISS tle from CelesTrak ..."
	curl -s -X POST http://localhost:8080/v2/satellites/25544/tle/refresh | jq -r .

backfill-iss-tles:  ## Backfill all ISS TLEs
	@echo "Backfilling the ISS tle data from CelesTrak ..."
	curl -s -X POST http://localhost:8080/v2/satellites/25544/tle/backfill | jq -r .

coordinates-%:  ## Get data on coordinates
	curl -s http://localhost:8080/v2/coordinates/$(*) | jq -r .
