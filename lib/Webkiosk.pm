package Webkiosk;

use Moo;

use Kibini::DB;
extends 'Adherent';

has wk_heure_deb => ( is => 'ro' );
has wk_heure_fin => ( is => 'ro' );
has wk_espace => ( is => 'ro' );
has wk_poste => ( is => 'ro' );

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
    
    if ( $args[0]->{wk} ) {
        my %wk = %{$args[0]->{wk}};
        foreach my $k (keys(%wk)) {
            $arg->{$k} = $wk{$k};
        }
    }

    return $arg;
}

sub get_wkusers_from_koha {
    my ($self) = @_;

    my @koha_fields = ("dateofbirth", "city", "altcontactcountry", "categorycode", "branchcode", "borrowernumber", "dateenrolled");
    $self->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'userid' } );
    
    return $self;
}

sub mod_data_to_statdb_webkiosk {
    my ($self) = @_;
    
    $self->{statdb_ville} = $self->{koha_city};
    $self->{statdb_iris} = $self->{koha_altcontactcountry};
    $self->{statdb_branchcode} = $self->{koha_branchcode};
    $self->{statdb_categorycode} = $self->{koha_categorycode};
    $self->get_age_at_time_of_event( {format_date_event => 'datetime', date_event_field => 'wk_heure_deb'} );
    $self->get_fidelite( {format_date_event => 'datetime', date_event_field => 'wk_heure_deb'} );

    return $self;
}

sub add_data_to_statdb_webkiosk {
    my ($self) = @_;
    
    my $dbh = $self->{dbh};
    my $req = <<SQL;
INSERT INTO statdb.stat_webkiosk (heure_deb, heure_fin, espace, poste, id, borrowernumber, age, sexe, ville, iris, branchcode, categorycode, fidelite)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute( $self->{wk_heure_deb}, $self->{wk_heure_fin}, $self->{wk_espace}, $self->{wk_poste}, $self->{koha_userid}, $self->{koha_borrowernumber}, $self->{statdb_age}, $self->{statdb_sexe}, $self->{statdb_ville}, $self->{statdb_iris}, $self->{statdb_branchcode}, $self->{statdb_categorycode}, $self->{statdb_fidelite} );
	$sth->finish();

    return $self;
}

1;