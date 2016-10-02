#!/usr/bin/perl

#use strict ;
#use warnings ;
use utf8 ;
use DBI ;
use DateTime ;
use DateTime::Format::MySQL ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin );
use YAML qw(LoadFile) ;

use lib "$Bin/modules/" ;
use fonctions ;
use dbrequest ;

# On récupère l'adresse d'Elasticsearch
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $es_node = $conf->{elasticsearch}->{node} ;

my $es_maxdatetime = es_maxdatetime("webkiosk", "sessions", "session_heure_deb") ;
print "webkiosk : $es_maxdatetime\n" ;
webkiosk($es_maxdatetime, $es_node) ;

	

sub webkiosk {
	my ( $date, $es_node ) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "webkiosk" ;
	my $type = "sessions" ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	w.heure_deb,
	w.heure_fin,
	w.espace,
	w.poste,
	SHA1(w.id),
	w.age,
	w.sexe,
	w.ville,
	w.iris,
	w.branchcode,
	w.categorycode,
	w.fidelite
FROM statdb.stat_webkiosk w
WHERE w.heure_deb > ?
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($date);
	my $i = 1 ; 
	while (my @row = $sth->fetchrow_array) {
		my ( $heure_deb, $heure_fin, $groupe, $poste, $id, $age, $sexe, $ville, $iris, $branchcode, $categorycode, $fidelite ) = @row ;
		my $duree ;
		if (length $heure_fin) {
			$duree = duree_datetime("minutes", $heure_deb, $heure_fin ) ;
		}
		my $espace = espace($groupe) ;
		
		my ( $age_lib1, $age_lib2, $age_lib3 ) ;
		if ( $age eq "NP" ) { 
			$age = undef ;
		} else {
			$age_lib1 = age($age, "trmeda") ;
			$age_lib2 = age($age, "trmedb") ;
			$age_lib3 = age($age, "trinsee") ;
		}
		my ( $carte, $personnalite ) = category($categorycode) ;
		if ( $personnalite eq "C" )	{
			$personnalite = "Personne" ;
		} else {
			$personnalite = "Collectivité" ;
		}
		
		my $type_carte = type_carte($categorycode) ;
		
		$branchcode = branches($branchcode) ;
		my ( $irisNom, $quartier ) = undef ;
		if (defined $iris) {
			($irisNom, $quartier) = quartier_rbx($iris) ;
		}
		
		my %index = (
			index   => $index,
			type    => $type,
			body    => {
				session_heure_deb => $heure_deb,
				session_heure_fin => $heure_fin,
				session_duree => $duree,
				session_espace => $espace,
				session_groupe => $groupe,
				session_poste => $poste,
				adherent_id => $id,
				adherent_age => $age,
				adherent_age_lib1 => $age_lib1,
				adherent_age_lib2 => $age_lib2,
				adherent_age_lib3 => $age_lib3,
				adherent_carte => $carte,
				adherent_type_carte => $type_carte,
				adherent_nb_annee_inscription => $fidelite,
				adherent_ville => $ville,
				adherent_rbx_iris => $iris,
				adherent_rbx_nom_iris => $irisNom,
				adherent_rbx_quartier => $quartier,
				adherent_site_inscription => $branchcode,
				adherent_personnalite => $personnalite
			}
		) ;

		$e->index(%index) ;

		print "$heure_deb - $i - $id\n" ;
		$i++ ;	
	}
	$sth->finish();
	$dbh->disconnect();
}

sub duree_datetime {
	my ($units, $datetime1, $datetime2) = @_ ;

	my $dt_datetime1 = DateTime::Format::MySQL->parse_datetime($datetime1) ;
	my $dt_datetime2 = DateTime::Format::MySQL->parse_datetime($datetime2) ;

	my $dt_duree = $dt_datetime2->subtract_datetime($dt_datetime1);

	return $dt_duree->in_units($units) ;
}

sub espace {
	my ($groupe) = @_ ;
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
	my $espace = $espaces{$groupe} ;
	return $espace ;
}