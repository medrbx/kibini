#!/usr/bin/perl

use Modern::Perl;
use utf8;
use Search::Elasticsearch;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;
use adherents;
use collections::poldoc;

my $log_message;
my $process = "es_adherents.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

# On récupère la date de dernière mise à jour de statdb.stat_borrowers
my $dbh = GetDbh();
my $req = "SELECT MAX(date_extraction) FROM statdb.stat_adherents";
my $sth = $dbh->prepare($req);
$sth->execute();
my $date = $sth->fetchrow_array;
$sth->finish();
$dbh->disconnect();

# On recrée l'index avant d'indexer :
#my $result = RegenerateIndex($es_node, "adherents2");
my $i = adherents($date, $es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);


sub adherents {
    my ( $date, $es_node ) = @_;    
    my %params = ( nodes => $es_node );
    my $index = "adherents2";
    my $type = "adherents";

    my $e = Search::Elasticsearch->new( %params );
    
    my $dbh = GetDbh();
    my $req = "SELECT * FROM statdb.stat_adherents WHERE date_extraction = ?";

    my $sth = $dbh->prepare($req);
    $sth->execute($date);
    my $i = 0;
    while (my $adherent = $sth->fetchrow_hashref) {
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
            ($adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}, $adherent->{geo_roubaix_secteur} ) = GetRbxDistrict($dbh, $adherent->{geo_roubaix_iris});
        }
		
		$adherent->{geo_ville_bm} = GetCityLibrary( $adherent->{geo_ville} );
        
        # inscription
        ( $adherent->{inscription_carte}, $adherent->{personnalite} ) = GetCategoryDesc( $dbh, $adherent->{inscription_code_carte} );
        $adherent->{type_carte} = GetCardType($adherent->{inscription_code_carte});
        if ( $adherent->{inscription_code_site} eq 'MED' ) {
            $adherent->{inscription_site_inscription} = "Médiathèque";
        } elsif ( $adherent->{inscription_code_site} eq 'BUS' ) { 
            $adherent->{inscription_site_inscription} = "Zèbre";
        }
        $adherent->{inscription_fidelite_tr} = GetTrFidelite($adherent->{inscription_fidelite});
		if ( $adherent->{inscription_attribut} ) {
			$adherent->{inscription_attribut_lib} = getEsAttribute($adherent->{inscription_attribut});
		} else {
			$adherent->{inscription_attribut_lib}->{action} = ["aucune action"];
		}
        
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
        
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                date_extraction => $adherent->{date_extraction},
                sexe => $adherent->{sexe},
                #ages_age => $adherent->{age},
                ages_lib1 => $adherent->{age_lib1},
                ages_lib2 => $adherent->{age_lib2},
                ages_lib3 => $adherent->{age_lib3},
                geo_ville => $adherent->{geo_ville},
                geo_ville_front => $adherent->{geo_ville_front},
                geo_roubaix_iris => $adherent->{geo_roubaix_iris},
                geo_roubaix_nom_iris => $adherent->{geo_roubaix_nom_iris},
                geo_roubaix_quartier => $adherent->{geo_roubaix_quartier},
		geo_roubaix_secteur => $adherent->{geo_roubaix_secteur},
		geo_ville_bm => $adherent->{geo_ville_bm},
                geo_gentile => $adherent->{gentile},
                inscription_personnalite => $adherent->{personnalite},
                inscription_carte => $adherent->{inscription_carte},
                inscription_type_carte => $adherent->{type_carte},
                inscription_site_inscription => $adherent->{inscription_site_inscription},
                inscription_gratuite => $adherent->{inscription_gratuite},
                inscription_prix => $adherent->{inscription_prix},
                inscription_fidelite => $adherent->{inscription_fidelite},
                inscription_fidelite_tr => $adherent->{inscription_fidelite_tr},
                activite_emprunteur => $adherent->{activite_emprunteur},
                activite_emprunteur_med => $adherent->{activite_emprunteur_med},
                activite_emprunteur_bus => $adherent->{activite_emprunteur_bus},
                activite_utilisateur_postes_informatiques => $adherent->{activite_utilisateur_postes_informatiques},
                activite_utilisateur_wifi => $adherent->{activite_utilisateur_wifi},
                activite_salle_etude => $adherent->{activite_utilisateur_salle_etude},
                activite => $adherent->{type_use},
                inscription_attribut => $adherent->{inscription_attribut_lib},
                nb_venues => $adherent->{nb_venues},
                nb_venues_tr => $adherent->{nb_venues_tr},
                nb_venues_prets => $adherent->{nb_venues_prets},
                nb_venues_prets_tr => $adherent->{nb_venues_prets_tr},
                nb_venues_prets_mediatheque => $adherent->{nb_venues_prets_mediatheque},
                nb_venues_prets_mediatheque_tr => $adherent->{nb_venues_prets_mediatheque_tr},
                nb_venues_prets_bus => $adherent->{nb_venues_prets_bus},
                nb_venues_prets_bus_tr => $adherent->{nb_venues_prets_bus_tr},
                nb_venues_postes_informatiques => $adherent->{nb_venues_postes_informatiques},
                nb_venues_postes_informatiques_tr => $adherent->{nb_venues_postes_informatiques_tr},
                nb_venues_wifi => $adherent->{nb_venues_wifi},
                nb_venues_wifi_tr => $adherent->{nb_venues_wifi_tr},
                nb_venues_salle_etude => $adherent->{nb_venues_salle_etude},
                nb_venues_salle_etude_tr => $adherent->{nb_venues_salle_etude_tr}
            }
        );
        
        $e->index(\%index);
        #print Dumper($adherent->{inscription_attribut_lib});
        $i++;
        print "$i\n";
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}
