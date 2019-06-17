# Build targets
build:
	docker build -t predictphp .
build-no-cache:
	docker build --no-cache -t predictphp .
run-local: rm-local-container
	docker run \
		--rm \
		-p 8080:80 \
		-d \
		-v ${PWD}/predict-api:/predict-api \
		--name predictphp \
		predictphp

logs-local:
	docker logs -f predictphp

# Debug targets
run-sleep-container: rm-local-container
	docker run \
		--rm \
		-d \
		-p 8080:80 \
		-v ${PWD}/predict-api:/predict-api \
		--name predictphp \
		predictphp sleep 1000000000
exec-bash-command:
	docker exec -ti predictphp bash -o vi
exec-bash: run-sleep-container exec-bash-command
	$(MAKE) rm-local-container
rm-local-container:
	-docker rm -f predictphp
