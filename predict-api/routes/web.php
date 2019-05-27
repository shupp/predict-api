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

$apiVersion = "v2";

$router->get('/', function () use ($router) {
    return $router->app->version();
});

$router->get("/$apiVersion/satellites", function () {
    $satellites = array(
        array(
            'name' => 'iss',
            'id'   => 25544
        )
    );
    return (new Response(json_encode($satellites), 200))
        ->header('Content-Type', 'application/json');
});
