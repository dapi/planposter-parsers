#!/usr/bin/php
<?php

ini_set("max_execution_time", 0);
ini_set('auto_detect_line_endings', TRUE);
ini_set('html_errors', false);
ini_set('implicit_flush', true);
ini_set('register_argc_argv', true);

date_default_timezone_set('Europe/Moscow');

include_once "YandexAfishaRuParser.php";

$args = getopt("dsl");

$json = "rules/options.json";
if (is_file($json))
{
    $contents = file_get_contents($json);
    if(!$contents)
        throw new Exception("failed to load json descripion module: $json");
    $description = json_decode($contents);

    if (isset($description->debug_mode) && !$description->debug_mode)
        $args['s'] = $description->debug_mode;

    if (isset($description->include_snapshot) && (int)$description->include_snapshot )
        $args['d'] = $description->include_snapshot;
    else
        unset($args['d']);
    
    if (isset($description->day_limit) && (int)$description->day_limit > 0)
        $args['l'] = $description->day_limit;
}

if(isset($args['d']))
    print "в вывод парсера будет включен снимок html-страницы в момент ее разбора\n";
if(isset($args['s']))
    print "вывод отладочной информации отключен\n";
if(isset($args['l']))
    print "глубина парсинга ". $args['l'] ." дня(ей)\n";

$parser = new YandexAfishaRuParser( $args );
$parser->parse();

?>