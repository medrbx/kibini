package kibini::elasticsearch ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( GetEsNode ) ;

use strict ;
use warnings ;

use kibini::config ;

# fonction permettant de récupérer le node d'Elasticsearch
sub GetEsNode {
    my $conf_elasticsearch = GetConfig('elasticsearch') ;
    my $node = $conf_elasticsearch->{node} ;

    return $node ;
}

1;
