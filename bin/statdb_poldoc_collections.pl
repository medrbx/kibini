#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;
use kibini::time ;
use collections::poldoc ;

my $log_message ;
my $process = "statdb_poldoc_collections.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
#AddCrontabLog($log_message) ;

my $dbh = GetDbh() ;

my @sites = qw( GP MD ZB CL ) ;
my $site ;

my %siteClauseWhere = (
    "GP" => "i.location != 'ZZ'",
    "MD" => "i.location NOT IN('MED0A', 'BUS1A')",
    "ZB" => "i.location = 'BUS1A'",
    "CL" => "i.location = 'MED0A'"
) ;


foreach $site (@sites) {
    my $req = <<SQL;
INSERT INTO statdb.stat_poldoc_collections(date, site, ccode, support, location, nb_exemplaires, nb_exemplaires_empruntables, nb_exemplaires_excluspret, nb_exemplaires_traitement, nb_exemplaires_abimes, nb_exemplaires_reparation_retrait, nb_exemplaires_perdus, nb_exemplaires_non_restitues)
SELECT
    CURDATE(),
    "$site",
    i.ccode,
    bi.itemtype,
    i.location,
    COUNT(i.itemnumber),
    COUNT(IF(i.notforloan = 0 AND i.itemlost = 0 AND i.damaged = 0, i.itemnumber, NULL)),
    COUNT(IF(i.notforloan = 2 AND i.itemlost = 0 AND i.damaged = 0, i.itemnumber, NULL)),
    COUNT(IF(i.notforloan = -2 AND i.itemlost = 0 AND i.damaged = 0, i.itemnumber, NULL)),
    COUNT(IF(i.itemlost = 0 AND i.damaged = 1, i.itemnumber, NULL)),
    COUNT(IF(i.notforloan = -3 OR i.notforloan = -4 AND i.itemlost = 0 AND i.damaged = 0, i.itemnumber, NULL)),
    COUNT(IF(i.itemlost = 2 AND i.damaged = 0, i.itemnumber, NULL)),
    COUNT(IF(i.itemlost = 1 AND i.damaged = 0, i.itemnumber, NULL))    
FROM koha_prod.items i
JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
WHERE i.location != 'MUS1A'
    AND i.notforloan != 4
    AND $siteClauseWhere{$site}
GROUP BY i.ccode, bi.itemtype, i.location
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    $sth-> finish() ;
}

$dbh->disconnect() ;



# On log la fin de l'opération
$log_message = "$process : ending\n" ;
#AddCrontabLog($log_message) ;