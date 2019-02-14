package SalleEtude;

use Moo;
use utf8;

use Kibini::ES;

extends 'Adherent';

has consultation_id => ( is => 'ro' );
has consultation_duree => ( is => 'ro' );
has consultation_date_heure_entree => ( is => 'ro' );
has consultation_date_heure_sortie => ( is => 'ro' );

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
    
    if ( $args[0]->{se} ) {
        my %se = %{$args[0]->{se}};
        foreach my $k (keys(%se)) {
            $arg->{$k} = $se{$k};
        }
    }
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    return $arg;
}

sub get_seuser_from_koha {
    my ($self) = @_;

    my @koha_fields = ("dateofbirth", "title", "city", "altcontactcountry", "categorycode", "branchcode", "borrowernumber", "dateenrolled");
    $self->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'cardnumber' } );
    
    return $self;
}

sub get_seuser_data {
    my ($self) = @_;
    
    $self->_get_session_duree;
    
    my $param_get_statdb_generic_data = {
        param_get_statdb_age => {
            date_event_format => 'datetime',
            date_event_field => $self->{consultation_date_heure_entree}
        },
        param_get_statdb_nb_annees_adhesion => {
            date_event_format => 'datetime',
            date_event_field => $self->{consultation_date_heure_entree}
        }
    };
    
    $self->get_statdb_adherent_generic_data($param_get_statdb_generic_data);
    
    my $param_get_es_generic_data = {
        param_get_es_age => {
            format_date_event => 'datetime',
            date_event_field => $self->{consultation_date_heure_entree}
        },
        param_get_es_nb_annees_adhesion => {
            format_date_event => 'datetime',
            date_event_field => $self->{consultation_date_heure_entree}
        }
    };
    
    $self->get_es_adherent_generic_data($param_get_es_generic_data);

    return $self;
}

sub add_data_to_statdb_freq_etude {
    my ($self) = @_;
    
    my %statdb_se_specific_data = %{$self->export_se_specific_data_to_statdb};
    my %statdb_adherent_data = %{$self->export_adherent_generic_data_to_statdb};    
    
    my $dbh = $self->{dbh};
    my $req = <<SQL;
UPDATE statdb.stat_freq_etude
SET
    borrowernumber = ?,
    sexe = ?,
    age = ?,
    ville = ?,
    iris = ?,
    categorycode = ?
WHERE id = ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute(
        $statdb_adherent_data{'statdb_borrowernumber'},
        $statdb_adherent_data{'statdb_sexe'},
        $statdb_adherent_data{'statdb_age'},
        $statdb_adherent_data{'statdb_ville'},
        $statdb_adherent_data{'statdb_rbx_iris'},
        $statdb_adherent_data{'statdb_categorycode'},
        $statdb_se_specific_data{'consultation_id'}
    );
    $sth->finish();
}

sub export_se_specific_data_to_statdb {
    my ($self, $param) = @_;
    my $se_data = {
        consultation_id => $self->{consultation_id},
        consultation_duree => $self->{consultation_duree},
        consultation_date_heure_entree => $self->{consultation_date_heure_entree},
        consultation_date_heure_sortie => $self->{session_poste}
    };

    return $se_data;
}

sub _get_session_duree {
    my ($self) = @_ ;

    my $kt = Kibini::Time->new({ start => { value => $self->{consultation_date_heure_entree}, format => 'datetime' }, end => { value => $self->{consultation_date_heure_sortie}, format => 'datetime' }});
    $kt->get_duration({type => 'minutes'});

    $self->{consultation_duree} = $kt->duration;
    
    return $self ;
}

1;

__END__

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
            date_event_format => 'datetime',
            date_event_field => $self->{session_heure_deb}
        },
        param_get_statdb_nb_annees_adhesion => {
            date_event_format => 'datetime',
            date_event_field => $self->{session_heure_deb}
        }
    };
    
    $self->get_statdb_adherent_generic_data($param_get_statdb_generic_data);
    
    my $param_get_es_generic_data = {
        param_get_es_age => {
            format_date_event => 'datetime',
            date_event_field => $self->{session_heure_deb}
        },
        param_get_es_nb_annees_adhesion => {
            format_date_event => 'datetime',
            date_event_field => $self->{session_heure_deb}
        }
    };
    
    $self->get_es_adherent_generic_data($param_get_es_generic_data);

    return $self;
}

sub add_data_to_statdb_webkiosk {
    my ($self) = @_;
    
    my %statdb_wk_specific_data = %{$self->export_wk_specific_data_to_statdb};
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
    
    my $e = Kibini::ES->new->e;
    

    my %es_wk_specific_data = %{$self->export_wk_specific_data_to_es};
    my %es_adherent_data = %{$self->export_adherent_generic_data_to_es};

    my %index = (
        index   => 'webkiosk',
        type    => 'sessions',
        body    => {
            session_heure_deb => $es_wk_specific_data{'session_heure_deb'},
            session_heure_fin => $es_wk_specific_data{'session_heure_fin'},
            session_duree => $es_wk_specific_data{'session_duree'},
            session_espace => $es_wk_specific_data{'session_espace'},
            session_groupe => $es_wk_specific_data{'session_groupe'},
            session_poste => $es_wk_specific_data{'session_poste'},
            adherent_id => $es_adherent_data{es_adherentid},
            adherent_sexe => $es_adherent_data{es_sexe},
            adherent_age => $es_adherent_data{es_age},
            adherent_age_lib1 => $es_adherent_data{es_age_lib1},
            adherent_age_lib2 => $es_adherent_data{es_age_lib2},
            adherent_age_lib3 => $es_adherent_data{es_age_lib3},
            adherent_carte => $es_adherent_data{es_carte},
            adherent_type_carte => $es_adherent_data{es_type_carte},
            adherent_inscription_prix => $es_adherent_data{es_inscription_prix},
            adherent_inscription_gratuite => $es_adherent_data{es_inscription_gratuite},
            adherent_nb_annee_inscription => $es_adherent_data{es_nb_annees_adhesion},
            adherent_nb_annee_inscription_tra => $es_adherent_data{es_nb_annees_adhesion_tra},
            adherent_ville => $es_adherent_data{es_geo_ville},
            adherent_rbx_iris => $es_adherent_data{es_geo_rbx_iris},
            adherent_rbx_nom_iris => $es_adherent_data{es_geo_rbx_nom_iris},
            adherent_rbx_quartier => $es_adherent_data{es_geo_rbx_quartier},
            adherent_rbx_secteur => $es_adherent_data{es_geo_rbx_secteur},
            adherent_geo_gentilite => $es_adherent_data{es_geo_gentilite},
            adherent_geo_ville_bm => $es_adherent_data{es_geo_ville_bm},
            adherent_es_geo_ville_front => $es_adherent_data{es_geo_ville_front},
            adherent_site_inscription => $es_adherent_data{es_site_inscription},
            adherent_personnalite => $es_adherent_data{es_personnalite},
            adherent_attributes => $es_adherent_data{es_attributes}
        }
    );

    $e->index(%index);

    return \%index;
}

sub export_wk_specific_data_to_statdb {
    my ($self, $param) = @_;
    my $wk_data = {
        session_heure_deb => $self->{session_heure_deb},
        session_heure_fin => $self->{session_heure_fin},
        session_espace => $self->{session_espace},
        session_poste => $self->{session_poste}
    };

    return $wk_data;
}

sub export_wk_specific_data_to_es {
    my ($self, $param) = @_;
    my $wk_data = {
        session_heure_deb => $self->{session_heure_deb},
        session_heure_fin => $self->{session_heure_fin},
        session_espace => $self->{session_espace},
        session_groupe => $self->{session_groupe},
        session_poste => $self->{session_poste},
        session_duree => $self->{session_duree}
    };

    return $wk_data;
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
    $self->{session_espace} = $espaces{$self->{session_groupe}} ;
    return $self ;
}

1;
