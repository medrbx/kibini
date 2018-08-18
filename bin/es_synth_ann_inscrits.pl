#! /usr/bin/perl

use strict ;
use warnings ;
use Text::CSV ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::elasticsearch ;
use kibini::log ;

my $log_message ;
my $process = "es_synth_inscrits.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

#my $result = RegenerateIndex($es_node, "inscrits_synth_carte") ;

my $i = synth_inscrits($es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub synth_inscrits {
    my ($es_node) = @_ ;
    my %params = ( nodes => $es_node ) ;
    my $index = "synth_ann_inscrits" ;
    my $type = "inscrits" ;

    my $e = Search::Elasticsearch->new( %params ) ;
    
    open my $fic, "<:encoding(utf8)", "/home/kibini/kibini_prod/data/es_csv/inscrits.csv";

    my $csv = Text::CSV->new ({
        binary    => 1, # permet caractères spéciaux (?)
        auto_diag => 1, # permet diagnostic immédiat des erreurs
    });

    my $i = 0 ;
    while (my $row = $csv->getline ($fic)) {
        my ($annee, , $nb_inscrits, $carte) = @$row ;
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                carte => $carte,
                annee => $annee,
                nb_inscrits => $nb_inscrits
            }
        ) ;
        print "$annee, $carte, $nb_inscrits\n" ;
        $e->index(%index) ;

        $i++ ;
    }
    return $i ;
}