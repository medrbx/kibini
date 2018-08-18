#! /usr/bin/perl

use strict ;
use warnings ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use collections::biblio2 ;

my $log_message ;
my $process = "data_bib.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

my $es_node = GetEsNode() ;
my %params = ( nodes => $es_node ) ;
my $e = Search::Elasticsearch->new( %params ) ;

my $dbh = GetDbh() ;
my $i = 0 ;
my $j = 0 ;

my $maxtimestamp = GetMaxDateDataBiblio($dbh) ;

my @tables = qw( biblioitems deletedbiblioitems ) ;
foreach my $table (@tables) {
    my $count = DelFromDataBiblio($dbh, $table, $maxtimestamp, $e) ;
    $j = $j + $count ;
}

$log_message = "$process : $j rows deleted" ;
AddCrontabLog($log_message) ;

foreach my $table (@tables) {
    my $count = AddDataBiblio($dbh, $table, $maxtimestamp, $e) ;
    $i = $i + $count ;
}


$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;