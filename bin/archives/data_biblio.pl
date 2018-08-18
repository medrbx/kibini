#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;
use collections::biblio ;

my $log_message ;
my $process = "data_biblio.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;


my $dbh = GetDbh() ;
my $i = 0 ;
my $j = 0 ;

my $maxtimestamp = GetMaxDateDataBiblio($dbh) ;

my @tables = qw( biblioitems deletedbiblioitems ) ;
foreach my $table (@tables) {
    my $count = DelFromDataBiblio($dbh, $table, $maxtimestamp) ;
    $j = $j + $count ;
}

$log_message = "$process : $j rows deleted" ;
AddCrontabLog($log_message) ;

foreach my $table (@tables) {
    my $count = AddDataBiblio($dbh, $table, $maxtimestamp) ;
    $i = $i + $count ;
}


$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;