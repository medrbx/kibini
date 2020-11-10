#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::ES;
use Kibini::Log;

my $log = Kibini::Log->new;
my $process = "WK_new_to_es.pl";
$log->add_log("$process : beginning");

my $e = Kibini::ES->new->e;

my $file_in = "/home/kibini/stat_sessions_webkiosk_201902202234_es_v3.json";
#my $file_in = "/home/kibini/test.json";
my $importer = Catmandu->importer('JSON', fix => '/home/kibini/kibini_prod/tools/WK_new_to_es.fix', file => $file_in);

my $i = 0;
$importer->each(sub {
    my $index = shift;
	$i++;
	$e->index($index);
	$log->add_log("$process : $i rows added") if $i % 10000 == 0;
	print "$i\n";;
});

$log->add_log("$process : $i rows added");
$log->add_log("$process : ending");