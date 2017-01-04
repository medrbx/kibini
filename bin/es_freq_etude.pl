#!/usr/bin/perl

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::MySQL ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use fonctions ;
use dbrequest ;
use esrbx ;

my $log_message ;
my $process = "es_freq_etude.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;

my $i = es_freq_etude($es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;

sub es_freq_etude {
	my ( $es_node ) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "freq_etude" ;
	my $type = "consultations" ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	datetime_entree,
	duree,
	SHA1(borrowernumber),
	sexe,
	age,
	categorycode,
	ville,
	iris
FROM statdb.stat_freq_etude
WHERE DATE(datetime_entree) = (CURDATE() - INTERVAL 1 DAY)
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute();
	my $i = 0 ; 
	while (my @row = $sth->fetchrow_array) {
		my ( $datetime_entree, $duree, $borrowernumber, $sexe, $age, $categorycode, $ville, $iris ) = @row ;

		my ( $irisNom, $quartier ) = undef ;
		if (defined $iris) {
			($irisNom, $quartier) = quartier_rbx($iris) ;
		}
	
		my ( $age_lib1, $age_lib2, $age_lib3 ) ;
		if ( defined $age ) { 
			$age_lib1 = age($age, "trmeda") ;
			$age_lib2 = age($age, "trmedb") ;
			$age_lib3 = age($age, "trinsee") ;
		}

		my ( $carte, $personnalite ) = category($categorycode) ;
		
		my $type_carte = type_carte($categorycode) ;
		
		#my ($pret_year, $pret_month, $pret_week_number, $pret_day, $pret_jour_semaine, $pret_hour) = date_form($issuedate) ;

		$duree = time_to_minutes($duree) ;
	
		my %index = (
			index   => $index,
			type    => $type,
			#id      => $id,
			body    => {
				lecteur_age => $age,
				lecteur_age_lib1 => $age_lib1,
				lecteur_age_lib2 => $age_lib2,
				lecteur_age_lib3 => $age_lib3,
				lecteur_carte => $carte,
				lecteur_id => $borrowernumber,
				lecteur_rbx_iris => $iris,
				lecteur_rbx_nom_iris => $irisNom,
				lecteur_rbx_quartier => $quartier,
				lecteur_sexe => $sexe,
				lecteur_type_carte => $type_carte,
				lecteur_ville => $ville,
				date => $datetime_entree,
				consultation_duree => $duree
			}
		) ;

		$e->index(%index) ;
		$i++ ;	
	}
	$sth->finish();
	$dbh->disconnect();
	return $i ;
}

sub time_to_minutes {
    my ($time_str) = @_;
    my ($hours, $minutes, $seconds) = split(/:/, $time_str);
    return $hours * 60 + $minutes ;
}
