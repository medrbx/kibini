package Webkiosk;

use Moo;
use utf8;

use Kibini::ES;

with 'Evenement', 'Adherent';

has session_groupe => ( is => 'ro' );
has session_poste => ( is => 'ro' );
has session_id => ( is => 'ro' );

has statdb_session_groupe => ( is => 'ro' );
has statdb_session_poste => ( is => 'ro' );
has statdb_session_id => ( is => 'ro' );

has es_session_espace => ( is => 'ro' );
has es_session_groupe => ( is => 'ro' );
has es_session_poste => ( is => 'ro' );
has es_session_id => ( is => 'ro' );

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
    
    $self->get_es_duree_ab('minutes');
    unless ($self->{statdb_session_id}) {
        if ($self->{session_id}) {
            $self->{statdb_session_id} = $self->{session_id};
        } elsif ($self->{es_session_id}) {
            $self->{statdb_session_id} = $self->{es_session_id};
        }
    }
    unless ($self->{statdb_session_groupe}) {
        if ($self->{session_groupe}) {
            $self->{statdb_session_groupe} = $self->{session_groupe};
        } elsif ($self->{es_session_groupe}) {
            $self->{statdb_session_groupe} = $self->{es_session_groupe};
        }
    }
    unless ($self->{statdb_session_poste}) {
        if ($self->{session_poste}) {
            $self->{statdb_session_poste} = $self->{session_poste};
        } elsif ($self->{es_session_poste}) {
            $self->{statdb_session_poste} = $self->{es_session_poste};
        }
    }
    unless ($self->{es_session_id}) {
        if ($self->{session_id}) {
            $self->{es_session_id} = $self->{session_id};
        } elsif ($self->{statdb_session_id}) {
            $self->{es_session_id} = $self->{statdb_session_id};
        }
    }

    unless ($self->{es_session_groupe}) {
        if ($self->{session_groupe}) {
            $self->{es_session_groupe} = $self->{session_groupe};
        } elsif ($self->{statdb_session_groupe}) {
            $self->{es_session_groupe} = $self->{statdb_session_groupe};
        }
    }
    unless ($self->{es_session_poste}) {
        if ($self->{session_poste}) {
            $self->{es_session_poste} = $self->{session_poste};
        } elsif ($self->{statdb_session_poste}) {
            $self->{es_session_poste} = $self->{statdb_session_poste};
        }
    }
    $self->_get_wk_location;    

    my $param_get_statdb_generic_data = {
        param_get_statdb_age => {
            date_event_format => 'datetime',
            date_event_field => $self->{statdb_date_heure_a}
        },
        param_get_statdb_inscription_nb_annees_adhesion => {
            date_event_format => 'datetime',
            date_event_field => $self->{statdb_date_heure_a}
        }
    };
    
    $self->get_statdb_adherent_generic_data($param_get_statdb_generic_data);
    
    my $param_get_es_generic_data = {
        param_get_es_age => {
            format_date_event => 'datetime',
            date_event_field => $self->{es_date_heure_a}
        },
        param_get_es_inscription_nb_annees_adhesion => {
            format_date_event => 'datetime',
            date_event_field => $self->{es_date_heure_a}
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
    my $res = $sth->execute(
        $statdb_wk_specific_data{'statdb_session_heure_deb'},
        $statdb_wk_specific_data{'statdb_session_heure_fin'},
        $statdb_wk_specific_data{'statdb_session_groupe'},
        $statdb_wk_specific_data{'statdb_session_poste'},
        $statdb_adherent_data{'statdb_userid'},
        $statdb_adherent_data{'statdb_borrowernumber'},
        $statdb_adherent_data{'statdb_age'},
        $statdb_adherent_data{'statdb_sexe_code'},
        $statdb_adherent_data{'statdb_geo_ville'},
        $statdb_adherent_data{'statdb_geo_rbx_iris'},
        $statdb_adherent_data{'statdb_inscription_site_code'},
        $statdb_adherent_data{'statdb_inscription_carte_code'},
        $statdb_adherent_data{'statdb_inscription_nb_annees_adhesion'}
    );
    $sth->finish();
    return $res;
}

sub add_data_to_es_webkiosk {
    my ($self) = @_;
    
    my $e = Kibini::ES->new->e;
    

    my %es_wk_specific_data = %{$self->export_wk_specific_data_to_es};
    my %es_adherent_data = %{$self->export_adherent_generic_data_to_es};

    my %index = (
        index   => 'sessions_webkiosk',
        type    => 'sessions',
        id     => $es_wk_specific_data{es_session_id},
        body    => {
            session_id => $es_wk_specific_data{es_session_id},
            session_heure_deb => $es_wk_specific_data{es_session_heure_deb},
            session_heure_deb_annee => $es_wk_specific_data{es_session_heure_deb_annee},
            session_heure_deb_heure => $es_wk_specific_data{es_session_heure_deb_heure},
            session_heure_deb_jour => $es_wk_specific_data{es_session_heure_deb_jour},
            session_heure_deb_jour_semaine => $es_wk_specific_data{es_session_heure_deb_jour_semaine},
            session_heure_deb_mois => $es_wk_specific_data{es_session_heure_deb_mois},
            session_heure_deb_semaine => $es_wk_specific_data{es_session_heure_deb_semaine},
            session_heure_fin => $es_wk_specific_data{es_session_heure_fin},
            session_heure_fin_annee => $es_wk_specific_data{es_session_heure_fin_annee},
            session_heure_fin_heure => $es_wk_specific_data{es_session_heure_fin_heure},
            session_heure_fin_jour => $es_wk_specific_data{es_session_heure_fin_jour},
            session_heure_fin_jour_semaine => $es_wk_specific_data{es_session_heure_fin_jour_semaine},
            session_heure_fin_mois => $es_wk_specific_data{es_session_heure_fin_mois},
            session_heure_fin_semaine => $es_wk_specific_data{es_session_heure_fin_semaine},
            session_duree => $es_wk_specific_data{es_session_duree},
            session_espace => $es_wk_specific_data{es_session_espace},
            session_groupe => $es_wk_specific_data{es_session_groupe},
            session_poste => $es_wk_specific_data{es_session_poste},
            adherent_adherentid => $es_adherent_data{es_adherentid},
            adherent_sexe => $es_adherent_data{es_sexe},
            adherent_age_code => $es_adherent_data{es_age_code},
            adherent_age_lib1 => $es_adherent_data{es_age_lib1},
            adherent_age_lib2 => $es_adherent_data{es_age_lib2},
            adherent_age_lib3 => $es_adherent_data{es_age_lib3},
            adherent_geo_gentilite => $es_adherent_data{es_geo_gentilite},
            adherent_geo_rbx_iris => $es_adherent_data{es_geo_rbx_iris},
            adherent_geo_rbx_nom_iris => $es_adherent_data{es_geo_rbx_nom_iris},
            adherent_geo_rbx_quartier     => $es_adherent_data{es_geo_rbx_quartier},
            adherent_geo_rbx_secteur => $es_adherent_data{es_geo_rbx_secteur},
            adherent_geo_ville => $es_adherent_data{es_geo_ville},
            adherent_geo_ville_bm => $es_adherent_data{es_geo_ville_bm},
            adherent_geo_ville_front => $es_adherent_data{es_geo_ville_front},
            adherent_inscription_carte => $es_adherent_data{es_inscription_carte},
            adherent_inscription_gratuite => $es_adherent_data{es_inscription_gratuite},
            adherent_inscription_nb_annees_adhesion => $es_adherent_data{es_inscription_nb_annees_adhesion},
            adherent_inscription_nb_annees_adhesion_tra => $es_adherent_data{es_inscription_nb_annees_adhesion_tra},
            adherent_inscription_personnalite  => $es_adherent_data{es_inscription_personnalite},
            adherent_inscription_prix => $es_adherent_data{es_inscription_prix},
            adherent_inscription_site => $es_adherent_data{es_inscription_site},
            adherent_inscription_type_carte => $es_adherent_data{es_inscription_type_carte},
            adherent_attributes_action => $es_adherent_data{es_attributes_action},
            adherent_attributes_collectivites => $es_adherent_data{es_attributes_collectivites},
            adherent_attributes_pcs => $es_adherent_data{es_attributes_pcs},
            adherent_attributes_zebre => $es_adherent_data{es_attributes_zebre}
        }
    );

    my $res = $e->index(%index);

    return \%index;
}

sub export_wk_specific_data_to_statdb {
    my ($self, $param) = @_;
    my $wk_data = {
        statdb_session_heure_deb => $self->{statdb_date_heure_a},
        statdb_session_heure_fin => $self->{statdb_date_heure_b},
        statdb_session_groupe => $self->{statdb_session_groupe},
        statdb_session_poste => $self->{statdb_session_poste},
        statdb_session_id => $self->{statdb_session_id}
    };

    return $wk_data;
}

sub export_wk_specific_data_to_es {
    my ($self, $param) = @_;
    my $wk_data = {
        es_session_heure_deb => $self->{es_date_heure_a},
        es_session_heure_deb_annee => $self->{es_date_heure_a_annee},
        es_session_heure_deb_heure => $self->{es_date_heure_a_heure},
        es_session_heure_deb_jour => $self->{es_date_heure_a_jour},
        es_session_heure_deb_jour_semaine => $self->{es_date_heure_a_jour_semaine},
        es_session_heure_deb_mois => $self->{es_date_heure_a_mois},
        es_session_heure_deb_semaine => $self->{es_date_heure_a_semaine},
        es_session_heure_fin => $self->{es_date_heure_b},
        es_session_heure_fin_annee => $self->{es_date_heure_b_annee},
        es_session_heure_fin_heure => $self->{es_date_heure_b_heure},
        es_session_heure_fin_jour => $self->{es_date_heure_b_jour},
        es_session_heure_fin_jour_semaine => $self->{es_date_heure_b_jour_semaine},
        es_session_heure_fin_mois => $self->{es_date_heure_b_mois},
        es_session_heure_fin_semaine => $self->{es_date_heure_b_semaine},
        es_session_duree => $self->{es_duree_ab},
        es_session_espace => $self->{es_session_espace},
        es_session_groupe => $self->{es_session_groupe},
        es_session_poste => $self->{es_session_poste},
        es_session_id => $self->{es_session_id}
    };

    return $wk_data;
}

sub ano_statdb_sessions_webkiosk {
    my ($self) = @_;
    
    my $dbh = $self->{dbh};
    my $req = <<SQL;
UPDATE statdb.stat_sessions_webkiosk
SET
	adherent_adherentid = NULL,
	updated_on = NOW()
WHERE DATE(session_date_heure_debut) < CURDATE() - INTERVAL 1 YEAR AND adherent_adherentid IS NOT NULL
SQL
    my $sth = $dbh->prepare($req);
    my $res = $sth->execute;

    return $res;
}


sub _get_wk_location {
    my ($self) = @_;
    
    if ($self->{statdb_session_poste}) {
        $self->{es_session_poste} = $self->{statdb_session_poste};
    }
    
    if ($self->{statdb_session_groupe}) {
        $self->{es_session_groupe} = $self->{statdb_session_groupe};
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
        );
        $self->{es_session_espace} = $espaces{$self->{es_session_groupe}};
    }
    
    return $self;
}

1;
