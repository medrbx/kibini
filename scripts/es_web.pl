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
use esrbx ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;
my $index = "web" ;
my @types = qw( site bn-r ) ;

for my $type (@types) {
	my $es_maxdatetime = es_maxdatetime("web", $type, "date") ;
	print "$type : $es_maxdatetime\n" ;
	web( $es_maxdatetime, $es_node, $index, $type ) ;
}
	
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

		print "$date - $site\n" ;	
	}
	$sth->finish();
	$dbh->disconnect();
}