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

# On indexe :
borrowers_synth($date) ;

sub borrowers_synth {
	my ( $date ) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "adherents_synth" ;
	my $type = "inscrits" ;

	my $e = Search::Elasticsearch->new( %params ) ;
	
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	CASE WHEN b.zipcode = '59100' THEN 'Roubaisiens' ELSE 'Non Roubaisiens' END,
    b.categorycode,
    b.age,
    b.emprunteur,
    COUNT(b.borrowernumber)
FROM stat_borrowers b
WHERE b.date = ? AND b.dateexpiry >= ?
GROUP BY CASE WHEN b.zipcode = '59100' THEN 'Roubaisiens' ELSE 'Non Roubaisiens' END, b.categorycode, b.age, b.emprunteur
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($date, $date);
	while (my @row = $sth->fetchrow_array) {
		my ( $roubaix, $categorycode, $age, $activite_emprunteur, $nb ) = @row ;
		
		my ( $carte, $personnalite ) = category($categorycode) ;
		
		my ( $age_lib1, $age_lib2, $age_lib3 ) ;
		if ( $age eq "NP" ) { 
			$age = undef ;
		} else {
			$age_lib1 = age($age, "trmeda") ;
			$age_lib2 = age($age, "trmedb") ;
			$age_lib3 = age($age, "trinsee") ;
		}
		
		my %index = (
			index   => $index,
			type    => $type,
			body    => {
				date => $date,
				ages_age => $age,
				ages_lib1 => $age_lib1,
				ages_lib2 => $age_lib2,
				ages_lib3 => $age_lib3,
				geo_ville => $roubaix,
				activite_emprunteur => $activite_emprunteur,
				inscription_carte => $carte,
				personnalite => $personnalite,
				nb_inscrits => $nb
			}
		) ;
		
		print "$date, $age, $age_lib1, $roubaix, $activite_emprunteur\n" ;
		$e->index(%index) ;
		
		}
	$sth->finish();
	$dbh->disconnect();
}
