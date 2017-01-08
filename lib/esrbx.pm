package esrbx ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( es_node ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile) ;

# fonction permettant de récupérer le node d'Elasticsearch
sub es_node {
	my $fic_conf = "$Bin/../etc/kibini_conf.yaml" ;
	my $conf = LoadFile($fic_conf);
	return $conf->{elasticsearch}->{node} ;
}

1;