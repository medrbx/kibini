package Webkiosk;

use Moo;

use Kibini::ES;
use Kibini::Time;

extends 'Adherent';

has session_heure_deb => ( is => 'ro' );
has session_heure_fin => ( is => 'ro' );
has session_espace => ( is => 'rw' );
has session_poste => ( is => 'ro' );
has session_duree  => ( is => 'ro' );

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
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    return $arg;
}

sub get_wkuser_from_koha {
    my ($self) = @_;

    my @koha_fields = ("dateofbirth", "city", "altcontactcountry", "categorycode", "branchcode", "borrowernumber", "dateenrolled");
    $self->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'userid' } );
    
    return $self;
}

sub get_wkuser_data {
    my ($self) = @_;
    
	$self->_get_wk_location;
	$self->_get_session_duree;
	
	$self->get_statdb_adherentid;
	$self->get_statdb_userid;
	$self->get_statdb_borrowernumber;
	$self->get_statdb_age( {format_date_event => 'datetime', date_event_field => 'session_heure_deb'} );
	$self->get_statdb_sexe;
	$self->get_statdb_ville;
	$self->get_statdb_rbx_iris;
	$self->get_statdb_branchcode;
	$self->get_statdb_categorycode;
	$self->get_statdb_nb_annees_adhesion( {format_date_event => 'datetime', date_event_field => 'session_heure_deb'} );
	
	$self->get_es_adherentid;
	$self->get_es_age( {format_date_event => 'datetime', date_event_field => 'session_heure_deb'} );
	$self->get_es_age_labels;	
	$self->get_es_carte;
	$self->get_es_type_carte;
	$self->get_es_nb_annees_adhesion( {format_date_event => 'datetime', date_event_field => 'session_heure_deb'} );
	$self->get_es_ville;
	$self->get_es_rbx_iris;
	$self->get_es_rbx_nom_iris;
	$self->get_es_rbx_quartier;
	$self->get_es_rbx_secteur;
	$self->get_es_site_inscription;
	$self->get_es_personnalite;

    return $self;
}

sub add_data_to_statdb_webkiosk {
    my ($self) = @_;
    
    my $dbh = $self->{dbh};
    my $req = <<SQL;
INSERT INTO statdb.stat_webkiosk (
	heure_deb,
	heure_fin,
	espace,
	poste,
	id,
	borrowernumber,
	age,
	sexe,
	ville,
	iris,
	branchcode,
	categorycode,
	fidelite)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute(
		$self->{session_heure_deb},
		$self->{session_heure_fin},
		$self->{session_espace},
		$self->{session_poste},
		$self->{statdb_userid},
		$self->{statdb_borrowernumber},
		$self->{statdb_age},
		$self->{statdb_sexe},
		$self->{statdb_ville},
		$self->{statdb_rbx_iris},
		$self->{statdb_branchcode},
		$self->{statdb_categorycode},
		$self->{statdb_nb_annees_adhesion}
	);
    $sth->finish();
}

sub add_data_to_es_webkiosk {
    my ($self) = @_;
	
	my $e = Kibini::ES->new;

}

sub _get_wk_location {
    my ($self) = @_ ;
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
    $self->{session_espace} = $espaces{$self->{session_espace}} ;
    return $self ;
}

sub _get_session_duree {
    my ($self) = @_ ;
	
	my $time = Kibini::Time->new;
	$time->get_duration({ datetime1 => $self->{session_heure_deb}, datetime2 => $self->{session_heure_fin}, type => 'minutes' });
	$self->{session_duree} = $time->{duration};
	
    return $self ;
}

1;