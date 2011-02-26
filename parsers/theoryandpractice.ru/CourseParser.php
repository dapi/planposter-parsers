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
    protected  $cityList;
    protected  $output_json;
    
    function  __construct($use_snapshot, $debug_mode)
    {
        parent::__construct($use_snapshot, $debug_mode);
        $this->output_json = fopen("output_course.json", "w+");
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
                        $course['url'] = $pageUrl;
                        $course['source'] = $domain;
                        if ($this->use_snapshot)
                            $course['snapshot'] = $this->snapshot;
                        $course['snapshot'] = '';
                        $course['category'] = 'Курс';
                        $course['city'] = $city;
                        $course['uid'] = '';
                        $course['dump_type'] = 'text';

                        $Course = new Course($course);

                        $this->changeOutputJsonFile("data/course_". md5($course['url'] . time()) . ".json");
                        fwrite($this->output_json, $Course->export()."\n");
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
