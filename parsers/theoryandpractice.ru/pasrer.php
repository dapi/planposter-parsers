#!/usr/bin/php
<?php
    header("Content-type: text/plain; charset=utf-8");

    ini_set("max_execution_time", "9000000000000");
    ini_set('auto_detect_line_endings', TRUE);
    date_default_timezone_set('Europe/Moscow');

    include_once 'theoryandpracticeRuParser.php';

    if (isset($_REQUEST['d']) || isset($_REQUEST['skip-courses']) || isset($_REQUEST['skip-seminars']) || isset($_REQUEST['skip-lite-cities']))
    {
        if (isset($_REQUEST['d']))
        {
            $args['d'] = 0;
            print "debug mode enabled\n";
        }
        if (isset($_REQUEST['skip-courses']))
        {
            $args['skip-courses'] = 0;
            print "курсы будут пропущены";
        }
        if (isset($_REQUEST['skip-seminars']))
        {
            $args['skip-seminars'] = 0;
            print "лекции будут пропущены";
        }
        if (isset($_REQUEST['skip-lite-cities']))
        {
            $args['skip-lite-cities'] = 0;
            print "лекции для городов из категории lite будут пропущены";
        }
    }else
    {
        $args = getopt("d", array("skip-courses","skip-seminars","skip-lite-cities"));

        if(isset($args['d']))
            print "debug mode enabled\n";
        if(isset($args['skip-courses']))
            print "курсы будут пропущены";
        if(isset($args['skip-seminars']))
            print "лекции будут пропущены";
        if(isset($args['skip-lite-cities']))
            print "лекции для городов из категории lite будут пропущены";
    }
    $parser = new TheoryandpracticeRuParser( $args );
    $parser->parse();
?>

