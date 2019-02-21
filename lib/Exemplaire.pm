package Exemplaire;

use Moo;
use utf8;

with 'Document';

sub get_exemplaire_from_koha {
    my ($self) = @_;

    my @koha_fields = ("i.biblionumber","i.barcode","b.title");
    $self->get_document_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'itemnumber' } );
    
    return $self;
}

1;

__END__