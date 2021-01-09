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
            'name'          => 'iss',
            'id'            => 25544,
            'tleUrl'        => 'http://www.celestrak.com/NORAD/elements/stations.txt',
            'tleArchiveUrl' => 'http://www.celestrak.com/NORAD/archives/zarya.zip',
            'defaultHeader' => 'ISS (ZARYA)'
        )
    );

    public function listSatellites() {
        // Prune output
        $satellites = [];
        foreach($this->_satellites as $key => $sat) {
            array_push(
                $satellites,
                array(
                    "name" => $sat["name"],
                    "id"   => $sat["id"]
                )
            );
        }
        return (new Response(json_encode($satellites), 200))
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

    protected function _insertTleIntoDb(\Predict_TLE $tle)
    {
        // Check first
        $query = "SELECT `id` FROM tles WHERE
                    `norad_cat_no` = ?
                    AND `el_set_epoch_unix` = ?";
        $results = app('db')->select(
            $query,
            [
                $tle->catnr,
                \Predict_Time::getEpochTimeStamp($tle)
            ]
        );
        if (count($results)) {
            return;
        }

        // If no results, insert
        $query = "INSERT INTO tles (
                    `norad_cat_no`,
                    `el_set_epoch_unix`,
                    `el_set_line_0`,
                    `el_set_line_1`,
                    `el_set_line_2`
                  ) VALUES (?, ?, ?, ?, ?)";
        $results = app('db')->insert(
            $query,
            [
                $tle->catnr,
                \Predict_Time::getEpochTimeStamp($tle),
                $tle->header,
                $tle->line1,
                $tle->line2
            ]
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
        $footprint = $sat->footprint;
        if ($units == 'miles') {
            $satAlt    = $sat->alt  * \Predict::km2mi;
            $velocity  = $velocity  * \Predict::km2mi;
        }

        $data = array(
            'name'       => $this->_satellites[$id]['name'],
            'id'         => $this->_satellites[$id]['id'],
            'latitude'   => $sat->ssplat,
            'longitude'  => $sat->ssplon,
            'altitude'   => $satAlt,
            'velocity'   => $velocity,
            'visibility' => $vis,
            'footprint'  => $footprint,
            'timestamp'  => $timestamp,
            'daynum'     => $daynum,
            'solar_lat'  => $solarlat,
            'solar_lon'  => $solarlon,
            'units'      => $units
        );

        return $data;
    }

    public function refreshTle($id) {
        if (!isset($this->_satellites[$id])) {
            return (new Response("", 404))
                ->header('Content-Type', 'application/json');
        }

        $contents = file_get_contents($this->_satellites[$id]['tleUrl']);
        if ($contents === false) {
            return (new Response(['error' => 'Unable to retrieve tle'], 500))
                ->header('Content-Type', 'application/json');
        }
        $lines = explode("\r\n", $contents);
        $tle = new \Predict_TLE(
            $lines[0],
            $lines[1],
            $lines[2]
        );

        $this->_insertTleIntoDb($tle);

        $payload = array(
            'tle_timestamp' => \Predict_Time::getEpochTimeStamp($tle),
            'header'        => $tle->header,
            'line1'         => $tle->line1,
            'line2'         => $tle->line2
        );
        return (new Response(json_encode($payload), 200))
            ->header('Content-Type', 'application/json');
    }

    public function backfillTle($id) {
        if (!isset($this->_satellites[$id])) {
            return (new Response("", 404))
                ->header('Content-Type', 'application/json');
        }

        // Fetch zip contents
        $sat = $this->_satellites[$id];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $sat['tleArchiveUrl']);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $results = curl_exec($ch);
        curl_close($ch);

        if ($results === false) {
            return (new Response(['error' => 'Unable to retrieve tle archive'], 500))
                ->header('Content-Type', 'application/json');
        }

        // Unzip, which has to be done on the filesystem unfortunately
        $uniq = uniqid();
        $dirName = "/tmp/predict-api-" . $uniq;
        $zipName = $dirName . ".zip";

        $temp = fopen($zipName, "w+");
        fwrite($temp, $results);
        fclose($temp);

        $zip = new \ZipArchive();
        $zip->open($zipName);
        $zip->extractTo($dirName);
        $zip->close();

        $urlParts = explode('/', $sat['tleArchiveUrl']);
        $pathEnd = end($urlParts);
        $txtName = $dirName . '/' . str_replace('.zip', '.txt', $pathEnd);

        $contents = file_get_contents($txtName);

        // Clean up temp files
        unlink($zipName);
        unlink($txtName);
        rmdir($dirName);

        // Insert into DB
        $lines = explode("\r\n", $contents);

        $currentLine = 0;
        while ($currentLine < (count($lines) - 2)) {
            $line1 = $lines[$currentLine];
            $currentLine++;
            $line2 = $lines[$currentLine];
            $currentLine++;

            $tle = new \Predict_TLE(
                $sat['defaultHeader'],
                $line1,
                $line2
            );
            $this->_insertTleIntoDb($tle);
        }

        return (new Response(json_encode(array('status' => 'ok')), 201))
            ->header('Content-Type', 'application/json');
    }

    public function coordinates($id) {
        // Get params
        $coords = explode(',', $id);
        $lat    = isset($coords[0]) ? $coords[0] : '';
        $lon    = isset($coords[1]) ? $coords[1] : '';

        if (!$this->_validateCoordinate($lat) || !$this->_validateCoordinate($lon)) {
            $errorMessage = 'invalid coordinates';
            return (new Response(json_encode(array('status' => 'error', 'message' => $errorMessage)), 400))
                ->header('Content-Type', 'application/json');
        }

        // Run query
        $tzId  = null;
        $query = "SELECT tzid FROM combined_shapefile_with_oceans WHERE ST_Contains(SHAPE, POINT(?, ?)) LIMIT 1";
        $results = app('db')->select($query, [$lon, $lat]);

        if (!count($results)) {
            $errorMessage = 'Timezone Not Found for coordinates';
            return (new Response(json_encode(array('status' => 'error', 'message' => $errorMessage)), 404))
                ->header('Content-Type', 'application/json');
        }
        $tzId = $results[0]->tzid;

        // Add some extra data
        $mapsUrl     = 'https://maps.google.com/maps?q=' . $lat . ',' . $lon . '&z=4';
        $date        = new \DateTime($tzId);
        $location    = $date->getTimezone()->getLocation();
        $countryCode = isset($location['country_code'])
                       ? $location['country_code'] : 'unknown';

        $data = array(
            'latitude'       => $lat,
            'longitude'      => $lon,
            'timezone_id'    => $tzId,
            'offset'         => $date->getOffset() / 60 / 60, // Use hours
            'country_code'   => $countryCode,
            'map_url'        => $mapsUrl
        );
        return $data;
    }

    protected function _validateCoordinate($coord)
    {
        if (!is_numeric($coord)) {
            return false;
        }

        if ($coord >= 360 || $coord <= -360) {
            return false;
        }
        return true;
    }

    public function healthCheck() {
        try {
            $results = app('db')->select("select count(*) as count from combined_shapefile_with_oceans;");
            // This is a bit brittle, let's say above 430 for now
            if ((int)$results[0]->count >= '430') {
                $payload = ['status' => 'error', 'message' => 'db not ready'];
                return $payload;
            }
        } catch (\PDOException $e) {
            $payload = ['status' => 'error', 'message' => 'db error'];
            return $payload;
        }
        return ['status' => 'ok'];
    }
}
