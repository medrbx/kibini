package Webkiosk;

use Moo;

use Kibini::ES;

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

    my @koha_fields = ("dateofbirth", "title", "city", "altcontactcountry", "categorycode", "branchcode", "borrowernumber", "dateenrolled");
    $self->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'userid' } );
    
    return $self;
}

sub get_wkuser_data {
    my ($self) = @_;
    
    $self->_get_wk_location;
    $self->_get_session_duree;
	
	my $param_get_statdb_generic_data = {
		param_get_statdb_age => {
			format_date_event => 'datetime',
			date_event_field => 'session_heure_deb'
		},
		param_get_statdb_nb_annees_adhesion => {
			format_date_event => 'datetime',
			date_event_field => 'session_heure_deb'
		}
	};
    
	$self->get_statdb_adherent_generic_data($param_get_statdb_generic_data);
	
	my $param_get_es_generic_data = {
		param_get_es_age => {
			format_date_event => 'datetime',
			date_event_field => 'session_heure_deb'
		},
		param_get_es_nb_annees_adhesion => {
			format_date_event => 'datetime',
			date_event_field => 'session_heure_deb'
		}
	};
    
	$self->get_es_adherent_generic_data($param_get_es_generic_data);

    return $self;
}

sub add_data_to_statdb_webkiosk {
    my ($self) = @_;
	
	my %statdb_wk_specific_data = %{$self->export_wk_specific_data};
	my %statdb_adherent_data = %{$self->export_adherent_generic_data_to_statdb};	
    
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
        $statdb_wk_specific_data{'session_heure_deb'},
        $statdb_wk_specific_data{'session_heure_fin'},
        $statdb_wk_specific_data{'session_espace'},
        $statdb_wk_specific_data{'session_poste'},
        $statdb_adherent_data{'statdb_userid'},
        $statdb_adherent_data{'statdb_borrowernumber'},
        $statdb_adherent_data{'statdb_age'},
        $statdb_adherent_data{'statdb_sexe'},
        $statdb_adherent_data{'statdb_ville'},
        $statdb_adherent_data{'statdb_rbx_iris'},
        $statdb_adherent_data{'statdb_branchcode'},
        $statdb_adherent_data{'statdb_categorycode'},
        $statdb_adherent_data{'statdb_nb_annees_adhesion'}
    );
    $sth->finish();
}

sub add_data_to_es_webkiosk {
    my ($self) = @_;
    
    my $e = Kibini::ES->new;

}

sub export_wk_specific_data {
    my ($self, $param) = @_;
	my $wk_data = {
		session_heure_deb => $self->{session_heure_deb},
		session_heure_fin => $self->{session_heure_fin},
		session_espace => $self->{session_espace},
		session_poste => $self->{session_poste}
	};

    return $wk_data;
}

sub export_adherent_generic_data_to_es {
    my ($self) = @_;
	my $adherent_data = {
        es_sexe => $self->{es_sexe},
        es_age => $self->{es_age},
        es_age_lib1 => $self->{es_age_lib1},
        es_age_lib2 => $self->{es_age_lib2},
        es_age_lib3 => $self->{es_age_lib3},
        es_geo_ville => $self->{es_geo_ville},
        es_geo_rbx_iris => $self->{es_geo_rbx_iris},
        es_geo_rbx_nom_iris => $self->{es_geo_rbx_nom_iris},
        es_geo_rbx_quartier => $self->{es_geo_rbx_quartier},    
        es_geo_rbx_secteur => $self->{es_geo_rbx_secteur},
        es_geo_gentilite => $self->{es_geo_gentilite},
        es_geo_ville_bm => $self->{es_geo_ville_bm},
        es_geo_ville_front => $self->{es_geo_ville_front},
        es_carte => $self->{es_carte},
        es_type_carte => $self->{es_type_carte},
        es_personnalite  => $self->{es_personnalite},
        es_site_inscription => $self->{es_site_inscription},
        es_inscription_prix => $self->{es_inscription_prix},
        es_inscription_gratuite => $self->{es_inscription_gratuite},
        es_nb_annees_adhesion => $self->{es_nb_annees_adhesion},
        es_nb_annees_adhesion_tra => $self->{es_nb_annees_adhesion_tra},
        es_adherentid => $self->{es_adherentid},
        es_attributes => $self->{es_attributes}
	};

    return $adherent_data;
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
