<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of CourseParse
 *
 * @author Olg3andr
 */

include_once 'Parser.php';
include_once 'Course.php';

class CourseParser extends Parser
{
    protected $cityList;
    protected $file_name_counter = 0;

    function  __construct($include_snapshot, $debug_mode)
    {
        parent::__construct($include_snapshot, $debug_mode);
    }

    function  __destruct() {
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
            if (preg_match('/moscow$|spb$/', $cityUrl))
            {
                $this->html->loadFromUrl($cityUrl);

                $domain =  $this->html->getUrl();
                $url = $domain . "/courses";
                for(;;)
                {
                    $o = $this->parsePage($url, "CourseList.json");
                    
                    if(!sizeof($o['url']))
                         break;

                    foreach( $o['url'] as $pageUrl)
                    {
                        $this->deb($pageUrl);
                        $course = $this->parsePage($domain . $pageUrl, "Course.json");
                        $course['url'] = $domain . $pageUrl;
                        $course['source'] = $domain;
                        $course['snapshot'] = $this->include_snapshot ? $this->snapshot : '';
                        $course['category'] = 'Курс';
                        $course['city'] = $city;
                        $course['uid'] = '';
                        $course['dump_type'] = 'text';

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
}
?>
