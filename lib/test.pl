#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );
use YAML qw(LoadFile) ;

use lib "$Bin";
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use collections::poldoc ;
use kibini::config ;

my $log_message ;
my $process = "es_items.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

# On supprime l'index items puis on le recrée :
#my $result = RegenerateIndex($es_node, "items") ;


#my $mappings = GetEsMappingConf("items");

my $conf_elasticsearch = GetConfig('elasticsearch');
my $mappings_file = $conf_elasticsearch->{mappings_file} ;
my $mappings_data = LoadFile($mappings_file) ;