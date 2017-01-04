#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use fonctions ;
use dbrequest ;
use esrbx ;

my $log_message ;
my $process = "es_items.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = es_node() ;

# On supprime l'index items puis on le recrée :
reg_items() ;

my $itemnumbermax = itemnumbermax() ;
my $delta = 100 ;

my $nb = 0 ;
while ( $itemnumbermax > 0 ) {
	my $i = items($itemnumbermax, $delta, $es_node) ;
	$itemnumbermax = $itemnumbermax - $delta ;
	$nb = $nb + $i ;
}

# On log la fin de l'opération
$log_message = "$process : $nb lignes indexées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;


sub reg_items {
	my %params = ( nodes => $es_node ) ;
	my $index = "items" ;
	my $type = "exemplaires" ;
	my %items = (
        index => 'items',
		body => {
			mappings => {
				"exemplaires" => {
					properties => {
						'abime' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'itemnumber' => {
							'type' => 'integer'
						},
						'biblionumber' => {
							'type' => 'integer'
						},
						'code_barre' => {
							'type' => 'string'
						},
						'collection_ccode' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'collection_lib1' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'collection_lib2' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'collection_lib3' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'collection_lib4' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'sll_public' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'sll_acces' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'sll_collection' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'sll_prets_coll' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'sll_prets' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'cote' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'date_creation' => {
							'type' => 'date',
							'format' => 'yyyy-MM-dd'
						},
						'date_dernier_pret' => {
							'type' => 'date',
							'format' => 'yyyy-MM-dd'
						},
						'emprunt' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'localisation' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'perdu' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'prix' => {
							'type' => 'float'
						},
						'prix_rempla' => {
							'type' => 'float'
						},
						'retire_collection' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'site_detenteur' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'site_rattach' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'statut' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'support' => {
							'type' => 'string',
							'index' => 'not_analyzed'
						},
						'titre' => {
							'type' => 'string',						,
							'index' => 'not_analyzed'
						},
						'annee_publication' => {
							'type' => 'integer'
						}
					}
				}
			}
		}
	) ;
	
	my $e = Search::Elasticsearch->new( %params ) ;
	$e->indices->delete(index => "items");
	$e->indices->create(%items);
}	

sub items {
my ($itemnumbermax, $delta, $es_node ) = @_ ;
my $minitemnumber = $itemnumbermax - $delta ;

my %params = ( nodes => $es_node ) ;
my $index = "items" ;
my $type = "exemplaires" ;

my $e = Search::Elasticsearch->new( %params ) ;

my $dbh = dbh("koha_prod") ;

my $req = <<SQL;
SELECT
	i.itemnumber,
	i.biblionumber,
	b.title,
	bi.itemtype,
	i.dateaccessioned,
	i.ccode,
	c.lib1,
	c.lib2,
	c.lib3,
	c.lib4,
	i.barcode,
	i.location,
	i.notforloan,
	i.damaged,
	i.withdrawn,
	i.itemlost,
	i.homebranch,
	i.holdingbranch,
	i.datelastborrowed,
	i.onloan,
	i.itemcallnumber,
	bi.publicationyear,
	i.price
FROM koha_prod.items i
JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
JOIN statdb.lib_collections2 c ON i.ccode = c.ccode
WHERE i.notforloan != 4
	AND i.itemnumber <= ? AND itemnumber > ?
SQL

my $sth = $dbh->prepare($req);
$sth->execute($itemnumbermax, $minitemnumber);
my $i = 0 ;
while (my @row = $sth->fetchrow_array) {
	my ($itemnumber, $biblionumber, $title, $itemtype, $dateaccessionned, $ccode, $lib1, $lib2, $lib3, $lib4, $barcode, $location, $notforloan, $damaged, $withdrawn, $itemlost, $homebranch, $holdingbranch, $datelastborrowed, $onloan, $itemcallnumber, $publicationyear, $price ) = @row ;

	if (!defined $lib2) {
		$lib2 = "NP" ;
	} 
	if (!defined $lib3) {
		$lib3 = "NP" ;
	}
	if (!defined $lib4) {
		$lib4 = "NP" ;
	}

	$homebranch = branches($homebranch) ;
	$holdingbranch = branches($holdingbranch) ;

#	if (!defined $price) {
#		$price = 0 ;
#	}

#	if (!defined $replacementprice) {
#		$replacementprice = 0 ;
#	}

	if (!defined $datelastborrowed) {
		$datelastborrowed = "1970-01-01" ;
	}

	if (!defined $onloan) {
		$onloan = "Non emprunté" ;
	} else {
		$onloan = "Emprunté" ;
	}

	if (!defined $itemcallnumber) {
		$itemcallnumber = "Non renseigné" ;
	}
	
	my ( $sll_public, $sll_acces, $sll_collection, $sll_prets_coll, $sll_prets ) = lib_sll( $ccode, $location, $itemtype ) ;

	$itemtype = av($itemtype, "ccode") ;
	$location = av($location, "LOC") ;
	$notforloan = av($notforloan, "ETAT") ;
	$damaged = av($damaged, "DAMAGED") ;
	$withdrawn = av($withdrawn, "RETIRECOLL") ;
	$itemlost = av($itemlost, "LOST") ;

	$e->index(
		index   => $index,
		type    => $type,
		id      => $itemnumber,
		body    => {
			itemnumber => $itemnumber,
			biblionumber   => $biblionumber,
			titre => $title,
			support => $itemtype,
			date_creation => $dateaccessionned,
			code_barre => $barcode,
			collection_ccode => $ccode,
			collection_lib1 => $lib1,
			collection_lib2 =>	$lib2,
			collection_lib3 => $lib3,
			collection_lib4 => $lib4,
			sll_public => $sll_public,
			sll_acces => $sll_acces,
			sll_collection => $sll_collection,
			sll_prets_coll => $sll_prets_coll,
			sll_prets => $sll_prets,
			localisation => $location,
			statut => $notforloan,
			abime => $damaged,
			retire_collection => $withdrawn,
			perdu => $itemlost,
			site_rattach => $homebranch,
			site_detenteur => $holdingbranch,
			date_dernier_pret => $datelastborrowed, 
			emprunt => $onloan,
			cote => $itemcallnumber,
			annee_publication => $publicationyear,
			prix => $price
		}
	) ;
	$i++ ;
}
$sth->finish();
$dbh->disconnect();
return $i ;
}