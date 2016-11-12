#!/usr/bin/perl

use strict ;
#use warnings ;
use utf8 ;
use DBI ;
use DateTime ;
use DateTime::Format::MySQL ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile) ;

use lib "$Bin/modules/" ;
use fonctions ;
use dbrequest ;
use esrbx ;

# On log le début de l'opération
my $dt = datetime() ;
print "[$dt] : es_borrowers.pl : début\n" ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;

# On récupère la date de dernière mise à jour de statdb.stat_borrowers
my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;
my $req = "SELECT MAX(date) FROM statdb.stat_borrowers" ;
my $sth = $dbh->prepare($req);
$sth->execute();
my $date = $sth->fetchrow_array ;
$sth->finish();
$dbh->disconnect();

reg_index() ;
borrowers($date, $es_node) ;

sub reg_index {
	my %params = ( nodes => $es_node ) ;
	my $index = "adherents" ;
	my $type = "inscrits" ;
	my %adherents = (
        index => 'adherents',
		body => {
			mappings => {
				"inscrits" => {
					properties => {
						"action" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"activite_emprunteur" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"activite_emprunteur_bus" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"activite_emprunteur_med" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"activite_utilisateur_webkiosk" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"adherent" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"ages_age" => {
							"type" => "integer"
						},
						"ages_lib1" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"ages_lib2" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"ages_lib3" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"borrowernumber" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"communication" => {
							"type" => "string",
							"index" => "not_analyzed"
						},						
						"communication_courriel" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"communication_telephone_fixe" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"communication_telephone_mobile" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"date" => {
							"type" => "date",
							"format" => "strict_date_optional_time||epoch_millis"
						},
						"geo_code_postal" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_pays" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_roubaix_iris" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_roubaix_nom_iris" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_roubaix_quartier" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_ville" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"geo_ville15" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"inscription_carte" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"inscription_date_expiration" => {
							"type" => "date",
							"format" => "yyyy-MM-dd"
						},
						"inscription_date_inscription" => {
							"type" => "date",
							"format" => "yyyy-MM-dd"
						},
						"inscription_fidelite" => {
							"type" => "integer"
						},
						"inscription_personnalite" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"inscription_site_inscription" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"inscription_type_carte" => {
							"type" => "string",
							"index" => "not_analyzed"
						},
						"sexe" => {
							"type" => "string",
							"index" => "not_analyzed"
						}
					}
				}
			}
		}
	) ;

	my $e = Search::Elasticsearch->new( %params ) ;
	$e->indices->delete(index => "adherents");
	$e->indices->create(%adherents);
}

sub borrowers {
	my ( $date, $es_node ) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "adherents" ;
	my $type = "inscrits" ;

	my $e = Search::Elasticsearch->new( %params ) ;
	
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
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
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($date, $date);
	while (my @row = $sth->fetchrow_array) {
		my ( $date, $borrowernumber, $sexe, $age, $city, $zipcode, $country, $iris, $email, $phone, $mobile, $branchcode, $categorycode, $dateenrolled, $dateexpiry, $fidelite, $emprunteur, $emprunteur_med, $emprunteur_bus, $utilisateur_webkiosk, $attribute ) = @row ;
		
		my $ville15 = ville15($city) ;
		
		my ( $carte, $personnalite ) = category($categorycode) ;
		
		if ( $personnalite eq "C" )	{
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
				action => $attribute
			}
		) ;

		$e->index(%index) ;
		
		print "$date, $borrowernumber\n" ;
	}
	$sth->finish();
	$dbh->disconnect();
}

# On log la fin de l'opération
my $dt = datetime() ;
print "[$dt] : es_borrowers.pl : fin\n" ;