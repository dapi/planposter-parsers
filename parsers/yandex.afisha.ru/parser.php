#!/usr/bin/php
<?php

ini_set("max_execution_time", 0);
ini_set('auto_detect_line_endings', TRUE);
ini_set('html_errors', false);
ini_set('implicit_flush', true);
ini_set('register_argc_argv', true);

date_default_timezone_set('Europe/Moscow');

include_once "YandexAfishaRuParser.php";

$args = getopt("ds");

if(isset($args['d']))
    print "в вывод парсера будет включен снимок html-страницы в момент ее разбора\n";
if(isset($args['s']))
    print "вывод отладочной информации отключен";

$parser = new YandexAfishaRuParser( $args );
$parser->parse();

?>