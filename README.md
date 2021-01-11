# Overview

![LeafletJS Integration Example Image](examples/images/leafletjs.png?raw=true)


PredictPHP is a REST API for the [Predict](https://github.com/shupp/Predict) library.  It is written in the [lumen](https://lumen.laravel.com) framework, and is available via docker container.  [TLE](https://en.wikipedia.org/wiki/Two-line_element_set) data is provided courtesy of [CelesTrak](http://celestrak.com).

There is an example integration with [Leaflet](https://leafletjs.com) [here](examples/leafletjs) (see the image above).

[Predict](https://github.com/shupp/Predict), a PHP port of [gpredict](http://gpredict.oz9aec.net), allows you to do determine the position of a satellite (such as the International Space Station) as viewed from a given location.

The coordinates endpoints rely on shapefiles built by [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder). The database is [mariadb](https://mariadb.org).

## Building and Running

Build the predictphp/api image

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

You may also want to run `make logs`, and wait for the MySQL data seeding to complete:
```
$ make logs
--SNIP--
mysql-seed-client_1  | MySQL is now available
mysql-seed-client_1  | Creating tables:
mysql-seed-client_1  | done.
mysql-seed-client_1  | Populating tables:
mysql-seed-client_1  | Adding timezones shapefile to db
mysql-seed-client_1  | 0...10...20...30...40...50...60...70...80...90...100 - done.
mysql-seed-client_1  | done
predict-api_mysql-seed-client_1 exited with code 0
```

Alternatively, you can use the `wait-until-api-ready` target:
```
$ make wait-until-api-ready
Waiting for API to be ready ...
Waiting ...
Waiting ...
Waiting ...
Waiting ...
Done.
```

Lastly, you can use a series of `make` targets to chain together starting up from scratch after building:

```
make up wait-until-api-ready open-map
```

## Endpoints
Below are the current endpoints supported.  Note that the API version is `2`, and paths will need to be prefixed with `/v2`.

---
### GET /satellites

This endpoint returns a list of satellites that this API has information about, inluding a common name and NORAD catalog id.

#### Parameters
None

#### Example URL
```
curl -s http://localhost:8080/v2/satellites
```

#### Example Response
```
[
  {
    "name": "iss",
    "id": 25544
  }
]
```

---
### GET /satellites/[id]

Returns position, velocity, and other related information about a satellite for a given point in time. `[id]` is required and should be the NORAD catalog id. For the ISS, that id is 25544.

#### Parameters
| Name   | Description | Required | Default |
| ------ | ----------- | -------- | ------- |
| units | Whether to use `miles` or `kilometers` | no | `kilometers` |

#### Example URL
```
curl -s http://localhost:8080/v2/satellites/25544
```

#### Example Response
```
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

---
### GET /satellites/[id]/tle

Returns the TLE data for a given satellite in either `json` or `text` format

#### Parameters
| Name   | Description | Required | Default |
| ------ | ----------- | -------- | ------- |
| format | response format, can be `json` or `text` | no | `json` |

#### Example URL
```
curl -s http://localhost:8080/v2/satellites/25544/tle?format=text
```

#### Example Response
```
ISS (ZARYA)
1 25544U 98067A   20143.56318382  .00000454  00000-0  16202-4 0  9994
2 25544  51.6434 115.2941 0001418 343.5417 126.5978 15.49381561228046
```

---
### POST /satellites/[id]/tle/refresh

Refresh the ISS TLE file from [CelesTrak](http://celestrak.com).  This should be used at maximum once a day to keep your TLE up to date for a given satellite.

#### Parameters
None

#### Example URL
```
curl -s -X POST http://localhost:8080/v2/satellites/25544/tle/refresh
```

#### Example Response
```
{
  "tle_timestamp": 1590154259,
  "header": "ISS (ZARYA)             ",
  "line1": "1 25544U 98067A   20143.56318382  .00000454  00000-0  16202-4 0  9994",
  "line2": "2 25544  51.6434 115.2941 0001418 343.5417 126.5978 15.49381561228046"
}
```

---
### POST /satellites/[id]/tle/backfill

Backfill all historical TLEs from [celestrak](http://celestrak.com) for a given satellite.  __This should only be called once__.

NOTE: it may take 10 seconds or so to complete.

#### Parameters
None

#### Example URL
```
curl -s -X POST http://localhost:8080/v2/satellites/25544/tle/backfill
```

#### Example Response
```
{
  "status":"ok"
}
```

---
### GET /coordinates/[lat,lon]

Returns position, current time offset, country code, and timezone id for a given set of coordinates in the format of longitude,latitude.

#### Parameters
None

#### Example URL
```
curl -s http://localhost:8080/v2/coordinates/37.770061,-122.466157
```

#### Example Response
```
{
  "latitude": "37.770061",
  "longitude": "-122.466157",
  "timezone_id": "America/Los_Angeles",
  "offset": -7,
  "country_code": "US",
  "map_url": "https://maps.google.com/maps?q=37.770061,-122.466157&z=4"
}
```
