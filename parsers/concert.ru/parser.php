#!/usr/bin/php
<?php

ini_set("max_execution_time", "9000000000000");
ini_set('auto_detect_line_endings', TRUE); 

date_default_timezone_get('Europe/Moscow');

include_once "ConcertRuParser.php";

$args = getopt("d");

if(isset($args['d']))
    printf("debug mode enabled\n");
$parser = new ConcertRuParser( isset($args['d']) );
$parser->parse();

?>
