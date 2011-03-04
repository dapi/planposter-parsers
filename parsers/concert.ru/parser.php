#!/usr/bin/php
<?php

ini_set("max_execution_time", 0);
ini_set('auto_detect_line_endings', TRUE); 
ini_set('html_errors', false);
ini_set('implicit_flush', true);
ini_set('register_argc_argv', true);

date_default_timezone_get('Europe/Moscow');

include_once "ConcertRuParser.php";

$args = getopt("ds",array("parse-details"));

if(isset($args['d']))
    print "в вывод парсера будет включен снимок html-страницы в момент ее разбора\n";
if(isset($args['s']))
    print "вывод отладочной информации отключен";

print "parse details:";
print isset($args['parse-details']) ? "yes\n" : "no\n";

$parser = new ConcertRuParser( $args );
$parser->parse();

?>
