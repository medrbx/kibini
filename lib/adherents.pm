package adherents;

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( 
    getSex
	getBorrowerAttributes
	getUses
	insertAdherentIntoStatdb_adherent
	getBorrowerDataByBorrowernumber
	getBorrowerDataByUserid
	GetBorrowersForQA
	GetAgeLib	
    GetCityFront	
    GetCategoryDesc	
    GetRbxDistrict	
    GetCardType	
    GetTrFidelite	
    GetTrVenue	
    getTypeUse	
    getEsAttribute	
    getPrixAdhesion
);

use Modern::Perl;
use List::MoreUtils qw(any uniq);

use LWP::UserAgent;
use Encode qw(encode);
use JSON;
use kibini::db;
use utf8;

sub getBorrowerDataByBorrowernumber {
    my ($borrowernumber) = @_;
    
    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    CURDATE() AS date_extraction,
    b.borrowernumber AS adherent_id,
    b.title,
    YEAR(CURDATE()) - YEAR(b.dateofbirth) AS age,
    b.city AS geo_ville,
    b.altcontactcountry AS geo_roubaix_iris,
    b.branchcode AS inscription_code_site,
    b.categorycode AS inscription_code_carte,
    YEAR(CURDATE()) - YEAR(b.dateenrolled) AS inscription_fidelite
FROM koha_prod.borrowers b
WHERE b.borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
    my $adherent = $sth->fetchrow_hashref;
    
    $adherent->{sexe} = getSex($adherent->{title}, $adherent->{inscription_code_carte});
    $adherent->{attributes} = getBorrowerAttributes($dbh, $adherent->{adherent_id});
    $adherent->{nb_venues} = getUses($dbh, $adherent);
    
    # sexe
        if ($adherent->{sexe} eq 'F' ) {
            $adherent->{sexe} = 'Femme';
        } elsif ($adherent->{sexe} eq 'M' ) {
            $adherent->{sexe} = 'Homme';
        }
        
        #age
        $adherent->{age_lib1} = GetAgeLib($dbh, $adherent->{age}, "trmeda");
        $adherent->{age_lib2} = GetAgeLib($dbh, $adherent->{age}, "trmedb");
        $adherent->{age_lib3} = GetAgeLib($dbh, $adherent->{age}, "trinsee");
        
        
        # geo
        if ($adherent->{geo_ville} eq 'ROUBAIX') {
            $adherent->{gentile} = 'Roubaisien';
        } else {
            $adherent->{gentile} = 'Non Roubaisien';
        }
        $adherent->{geo_ville_front} = GetCityFront( $adherent->{geo_ville} );
        if (defined $adherent->{geo_roubaix_iris}) {
            ($adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}, $adherent->{geo_roubaix_secteur}) = GetRbxDistrict($dbh, $adherent->{geo_roubaix_iris});
        }
        
        # inscription
        ( $adherent->{inscription_carte}, $adherent->{personnalite} ) = GetCategoryDesc( $dbh, $adherent->{inscription_code_carte} );
        $adherent->{type_carte} = GetCardType($adherent->{inscription_code_carte});
        if ( $adherent->{inscription_code_site} eq 'MED' ) {
            $adherent->{inscription_site_inscription} = "Médiathèque";
        } elsif ( $adherent->{inscription_code_site} eq 'BUS' ) { 
            $adherent->{inscription_site_inscription} = "Zèbre";
        }
        $adherent->{inscription_fidelite_tr} = GetTrFidelite($adherent->{inscription_fidelite});
        $adherent->{inscription_attribut_lib} = getEsAttribute($adherent->{inscription_attribut}) if ( $adherent->{inscription_attribut} );

        $adherent->{nb_venues_prets_mediatheque} = $adherent->{nb_venues}->{prets_mediatheque};
        $adherent->{nb_venues_prets_bus} = $adherent->{nb_venues}->{prets_bus};
        $adherent->{nb_venues_postes_informatiques} = $adherent->{nb_venues}->{postes_informatiques};
        $adherent->{nb_venues_wifi} = $adherent->{nb_venues}->{wifi};
        $adherent->{nb_venues_salle_etude} = $adherent->{nb_venues}->{salle_etude};
        $adherent->{nb_venues} = $adherent->{nb_venues}->{toutes_pratiques};
            
        # venues
        $adherent->{nb_venues_tr} = GetTrVenue($adherent->{nb_venues});
        $adherent->{nb_venues_prets_mediatheque_tr} = GetTrVenue($adherent->{nb_venues_prets_mediatheque});
        $adherent->{nb_venues_prets_bus_tr} = GetTrVenue($adherent->{nb_venues_prets_bus});
        $adherent->{nb_venues_prets} = $adherent->{nb_venues_prets_mediatheque} + $adherent->{nb_venues_prets_bus};
        $adherent->{nb_venues_prets_tr} = GetTrVenue($adherent->{nb_venues_prets});
        $adherent->{nb_venues_postes_informatiques_tr} = GetTrVenue($adherent->{nb_venues_postes_informatiques});
        $adherent->{nb_venues_wifi_tr} = GetTrVenue($adherent->{nb_venues_wifi});
        $adherent->{nb_venues_salle_etude_tr} = GetTrVenue($adherent->{nb_venues_salle_etude});
        
        # activité
        if ( $adherent->{nb_venues_prets_mediatheque} > 0 || $adherent->{nb_venues_prets_bus} > 0 ) {
            $adherent->{activite_emprunteur} = "Emprunteur";
        } else {
            $adherent->{activite_emprunteur} = "Non emprunteur";
        }
        if ( $adherent->{nb_venues_prets_mediatheque} > 0 ) {
            $adherent->{activite_emprunteur_med} = "Emprunteur Médiathèque";
        } else {
            $adherent->{activite_emprunteur_med} = "Non emprunteur Médiathèque";
        }
        if ( $adherent->{nb_venues_prets_bus} > 0 ) {
            $adherent->{activite_emprunteur_bus} = "Emprunteur Zèbre";
        } else {
            $adherent->{activite_emprunteur_bus} = "Non emprunteur Zèbre";
        }
        if ( $adherent->{nb_venues_postes_informatiques} > 0 ) {
            $adherent->{activite_utilisateur_postes_informatiques} = "Utilisateur postes informatiques";
        } else {
            $adherent->{activite_utilisateur_postes_informatiques} = "Non utilisateur postes informatiques";
        }
        if ( $adherent->{nb_venues_wifi} > 0 ) {
            $adherent->{activite_utilisateur_wifi} = "Utilisateur Wifi";
        } else {
            $adherent->{activite_utilisateur_wifi} = "Non utilisateur Wifi";
        }
        if ( $adherent->{nb_venues_salle_etude} > 0 ) {
            $adherent->{activite_utilisateur_salle_etude} = "Utilisateur Salle d'étude";
        } else {
            $adherent->{activite_utilisateur_salle_etude} = "Non utilisateur Salle d'étude";
        }
        
        $adherent->{type_use} = getTypeUse($adherent);
        
        # prix inscription
        ($adherent->{inscription_gratuite}, $adherent->{inscription_prix}) = getPrixAdhesion($adherent->{inscription_code_carte});
    
    
    return $adherent;
}

sub getBorrowerDataByUserid {
    my ($userid) = @_;
    
    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    CURDATE() AS date_extraction,
    b.borrowernumber AS adherent_id,
    b.title,
    YEAR(CURDATE()) - YEAR(b.dateofbirth) AS age,
    b.city AS geo_ville,
    b.altcontactcountry AS geo_roubaix_iris,
    b.branchcode AS inscription_code_site,
    b.categorycode AS inscription_code_carte,
    YEAR(CURDATE()) - YEAR(b.dateenrolled) AS inscription_fidelite
FROM koha_prod.borrowers b
WHERE b.userid = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($userid);
    my $adherent = $sth->fetchrow_hashref;
    
    $adherent->{sexe} = getSex($adherent->{title}, $adherent->{inscription_code_carte});
    $adherent->{attributes} = getBorrowerAttributes($dbh, $adherent->{adherent_id});
    $adherent->{nb_venues} = getUses($dbh, $adherent);
    
    # sexe
        if ($adherent->{sexe} eq 'F' ) {
            $adherent->{sexe} = 'Femme';
        } elsif ($adherent->{sexe} eq 'M' ) {
            $adherent->{sexe} = 'Homme';
        }
        
        #age
        $adherent->{age_lib1} = GetAgeLib($dbh, $adherent->{age}, "trmeda");
        $adherent->{age_lib2} = GetAgeLib($dbh, $adherent->{age}, "trmedb");
        $adherent->{age_lib3} = GetAgeLib($dbh, $adherent->{age}, "trinsee");
        
        
        # geo
        if ($adherent->{geo_ville} eq 'ROUBAIX') {
            $adherent->{gentile} = 'Roubaisien';
        } else {
            $adherent->{gentile} = 'Non Roubaisien';
        }
        $adherent->{geo_ville_front} = GetCityFront( $adherent->{geo_ville} );
        if (defined $adherent->{geo_roubaix_iris}) {
            ($adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}, $adherent->{geo_roubaix_secteur}) = GetRbxDistrict($dbh, $adherent->{geo_roubaix_iris});
        }
        
        # inscription
        ( $adherent->{inscription_carte}, $adherent->{personnalite} ) = GetCategoryDesc( $dbh, $adherent->{inscription_code_carte} );
        $adherent->{type_carte} = GetCardType($adherent->{inscription_code_carte});
        if ( $adherent->{inscription_code_site} eq 'MED' ) {
            $adherent->{inscription_site_inscription} = "Médiathèque";
        } elsif ( $adherent->{inscription_code_site} eq 'BUS' ) { 
            $adherent->{inscription_site_inscription} = "Zèbre";
        }
        $adherent->{inscription_fidelite_tr} = GetTrFidelite($adherent->{inscription_fidelite});
        $adherent->{inscription_attribut_lib} = getEsAttribute($adherent->{inscription_attribut}) if ( $adherent->{inscription_attribut} );

        $adherent->{nb_venues_prets_mediatheque} = $adherent->{nb_venues}->{prets_mediatheque};
        $adherent->{nb_venues_prets_bus} = $adherent->{nb_venues}->{prets_bus};
        $adherent->{nb_venues_postes_informatiques} = $adherent->{nb_venues}->{postes_informatiques};
        $adherent->{nb_venues_wifi} = $adherent->{nb_venues}->{wifi};
        $adherent->{nb_venues_salle_etude} = $adherent->{nb_venues}->{salle_etude};
        $adherent->{nb_venues} = $adherent->{nb_venues}->{toutes_pratiques};
            
        # venues
        $adherent->{nb_venues_tr} = GetTrVenue($adherent->{nb_venues});
        $adherent->{nb_venues_prets_mediatheque_tr} = GetTrVenue($adherent->{nb_venues_prets_mediatheque});
        $adherent->{nb_venues_prets_bus_tr} = GetTrVenue($adherent->{nb_venues_prets_bus});
        $adherent->{nb_venues_prets} = $adherent->{nb_venues_prets_mediatheque} + $adherent->{nb_venues_prets_bus};
        $adherent->{nb_venues_prets_tr} = GetTrVenue($adherent->{nb_venues_prets});
        $adherent->{nb_venues_postes_informatiques_tr} = GetTrVenue($adherent->{nb_venues_postes_informatiques});
        $adherent->{nb_venues_wifi_tr} = GetTrVenue($adherent->{nb_venues_wifi});
        $adherent->{nb_venues_salle_etude_tr} = GetTrVenue($adherent->{nb_venues_salle_etude});
        
        # activité
        if ( $adherent->{nb_venues_prets_mediatheque} > 0 || $adherent->{nb_venues_prets_bus} > 0 ) {
            $adherent->{activite_emprunteur} = "Emprunteur";
        } else {
            $adherent->{activite_emprunteur} = "Non emprunteur";
        }
        if ( $adherent->{nb_venues_prets_mediatheque} > 0 ) {
            $adherent->{activite_emprunteur_med} = "Emprunteur Médiathèque";
        } else {
            $adherent->{activite_emprunteur_med} = "Non emprunteur Médiathèque";
        }
        if ( $adherent->{nb_venues_prets_bus} > 0 ) {
            $adherent->{activite_emprunteur_bus} = "Emprunteur Zèbre";
        } else {
            $adherent->{activite_emprunteur_bus} = "Non emprunteur Zèbre";
        }
        if ( $adherent->{nb_venues_postes_informatiques} > 0 ) {
            $adherent->{activite_utilisateur_postes_informatiques} = "Utilisateur postes informatiques";
        } else {
            $adherent->{activite_utilisateur_postes_informatiques} = "Non utilisateur postes informatiques";
        }
        if ( $adherent->{nb_venues_wifi} > 0 ) {
            $adherent->{activite_utilisateur_wifi} = "Utilisateur Wifi";
        } else {
            $adherent->{activite_utilisateur_wifi} = "Non utilisateur Wifi";
        }
        if ( $adherent->{nb_venues_salle_etude} > 0 ) {
            $adherent->{activite_utilisateur_salle_etude} = "Utilisateur Salle d'étude";
        } else {
            $adherent->{activite_utilisateur_salle_etude} = "Non utilisateur Salle d'étude";
        }
        
        $adherent->{type_use} = getTypeUse($adherent);
        
        # prix inscription
        ($adherent->{inscription_gratuite}, $adherent->{inscription_prix}) = getPrixAdhesion($adherent->{inscription_code_carte});
    
    
    return $adherent;
}

sub getSex {
    my ($titre, $categorycode) = @_;
    my $sex;
    my @codes = qw( MEDA MEDB MEDC CSVT MEDP BIBL CSLT );
    if ( any { /$categorycode/ } @codes ) {
        if ( $titre eq 'Madame' ) {
            $sex = 'F';
        } elsif ( $titre eq 'Monsieur' ) {
            $sex = 'M';
        } else {
            $sex = 'NC';
        }
    } else {
        $sex = 'NP';
    }
    return $sex;
}

sub getBorrowerAttributes {
    my ($dbh, $borrowernumber) = @_;

    my @attributes;
    my $req = "SELECT code, attribute FROM koha_prod.borrower_attributes WHERE borrowernumber = ?";
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
    while (my $att = $sth->fetchrow_array) {
        push @attributes, $att;
    }
    $sth->finish();
    my $attributes = join '|', @attributes;
    return $attributes;
}

sub getUses {
    my ($dbh, $adherent) = @_;
    my $venues;
    
    my @dates_issues_med = _getDateIssues($dbh, $adherent->{adherent_id}, 'MED', $adherent->{date_extraction});
    my @dates_issues_bus = _getDateIssues($dbh, $adherent->{adherent_id}, 'BUS', $adherent->{date_extraction});
    my @dates_conn_wk = _getDateWebkioskConn($dbh, $adherent->{adherent_id}, $adherent->{date_extraction});
    my @dates_conn_wifi = _getDateWifiConn($dbh, $adherent->{adherent_id}, $adherent->{date_extraction});
    my @dates_freq_salle_etude = _getDateFreqSalleEtude($dbh, $adherent->{adherent_id}, $adherent->{date_extraction});
    
    $venues->{prets_mediatheque} = scalar(@dates_issues_med);
    $venues->{prets_bus} = scalar(@dates_issues_bus);
    $venues->{postes_informatiques} = scalar(@dates_conn_wk);
    $venues->{wifi} = scalar(@dates_conn_wifi);
    $venues->{salle_etude} = scalar(@dates_freq_salle_etude);
    
    my @dates = (@dates_issues_med, @dates_issues_bus, @dates_conn_wk, @dates_conn_wifi, @dates_freq_salle_etude);
    @dates = uniq (@dates);
    $venues->{toutes_pratiques} = scalar(@dates);
    
    return $venues;
}

sub _getDateIssues {
    my ($dbh, $borrowernumber, $branch, $date) = @_;
    my @dates;
    
    my $req = "SELECT DISTINCT(DATE(issuedate)) FROM statdb.stat_issues WHERE borrowernumber = ? AND branch = ? AND DATE(issuedate) < ? AND DATE(issuedate) >= ? - INTERVAL 1 YEAR";
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $branch, $date, $date);
    while (my $date = $sth->fetchrow_array) {
        push @dates, $date;
    }
    $sth->finish();

    return @dates;
}

sub _getDateWebkioskConn {
    my ($dbh, $borrowernumber, $date) = @_;
    my @dates;
    
    my $req = "SELECT DISTINCT(DATE(heure_deb)) FROM statdb.stat_webkiosk WHERE borrowernumber = ? AND DATE(heure_deb) < ? AND DATE(heure_deb) >= ? - INTERVAL 1 YEAR";
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date, $date);
    while (my $date = $sth->fetchrow_array) {
        push @dates, $date;
    }
    $sth->finish();

    return @dates;
}

sub _getDateWifiConn {
    my ($dbh, $borrowernumber, $date) = @_;
    my @dates;
    
    my $req = "SELECT DISTINCT(DATE(start_wifi)) FROM statdb.stat_wifi WHERE borrowernumber = ? AND DATE(start_wifi) < ? AND DATE(start_wifi) >= ? - INTERVAL 1 YEAR";
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date, $date);
    while (my $date = $sth->fetchrow_array) {
        push @dates, $date;
    }
    $sth->finish();

    return @dates;
}

sub _getDateFreqSalleEtude {
    my ($dbh, $borrowernumber, $date) = @_;
    my @dates;
    
    my $req = "SELECT DISTINCT(DATE(datetime_entree)) FROM statdb.stat_freq_etude WHERE borrowernumber = ? AND DATE(datetime_entree) < ? AND DATE(datetime_entree) >= ? - INTERVAL 1 YEAR";
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date, $date);
    while (my $date = $sth->fetchrow_array) {
        push @dates, $date;
    }
    $sth->finish();

    return @dates;
}

sub insertAdherentIntoStatdb_adherent {
    my ($dbh, $adherent) = @_;
    my $req = "INSERT INTO statdb.stat_adherents VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )";
    my $sth = $dbh->prepare($req);
    $sth->execute(
        $adherent->{date_extraction},
        $adherent->{age},
        $adherent->{geo_ville},
        $adherent->{geo_roubaix_iris},
        $adherent->{sexe},
        $adherent->{inscription_code_carte},
        $adherent->{inscription_code_site},
        $adherent->{attributes},
        $adherent->{inscription_fidelite},
        $adherent->{nb_venues}->{prets_mediatheque},
        $adherent->{nb_venues}->{prets_bus},
        $adherent->{nb_venues}->{postes_informatiques},
        $adherent->{nb_venues}->{wifi},
        $adherent->{nb_venues}->{salle_etude},
        $adherent->{nb_venues}->{toutes_pratiques}
    );
    $sth->finish();
}

sub GetBorrowersForQA {
    # On récupère par webservice tous les adhérents répondant aux conditions fixées dans la requête
    my $ws = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report?id=166";
    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new( GET => $ws );
    my $rep = $ua->request($request)->{'_content'};
    my $borrowers = decode_json($rep);

    # On ne garde que ceux présentant un "PB" et on les pousse dans la variable @ko
    my @ko;
    foreach my $borrower (@$borrowers) {
        my @b = @$borrower;
        my $ko = 0;
        for (my $i = 3; $i <= 10; $i++) {
            if ( $b[$i] eq 'PB' ) {
                $ko = 1;
                last;
            } 
        }
        if ($ko == 1) {
            push @ko, $borrower;
        }
    }
    return \@ko;
}

sub GetAgeLib {
    my ($dbh, $age, $lib) = @_ ;
    my $req = "SELECT libelle FROM statdb.lib_age WHERE age = ? AND type = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($age, $lib);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCityFront {
    my ( $city ) = @_;
    my $ville6;
    my @liste = qw( CROIX HEM LEERS LYS-LEZ-LANNOY ROUBAIX TOURCOING WATTRELOS );
    if ( grep {$_ eq $city} @liste ) {
        $ville6 = $city;
    } else {
        $ville6 = "AUTRE";
    }
    return $ville6;
}

sub GetCategoryDesc {
    my ($dbh, $categorycode) = @_;
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

sub GetRbxDistrict {
    my ($dbh, $iris) = @_ ;
    my $req = "SELECT irisNom, quartier, secteur FROM statdb.iris_lib WHERE irisInsee = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($iris);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCardType {
    my ( $categorycode ) = @_ ;
    my $type_carte ;
    if ($categorycode eq "BIBL" ) { $type_carte = "Médiathèque" ; }
    my @liste = qw( MEDA MEDB MEDC CSVT MEDP ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Médiathèque Plus" ; }
    if ($categorycode eq "CSLT" ) { $type_carte = "Consultation sur place" ; }
    @liste = qw( COLI COLD ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Prêt en nombre" ; }
    @liste = qw( ECOL CLAS COLS ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Service collectivités" ; }
    return $type_carte ;
}

sub GetTrFidelite {
    my ($count) = @_;
    my $tr;
    
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
        $tr = "g/ 10 ans et plus";
    } 
    
    return $tr;
}

sub GetTrVenue {
    my ($count) = @_;
    my $tr;
    
    if ($count == 0 ) {
        $tr = "a/ Jamais";
    } elsif ($count == 1 ) {
        $tr = "b/ 1 fois par an";
    } elsif ($count > 1 && $count <= 4 ) {
        $tr = "c/ entre 2 et 4 fois par an";
    } elsif ($count > 4 && $count <= 9 ) {
        $tr = "d/ entre 5 et 9 fois par an";
    } elsif ($count > 9 && $count <= 20 ) {
        $tr = "e/ entre 10 et 20 fois par an";
    } elsif ($count > 20 && $count <= 50 ) {
        $tr = "f/entre 21 et 50 fois par an";
    } else {
        $tr = "g/ plus de 50 fois par an";
    } 
    
    return $tr;
}

sub getTypeUse {
    my ($adherent) = @_;
        
    my @use;
    if ( $adherent->{activite_emprunteur} eq 'Emprunteur' ) {
        push @use, 'prêt';
    }
        
    if ( $adherent->{activite_utilisateur_salle_etude} eq "Utilisateur Salle d'étude" ) {
        push @use, 'étude';
    }
        
    if ( $adherent->{activite_utilisateur_postes_informatiques} eq "Utilisateur postes informatiques" ) {
        push @use, 'postes';
    }
        
    if ( $adherent->{activite_utilisateur_wifi} eq "Utilisateur Wifi" ) {
        push @use, 'wifi';
    }
        
    if ( scalar(@use) == 0 ) {
        push @use, 'aucune trace';
    }

    my $type_use = join( " + ", @use);
    return $type_use;
}

sub getEsAttribute {
    my ($inscription_attribut) = @_;
    
    my @attributes = split /\|/, $inscription_attribut;
    my $es_attribute = {};
    
    foreach my $attribute (@attributes) {
        my ($lib_attribute, $code) = _getEsAttributeLib($attribute);
        $es_attribute->{$code} = [];
        push $es_attribute->{$code}, $lib_attribute;
    }
    
    return $es_attribute;
}

sub _getEsAttributeLib {
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

sub getPrixAdhesion {
	my ($categorycode) = @_;
	my ($gratuit, $prix);
	
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
	
	my @results = ($gratuit, $prix);
}

1;