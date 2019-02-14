package Kibini::ES;

use Moo;
use Search::Elasticsearch;

use Kibini::Config;

has e => ( is => 'ro', builder => '_get_e' );


sub get_es_max_date_and_time {
    my ($self, $param) = @_;
        
    my $e = $self->{e};    
    my $result =  $e->search(
        index => $param->{index},
        type  => $param->{type},
        body    => {
            aggs       => {
                max_datetime => {
                    max => {
                        field => $param->{field}
                    }
                }
            }
        }
    );

    return $result->{aggregations}->{max_datetime}->{value_as_string} ; 
}

sub _get_e {
    my $conf_elasticsearch = Kibini::Config->new->elasticsearch;
    my $es_node = $conf_elasticsearch->{node};
    my %params = ( nodes => $es_node );

    my $e = Search::Elasticsearch->new( nodes => $es_node );
    
    return $e;
}

1;
