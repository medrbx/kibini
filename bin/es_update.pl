#!/usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Es_Update;

my $es_update = Es_Update->new;

my $log = $es_update->logger;
my $process = "es_update.pl";
$log->add_log("$process : beginning");

$es_update->update_es_sessions_webkiosk;

$log->add_log("$process : ending\n");


