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


my $log_message ;
my $process = "es_rfid.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

my %params = ( nodes => , $es_node ) ;
my $e = Search::Elasticsearch->new( %params ) ;

my $dbh = GetDbh() ;

my $i = 0 ;
my $nb = $i ;
my $es_maxdatetime_prets = GetEsMaxDateTime("rfid", "prets", "date.datetime") ;
$i = es_rfid("prets", $es_maxdatetime_prets) ;
$nb = $nb + $i ;
my $es_maxdatetime_retours = GetEsMaxDateTime("rfid", "retours", "date.datetime") ;
$i = es_rfid("retours", $es_maxdatetime_retours) ;
$nb = $nb + $i ;

$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;



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
		my ( $year, $month, $week_number, $day, $jour_semaine, $hour ) = GetSplitDateTime($date_transaction) ;
		
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