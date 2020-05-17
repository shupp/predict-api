IMAGE = predictphp

help:
	@grep '^[^#[:space:]].*:' Makefile \
		| awk -F: '{ print $$1 }' \
		| sort

# Build targets
build:
	docker build -t $(IMAGE) .
build-no-cache:
	docker build --no-cache -t $(IMAGE) .

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
	docker run --entrypoint /bin/sh --rm -it $(IMAGE) /bin/sh
