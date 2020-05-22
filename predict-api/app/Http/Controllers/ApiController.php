<?php

namespace App\Http\Controllers;

use Illuminate\Http\Response;
use Log;

require_once 'Predict.php';
require_once 'Predict/TLE.php';
require_once 'Predict/Time.php';
require_once 'Predict/QTH.php';
require_once 'Predict/Sat.php';

class ApiController extends Controller
{
    protected $_satellites = array(
        '25544' => array(
            'name' => 'iss',
            'id'   => 25544
        )
    );

    public function listSatellites() {
        return (new Response(json_encode(array_values($this->_satellites)), 200))
            ->header('Content-Type', 'application/json');
    }

    public function getTle($id) {
        if (!isset($this->_satellites[$id])) {
            return (new Response('{}', 404))
                ->header('Content-Type', 'application/json');
        }

        $tle = $this->_getTleByDate($id, time());

        $params = app('request')->query->all();
        if (isset($params['format']) && $params['format'] == 'text') {
            $payload  = $tle->header . "\n";
            $payload .= $tle->line1 . "\n";
            $payload .= $tle->line2 . "\n";

            return (new Response($payload, 200))
                ->header('Content-Type', 'text/plain');
        } else {
            $payload = array(
                'requested_timestamp' => time(),
                'tle_timestamp'       => \Predict_Time::getEpochTimeStamp($tle),
                'header'              => $tle->header,
                'line1'               => $tle->line1,
                'line2'               => $tle->line2
            );
            return (new Response(json_encode($payload), 200))
                ->header('Content-Type', 'application/json');
        }
    }

    protected function _getTleByDate($catNo, $date = null)
    {
        if ($date === null) {
            $date = time();
        } else if ($date < 0) {
            throw new \Exception('Whoops, date is < 0! ' . $date);
        }
        $catNo = (int) $catNo;

        $query = "SELECT *
                    FROM tles
                    WHERE `norad_cat_no` = ?
                    ORDER BY abs(? - CAST(el_set_epoch_unix AS SIGNED)) LIMIT 1";
        $results = app('db')->select($query, [$catNo, $date]);

        if (!count($results)) {
            throw new \Exception('TLE Not Found');
        }

        return new \Predict_TLE(
            $results[0]->el_set_line_0,
            $results[0]->el_set_line_1,
            $results[0]->el_set_line_2
        );
    }

    public function getSatellite($id) {
        if (!isset($this->_satellites[$id])) {
            return (new Response("", 404))
                ->header('Content-Type', 'application/json');
        }

        $predict  = new \Predict();
        $qth      = new \Predict_QTH();
        $qth->lat = 39.164141;
        $qth->lon = -122.695312;
        $qth->alt = 0;


        $params = app('request')->query->all();
        $units = 'kilometers';
        if (isset($params['units']) && $params['units'] == 'miles') {
            $units = 'miles';
        }
        if (isset($params['timestamp']) && is_numeric($params['timestamp'])) {
            $timestamp = int($params['timestamp']);
        } else {
            $timestamp = time();
        }

        $timestamp = time();
        $tle = $this->_getTleByDate($id, $timestamp);
        $sat = new \Predict_Sat($tle);

        $daynum         = \Predict_Time::get_current_daynum();
        $solar_vector   = new \Predict_Vector();
        $solar_geodetic = new \Predict_Geodetic();
        \Predict_Solar::Calculate_Solar_Position($daynum, $solar_vector);
        \Predict_SGPObs::Calculate_LatLonAlt($daynum, $solar_vector, $solar_geodetic);
        $solarlat = \Predict_Math::Degrees($solar_geodetic->lat);
        $solarlon = \Predict_Math::Degrees($solar_geodetic->lon);

        $predict->predict_calc($sat, $qth, $daynum);
        $vis = $predict->get_sat_vis($sat, $qth, $daynum);

        /* also store visibility "bit" */
        switch ($vis) {
            case \Predict::SAT_VIS_VISIBLE:
                $vis = 'visible';
                break;
            case \Predict::SAT_VIS_DAYLIGHT:
                $vis = 'daylight';
                break;
            case \Predict::SAT_VIS_ECLIPSED:
                $vis = 'eclipsed';
                break;
            default:
                $vis = null;
        }

        // Handle units
        $velocity = $sat->velo * 60 * 60;
        $satAlt = $sat->alt;
        if ($units == 'miles') {
            $satAlt = $sat->alt * \Predict::km2mi;
            $velocity = $velocity * \Predict::km2mi;
        }

        $data = array(
            'name'      => $this->_satellites[$id]['name'],
            'latitude'  => $sat->ssplat,
            'longitude' => $sat->ssplon,
            'altitude'  => number_format($satAlt, 2),
            'velocity'  => number_format($velocity, 2),
            'visbility' => $vis,
            'footprint' => ($sat->footprint * 1000) / 2,
            'timestamp' => $timestamp,
            'solar_lat' => $solarlat,
            'solar_lon' => $solarlon,
            'units'     => $units
        );

        return $data;
    }
}
