<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Seminar
 *
 * @author Olg3andr
 */
include_once 'Utils.php';

class Seminar
{
    protected $d;

    function  __construct($Data) {
        $this->d = $Data;
    }

    protected function validate()
    {
        if (isset($this->d['date']))
            $this->d['date'] = decodeDate(preg_replace("/\./", '', $this->d['date']));
        if (isset($this->d['place']['link']))
            $this->d['place']['link'] = $this->d['source'] . $this->d['place']['link'];
    }
    protected function getDetails()
    {
        $s = '';
        if(isset($this->d['seminarDescription']['descr']))
        {
            foreach ($this->d['seminarDescription']['descr'] as $p)
                $s .= $p ."\n";
        }
        if(isset($this->d['seminarDescription']['notes']))
            $s .= $this->d['seminarDescription']['notes'] ."\n\n";
        if(isset($this->d['price']))
            $s .= "цена: ". $this->d['price'] ."\n\n";
        if(isset($this->d['place']['phone']) || isset($this->d['place']['site']))
        {
            $s .= "место проведения (контактная информанция):\n";
            if(isset($this->d['place']['phone']))
                $s .= "\tтел.:". $this->d['place']['phone'] ."\n";
            if(isset($this->d['website']))
                $s .= "\tсайт: ".$this->d['place']['website'] ."\n";
        }
        if(isset($this->d['presenters']) && sizeof($this->d['presenters']) )
        {
            $s .=    "Лекторы:\n";
            foreach($this->d['presenters'] as $presenter)
            {
                if(isset($presenter['name']))
                {
                    $s .=  $presenter['name'] ."\n";
                    if (isset($presenter['short']))
                        $s .= $presenter['short'] ."\n\n";
                }
            }
        }
        if( isset($this->d['organizers']) && sizeof($this->d['organizers']) )
        {
            $s .= "Организаторы: \n";
            foreach($this->d['organizers'] as $organizer)
            {
                if(isset($organizer['title']))
                {
                    $s .= $organizer['title'] ."\n";
                    if(isset($organizer['short']))
                        $s .= $organizer['short'] ."\n\n";
                }
            }
        }
        return $s;
    }
    public function export()
    {
        $this->validate();
        $json = array
        (
            'source'    => $this->d['source'],
            'url'       => $this->d['url'],
            'uid'       => $this->d['uid'],
            'image_url' => $this->d['poster'],
            'subject'   => $this->d['title'],
            'category'  => $this->d['category'],
            'place'     => isset($this->d['place']['title']) ? $this->d['place']['title'] : '',
            'address'   => isset($this->d['place']['address']) ? $this->d['place']['address'] : '',
            'city'      => $this->d['city'],
            'date'      => isset($this->d['date']) ? $this->d['date'] : '' ,
            'time'      => isset($this->d['time']) ? $this->d['time'] : '',
            'period'    => '',
            'details'   => $this->getDetails(),
            'dump'      => $this->d['snapshot'],
            'dump_type' => $this->d['dump_type']
        );

        return preg_replace("/\"\,\"/", "\",\n\"", json_fix_cyr(json_encode($json)));
    }
}
?>
