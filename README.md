# Overview
PredictPHP is a REST API for the [Predict](https://github.com/shupp/Predict) library.  It is written in the [lumen](https://lumen.laravel.com) framework, and is available via docker container.

[Predict](https://github.com/shupp/Predict), a PHP port of [gpredict](http://gpredict.oz9aec.net), allows you to do determine the position of a satellite (such as the International Space Station) as viewed from a given location.

## Example usage

Build the predict-api image

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

Now you can call the api to list satellites:

```
$ curl -s localhost:8080/v2/satellites | jq .
[
  {
    "name": "iss",
    "id": 25544
  }
]
```

Refresh the ISS TLE file:

```
$ curl -s -X POST "localhost:8080/v2/satellites/25544/tle/refresh" | jq -r .
{
  "tle_timestamp": 1590154259,
  "header": "ISS (ZARYA)             ",
  "line1": "1 25544U 98067A   20143.56318382  .00000454  00000-0  16202-4 0  9994",
  "line2": "2 25544  51.6434 115.2941 0001418 343.5417 126.5978 15.49381561228046"
}
```

Backfill the archive for a TLE:

```
$ time curl -s -X POST "localhost:8080/v2/satellites/25544/tle/backfill"
{"status":"ok"}
real	0m6.954s
user	0m0.006s
sys	0m0.007s
```

And then get the current ISS location:

```
$ curl -s "localhost:8080/v2/satellites/25544" | jq -r .
{
  "name": "iss",
  "id": 25544,
  "latitude": -24.070395006619634,
  "longitude": -97.42697638827526,
  "altitude": 424.3843339899677,
  "velocity": 27566.413118197586,
  "visbility": "daylight",
  "footprint": 4529.702061387002,
  "timestamp": 1590179936,
  "daynum": 2458992.360379651,
  "solar_lat": 20.600465610298308,
  "solar_lon": 229.4546645720982,
  "units": "kilometers"
}
```

Lastly, you can also pull down a TLE file:

```
$ curl -s "localhost:8080/v2/satellites/25544/tle?format=text"
ISS (ZARYA)
1 25544U 98067A   20143.56318382  .00000454  00000-0  16202-4 0  9994
2 25544  51.6434 115.2941 0001418 343.5417 126.5978 15.49381561228046
```
