package collections ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( dataCollections ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin );
use Encode qw(encode);
use JSON ;

sub dataCollections {
    my ($index) = @_ ;
    my $file = "$Bin/../public/data/collections.json";
    open my $fic, "<", $file ;
    my $json = <$fic> ;
    close $fic;
    my $collections_data = decode_json $json ;
    return $collections_data->{'collection'}->[$index] ;
}

1 ;