package Kibini::ES;

use Moo;
use YAML qw(LoadFile);
use Search::Elasticsearch;

use Kibini::Config;

has e => ( is => 'ro', builder => '_get_e' );
has conf => ( is => 'ro', builder => '_get_conf' );
has mappings => ( is => 'ro');


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

    return $result->{aggregations}->{max_datetime}->{value_as_string}; 
}

sub get_mappings {
    my ( $self ) = @_;

    my $mappings_file = $self->{conf}->{mappings_file};
    $self->{mappings} = LoadFile($mappings_file);
    
    return $self;
}

sub regenerate_index {
    my ( $self, $index_name ) = @_;

    my $mapping = $self->{mappings}->{$index_name};
    my %index_conf = (
        index => $index_name,
        body => $mapping
    );

    my $e = $self->{e};
    $e->indices->delete( index => $index_name );
    my $result = $e->indices->create( %index_conf );
    
    return $result;
}

sub _get_e {
    my $conf_elasticsearch = Kibini::Config->new->elasticsearch;
    my $es_node = $conf_elasticsearch->{node};
    my %params = ( nodes => $es_node );

    my $e = Search::Elasticsearch->new( nodes => $es_node );
    
    return $e;
}

sub _get_conf {
    my $conf = Kibini::Config->new->elasticsearch;
   
    return $conf;
}

1;