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

    protected $cityList;
    protected $file_name_counter = 0;

    function  __construct($include_snapshot, $debug_mode)
    {
        parent::__construct($include_snapshot, $debug_mode);
    }

    function  __destruct()
    {
        parent::__destruct();
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
                        $seminar['url'] = $domain . $pageUrl;
                        $seminar['source'] = $domain;
                        $seminar['snapshot'] = $this->include_snapshot ? $this->snapshot : '';
                        $seminar['category'] = 'Семинар';
                        $seminar['city'] = $city;
                        $seminar['uid'] = '';
                        $seminar['dump_type'] = 'text';
                        if($lite)
                            $seminar['lite'] = $lite;

                        $Seminar = new Seminar($seminar);
                        $Seminar->toJsonFile("data/seminar_". ++$this->file_name_counter . ".json");
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
