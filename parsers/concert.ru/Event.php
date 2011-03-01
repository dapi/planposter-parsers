<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Event
 *
 * @author J0nny
 */
include_once 'lib/Utils.php';
class Event
{
    protected $d;

    function  __construct($Data) {
        $this->d = $Data;
    }

    protected function validate()
    {
        if($this->d['image_url'] == 'img/1x1.gif')
            $this->d['image_url'] = '';
        else
            $this->d['image_url'] = $this->d['source'] . '/' . $this->d['image_url'];

        $re = "/([0-9]{2}).([0-9]{2}).([0-9]{4})\s+([0-9]{2}:[0-9]{2})/";
        $this->d['date'] = '';
        $this->d['time'] = '';
        if(preg_match($re, $this->d['datetime'], $matches))
        {
            $this->d['date'] = $matches[3]."-".$matches[2]."-".$matches[1];
            $this->d['time'] = $matches[4];
        }
        unset($this->d['datetime']);
    }
    protected function getDetails()
    {
        return '';
    }
    public function toJsonString()
    {
        $this->validate();
        $json = array
        (
            'source'    => $this->d['source'],
            'url'       => $this->d['url'],
            'uid'       => $this->d['uid'],
            'image_url' => $this->d['image_url'],
            'subject'   => $this->d['title'],
            'category'  => $this->d['category'],
            'place'     => $this->d['place'],
            'address'   => $this->d['address'],
            'city'      => $this->d['city'],
            'date'      => $this->d['date'],
            'time'      => $this->d['time'],
            'period'    => '',
            'details'   => $this->getDetails(),
            'dump'      => $this->d['snapshot'],
            'dump_type' => $this->d['dump_type']
        );

        return preg_replace("/\"\,\"/", "\",\n\"", json_fix_cyr(json_encode($json)));
    }
    public function toJsonFile($fname)
    {
        $f = fopen($fname, "w");
        fwrite($f, $this->toJsonString());
        fclose($f);
    }
}
?>
