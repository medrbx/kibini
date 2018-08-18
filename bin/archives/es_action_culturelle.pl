#!/usr/bin/perl

use strict ;
use warnings ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use kibini::time ;

use action_culturelle ;

use Data::Dumper ;

my $log_message ;
my $process = "es_action_culturelle.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;
RegenerateIndex($es_node, 'action_culturelle') ;

my $i = AddEsLastAction_culturelle($es_node) ;

print Dumper($i) ; 

# On log la fin de l'opération
#$log_message = "$process : $i rows indexed" ;
#AddCrontabLog($log_message) ;
#$log_message = "$process : ending\n" ;
#AddCrontabLog($log_message) ;


