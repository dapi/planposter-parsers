<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Event
 *
 * @author Olg3andr
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
        $this->d['details'] =   (isset($this->d['descr'])      ? $this->d['descr']  ."\n"     : '').
                                (isset($this->d['descr_ext'])  ? $this->d['descr_ext'] ."\n"  : '');

        if ($this->d['image_url_ext'])
        {
            $this->d['image_url'] = $this->d['image_url_ext'];
            if (!preg_match("/\:\/\//", $this->d['image_url']))
               $this->d['image_url'] = "http://afisha.yandex.ru/". $this->d['image_url'];
            unset($this->d['image_url_ext']);
        }


        if (isset($this->d['time']['t_arr']))
        {
            $size = sizeof($this->d['time']['t_arr']);
            if(!$size)
            {
                if ( $this->d['time']['t_text'] && preg_match("/(весь\sдень)/", $this->d['time']['t_text'], $m ) )
                {
                    $this->d['period'] = 1440;
                    $this->d['time'] = '00:00';
                }
            }elseif($size > 1)
            {
                $this->d['details'] .= "Время: ";
                foreach($this->d['time']['t_arr'] as $t)
                    $this->d['details'] .= $t ." ";
                
                $this->d['details'] .= "\n";
                $this->d['time'] = '';
            }
            elseif($size == 1)
            {
                foreach($this->d['time']['t_arr'] as $t)
                {
                    $this->d['time'] = $t;
                    break;
                }
            }
        }
        if (is_array($this->d['time']))
            $this->d['time'] = '';

        

        if (preg_match("/Кино/", $this->d['category']))
        {
            if (isset($this->d['descr']))
            {
                if (preg_match("/\,\s(\d+)\sмин\./", $this->d['descr'], $period))
                    $this->d['period'] = $period[1];
            }
            
            if (isset($this->d['placeList']))
            {
                $this->d['details'] .= "\nБилеты можно купить в кинотеатрах: \n";
                foreach($this->d['placeList'] as $place)
                {
                    if (isset($place['times']) && sizeof($place['times']))
                        $this->d['details'] .= "\n«". $place['title'] ."»\nАдреc: ". $place['descr'] . "\nВремя сеанса: ". implode(",", $place['times']) ."\n";
                }
                unset($this->d['placeList']);
            }
            $this->d['address'] = '';
        }
        elseif (preg_match("/Выставки/", $this->d['category']))
        {
            if (!isset($this->d['details']))
                $this->d['details'] = $this->d['details'] ? $this->d['details'] : '';

            $this->d['address'] = '';
        }

        if (!isset($this->d['place']) && $this->d['placeListExt'])
            $this->d['place'] = $this->d['placeListExt']['title'];
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
            'subject'   => $this->d['subject'],
            'category'  => $this->d['category'],
            'period'    => (isset($this->d['period']) ? $this->d['period'] : ''),
            'city'      => $this->d['city'],
            'date'      => $this->d['date'],
            'time'      => (isset($this->d['time']) && $this->d['time'] ? $this->d['time'] : ''),
            'place'     => (isset($this->d['place']) && $this->d['place'] ? $this->d['place'] : ''),
            'address'   => (isset($this->d['address']) && $this->d['address'] ? $this->d['address'] : ''),
            'details'   => $this->d['details'],
            'dump'      => $this->d['snapshot'],
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
