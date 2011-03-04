#!/usr/bin/php
<?php
    ini_set("max_execution_time", "0");
    ini_set('auto_detect_line_endings', TRUE);

    ini_set('html_errors', false);
    ini_set('implicit_flush', true);
    ini_set('register_argc_argv', true);
    
    date_default_timezone_set('Europe/Moscow');

    include_once 'theoryandpracticeRuParser.php';

    $args = getopt("d", array("skip-courses","skip-seminars","skip-lite-cities"));

    if(isset($args['d']))
        print "debug mode enabled\n";
    if(isset($args['skip-courses']))
        print "курсы будут пропущены";
    if(isset($args['skip-seminars']))
        print "лекции будут пропущены";
    if(isset($args['skip-lite-cities']))
        print "лекции для городов из категории lite будут пропущены";
    
    $parser = new TheoryandpracticeRuParser( $args );
    $parser->parse();
?>

