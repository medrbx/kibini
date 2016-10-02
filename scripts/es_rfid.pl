#!/usr/bin/perl

# use strict ;
# use warnings ;
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

# On récupère l'adresse d'Elasticsearch
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $es_node = $conf->{elasticsearch}->{node} ;

my %params = ( nodes => , $es_node ) ;
my $e = Search::Elasticsearch->new( %params ) ;

my $dbh = dbh("statdb") ;

my $es_maxdatetime_prets = es_maxdatetime("rfid", "prets", "date.datetime") ;
print "prets : $es_maxdatetime_prets\n" ;
#my $es_maxdatetime_prets = "2015-09-07" ;
#my $es_maxdatetime_retours = "2015-09-07" ;
es_rfid("prets", $es_maxdatetime_prets) ;
my $es_maxdatetime_retours = es_maxdatetime("rfid", "retours", "date.datetime") ;
print "retours : $es_maxdatetime_retours\n" ;
es_rfid("retours", $es_maxdatetime_retours) ;

$dbh->disconnect();

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
		
		print "$transaction, $date_transaction, $borne, $year, $month, $day, $jour_semaine, $hour, $nb_transactions_champs\n" ;
	}
	$sth->finish();
}