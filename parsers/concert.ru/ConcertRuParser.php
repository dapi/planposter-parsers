<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of ConcertRuParser
 *
 * @author J0nny
 */
include "../../parselib/ParserBase.php";
include_once 'Event.php';
// Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3
// ASP.NET_SessionId
// SearchPerPage = 100
// CityID
// - зайти на сайт
// - Получить список городов
// /html/body/form/table/tbody/tr/td[2]/table/tbody/tr[4]/td/div/select/option
// id : string(@value)
// name : string(.)
// - получить список категорий и ссылок на них
// /html/body/form/table[8]/tbody/tr[2]/td/table[contains(@id,"GroupHeaderTable")]/tbody/tr/td/a
// - для каждой категории обработать список мероприятий
// //table[contains(@id="MainPage_GroupList")]/tbody/tr/td/table[1]/tbody/tr[2]
// image : string(td[1]/img/@src)
// url : string(td[2]/a/@href)
// title : string(td[2]/a)
// datetime : string(td[2]/span/text()[2])
// place : string(td[2]/span/a)
// address : string(td[2]/span/a/@title)
// placePageUrl : string(td[2]/span/a/@href)
// uid : разбор ссылки ActionID
class ConcertRuParser extends ParserBase
{
    protected $file_name_counter = 0;
    protected $parse_details = false;
    function  __construct($args) {
        parent::__construct(isset($args['d']));
        $this->html->init("tmp/concert_ru_cookies.txt");
        $this->parse_details = array_key_exists('parse-details', $args);
    }

    function parse()
    {
        $cityList = $this->parsePage("http://concert.ru", "rules/citylist.json");

        foreach($cityList as $j)
        {
            $city   = $j['name'];
            $cityId = $j['id'];
            $this->deb("city: $city, id: $cityId");
            if( $cityId == '0')
                continue;
            $this->html->setCookie("cityID=$cityId; SearchPerPage=100");
            $categoryList = $this->parsePage("http://concert.ru", "rules/categorylist.json");
            $domain =  $this->html->getUrl();
            
            foreach($categoryList as $j)
            {
                $name   = $j['name'];
                $url    = $domain . '/' . $j['url'];
                //$this->deb("\tcategory: $name, url: $url");


                 $event_count = 0;
                for(;;)
                {
                    $o = $this->parsePage($url, "rules/eventlist.json");
                    foreach( $o['events'] as $data)
                    {
                        //$this->deb("\t\t" . ++$event_count . ".   " . $data['url']);
                        $this->deb("( $name ) " . $data['title']);
                        $data['source']    = $domain;
                        $data['url']       = $domain . '/' . $data['url'];
                        $data['category']  = $name;
                        $data['city']      = $city;
                        $data['uid']       = '';
                        $data['dump_type'] = 'text';
                        if($this->parse_details)
                            $data += $this->ParsePage($data['url'], "rules/eventdetails.json");
                        $data['snapshot']  = $this->debug_mode ? $this->snapshot : '';
                        $event = new Event($data);
                        $event->toJsonFile("data/" . ++$this->file_name_counter . ".json");
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
