<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of YandexAfishaRuParser
 *
 * @author Olg3andr
 */

include "../../parselib/ParserBase.php";
include "Event.php";

class YandexAfishaRuParser extends ParserBase{
    //put your code here

    protected $places;

    function  __construct($args) {
        parent::__construct($args);
        
        $this->html->init("tmp/yandex_afisha_ru_cookies.txt");
        $this->places = array();
    }

    function  parse()
    {
        $domain = "http://afisha.yandex.ru";
        $cityList = $this->parsePage($domain . "/change_city/", "rules/citylist.json");

        //$cityList[0] = array('name' => 'Москва' , 'url' => '/msk/');

        for(;;)
        {
            $j = each($cityList);
            
            // выходим, если нет больше городов
            if (!$j) break;

            $city   = $j[1]['name'];
            $cityUrl = $j[1]['url'];
            $this->deb("city: $city, url: $cityUrl");

            //заходим в выбиралку
            //$url = $domain. $cityUrl ."events/?date=". date("Y") ."-". date("m") ."-". date("d") ."&limit=100&page=1";
            $url = $domain. $cityUrl ."events/?date=2011-03-26&limit=100&page=1";
            $o = $this->parsePage($url, "rules/eventlist.json");

            $next_days = $o['next_day'];
            $next_week = $o['next_week'];
            for(;;)
            {
                // выходим, если нет событий
                if(!sizeof($o['events'])) break;
                
                for(;;)
                {
                    $next_day = each($next_days);
                    if (isset($next_day['value']) && $next_day['value'])
                    {
                        $o = $this->parsePage($domain . $next_day['value'] ."&limit=100&page=1", "rules/eventlist.json");

                        // выходим, если нет событий
                        if(!sizeof($o['events'])) break;

                        $page_num = 1;
                        for(;;)
                        {
                            $this->deb("Страница " . $page_num);

                            array_shift($o['events']);
                            foreach( $o['events'] as $data)
                            {
                                $this->deb("( ". $data['category'] ." ) " . $data['url']);

                                preg_match("/\/(\d+)\/\?date\=([\d]{4})\-([\d]{2})\-([\d]{2})/", $data['url'] , $matches );
                                $data['uid'] = $matches[1];
                                $data['source']    = $domain;
                                $data['url']       = $domain . '/' . $data['url'];
                                $data['category']  = $data['category'];
                                $data['city']      = $city;
                                $data['dump_type'] = 'text';
                                $data['date'] = $matches[2] ."-". $matches[3] ."-". $matches[4];

                                $data['snapshot'] = $this->include_snapshot ? $this->snapshot : '';

                                $data += $this->parsePage($data['url'], "rules/event.json");

                                $Event = new Event($data);
                                $Event->toJsonFile("data/" . $data['date'] . "_". $data['uid'] .".json");
                            }

                            $next_page = $o['next_page'];
                            if (sizeof($next_page) == 2)
                                $next_page = $next_page[1]['url'];
                            elseif (sizeof($next_page) == 1)
                            {
                                if (preg_match("/след/", $next_page[0]['name']))
                                    $next_page = $next_page[0]['url'];
                                else
                                    break;
                            }else
                                break;
                            $o = $this->parsePage($domain. $next_page, "rules/eventlist.json");

                            $page_num++;
                        }
                    }else
                        break;
                }

                $o = $this->parsePage($domain. $next_week, "rules/eventlist.json");
                $next_days = $o['next_day'];
                $next_week = $o['next_week'];
            }
        }
    }
}
?>