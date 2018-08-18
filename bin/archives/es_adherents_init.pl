#!/usr/bin/perl

use strict;
#use warnings;
use utf8;
use Search::Elasticsearch;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;
use adherents::es;
use collections::poldoc;

my $es_node = GetEsNode();

# On recrée l'index avant d'indexer :
#my $result = RegenerateIndex($es_node, "adherents2");

my @dates = qw (2018-02-27  2018-01-30   2017-12-26 2017-11-28	2017-10-31	2017-09-26	2017-08-29	2017-07-25	2017-06-27	2017-05-30	2017-04-25	2017-03-28	2017-02-28	2017-01-31	2016-12-27	2016-11-29	2016-10-25	2016-09-27	2016-08-30	2016-07-26	2016-06-28	2016-05-31	2016-04-26	2016-03-29	2016-02-23	2016-01-26	2015-12-29	2015-11-24	2015-10-27	2015-09-29	2015-08-11	2015-07-28);
foreach my $date (@dates) {
	adherents($date, $es_node);
#	print "$date\n";
}



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
            ($adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}) = GetRbxDistrict($dbh, $adherent->{geo_roubaix_iris});
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
        #print Dumper(\%index);
        print "$date : $i\n";
        $i++;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}
