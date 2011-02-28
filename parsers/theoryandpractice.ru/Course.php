<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Course
 *
 * @author Olg3andr
 */
include_once 'Utils.php';

class Course {
    //put your code here
    protected $d;

    function  __construct($Data) {
        $this->d = $Data;
    }
    
    protected function validate()
    {
        if (isset($this->d['dateStart']))
            $this->d['dateStart'] = decodeDate($this->d['dateStart']);
        if (isset($this->d['duration']))                            // длительность в минутах
            $this->d['duration'] = $this->d['duration'] * 60;
        else
            $this->d['duration'] = "";
        
        if (isset($this->d['timeString']) && isValidTimeFormat($this->d['timeString']) )
        {
            $this->d['time'] = $this->d['timeString'];
            unset($this->d['timeString']);
        }
        
    }

    protected function getDetails()
    {
        $s = '';
        if(isset($this->d['price']))
            $s .= "цена: ". $this->d['price'] ."\n";
        if(isset($this->d['timeString']))
            $s .= $this->d['timeString'] ."\n";
        if(isset($this->d['short']))
            $s .= $this->d['short']."\n\n";
        if(isset($this->d['form']))
            $s .= $this->d['form'] ."\n\n";
        if(isset($this->d['requirements']))
            $s .= $this->d['requirements']."\n\n";

        if(isset($this->d['place']['phone']) || isset($this->d['place']['site']) || isset($this->d['place']['email']))
        {
            $s .= "место проведения (контактная информанция):\n";
            if(isset($this->d['place']['phone']))
                $s .= "\tтел.: ".$this->d['place']['phone'] ."\n";
            if(isset($this->d['place']['site']))
                $s .= "\tсайт: ". $this->d['place']['site'] ."\n";
            if(isset($this->d['place']['email']))
                $s .= "\temail: ". $this->d['place']['email'] ."\n";
        }
        if (isset($this->d['dateEnd']))
            $s .= "Дата окончания курса: ". $this->d['dateEnd'] ."\n";

        if(isset($this->d['teachers']) && sizeof($this->d['teachers']) )
        {
            $s .= "Преподаватели:\n";
            foreach($this->d['teachers'] as $teacher)
            {
                if(isset($teacher['title']))
                {
                    $s .=  $teacher['title'] ."\n";
                    if (isset($teacher['short']))
                        $s .= $teacher['short'] ."\n\n";
                }
            }
        }
        if(isset($this->d['organizers']) && sizeof($this->d['organizers']) )
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

    public function toJsonString()
    {
        $this->validate();
        
        $json = array(
            'source'    => $this->d['source'],
            'url'       => $this->d['url'],
            'uid'       => $this->d['uid'],
            'image_url' => $this->d['poster'],
            'subject'   => $this->d['title'],
            'category'  => $this->d['category'],
            'place'     => isset($this->d['place']['title']) ? $this->d['place']['title'] : '',
            'address'   => isset($this->d['place']['address']) ? $this->d['place']['address'] : '',
            'city'      => $this->d['city'],
            'date'      => isset($this->d['dateStart']) ? $this->d['dateStart'] : '',
            'time'      => isset($this->d['time']) ? $this->d['time'] : '',
            'period'    => isset($this->d['duration']) ? $this->d['duration'] : '',
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
