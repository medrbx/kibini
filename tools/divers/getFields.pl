#! /usr/bin/perl

use strict;
use warnings;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::elasticsearch;

my $es_node = GetEsNode();
my %params = ( nodes => $es_node );
my $index = "test_fields";
my $type = "fields";
my $e = Search::Elasticsearch->new( %params );
 
my $importer = Catmandu->importer('MARC', type => 'RAW', file => "/home/kibini/kibini_prod/data/2018-01-07-notices_total.mrc");

$importer->each(sub {
    my $data = shift;
    my @field_tags;
    foreach my $field ( @{$data->{record}} ) {
        my @field_elements = @$field;
        my @subfield_tags;
        my $field_str;
        if ( $field_elements[0] ne 'LDR' ) {
            if ( $field_elements[0] >= 10 ) {
                my $n = scalar(@field_elements);
                my $i = 3;
                while ( $i < $n) {
                    push @subfield_tags, $field_elements[$i];
                    $i = $i + 2;
                }
                $field_str = { tag => "F_" . $field_elements[0], subfields_tag => \@subfield_tags };
            } else {
                $field_str = { tag => "F_" . $field_elements[0]};
            }
            
        } else {
            $field_str = { tag => "F_" . $field_elements[0]};
        }
        push @field_tags, $field_str;
    }
    my %record_fields = (
        id => "RBX_" . $data->{_id},
        fields => \@field_tags
    );

	my %index = (
        index   => $index,
        type    => $type,
        body    => \%record_fields
    ) ;

    $e->index(%index) ;
	
    print Dumper(\%record_fields);
});
