package Adherent::Kibini;

use Moo;

use 'Kibini::DB';

has date_extraction => ( is => 'ro' );
has adherent_id => ( is => 'ro' );
has age => ( is => 'ro' );
has geo_ville => ( is => 'ro' );
has geo_roubaix_iris => ( is => 'ro' );
has sexe => ( is => 'ro' );
has inscription_code_carte => ( is => 'ro' );
has inscription_code_site => ( is => 'ro' );
has attributes => ( is => 'ro' );
has inscription_fidelite => ( is => 'ro' );

has dbh => ( is => 'ro' );


1;


__END__
