<?php

ini_set("max_execution_time", "9000000000000");

include_once 'CourseParser.php';
include_once 'SeminarParser.php';

$CourseParser = new CourseParser(isset($_REQUEST['snapshot']), isset($_REQUEST['debug']));
$CourseParser->parse();

$SeminarParser = new SeminarParser(isset($_REQUEST['snapshot']), isset($_REQUEST['debug']));
$SeminarParser->parse();
?>
