<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of theoryandpracticeRuParser
 *
 * @author J0nny
 */

include_once '../../parselib/ParserBase.php';
include_once "Course.php";
include_once "Seminar.php";

class TheoryandpracticeRuParser extends ParserBase
{
    protected $file_name_counter = 0;
    protected $skip_courses     = false;
    protected $skip_seminars    = false;
    protected $skip_lite_cities = false;
    
    function  __construct($args)
    {
        parent::__construct(isset($args['d']));

        $this->skip_courses     = array_key_exists('skip-courses', $args);
        $this->skip_seminars    = array_key_exists('skip-seminars', $args);
        $this->skip_lite_cities = array_key_exists('skip-lite-cities', $args);
        $this->html->init("tmp/theoryandpractice_ru_cookies.txt");
        $this->html->setTimeOut(60);
    }

    function  parseCourses()
    {
        $file_name_counter = 0;
        $cityList = $this->parsePage("http://theoryandpractice.ru", "rules/citylist.json");

        $k_exst = false;
        foreach($cityList as $c)
            if ($c['name'] == 'Москва')
               $k_exst = true;
        
        if (!$k_exst)
            array_unshift($cityList, array('name' => 'Москва', 'url' => "http://theoryandpractice.ru/change_city/moscow"));

        for($i=0; $i < sizeof($cityList); ++$i)//$cityList as $city => $cityUrl)
        {
            $city = $cityList[$i]['name'];
            $cityUrl = $cityList[$i]['url'];
            if (preg_match('/moscow$|spb$/', $cityUrl))
            {
                $this->deb($city);
                $this->html->loadFromUrl($cityUrl);
                $domain =  $this->html->getUrl();
                $url = $domain . "/courses";
                for(;;)
                {
                    $o = $this->parsePage($url, "rules/courselist.json");

                    if(!sizeof($o['url']))
                         break;

                    foreach( $o['url'] as $pageUrl)
                    {
                        //$this->deb($domain . $pageUrl);
                        $course = $this->parsePage($domain . $pageUrl, "rules/course.json");
                        $course['url'] = $domain . $pageUrl;
                        $course['source'] = $domain;
                        $course['snapshot'] = $this->debug_mode ? $this->snapshot : '';
                        $course['category'] = 'Курс';
                        $course['city'] = $city;
                        $course['uid'] = '';
                        $course['dump_type'] = 'text';

                        $this->deb( " ( Курс ) " . $course['title'] );

                        $Course = new Course($course);
                        $Course->toJsonFile("data/course_". ++$this->file_name_counter . ".json");
                    }

                    if(!$o['next_page'])
                        break;

                    $url = $domain . $o['next_page'];
                }
            }
        }
    }

    function  parseSeminars()
    {
        $file_name_counter = 0;
        $cityList = $this->parsePage("http://theoryandpractice.ru", "rules/citylist.json");

        $k_exst = false;
        foreach($cityList as $c)
            if ($c['name'] == 'Москва')
               $k_exst = true;

        if (!$k_exst)
            array_unshift($cityList, array('name' => 'Москва', 'url' => "http://theoryandpractice.ru/change_city/moscow"));

        for($i=0; $i < count($cityList); ++$i)//$cityList as $city => $cityUrl)
        {
            $city = $cityList[$i]['name'];
            $cityUrl = $cityList[$i]['url'];

            // меняем город
            $this->html->loadFromUrl($cityUrl);

            $lite = false;
            if (!preg_match('/moscow$|spb$|copenhagen$/', $cityUrl))
                 $lite = true;
            if($lite && $this->skip_lite_cities)
                continue;

            $this->deb($city);

            $domain =  $this->html->getUrl();
            $url    = $domain . "/seminars";

            for(;;)
            {
                $o = $this->parsePage($url, "rules/seminarlist.json");

                if(!isset($o['url']) || !sizeof($o['url']))
                     break;

                foreach( $o['url'] as $pageUrl)
                {
                    // $this->deb($domain . $pageUrl);
                    $seminar = $this->parsePage($domain . $pageUrl, $lite ? "rules/seminarlite.json" : "rules/seminar.json");
                    $seminar['url'] = $domain . $pageUrl;
                    $seminar['source'] = $domain;
                    $seminar['snapshot'] = $this->debug_mode ? $this->snapshot : '';
                    $seminar['category'] = 'Семинар';
                    $seminar['city'] = $city;
                    $seminar['uid'] = '';
                    $seminar['dump_type'] = 'text';
                    if($lite)
                    {
                        $seminar['lite'] = $lite;
                        $this->deb( " ( Семинар ) " . $seminar['seminarDescription']['title'] );
                    }else
                        $this->deb( " ( Семинар ) " . $seminar['title'] );

                    $Seminar = new Seminar($seminar);
                    $Seminar->toJsonFile("data/seminar_". ++$this->file_name_counter . ".json");
                }

                if(!$o['next_page'])
                    break;

                $url = $domain . $o['next_page'];
            }
        }
    }

    function parse()
    {
        if(!$this->skip_courses)
        {
            $this->deb("COURSES:");
           // $this->parseCourses();
        }
        if(!$this->skip_seminars)
        {
            $this->deb("SEMINARS:");
            $this->parseSeminars();
        }
    }
}
?>
