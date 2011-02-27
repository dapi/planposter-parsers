<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of SeminarParser
 *
 * @author Olg3andr
 */
include_once 'Parser.php';
include_once 'Seminar.php';

class SeminarParser extends Parser{

    protected  $cityList;
    protected  $output_json;

    function  __construct($use_snapshot, $debug_mode)
    {
        parent::__construct($use_snapshot, $debug_mode);

        $this->output_json = fopen("output_seminar.json", "w+");
        fwrite($this->output_json, "[\n");
    }

    function  __destruct() {
        fwrite($this->output_json, "{}]");
        fclose($this->output_json);

        parent::__destruct();
    }

    protected function changeOutputJsonFile($fname)
    {
        fclose($this->output_json);
        $this->output_json = fopen($fname, "w+");
    }
    
    
    function  parse()
    {
        $cityList = $this->parsePage("http://theoryandpractice.ru", "CityList.json");
        array_unshift($cityList, array('name' => 'Москва', 'url' => "http://theoryandpractice.ru/change_city/moscow"));

        for($i=0; $i < sizeof($cityList); ++$i)//$cityList as $city => $cityUrl)
        {
            $city = $cityList[$i]['name'];
            $cityUrl = $cityList[$i]['url'];
            $this->deb($city);
            
            {
                $this->html->loadFromUrl($cityUrl);

                $domain =  $this->html->getUrl();
                $url = $domain . "/seminars";
                $lite = false;
                if (!preg_match('/moscow$|spb$|copenhagen$/', $cityUrl))
                     $lite = true;

                for(;;)
                {
                    $o = $this->parsePage($url, "SeminarList.json");

                    if(!isset($o['url']) || !sizeof($o['url']))
                         break;

                    foreach( $o['url'] as $pageUrl)
                    {
                        $this->deb($pageUrl);
                        $seminar = $this->parsePage($domain . $pageUrl, $lite ? "SeminarLite.json" : "Seminar.json");
                        
                        $seminar['url'] = $pageUrl;
                        $seminar['source'] = $domain;
                        if ($this->use_snapshot)
                            $seminar['snapshot'] = $this->snapshot;
                        $seminar['snapshot'] = '';
                        $seminar['category'] = 'Семинар';
                        $seminar['city'] = $city;
                        $seminar['uid'] = '';
                        $seminar['dump_type'] = 'text';

                        $Seminar = new Seminar($seminar);

                        $this->changeOutputJsonFile("data/seminar_". md5($seminar['url'] . time()) . ".json");
                        fwrite($this->output_json, $Seminar->export() ."\n");
                        //echo "\n\n</pre>";
                    }

                    if(!$o['next_page'])
                        break;

                    $url = $domain . $o['next_page'];
                }
            }
        }
    }
}
?>
