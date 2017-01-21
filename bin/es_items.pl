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
use fonctions ;
use collections::poldoc ;

my $log_message ;
my $process = "es_items.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

# On supprime l'index items puis on le recrée :
my $result = RegenerateIndex($es_node, "items") ;

my $itemnumbermax = itemnumbermax() ;
my $delta = 100 ;

my $nb = 0 ;
while ( $itemnumbermax > 0 ) {
    my $i = items($itemnumbermax, $delta, $es_node) ;
    $itemnumbermax = $itemnumbermax - $delta ;
    $nb = $nb + $i ;
}

# On log la fin de l'opération
$log_message = "$process : $nb rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub items {
    my ($itemnumbermax, $delta, $es_node ) = @_ ;
    my $minitemnumber = $itemnumbermax - $delta ;

    my %params = ( nodes => $es_node ) ;
    my $index = "items" ;
    my $type = "exemplaires" ;

    my $e = Search::Elasticsearch->new( %params ) ;

    my $dbh = GetDbh() ;

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

#    if (!defined $price) {
#        $price = 0 ;
#    }

#    if (!defined $replacementprice) {
#        $replacementprice = 0 ;
#    }

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
		
		my $pret12 = IsLoanedByItemnumber($itemnumber, 12) ;

        $e->index(
            index   => $index,
            type    => $type,
            id      => $itemnumber,
            body    => {
                itemnumber => $itemnumber,
                biblionumber => $biblionumber,
                titre => $title,
                support => $itemtype,
                date_creation => $dateaccessionned,
                code_barre => $barcode,
                collection_ccode => $ccode,
                collection_lib1 => $lib1,
                collection_lib2 =>    $lib2,
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
                prix => $price,
				pret12 => $pret12
            }
        ) ;
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}