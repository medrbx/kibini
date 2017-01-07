#!/usr/bin/perl

use warnings ;
use strict ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use salleEtude::stadb ;
use fonctions ;


my $log_message ;
my $process = "statdb_freq_etude.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On enrichit les données
ModEntranceAddingData() ;

# On log la fin de l'opération
$log_message = "$process : $i lignes intégrées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;