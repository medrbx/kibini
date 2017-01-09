package kibini::elasticsearch ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( GetEsNode ) ;

use strict ;
use warnings ;

use kibini::config ;

sub GetEsNode {
    my $conf_elasticsearch = GetConfig('elasticsearch') ;
    my $node = $conf_elasticsearch->{node} ;

    return $node ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::elasticsearch

=head1 DESCRIPTION

Ce module fournit des fonctions permettant de travailler avec l'instance Elasticsearch de Kibini.

=cut