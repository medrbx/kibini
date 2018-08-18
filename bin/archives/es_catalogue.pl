#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;

my $log_message ;
my $process = "es_catalogue.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On crée un objet Elasticsearch
my $es_node = GetEsNode() ;
my %params = ( nodes => $es_node ) ;
my $index = "catalogue" ;
my $type = "cata" ;
my $e = Search::Elasticsearch->new( %params ) ;

# On supprime l'index items puis on le recrée :
my $result = RegenerateIndex($es_node, "catalogue") ;


my $csv = Text::CSV->new ({ binary => 1 });
open(my $fd, "<:encoding(UTF-8)", "/home/kibini/kibini_prod/data/brewer_stat.csv") ;
$csv->column_names (qw( biblionumber ark isbn patrimoine support ));
my $nb = 0 ; 
while (my $row = $csv->getline_hr ($fd)) {
    my %index = (
        index   => $index,
        type    => $type,
        id      => $row->{'biblionumber'},
        body    => {
            biblionumber => $row->{'biblionumber'},
            ark => $row->{'ark'},
            isbn => $row->{'isbn'},
            patrimoine => $row->{'patrimoine'},
            support => $row->{'support'}
        }
    ) ;
    $e->index(\%index) ;   
    $nb++ ;
}
close $fd ;


# On log la fin de l'opération
$log_message = "$process : $nb rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;