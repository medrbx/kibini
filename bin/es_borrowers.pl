#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use kibini::time ;
use adherents ;
use fonctions ;

my $log_message ;
my $process = "es_borrowers.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

# On récupère la date de dernière mise à jour de statdb.stat_borrowers
my $dbh = GetDbh() ;
my $req = "SELECT MAX(date) FROM statdb.stat_borrowers" ;
my $sth = $dbh->prepare($req);
$sth->execute();
my $date = $sth->fetchrow_array ;
$sth->finish();
$dbh->disconnect();

# On recrée l'index avant d'indexer :
my $result = RegenerateIndex($es_node, "adherents") ;
my $i = borrowers($date, $es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub borrowers {
    my ( $date, $es_node ) = @_ ;    
    my %params = ( nodes => $es_node ) ;
    my $index = "adherents" ;
    my $type = "inscrits" ;

    my $e = Search::Elasticsearch->new( %params ) ;
    
    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
    s.date,
    SHA1(s.borrowernumber),
    CASE WHEN s.sexe = "M" THEN 'Homme' WHEN sexe = "F" THEN 'Femme' END AS 'sexe',
    s.age,
    s.city,
    s.zipcode,
    s.country,
    s.altcontactcountry,
    s.email,
    s.phone,
    s.mobile,
    s.branchcode,
    s.categorycode,
    s.dateenrolled,
    s.dateexpiry,
    s.fidelite,
    CASE WHEN s.emprunteur = "oui" THEN 'emprunteur' ELSE 'non_emprunteur' END AS 'emprunteur',
    CASE WHEN s.date_dernier_pret_med >= CURDATE() - INTERVAL 1 YEAR THEN 'emprunteur_med' ELSE 'non_emprunteur_med' END AS 'emprunteur_med',
    CASE WHEN s.date_dernier_pret_bus >= CURDATE() - INTERVAL 1 YEAR THEN 'emprunteur_bus' ELSE 'non_emprunteur_bus' END AS 'emprunteur_bus',
    CASE WHEN s.date_dernier_conn >= CURDATE() - INTERVAL 1 YEAR THEN 'utilisateur_webkiosk' ELSE 'non_utilisateur_webkiosk' END AS 'utilisateur_webkiosk',
    a.attribute
FROM statdb.stat_borrowers s
LEFT JOIN koha_prod.borrower_attributes a ON a.borrowernumber = s.borrowernumber
WHERE
    s.categorycode IN ('BIBL', 'MEDA', 'MEDB', 'MEDC', 'CSVT', 'CSLT', 'MEDPERS', 'CLAS', 'COLD', 'COLI', 'COLS', 'ECOL')
    AND s.dateexpiry >= ?
    AND s.date = ?
ORDER BY s.dateexpiry DESC
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($date, $date);
    my $i = 0 ;
    while (my @row = $sth->fetchrow_array) {
        my ( $date, $borrowernumber, $sexe, $age, $city, $zipcode, $country, $iris, $email, $phone, $mobile, $branchcode, $categorycode, $dateenrolled, $dateexpiry, $fidelite, $emprunteur, $emprunteur_med, $emprunteur_bus, $utilisateur_webkiosk, $attribute ) = @row ;
        
        my $ville15 = ville15($city) ;
        
        my ( $carte, $personnalite ) = category($categorycode) ;
        
        if ( $personnalite eq "C" ) {
            $personnalite = "Personne" ;
        } else {
            $personnalite = "Collectivité" ;
        }
        
        my $type_carte = type_carte($categorycode) ;
        
        my $branch = branches($branchcode) ;

        my ( $irisNom, $quartier ) = undef ;
        if (defined $iris) {
            ($irisNom, $quartier) = quartier_rbx($iris) ;
        }
    
        my ( $age_lib1, $age_lib2, $age_lib3 ) ;
        if ( $age eq "NP" ) { 
            $age = undef ;
        } else {
            $age_lib1 = age($age, "trmeda") ;
            $age_lib2 = age($age, "trmedb") ;
            $age_lib3 = age($age, "trinsee") ;
        }
    
        my $communication ;
        if (($email eq "X")||($mobile eq "X")||($phone eq "X")) {
            $communication = "ok" ;
        } else {
            $communication = "ko" ;
        }
        
        if ($email eq "X") {
            $email = "courriel_renseigné" ;
        } else {
            $email = "courriel_non_renseigné" ;
        }
        
        if ($phone eq "X") {
            $phone = "fixe_renseigné" ;
        } else {
            $phone = "fixe_non_renseigné" ;
        }

        if ($mobile eq "X") {
            $mobile = "mobile_renseigné" ;
        } else {
            $mobile = "mobile_non_renseigné" ;
        }
    
        
        if ($fidelite eq "NP") {
            $fidelite = undef ;
        }
        
        if (length $attribute) {
            $attribute = av($attribute, "ACTION") ;
        }
        
        my $id = $date.$borrowernumber ;
        
        my $nb_venues_pret = GetCountVisitsByLoans($borrowernumber) ;
        
        my %index = (
            index   => $index,
            type    => $type,
            id      => $id,
            body    => {
                date => $date,
                adherent => $borrowernumber,
                sexe => $sexe,
                ages_age => $age,
                ages_lib1 => $age_lib1,
                ages_lib2 => $age_lib2,
                ages_lib3 => $age_lib3,
                geo_ville => $city,
                geo_ville15 => $ville15,
                geo_code_postal => $zipcode,
                geo_pays => $country,
                geo_roubaix_iris => $iris,
                geo_roubaix_nom_iris => $irisNom,
                geo_roubaix_quartier => $quartier,
                communication => $communication,
                communication_courriel => $email,
                communication_telephone_fixe => $phone,
                communication_telephone_mobile => $mobile,
                inscription_personnalite => $personnalite,
                inscription_carte => $carte,
                inscription_type_carte => $type_carte,
                inscription_site_inscription => $branch,
                inscription_date_inscription => $dateenrolled,
                inscription_date_expiration => $dateexpiry,
                activite_emprunteur => $emprunteur,
                activite_emprunteur_med => $emprunteur_med,
                activite_emprunteur_bus => $emprunteur_bus,
                activite_utilisateur_webkiosk => $utilisateur_webkiosk,
                action => $attribute,
                nb_venues_pret => $nb_venues_pret
            }
        ) ;

        $e->index(%index) ;
        
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}