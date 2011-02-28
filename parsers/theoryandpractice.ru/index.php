<?php

ini_set("max_execution_time", "9000000000000");
ini_set('auto_detect_line_endings', TRUE); 

include_once 'CourseParser.php';
include_once 'SeminarParser.php';

$CourseParser = new CourseParser(isset($_REQUEST['include_snapshot']), isset($_REQUEST['debug_mode']));
$CourseParser->parse();

$SeminarParser = new SeminarParser(isset($_REQUEST['include_snapshot']), isset($_REQUEST['debug_mode']));
$SeminarParser->parse();
?>
