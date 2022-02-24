#! /usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Search::Elasticsearch; 
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::elasticsearch;
use kibini::log;

my $log_message;
my $process = "es_synth_documents.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

my $index = "synth_ann_exemplaires";
# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

#my $result = RegenerateIndex($es_node, $index);

my $i = synth_documents($es_node, $index);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);


sub synth_documents {
    my ($es_node, $index) = @_;
    my %params = ( nodes => $es_node );

    my $type = "exemplaires";

    my $e = Search::Elasticsearch->new( %params );
    
    open my $fic, "<:encoding(utf8)", "/home/kibini/kibini_prod/data/es_csv/synth_ann_exemplaires_20220216.csv";

    my $csv = Text::CSV->new ({
        binary    => 1, # permet caractères spéciaux (?)
        auto_diag => 1, # permet diagnostic immédiat des erreurs
    });

    my $i = 0;
    while (my $row = $csv->getline ($fic)) {
        my ($annee, $support, $nb_documents) = @$row;
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                support => $support,
                annee => $annee,
                nb_documents => $nb_documents
            }
        );
        print "$annee, $support, $nb_documents\n";
        $e->index(%index);

        $i++;
    }
    return $i;
}