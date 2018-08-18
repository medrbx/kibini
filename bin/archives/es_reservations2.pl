#!/usr/bin/perl

#use strict ;
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

my $log_message ;
my $process = "es_reservations.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $es_node = $conf->{elasticsearch}->{node} ;

my $nb = 0 ;
my $date = "2016-11-11" ;
while ($date ne "2014-06-30") {
	my $i = reservations($date, $es_node) ;
	$date = DateTime::Format::MySQL->parse_date($date) ;
	$date = $date->subtract( days => 1	) ;
	$date = DateTime::Format::MySQL->format_date($date) ;
	$log_message = "$process : $date ok, $i réservations indexées" ;
	log_file($log_message) ;
	$nb = $nb + $i ;
}

# On log la fin de l'opération
$log_message = "$process : $nb lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;


sub reservations {
	my ( $date, $es_node ) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "reservations" ;
	my $type = "reserves" ;
	
	print "$date\n" ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	r.reserve_id,
    SHA1(r.borrowernumber),
    r.reservedate,
    r.biblionumber,
    r.branchcode,
    r.notificationdate,
    r.cancellationdate,
    r.priority,
    r.found,
    r.timestamp,
    r.itemnumber,
    r.waitingdate,
    r.etat,
    r.espace,
    r.age,
    r.sexe,
    r.ville,
    r.iris,
    r.branchcode_borrower,
    r.categorycode,
    r.fidelite,
    r.motif_annulation,
    r.courriel,
    r.mobile,
    r.annulation,
    r.document_mis_cote,
	r.ccode
FROM statdb.stat_reserves r
WHERE r.reservedate = ?
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($date);
	my $i = 0 ;
	while (my @row = $sth->fetchrow_array) {
		my ( $reserve_id, $borrowernumber, $reservedate, $biblionumber, $branchcode, $notificationdate, $cancellationdate, $priority, $found, $timestamp, $itemnumber, $waitingdate, $etat, $espace, $age, $sexe, $ville, $iris, $branchcode_borrower, $categorycode, $fidelite, $motif_annulation, $courriel, $mobile, $annulation, $document_mis_cote, $ccode ) = @row ;
		
		my ($itemtype, $location, $homebranch, $lib1, $lib2, $lib3, $lib4 ) = "NC" ;
		if (length itemnumber) {
			$itemtype = getitemtype($biblionumber) ;
			$itemtype = av($itemtype, "ccode") ;
			
			($location, $homebranch, $ccode) = getdataitem($itemnumber) ;
			
			$location = av($location, "LOC") ;		
			$homebranch = branches($homebranch) ;
			
			# ( $ccode, $lib1, $lib2, $lib3, $lib4 ) = getdataccode($itemnumber) ;
		}
		
		if (length $ccode) {
			($lib1, $lib2, $lib3, $lib4) = ccodeniveaux($ccode) ;
		} else {
			$ccode = "NC"
		}
		
		my ( $irisNom, $quartier ) = undef ;
		if (defined $iris) {
			($irisNom, $quartier) = quartier_rbx($iris) ;
		}
		$branchcode = branches($branchcode) ;
		$branchcode_borrower = branches($branchcode_borrower) ;
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
		
		my %index = (
			index   => $index,
			type    => $type,
			id      => $reserve_id,
			body    => {
				reserve_id => $reserve_id,
				reservedate => $reservedate,
				reserveur_id => $borrowernumber,
				reserveur_age => $age,
				reserveur_age_lib1 => $age_lib1,
				reserveur_age_lib2 => $age_lib2,
				reserveur_age_lib3 => $age_lib3,
				reserveur_sexe => $sexe,
				reserveur_ville => $ville,
				reserveur_rbx_iris => $iris,
				reserveur_rbx_nom_iris => $irisNom,
				reserveur_rbx_quartier => $quartier,
				reserveur_site_inscription => $branchcode_borrower,
				reserveur_carte => $carte,
				reserveur_personnalite => $personnalite,
				reserveur_type_carte => $type_carte,
				reserveur_nb_annee_inscription => $fidelite,
				reserveur_mobile => $mobile,
				reserveur_courriel => $courriel,
				biblionumber => $biblionumber,
				site_retrait => $branchcode,
				date_notification => $notificationdate,
				date_annulation => $cancellationdate,
				date_mise_cote => $waitingdate,
				found => $found,
				etat => $etat,
				espace => $espace,
				motif_annulation => $motif_annulation,
				annulation => $annulation,
				document_mis_cote => $document_mis_cote,
				collection_ccode => $ccode,
				collection_lib1 => $lib1,
				collection_lib2 =>	$lib2,
				collection_lib3 => $lib3,
				collection_lib4 => $lib4,
				localisation => $location,
				site_rattach => $homebranch,
				support => $itemtype
			}
		) ;

		$e->index(%index) ;
		print "$date : $i\n" ;
		$i++ ;
	}
	$sth->finish();
	$dbh->disconnect();
	return $i ;
}