package Adherent::StatDB;

use Moo;

extends 'Kibini::DB';
with 'Adherent::Pratiques';

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

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{dbh} ) {
        $arg->{dbh} = $args[0]->{dbh};
    } else {
        my $dbh = Kibini::DB->new;
        $dbh = $dbh->dbh;
        $arg->{dbh} = $dbh;
    }

    if ( $args[0]->{adherent} ) {
        my %adh = %{$args[0]->{adherent}};
        foreach my $k (keys(%adh)) {
            $arg->{$k} = $adh{$k};
        }
    }

    return $arg;
}

1;


__END__
