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

# On récupère l'adresse d'Elasticsearch
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $es_node = $conf->{elasticsearch}->{node} ;

my $es_maxdatetime = es_maxdatetime("entrees", "camera", "entrees_date") ;
print "$es_maxdatetime\n" ;
entrees($es_maxdatetime, $es_node) ;

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
		print "$datetime, $entrees\n" ;
	}
	$sth->finish();
	$dbh->disconnect();
}