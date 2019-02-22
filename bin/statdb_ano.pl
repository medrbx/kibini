#! /usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::Log;
use Webkiosk;

my $log = Kibini::Log->new;
my $process = "statdb_ano.pl";
$log->add_log("$process : beginning");

my $i;

# Webkiosk
my $wk = Webkiosk->new;
$i = $wk->ano_statdb_sessions_webkiosk;
$log->add_log("statdb_sessions_webkiosk : $i rows anonymised");

$log->add_log("$process : ending\n");