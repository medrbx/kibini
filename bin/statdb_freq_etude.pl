#!/usr/bin/perl

use warnings ;
use strict ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::log ;
use salleEtude::statdb ;

my $log_message ;
my $process = "statdb_freq_etude.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On complète les données
my $i = ModEntranceAddingData() ;

# On log la fin de l'opération
$log_message = "$process : $i rows modified" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;