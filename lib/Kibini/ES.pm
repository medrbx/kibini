package Kibini::ES;

use Moo;
use Search::Elasticsearch;

use Kibini::Config;

has e => ( is => 'ro', builder => '_get_e' );

sub _get_e {
    my $conf_elasticsearch = Kibini::Config->new->elasticsearch;
    my $es_node = $conf_elasticsearch->{node};
    my %params = ( nodes => $es_node );

    my $e = Search::Elasticsearch->new( nodes => $es_node );
	
    return $e;
}

1;