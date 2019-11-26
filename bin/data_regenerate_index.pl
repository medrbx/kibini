#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Search::Elasticsearch;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::elasticsearch;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

# On supprime l'index items puis on le recrée :
my $result = RegenerateIndex($es_node, "sessions_webkiosk");