package webkiosk ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetWkLocation ) ;

use strict ;
use warnings ;

sub GetWkLocation {
    my ($groupe) = @_ ;
    my %espaces = (
        'Atelier' => 'Multimédia',
        'Disco' => 'Phare',
        'Etude' => 'Etude',
        'Jeux' => 'Jeunesse',
        'Lecture' => '1er étage',
        'Jeunesse' => 'Jeunesse',
        'Devoir' => 'Jeunesse',
        'Rdc' => 'Rez-de-chaussée',
        'Reussir' => 'Phare',
        'Cafe' => 'Rez-de-chaussée',
        'Rdc Ascenceur' => 'Rez-de-chaussée'
    ) ;
    my $espace = $espaces{$groupe} ;
    return $espace ;
}
