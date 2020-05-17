<?php

namespace App\Http\Controllers;

use Illuminate\Http\Response;

class ApiController extends Controller
{
    protected $_satellites = array(
        array(
            'name' => 'iss',
            'id'   => 25544
        )
    );

    public function listSatellites() {
        return (new Response(json_encode($this->_satellites), 200))
            ->header('Content-Type', 'application/json');
    }

    public function getTle($id) {
        $supportedSatellites = array("25544" => true);
        if (!isset($supportedSatellites[$id])) {
            return (new Response('{}', 404))
                ->header('Content-Type', 'application/json');
        }

        $results = app('db')->select(
            "SELECT * FROM tles WHERE norad_cat_no = ? ORDER BY date_created DESC LIMIT 1",
            array($id)
        );
        if (!count($results)) {
            return (new Response('{}', 404))
                ->header('Content-Type', 'application/json');
        }

        $params = app('request')->query->all();
        if (isset($params['format']) && $params['format'] == 'text') {
            $payload  = $results[0]->el_set_line_0 . "\n";
            $payload .= $results[0]->el_set_line_1 . "\n";
            $payload .= $results[0]->el_set_line_2 . "\n";

            return (new Response($payload, 200))
                ->header('Content-Type', 'text/plain');
        } else {
            $payload = array(
                'requested_timestamp' => time(),
                'tle_timestamp'       => $results[0]->el_set_epoch_unix,
                'header'              => $results[0]->el_set_line_0,
                'line1'               => $results[0]->el_set_line_1,
                'line2'               => $results[0]->el_set_line_2
            );
            return (new Response(json_encode($payload), 200))
                ->header('Content-Type', 'application/json');
        }
    }
}
