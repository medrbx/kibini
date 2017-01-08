#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use DateTime ;
use DateTime::Format::MySQL ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use fonctions ;
use dbrequest ;
use esrbx ;

my $log_message ;
my $process = "es_rfid.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;

my %params = ( nodes => , $es_node ) ;
my $e = Search::Elasticsearch->new( %params ) ;

my $dbh = dbh("statdb") ;

my $i = 0 ;
my $nb = $i ;
my $es_maxdatetime_prets = es_maxdatetime("rfid", "prets", "date.datetime") ;
$i = es_rfid("prets", $es_maxdatetime_prets) ;
$nb = $nb + $i ;
my $es_maxdatetime_retours = es_maxdatetime("rfid", "retours", "date.datetime") ;
$i = es_rfid("retours", $es_maxdatetime_retours) ;
$nb = $nb + $i ;

$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $nb lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;



sub es_rfid {
	my ( $transaction, $date ) = @_ ;
	my $operation ;
	my $nb_transactions_champs ;
	if ( $transaction eq "prets" ) {
		$operation = "pret" ;
		$nb_transactions_champs = "nb_prets" ;
	} elsif ( $transaction eq "retours" ) {
		$operation = "retour" ;
		$nb_transactions_champs = "nb_retours" ;		
	}
	my $req = <<SQL;
SELECT 
	n.date,
	n.borne,
	e.etage,
	n.nb
FROM statdb.stat_nedap n
JOIN statdb.stat_nedap_borne e ON e.lib = n.borne
WHERE operation = ?
	AND date > ?
SQL
	my $sth = $dbh->prepare($req);
	$sth->execute($operation, $date);
	my $i = 0 ;
	while (my @row = $sth->fetchrow_array) {
		my ( $date_transaction, $borne, $etage, $nb_transaction ) = @row ;
		my ( $year, $month, $week_number, $day, $jour_semaine, $hour ) = date_form($date_transaction) ;
		
		my %index = (
			index   => "rfid",
			type    => $transaction,
			body    => {
				date   => {
					datetime => $date_transaction,
					annee => $year,
					mois => $month,
					jour => $day,
					jour_semaine => $jour_semaine,
					heure => $hour,
					numero_semaine => $week_number
				},
				borne => $borne,
				etage => $etage,
				$nb_transactions_champs => $nb_transaction
			}
		) ;
		
		$e->index(%index) ;
		
		$i++ ;
	}
	$sth->finish();
	return $i ;
}