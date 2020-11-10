#! /usr/bin/perl

use strict ;
use warnings ;
use Text::CSV ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin ) ;
use Data::Dumper;

use lib "$Bin/../lib" ;
use kibini::elasticsearch ;
use kibini::log ;

my $log_message ;
my $process = "es_synth_prets.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

#my $result = RegenerateIndex($es_node, "syntheses") ;

my $i = synth_prets($es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub synth_prets {
    my ($es_node) = @_ ;
    my %params = ( nodes => $es_node ) ;
    my $index = "synth_ann_prets" ;
    my $type = "prets" ;

    my $e = Search::Elasticsearch->new( %params ) ;
    
    open my $fic, "<:encoding(utf8)", "/home/kibini/kibini_prod/data/es_csv/synth_ann_prets_20200122.csv";

    my $csv = Text::CSV->new ({
        binary    => 1, # permet caractères spéciaux (?)
        auto_diag => 1, # permet diagnostic immédiat des erreurs
    });

    my $i = 0 ;
    while (my $row = $csv->getline ($fic)) {
        my ($annee, $public, $support, $nb_prets) = @$row ;
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                public => $public,
                support => $support,
                annee => $annee,
                nb_prets => $nb_prets
            }
        ) ;
        #print "$public, $support, $annee, $nb_prets\n" ;
        $e->index(%index) ;
		print Dumper(\%index);

        $i++ ;
    }
    return $i ;
}