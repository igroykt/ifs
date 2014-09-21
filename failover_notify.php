#!/usr/local/bin/php -q
<?php
require_once("config.inc");
require_once("globals.inc");
require_once("notices.inc");
$options = getopt("s::");

if($argc != 3){echo "Usage: $argv[0] [subject] [message]\n"; die();}

send_smtp_message($argv[2], $argv[1]);
?>