#! /usr/bin/perl

use strict;
use warnings;
use Text::CSV ;
use utf8 ;
use Data::Dumper ; # pour débuguer uniquement
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::time ;

my $ccode = '"ACFIFZZ"' ;
my $branch = 'Médiathèque' ;
my $site ;

# on crée une connexion à statdb et ES
my $dbh = GetDbh() ;
my $es_node = GetEsNode() ;
my $e = Search::Elasticsearch->new( nodes => $es_node ) ;
my $date = GetDateTime('today') ;

# on prépare le fichier de sortie
my $out = "liste_doc_out.csv" ;
my $csv_out = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open( my $fd_out, ">:encoding(UTF-8)", $out ) ;
my @column_out = ( 'Support', 'CB', 'Titre', 'Auteur', 'Localisation', 'Cote', 'Statut', 'Année acquisition', 'Année publication', 'Nb prêts année', 'Nb réservations année', 'Nb prêts totaux' ) ;
$csv_out->print ($fd_out, \@column_out) ;

if ( $branch eq 'Médiathèque' ) {
	$site = 'homebranch = "MED"';
}

my $req = <<SQL;
SELECT
	i.biblionumber,
	i.itemnumber,
	bi.itemtype,
	i.location,
	i.barcode,
	b.title,
	b.author,
	i.itemcallnumber,
	i.notforloan,
	YEAR(i.dateaccessioned) as acq,
	bi.publicationyear,
	i.issues
FROM koha_prod.items i
JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
WHERE i.ccode = $ccode AND $site
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
my $i = 0 ;
while (my $item = $sth->fetchrow_hashref()) {
	$item->{nb_issues} = GetNbIssuesES($e, $item->{itemnumber}, $date);
	$item->{nb_reserves} = GetNbReserves($e, $item->{biblionumber}, $date);
	my @item_out = ( $item->{itemtype}, $item->{barcode}, $item->{title}, $item->{author}, $item->{location}, $item->{itemcallnumber}, $item->{notforloan}, $item->{acq}, $item->{publicationyear}, $item->{nb_issues}, $item->{nb_reserves}, $item->{issues} ) ;
    $csv_out->print ($fd_out, \@item_out) ;
	$i++;
	print "$i\n";
}

close $fd_out ;
$dbh->disconnect() ;


sub GetNbIssuesES {
    my ($e, $itemnumber, $date) = @_ ;
    
    my $body = {
        query => {
            bool => {
                must => [
                    { term => { doc_itemnumber => $itemnumber } }
                ],
                filter => [
                    { range => { pret_date_pret => { gte => "$date||-1y/d", lt => "$date||/d", format => "yyyy-MM-dd" } } }
                ]
            }
        }
    } ;
    
    my $result  = $e->count(
        index => 'prets',
        body  => $body
    );
    
    return $result->{'count'} ;
}

sub GetNbReserves {
    my ($e, $biblionumber, $date) = @_ ;
    
    my $body = {
        query => {
            bool => {
                must => [
                    { term => { biblionumber => $biblionumber } }
                ],
                filter => [
                    { range => { reservedate => { gte => "$date||-1y/d", lt => "$date||/d", format => "yyyy-MM-dd" } } }
                ]
            }
        }
    } ;
    
    my $result  = $e->count(
        index => 'reservations',
        body  => $body
    );
    
    return $result->{'count'} ;
}