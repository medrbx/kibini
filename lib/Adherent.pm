package Adherent;

use Moo;
use List::MoreUtils qw(any);
use utf8;

use Kibini::DB;
use Kibini::Crypt;
use Kibini::Time;

has crypter => ( is => 'ro' );

has dbh => ( is => 'ro' );

has koha_borrowernumber => ( is => 'ro' );
has koha_cardnumber => ( is => 'ro' );
has koha_title => ( is => 'ro' );
has koha_city => ( is => 'ro' );
has koha_dateofbirth => ( is => 'ro' );
has koha_branchcode => ( is => 'ro' );
has koha_categorycode => ( is => 'ro' );
has koha_dateenrolled => ( is => 'ro' );
has koha_userid => ( is => 'ro' );
has koha_altcontactcountry => ( is => 'ro' );

has koha_attributes => ( is => 'ro' ); # array

has statdb_sexe_code => ( is => 'ro' );
has statdb_age => ( is => 'ro' );  # à suppr pour ano
has statdb_age_code => ( is => 'ro' );
has statdb_geo_ville => ( is => 'ro' );
has statdb_geo_rbx_iris => ( is => 'ro' );
has statdb_inscription_carte_code => ( is => 'ro' );
has statdb_inscription_site_code => ( is => 'ro' );
has statdb_inscription_nb_annees_adhesion => ( is => 'ro' );
has statdb_userid => ( is => 'ro' );  # à suppr pour ano
has statdb_borrowernumber => ( is => 'ro' ); # à suppr pour ano
has statdb_adherentid => ( is => 'ro' );
has statdb_attributes => ( is => 'ro' ); # string

has es_sexe => ( is => 'ro' );
has es_age => ( is => 'ro' );
has es_age_lib1 => ( is => 'ro' );
has es_age_lib2 => ( is => 'ro' );
has es_age_lib3 => ( is => 'ro' );
has es_geo_ville => ( is => 'ro' );
has es_geo_rbx_iris => ( is => 'ro' );
has es_geo_rbx_nom_iris => ( is => 'ro' );
has es_geo_rbx_quartier => ( is => 'ro' );    
has es_geo_rbx_secteur => ( is => 'ro' );
has es_geo_gentilite => ( is => 'ro' );
has es_geo_ville_bm => ( is => 'ro' );
has es_geo_ville_front => ( is => 'ro' );
has es_inscription_carte => ( is => 'ro' );
has es_inscription_type_carte => ( is => 'ro' );
has es_inscription_personnalite  => ( is => 'ro' );
has es_inscription_site => ( is => 'ro' );
has es_inscription_prix => ( is => 'ro' );
has es_inscription_gratuite => ( is => 'ro' );
has es_inscription_nb_annees_adhesion => ( is => 'ro' );
has es_inscription_nb_annees_adhesion_tra => ( is => 'ro' );
has es_adherentid => ( is => 'ro' );
has es_attributes => ( is => 'ro' );

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
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    return $arg;
}

sub get_data_from_koha_by_id {
    my ($self, $param) = @_;
    
    my $dbh = $self->{dbh};
    
    my $select = join ", ", @{ $param->{koha_fields} };
    my $id = $param->{koha_id};
    my $req = "SELECT $select FROM koha_prod.borrowers WHERE $id = ?";
    my $sth = $dbh->prepare($req);
    $id = "koha_" . $id;
    $sth->execute($self->$id);
    my $result = $sth->fetchrow_hashref ;
    $sth->finish();
    
    foreach my $k (keys(%$result)) {
        my $key = "koha_" . $k;
        $self->{$key} = $result->{$k};
    }
    
    $self->get_koha_attributes;

    return $self;
}

sub get_statdb_adherent_generic_data {
    my ($self, $param) = @_;
    
    $self->get_statdb_adherentid;
    $self->get_statdb_userid;
    $self->get_statdb_borrowernumber;
    $self->get_statdb_age($param);
    $self->get_statdb_sexe_code;
    $self->get_statdb_geo_ville;
    $self->get_statdb_geo_rbx_iris;
    $self->get_statdb_inscription_site_code;
    $self->get_statdb_inscription_carte_code;
    $self->get_statdb_inscription_nb_annees_adhesion($param);
    $self->get_statdb_attributes;

    return $self;
}

sub get_es_adherent_generic_data {
    my ($self, $param) = @_;
    
    $self->get_es_adherentid;
    $self->get_es_age($param);
    $self->get_es_age_labels; 
    $self->get_es_sexe;    
    $self->get_es_inscription_carte;
    $self->get_es_inscription_type_carte;
    $self->get_es_inscription_nb_annees_adhesion($param);
    $self->get_es_inscription_nb_annees_adhesion_tra;
    $self->get_es_geo_ville;
    $self->get_es_geo_rbx_iris;
    $self->get_es_geo_rbx_nom_iris;
    $self->get_es_geo_rbx_quartier;
    $self->get_es_geo_rbx_secteur;
    $self->get_es_geo_gentilite;
    $self->get_es_geo_ville_front;
    $self->get_es_geo_ville_bm;
    $self->get_es_inscription_site;
    $self->get_es_inscription_personnalite;
    $self->get_es_inscription_prix_gratuite;
    $self->get_es_attributes;

    return $self;
}

sub get_koha_attributes {
    my ($self) = @_;

    my @attributes;
    my $req = "SELECT attribute FROM koha_prod.borrower_attributes WHERE borrowernumber = ?";
    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare($req);
    $sth->execute($self->{koha_borrowernumber});
    while (my $att = $sth->fetchrow_array) {
        push @attributes, $att;
    }
    $sth->finish();
    $self->{koha_attributes} = \@attributes;

    return $self;
}

sub get_statdb_age {
    my ($self, $param) = @_;
    
    if ( $self->{koha_dateofbirth} ) {
        my $date_event = $param->{param_get_statdb_age}->{date_event_field};
        my $date_event_format = $param->{param_get_statdb_age}->{date_event_format};        
        my $kt = Kibini::Time->new({ start => { value => $self->{koha_dateofbirth}, format => 'date' }, end => { value => $date_event, format => $date_event_format }});
        $kt->get_duration({type => 'years'});
        $self->{statdb_age} = $kt->duration;
    }
    return $self;
}

# TO DO
sub get_statdb_age_code {
    my ($self) = @_;
     
    return $self;
}

sub get_statdb_geo_ville {
    my ($self) = @_;
    
    $self->{statdb_geo_ville} = $self->{koha_city};
    
    return $self;
}

sub get_statdb_geo_rbx_iris {
    my ($self) = @_;
    
    $self->{statdb_geo_rbx_iris} = $self->{koha_altcontactcountry};
    
    return $self;
}

sub get_statdb_inscription_site_code {
    my ($self) = @_;
    
    $self->{statdb_inscription_site_code} = $self->{koha_branchcode};
    
    return $self;
}

sub get_statdb_inscription_carte_code {
    my ($self) = @_;
    
    $self->{statdb_inscription_carte_code} = $self->{koha_categorycode};
    
    return $self;
}

sub get_statdb_inscription_nb_annees_adhesion {
    my ($self, $param) = @_;
    
    if ($self->{koha_dateenrolled}) {
        my $date_event = $param->{param_get_statdb_inscription_nb_annees_adhesion}->{date_event_field};
        my $date_event_format = $param->{param_get_statdb_inscription_nb_annees_adhesion}->{date_event_format};        
        my $kt = Kibini::Time->new({ start => { value => $self->{koha_dateenrolled}, format => 'date' }, end => { value => $date_event, format => $date_event_format }} );
        $kt->get_duration({type => 'years'});
        $self->{statdb_inscription_nb_annees_adhesion} = $kt->duration;
    }

    return $self;
}

sub get_statdb_sexe_code {
    my ($self) = @_;
    
    my @categorycodes = qw( MEDA MEDB MEDC CSVT MEDP BIBL CSLT );
    my $categorycode;
    if ($self->{koha_categorycode} ) {
        $categorycode = $self->{koha_categorycode};
    } elsif ($self->{statdb_inscription_carte_code} ) {
        $categorycode = $self->{statdb_inscription_carte_code};
    }
    
    if ( any { /$categorycode/ } @categorycodes ) {
        if ( $self->{koha_title} ) {
            if ( $self->{koha_title} eq 'Madame' ) {
                $self->{statdb_sexe_code} = 'F';
            } elsif ( $self->{koha_title} eq 'Monsieur' ) {
                $self->{statdb_sexe_code} = 'M';
            } else {
                $self->{statdb_sexe_code} = 'NC';
            }
        }
    } else {
        $self->{statdb_sexe_code} = 'NP';
    }
    
    return $self;
}

sub get_statdb_userid {
    my ($self) = @_;
    
    $self->{statdb_userid} = $self->{koha_userid};
    
    return $self;
}

sub get_statdb_borrowernumber {
    my ($self) = @_;
    
    $self->{statdb_borrowernumber} = $self->{koha_borrowernumber};
    
    return $self;
}

sub get_statdb_attributes {
    my ($self) = @_;
    
    $self->{statdb_attributes} = join '|', @{$self->{koha_attributes}};
    
    return $self;
}

sub get_statdb_adherentid {
    my ($self) = @_;
    
    my $crypter = $self->{crypter};
    
    $self->{statdb_adherentid} = $crypter->crypt({ string => $self->{koha_borrowernumber}});
    
    return $self;
}

sub get_es_sexe {
    my ($self) = @_;
    
    if ( $self->{statdb_sexe_code} ) {
        if ($self->{statdb_sexe_code} eq 'F') {
            $self->{es_sexe} = 'Femme';
        } elsif ($self->{statdb_sexe_code} eq 'M') {
            $self->{es_sexe} = 'Homme';
        } elsif ($self->{statdb_sexe_code} eq 'NC') {
            $self->{es_sexe} = 'Inconnu';
        } elsif ($self->{statdb_sexe_code} eq 'M') {
            $self->{es_sexe} = 'Homme';
        } elsif ($self->{statdb_sexe_code} eq 'NP') {
            $self->{es_sexe} = 'NP';
        }
    } else {    
        my @categorycodes = qw( MEDA MEDB MEDC CSVT MEDP BIBL CSLT );
        my $categorycode;
        if ($self->{koha_categorycode} ) {
            $categorycode = $self->{koha_categorycode};
        } elsif ($self->{statdb_inscription_carte_code} ) {
            $categorycode = $self->{statdb_inscription_carte_code};
        }
    
        if ( any { /$categorycode/ } @categorycodes ) {
            if ( $self->{koha_title} ) {
                if ( $self->{koha_title} eq 'Madame' ) {
                    $self->{es_sexe} = 'Femme';
                } elsif ( $self->{koha_title} eq 'Monsieur' ) {
                    $self->{es_sexe} = 'Homme';
                } else {
                    $self->{es_sexe} = 'Inconnu';
                }
            }
        } else {
            $self->{es_sexe} = 'NP';
        }
    }
    
    return $self;
}

sub get_es_age {
    my ($self, $param) = @_;
    
    if ($self->{statdb_age}) {
        $self->{es_age} = $self->{statdb_age};
    } elsif ( $self->{koha_dateofbirth} ) {
        my $date_event = $param->{param_get_es_age}->{date_event_field};
        my $date_event_format = $param->{param_get_es_age}->{date_event_format};        
        my $kt = Kibini::Time->new({ start => { value => $self->{koha_dateofbirth}, format => 'date' }, end => { value => $date_event, format => $date_event_format }});
        $kt->get_duration({type => 'years'});
        $self->{es_age} = $kt->duration;
    }
     
    return $self;
}

sub get_es_age_labels {
    my ($self, $type) = @_;
    
    if ( $self->{statdb_age_code} ) {
        my $req = "SELECT trmeda, trmedb, trinsee FROM statdb.lib_age2 WHERE acode = ?";
        my $sth = $self->{dbh}->prepare($req);
        $sth->execute($self->{statdb_age_code});
        ($self->{es_age_lib1}, $self->{es_age_lib2}, $self->{es_age_lib3} ) = $sth->fetchrow_array;
        $sth->finish;    
    } elsif ( $self->{statdb_age} ) {
        my $req = "SELECT acode, trmeda, trmedb, trinsee FROM statdb.lib_age2 WHERE age = ?";
        my $sth = $self->{dbh}->prepare($req);
        $sth->execute($self->{statdb_age});
        ($self->{statdb_age_code}, $self->{es_age_lib1}, $self->{es_age_lib2}, $self->{es_age_lib3} ) = $sth->fetchrow_array;
        $sth->finish;    
    }
    
    return $self;
}

sub get_es_geo_ville {
    my ($self) = @_;
    
    if ($self->{koha_city}) {
        $self->{es_geo_ville} = $self->{koha_city};
    } else { 
        $self->{es_geo_ville} = $self->{statdb_geo_ville};    
    }
    
    return $self;
}

sub get_es_geo_rbx_iris {
    my ($self) = @_;
    
    if ($self->{koha_city}) {
        $self->{es_geo_rbx_iris} = $self->{koha_altcontactcountry};
    } else { 
        $self->{es_geo_rbx_iris} = $self->{statdb_iris};    
    }
    
    return $self;
}

sub get_es_geo_rbx_nom_iris {
    my ($self) = @_;
    
    ($self->{es_geo_rbx_nom_iris}, $self->{es_geo_rbx_quartier}, $self->{es_geo_rbx_secteur}) = _get_es_geo_rbx_geo($self) unless $self->{es_geo_rbx_nom_iris};
    
    return $self;
}

sub get_es_geo_rbx_quartier {
    my ($self) = @_;
    
    ($self->{es_geo_rbx_nom_iris}, $self->{es_geo_rbx_quartier}, $self->{es_geo_rbx_secteur}) = _get_es_geo_rbx_geo($self) unless $self->{es_geo_rbx_quartier};
    
    return $self;
}

sub get_es_geo_rbx_secteur {
    my ($self) = @_;
    
    ($self->{es_geo_rbx_nom_iris}, $self->{es_geo_rbx_quartier}, $self->{es_geo_rbx_secteur}) = _get_es_geo_rbx_geo($self) unless $self->{es_geo_rbx_secteur};
    
    return $self;
}

sub get_es_geo_gentilite {
    my ($self) = @_;
    
    if ($self->{es_geo_ville} eq 'ROUBAIX') {
        $self->{es_geo_gentilite} = 'Roubaisien';
    } else {
        $self->{es_geo_gentilite} = 'Non Roubaisien';
    }
     
    return $self;
}

sub get_es_geo_ville_front {
    my ($self) = @_;

    my @liste = qw( CROIX HEM LEERS LYS-LEZ-LANNOY ROUBAIX TOURCOING WATTRELOS );
    if ( grep {$_ eq $self->{es_geo_ville} } @liste ) {
        $self->{es_geo_ville_front} = $self->{es_geo_ville};
    } else {
        $self->{es_geo_ville_front} = "AUTRE";
    }

    return $self;
}

sub get_es_geo_ville_bm {
    my ($self) = @_;

    my @libok = ( 'LILLE', 'LYS-LEZ-LANNOY', 'MONS-EN-BAROEUL', 'MOUVAUX', 'ROUBAIX', 'TOURCOING', 'VILLENEUVE-D\'ASCQ', 'WASQUEHAL', 'WATTRELOS');
    my @libko = qw( CROIX HEM LEERS );
    if ( grep {$_ eq $self->{es_geo_ville}} @libok ) {
        $self->{es_geo_ville_bm} = "oui";
    } elsif ( grep {$_ eq $self->{es_geo_ville}} @libko ) {
        $self->{es_geo_ville_bm} = "non";
    } else {
        $self->{es_geo_ville_bm} = "NP";
    }

    return $self;
}

sub get_es_inscription_carte {
    my ($self) = @_;
    
    ($self->{es_inscription_carte}, $self->{es_inscription_personnalite}) = _get_es_inscription_personnalite($self) unless $self->{es_inscription_carte};
    
    return $self;
}

sub get_es_inscription_type_carte {
    my ($self) = @_;
    
    my $categorycode;
    if ($self->{koha_categorycode}) {
        $categorycode = $self->{koha_categorycode}
    } elsif ($self->{statdb_inscription_carte_code}) {
        $categorycode = $self->{statdb_inscription_carte_code}
    }

    my $type_carte ;
    if ($categorycode eq "BIBL" ) { $type_carte = "Médiathèque" ; }
    my @liste = qw( MEDA MEDB MEDC CSVT MEDP ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Médiathèque Plus" ; }
    if ($categorycode eq "CSLT" ) { $type_carte = "Consultation sur place" ; }
    @liste = qw( COLI COLD ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Prêt en nombre" ; }
    @liste = qw( ECOL CLAS COLS ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Service collectivités" ; }
    
    $self->{es_inscription_type_carte} = $type_carte;
    
    return $self;
}

sub get_es_inscription_personnalite {
    my ($self) = @_;
    
    ($self->{es_inscription_carte}, $self->{es_inscription_personnalite}) = _get_es_inscription_personnalite($self) unless $self->{es_inscription_personnalite};
    
    return $self;
}

sub get_es_inscription_site {
    my ($self) = @_;
    
    my $site;
    if ($self->{koha_branchcode}) {
        $site = $self->{koha_branchcode}
    } elsif ($self->{statdb_inscription_site_code}) {
        $site = $self->{statdb_inscription_site_code}
    }
    
    if ($site eq 'MED') {
        $self->{es_inscription_site} = 'Médiathèque';
    } elsif ($site eq 'BUS') {
        $self->{es_inscription_site} = 'Zèbre';
    } elsif ($site eq 'MUS') {
        $self->{es_inscription_site} = 'Musée André Diligent';
    }
    
    return $self;
}

sub get_es_inscription_nb_annees_adhesion {
    my ($self, $param) = @_;
    
    if ($self->{statdb_inscription_nb_annees_adhesion}) {
        $self->{es_inscription_nb_annees_adhesion} = $self->{statdb_inscription_nb_annees_adhesion};
    } elsif ($self->{koha_dateenrolled}) {
        my $date_event = $param->{param_get_es_inscription_nb_annees_adhesion}->{date_event_field};
        my $date_event_format = $param->{param_get_es_inscription_nb_annees_adhesion}->{date_event_format};        
        my $kt = Kibini::Time->new({ start => { value => $self->{koha_dateenrolled}, format => 'date' }, end => { value => $date_event, format => $date_event_format }});
        $kt->get_duration({type => 'years'});
        $self->{es_inscription_nb_annees_adhesion} = $kt->duration;
    }

    return $self;
}

sub get_es_inscription_nb_annees_adhesion_tra {
    my ($self) = @_;
    
    my $tr;
    my $count = $self->{es_inscription_nb_annees_adhesion};
    
    if ($count == 0 ) {
        $tr = "a/ 0";
    } elsif ($count == 1 ) {
        $tr = "b/ 1";
    } elsif ($count == 2 ) {
        $tr = "c/ 2";
    } elsif ($count == 3 ) {
        $tr = "d/ 3";
    } elsif ($count == 4 ) {
        $tr = "e/ 4";
    } elsif ($count > 4 && $count <= 10 ) {
        $tr = "f/ 5 - 10 ans";
    } else {
        $tr = "g/ Plus de 10 ans";
    }
    
    $self->{es_inscription_nb_annees_adhesion_tra} = $tr;
    
    return $self;
}


sub get_es_inscription_prix_gratuite {
    my ($self) = @_;
    
    my ($gratuit, $prix);
    
    my $categorycode;
    if ($self->{koha_categorycode}) {
        $categorycode = $self->{koha_categorycode}
    } elsif ($self->{statdb_inscription_carte_code}) {
        $categorycode = $self->{statdb_inscription_carte_code}
    }
    
    if ( $categorycode eq 'MEDA' ) {
        $gratuit = "payante";
        $prix = 35;
    } elsif ( $categorycode eq 'MEDB' ) {
        $gratuit = "payante";
        $prix = 17;
    } elsif ( $categorycode eq 'MEDC' ) {
        $gratuit = "payante";
        $prix = 5;
    } else {
        $gratuit = "gratuite";
        $prix = 0;
    }
    
    $self->{es_inscription_prix} = $prix;
    $self->{es_inscription_gratuite} = $gratuit;
    
    return $self;
}

sub get_es_adherentid {
    my ($self) = @_;
    
    if ($self->{statdb_adherentid}) {
        $self->{es_adherentid} = $self->{statdb_adherentid};
    } elsif ($self->{koha_borrowernumber}) {    
        my $crypter = $self->{crypter};
        $self->{statdb_adherentid} = $crypter->crypt({ string => $self->{koha_borrowernumber}});
    }
    
    return $self;
}

sub get_es_attributes {
    my ($self) = @_;
    
    my @attributes = split /\|/, $self->{statdb_attributes};
    my $es_attribute = {};
    
    foreach my $attribute (@attributes) {
        my ($lib_attribute, $code) = _get_es_attributes_lib($attribute);
        $es_attribute->{$code} = $lib_attribute;
    }
    
    $self->{es_attributes} = $es_attribute;
    
    return $self;
}

sub export_adherent_generic_data_to_statdb {
    my ($self) = @_;
    my $adherent_data = {
        statdb_userid => $self->{statdb_userid},
        statdb_borrowernumber => $self->{statdb_borrowernumber},
        statdb_age => $self->{statdb_age},
        statdb_age_code => $self->{statdb_age_code},
        statdb_sexe_code => $self->{statdb_sexe_code},
        statdb_geo_ville => $self->{statdb_geo_ville},
        statdb_geo_rbx_iris => $self->{statdb_geo_rbx_iris},
        statdb_inscription_site_code => $self->{statdb_inscription_site_code},
        statdb_inscription_carte_code => $self->{statdb_inscription_carte_code},
        statdb_inscription_nb_annees_adhesion => $self->{statdb_inscription_nb_annees_adhesion},
        statdb_adherentid => $self->{statdb_adherentid},
        statdb_attributes => $self->{statdb_attributes}
    };

    return $adherent_data;
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
        es_inscription_carte => $self->{es_inscription_carte},
        es_inscription_type_carte => $self->{es_inscription_type_carte},
        es_inscription_personnalite  => $self->{es_inscription_personnalite},
        es_inscription_site => $self->{es_inscription_site},
        es_inscription_prix => $self->{es_inscription_prix},
        es_inscription_gratuite => $self->{es_inscription_gratuite},
        es_inscription_nb_annees_adhesion => $self->{es_inscription_nb_annees_adhesion},
        es_inscription_nb_annees_adhesion_tra => $self->{es_inscription_nb_annees_adhesion_tra},
        es_adherentid => $self->{es_adherentid},
        es_attributes => $self->{es_attributes}
    };

    return $adherent_data;
}

sub _get_es_geo_rbx_geo {
    my ($self) = @_ ;
    
    my $dbh = $self->{dbh};
    my $iris;
    if ($self->{koha_altcontactcountry}) {
        $iris = $self->{koha_altcontactcountry}
    } elsif ($self->{statdb_geo_rbx_iris}) {
        $iris = $self->{statdb_geo_rbx_iris}
    }
    
    my $req = "SELECT irisNom, quartier, secteur FROM statdb.iris_lib WHERE irisInsee = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($iris);
    return $sth->fetchrow_array ;
    $sth->finish();
}

sub _get_es_inscription_personnalite {
    my ($self) = @_;
    
    my $dbh = $self->{dbh};
    my $categorycode;
    if ($self->{koha_categorycode}) {
        $categorycode = $self->{koha_categorycode}
    } elsif ($self->{statdb_inscription_carte_code}) {
        $categorycode = $self->{statdb_inscription_carte_code}
    }
    
    my $req = "SELECT description, category_type FROM statdb.lib_categories WHERE categorycode = ? ";
    my $sth = $dbh->prepare($req);
    $sth->execute($categorycode);
    my @result = $sth->fetchrow_array;
    $sth->finish();
    if ( $result[1] eq "C" ) {
        $result[1] = "Personne";
    } else {
        $result[1] = "Collectivité";
    }
    return @result;
}

sub _get_es_attributes_lib {
    my ($attribute) = @_;
    
    my %lib_attributes = (
        "AM01" => "Action éducative",
        "AM02" => "Apéro culture",
        "AM03" => "Eveil au livre",
        "AM04" => "Médiation",
        "AM05" => "Espace multimédia",
        "AM06" => "Nouveaux habitants",
        "AM07" => "Personnel Ville de Roubaix",
        "AM08" => "Personnel \"La Redoute\"",
        "AM09" => "Visite de classe",
        "B00" => "Arrêts foyers logements",
        "B01" => "Arrêt Bus Rue Louis Braille",
        "B02" => "Arrêt Bus Rue de Lannoy",
        "B03" => "Arrêt Bus Place du Travail",
        "B04" => "Arrêt Bus Rue du Danemark",
        "B05" => "Arrêt Bus Place du Progrès",
        "B06" => "Arrêt Bus Rue du Stand de tir",
        "B07" => "Arrêt Bus Place Carnot",
        "B08" => "Arrêt Bus Rue de France",
        "B09" => "Arrêt Bus Rue de Rome",
        "B10" => "Arrêt Bus Rue Léon Blum",
        "B11" => "Arrêt Bus Place la de la Nation",
        "B12" => "Arrêt Bus Rue de Philippeville",
        "B13" => "Arrêt Bus Rue de la Fraternité",
        "B14" => "Arrêt Bus Rue Jacques Prévert",
        "B15" => "Arrêt Bus Rue Jean-Baptiste Vercoutère",
        "B16" => "Arrêt Bus Avenue du Président Coty",
        "B17" => "Arrêt Bus Rue Montgolfier",
        "B18" => "Arrêt Bus Place Roussel",
        "B19" => "Arrêt Bus Boulevard de Fourmies",
        "B20" => "Arrêt Bus Rue d'Alger",
        "B21" => "Arrêt Bus Rue Léo Lagrange",
        "COL01" => "Maternelle",
        "COL02" => "Elémentaire",
        "COL03" => "Structure petite enfance",
        "COL04" => "Centre social",
        "COL05" => "Accueil spécialisé",
        "COL06" => "ALSH",
        "COL07" => "Périscolaire",
        "COL08" => "secondaire",
        "PCS01" => "Agriculteurs exploitants",
        "PCS02" => "Artisans, commerçants et chefs d'entreprise",
        "PCS03" => "Cadres et professions intellectuelles supérieures",
        "PCS04" => "Professions Intermédiaires",
        "PCS05" => "Employés",
        "PCS06" => "Ouvriers",
        "PCS07" => "Retraités",
        "PCS08" => "Lycéens",
        "PCS09" => "Etudiants",
        "PCS10" => "Autres personnes sans activité professionnelle"
    );
    
    my $lib_attribute = $lib_attributes{$attribute};
    
    my $code;
    if ( $attribute =~ m/^A/ ) {
        $code = 'action';
    } elsif ( $attribute =~ m/^B/ ) {
        $code = 'zèbre';
    } elsif ( $attribute =~ m/^C/ ) {
        $code = 'collectivités';
    } elsif ( $attribute =~ m/^P/ ) {
        $code = 'PCS';
    }
    
    my @res = ($lib_attribute, $code);
    return @res;
}

1;

__END__
