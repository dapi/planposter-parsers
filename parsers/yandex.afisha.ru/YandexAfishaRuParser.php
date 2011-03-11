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

    protected $day_counter;
    protected $is_day_count_limited;
    protected $day_limit = 0;
    protected $places;

    function  __construct($args) {
        parent::__construct($args);
        
        $this->is_day_count_limited = array_key_exists('l', $args);
        if ($this->is_day_count_limited)
            $this->day_limit = $args['l'];

        $this->html->init("tmp/yandex_afisha_ru_cookies.txt");
        $this->places = array();
    }

    function  parse()
    {
        $domain = "http://afisha.yandex.ru";
        $cityList = $this->parsePage($domain . "/change_city/", "rules/citylist.json");

        //$cityList[0] = array('name' => 'Москва' , 'url' => '/msk/');
        //$cityList[0] = array('name' => 'Минск' , 'url' => '/mnk/');

        for(;;)
        {
            $j = each($cityList);

            $this->day_counter = 0;
            
            // выходим, если нет больше городов
            if (!$j) break;

            $city   = $j[1]['name'];
            $cityUrl = $j[1]['url'];
            if(preg_match("/\/(\w+)\//", $cityUrl, $cityNameShort))
                $cityNameShort = $cityNameShort[1];
            else
                $cityNameShort = '';

            $this->deb("city: $city, url: $cityUrl");

            //заходим в выбиралку
            $url = $domain. $cityUrl ."events/?date=". date("Y") ."-". date("m") ."-". date("d") ."&limit=100&page=1";
            //$url = $domain. $cityUrl ."events/?date=2011-03-11&limit=100&page=1";
            
            $o = $this->parsePage($url, "rules/eventlist.json");

            $next_days = $o['next_day'];
            $next_week = $o['next_week'];
            for(;;)
            {
                // выходим, если нет событий
                if(!sizeof($o['events'])) break;
                
                for(;;)
                {
                    if ($this->is_day_count_limited)
                        $this->day_counter++;

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
                                $Event->toJsonFile("data/". $cityNameShort."_". $data['date'] . "_". $data['uid'] .".json");

                                sleep(1);
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

                    // ограничение глубины парсера
                    if ($this->is_day_count_limited && $this->day_counter == $this->day_limit)
                        break;
                }
                if ($this->is_day_count_limited && $this->day_counter == $this->day_limit)
                    break;
                
                $o = $this->parsePage($domain. $next_week, "rules/eventlist.json");
                $next_days = $o['next_day'];
                $next_week = $o['next_week'];
            }
        }
    }
}
?>
