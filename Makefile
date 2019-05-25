# Build targets
build:
	docker build -t predictphp .
build-no-cache:
	docker build --no-cache -t predictphp .

# Debug targets
run-sleep-container: rm-sleep-container
	docker run \
		--rm \
		-d \
		--name predictphp \
		predictphp sleep 1000000000
exec-bash-command:
	docker exec -ti predictphp bash -o vi
exec-bash: run-sleep-container exec-bash-command
exec-bash-only: exec-bash-command
rm-sleep-container:
	-docker rm -f predictphp
