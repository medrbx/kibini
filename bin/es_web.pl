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
my $process = "es_web.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupére l'adresse d'Elasticsearch
my $es_node = es_node() ;
my $index = "web" ;
my @types = qw( site bn-r ) ;

my $nb = 0 ;
for my $type (@types) {
	my $es_maxdatetime = es_maxdatetime("web", $type, "date") ;
	my $i = web( $es_maxdatetime, $es_node, $index, $type ) ;
	$nb = $nb + $i ;
}

# On log la fin de l'opération
$log_message = "$process : $nb lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;
	
sub web {
	my ( $date, $es_node, $index, $type ) = @_ ;
	my %params = ( nodes => $es_node ) ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = <<SQL;
SELECT
	date,
	site,
	nb_sessions,
	nb_pages_vues
FROM statdb.stat_web
WHERE site = ? AND date > ?
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($type, $date);
	my $i = 0 ;
	while (my @row = $sth->fetchrow_array) {
		my ( $date, $site, $nb_sessions, $nb_pages_vues ) = @row ;
		
		my %index = (
			index   => $index,
			type    => $type,
			body    => {
				date => $date,
				site => $site,
				nb_sessions => $nb_sessions,
				nb_pages_vues => $nb_pages_vues
			}
		) ;

		$e->index(%index) ;

		$i++ ;	
	}
	$sth->finish();
	$dbh->disconnect();
	return $i ;
}