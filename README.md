# Overview
PredictPHP is a REST API for the [Predict](https://github.com/shupp/Predict) library.  It is written in the [lumen](https://lumen.laravel.com) framework, and is available via docker container.

[Predict](https://github.com/shupp/Predict), a PHP port of [gpredict](http://gpredict.oz9aec.net), allows you to do determine the position of a satellite (such as the International Space Station) as viewed from a given location.

## Run the container
```
make build
make run-local
curl localhost:8080
```
