#! /usr/bin/perl

use strict ;
use warnings ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use collections::biblio2 ;

my $log_message ;
my $process = "data_biblio.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

my $es_node = GetEsNode() ;
my %params = ( nodes => $es_node ) ;
my $e = Search::Elasticsearch->new( %params ) ;
#my $result = RegenerateIndex($es_node, "catalogue") ;


my $dbh = GetDbh() ;
my $i = 0 ;
my $j = 0 ;


my @tables = qw( biblioitems deletedbiblioitems ) ;
foreach my $table (@tables) {
	my $req = "SELECT biblionumber FROM koha_prod.$table WHERE biblionumber NOT IN (SELECT biblionumber FROM statdb.data_bib)" ;
	my $sth = $dbh->prepare($req) ;
	$sth->execute() ;
	while ( my $biblionumber = $sth->fetchrow_array ) {
		my $count = AddDataBiblioFromBiblionumber($dbh, $table, $biblionumber, $e) ;
		$i++ ;
		print "$i - $table - biblionumber : $biblionumber\n" ;
    }
	$sth->finish() ;
}

$dbh->disconnect();

$log_message = "$process : $j rows deleted" ;
AddCrontabLog($log_message) ;

# On log la fin de l'opération
$log_message = "$process : $i rows added" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;
