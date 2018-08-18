package Adherent::Pratiques;

use Moo::Role;

has nb_venues_prets_mediatheque => ( is => 'ro' );
has nb_venues_prets_bus => ( is => 'ro' );
has nb_venues_postes_informatiques => ( is => 'ro' );
has nb_venues_wifi => ( is => 'ro' );
has nb_venues_salle_etude => ( is => 'ro' );
has nb_venues => ( is => 'ro' );

1;
