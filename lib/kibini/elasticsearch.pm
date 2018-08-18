package kibini::elasticsearch ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( GetEsNode RegenerateIndex GetEsMappingConf GetEsMaxId ) ;

use strict ;
use warnings ;
use YAML qw(LoadFile) ;
use Search::Elasticsearch ; 

use kibini::config ;

sub GetEsNode {
    my $conf_elasticsearch = GetConfig('elasticsearch') ;
    my $node = $conf_elasticsearch->{node} ;

    return $node ;
}

sub GetEsMappingConf {
    my ( $mapping_name ) = @_ ;

    my $conf_elasticsearch = GetConfig('elasticsearch') ;
    my $mappings_file = $conf_elasticsearch->{mappings_file} ;
    my $mappings_data = LoadFile($mappings_file) ;
    my $mappings = $mappings_data->{$mapping_name} ;
    
    return $mappings ;
}

sub RegenerateIndex {
    my ( $node, $index_name ) = @_ ;

    my %params = ( nodes => $node ) ;
    my $mappings = GetEsMappingConf($index_name) ;
    my %index_conf = (
        index => $index_name,
        body => $mappings
    ) ;

    my $e = Search::Elasticsearch->new( %params ) ;
    $e->indices->delete( index => $index_name );
    my $result = $e->indices->create( %index_conf );
    
    return $result ;
}

sub GetEsMaxId {
    my ( $index, $type, $field ) = @_ ;
    my $nodes = GetEsNode() ;
    my %params = ( nodes => $nodes ) ;

    my $e = Search::Elasticsearch->new( %params ) ;

    my $result =  $e->search(
        index => $index,
        type  => $type,
        body    => {
            aggs       => {
                max_id => {
                    max => {
                        field => $field
                    }
                }
            }
        }
    );

    return $result->{aggregations}->{max_id}->{value} ; 
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
