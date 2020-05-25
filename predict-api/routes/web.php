<?php

/*
|--------------------------------------------------------------------------
| Application Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all of the routes for an application.
| It is a breeze. Simply tell Lumen the URIs it should respond to
| and give it the Closure to call when that URI is requested.
|
*/

use Illuminate\Http\Response;
use App\Http\Controllers;

$apiVersion = "v2";

$router->get('/', function () use ($router) {
    return $router->app->version();
});

$router->get("/$apiVersion/satellites", 'ApiController@listSatellites');
$router->get("/$apiVersion/satellites/{id}",  'ApiController@getSatellite');
$router->get("/$apiVersion/satellites/{id}/tle",  'ApiController@getTle');
$router->post("/$apiVersion/satellites/{id}/tle/refresh",  'ApiController@refreshTle');
$router->post("/$apiVersion/satellites/{id}/tle/backfill",  'ApiController@backfillTle');
$router->get("/$apiVersion/coordinates/{id}",  'ApiController@coordinates');
