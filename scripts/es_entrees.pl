#!/usr/bin/perl

#use strict ;
#use warnings ;
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

my $log_message ;
my $process = "es_entrees.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;

my $es_maxdatetime = es_maxdatetime("entrees", "camera", "entrees_date") ;
my $i = entrees($es_maxdatetime, $es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;


sub entrees {
	my ($maxdatetime, $es_node) = @_ ;
	my %params = ( nodes => $es_node ) ;
	my $index = "entrees" ;
	my $type = "camera" ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	datetime,
	entrees
FROM statdb.stat_entrees
WHERE datetime > ?
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($maxdatetime);
	$i = 0 ;
	while (my @row = $sth->fetchrow_array) {
		my ( $datetime, $entrees ) = @row ;

		my ($entrees_year, $entrees_month, $entrees_week_number, $entrees_day, $entrees_jour_semaine, $entrees_hour) = date_form($datetime) ;
	
		my %index = (
			index   => $index,
			type    => $type,
			body    => {
				entrees_date => $datetime,
				entrees_date_annee => $entrees_year,
				entrees_date_mois => $entrees_month,
				entrees_date_semaine => $entrees_week_number,
				entrees_date_jour => $entrees_day,
				entrees_date_jour_semaine => $entrees_jour_semaine,
				entrees_date_heure => $entrees_hour,
				nb_entrees => $entrees
			}
		) ;

		$e->index(%index) ;
		$i++ ;
	}
	$sth->finish();
	$dbh->disconnect();
	return $i ;
}