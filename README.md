# Overview
PredictPHP is a REST API for the [Predict](https://github.com/shupp/Predict) library.  It is written in the [lumen](https://lumen.laravel.com) framework, and is available via docker container.

[Predict](https://github.com/shupp/Predict), a PHP port of [gpredict](http://gpredict.oz9aec.net), allows you to do determine the position of a satellite (such as the International Space Station) as viewed from a given location.

## Example usage

Build the predicphp image

```
make build
```

Then start up the components with docker-compose
```
$ make up
docker-compose up -d
Creating network "predict-api_predict_net" with driver "bridge"
Creating predict-api_mysql_1 ... done
Creating predict-api_mysql-seed-client_1 ... done
Creating predict-api_api_1               ... done
```

Now you can call the api

```
$ curl -s localhost:8080/v2/satellites | jq .
[
  {
    "name": "iss",
    "id": 25544
  }
]
```
