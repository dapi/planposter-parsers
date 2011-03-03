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
include_once '../../parselib/Utils.php';
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

        $re = "/.*Details\.aspx\?ActionID=([0-9]+)$/" ;
        if(preg_match($re, $this->d['url'], $matches))
            $this->d['uid'] = $matches[1];

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
        $s = '';
        if(isset($this->d['organizer']))
        {
            $s .= "Организатор:\n" .  $this->d['organizer'] . "\n";
        }
        if(isset($this->d['descr']))
            $s .= "Описание:\n" . $this->d['descr'] . "\n";
        return $s;
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
            'dump'      => iconv('windows-1251', 'utf-8', $this->d["snapshot"]),
            'dump_type' => $this->d['dump_type']
        );
        $s = json_encode($json);
        if(json_last_error())
            throw new Exception(json_error_string());
        return preg_replace("/\"\,\"/", "\",\n\"", json_fix_cyr($s));
    }
    public function toJsonFile($fname)
    {
        $f = fopen($fname, "w");
        fwrite($f, $this->toJsonString());
        fclose($f);
    }
}
?>
