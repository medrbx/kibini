#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;
use kibini::time ;

my $log_message ;
my $process = "statdb_items_borrowers.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

my $date = GetDateTime('today') ;

# On complète la table statdb.stat_docentrees
my $stat_docentrees = <<SQL;
INSERT INTO statdb.stat_docentrees (
    date_extraction,
    biblionumber,
    bibdatecreated,
    itemtype,
    itemnumber,
    itemdateaccessioned,    
    homebranch,
    location,
    itemcallnumber,
    barcode,
    datelastborrowed,
    datelastseen,
    notforloan,
    damaged,
    itemlost,
    withdrawn,
    issues,
    renewals,
    reserves,
    onloan,
    ccode,
    price,
    timestamp)
SELECT
    $date,
    i.biblionumber,
    b.datecreated,
    bi.itemtype,
    i.itemnumber,
    i.dateaccessioned,    
    i.homebranch,
    i.location,
    i.itemcallnumber,
    i.barcode,
    i.datelastborrowed,
    i.datelastseen,
    i.notforloan,
    i.damaged,
    i.itemlost,
    i.withdrawn,
    i.issues,
    i.renewals,
    i.reserves,
    i.onloan,
    i.ccode,
    i.price,
    i.timestamp
FROM koha_prod.items i
INNER JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
INNER JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
WHERE i.dateaccessioned >= '2014-07-28'
SQL

# On complète la table statdb.stat_docex
my $stat_docex = <<SQL;
INSERT INTO statdb.stat_docex (
  date,
  ccode,
  location,
  itemtype,
  exemplaires,
  commandes,
  traitements,
  empruntables,
  consultation_place,
  reparation,
  retrait,
  reliure,
  sortis,
  musee,
  perdus,
  non_restitue,
  abimes,
  empruntes)
SELECT
  $date,
  i.ccode,
  i.location,
  bi.itemtype,
  COUNT(itemnumber),
  COUNT(IF(i.notforloan = -1, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = -2, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 0, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 2, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = -4, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = -3, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 5, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = -1, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 4, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 3, i.itemnumber, NULL)),
  COUNT(IF(i.notforloan != 4 AND i.itemlost = 1 AND i.itemnumber NOT IN (SELECT itemnumber FROM koha_prod.issues), i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 0 AND i.itemlost = 1 AND i.itemnumber IN (SELECT itemnumber FROM koha_prod.issues), i.itemnumber, NULL)),
  COUNT(IF(i.notforloan = 0 AND i.itemnumber IN (SELECT itemnumber FROM koha_prod.issues), i.itemnumber, NULL))
FROM koha_prod.items i
INNER JOIN koha_prod.biblioitems bi ON i.biblionumber = bi.biblionumber
GROUP BY i.ccode, i.location, bi.itemtype;
SQL

# On complète la table statdb.stat_borrowers
my $stat_borrowers_1 = "INSERT INTO statdb.stat_borrowers (date, borrowernumber, cardnumber,  title,  city,  state,  zipcode,  country,  email,  phone,  mobile,    dateofbirth,  branchcode,  categorycode,  dateenrolled,  dateexpiry, gonenoaddress,  lost, contactname,  contactfirstname,  altcontactaddress1,  altcontactaddress2,  altcontactaddress3,  altcontactstate,  altcontactzipcode,  altcontactcountry ) SELECT  curdate(), borrowernumber,  cardnumber,  title,  city,  state,  zipcode,  country,  email,  phone,  mobile,    dateofbirth,  branchcode,  categorycode,  dateenrolled,  dateexpiry, gonenoaddress,  lost,  contactname,  contactfirstname,  altcontactaddress1,  altcontactaddress2,  altcontactaddress3,  altcontactstate,  altcontactzipcode,  altcontactcountry  FROM koha_prod.borrowers" ;

my $stat_borrowers_2 = <<SQL ;
UPDATE statdb.stat_borrowers
SET
        age = CASE
                WHEN categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP'
        ELSE YEAR(CURDATE()) - YEAR(dateofbirth) END,
        emprunteur = CASE
                WHEN borrowernumber IN (SELECT distinct borrowernumber FROM statdb.stat_issues WHERE issuedate >= (CURDATE() - INTERVAL 1 YEAR)) THEN 'oui'
        ELSE 'non' END,
        fidelite = CASE
                WHEN categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP'
        ELSE YEAR(CURDATE()) - YEAR(dateenrolled) END,
        sexe = CASE
                WHEN categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP'
        WHEN title = 'Madame' THEN 'F'
        WHEN title = 'Monsieur' THEN 'M' END
WHERE date = CURDATE();
SQL

my $dbh = GetDbh() ;

my @req = ( $stat_docentrees, $stat_docex, $stat_borrowers_1, $stat_borrowers_2 ) ;
for my $req (@req) {
    my $sth = $dbh->prepare($req);
    $sth->execute();
    $sth->finish();
}

# On anonymise stat_borrowers
my @columns = qw( state email phone mobile contactname contactfirstname ) ;
for my $column (@columns) { 
    my $req = "UPDATE statdb.stat_borrowers SET $column = NULL WHERE $column = '' AND date = CURDATE()" ;
    my $sth = $dbh->prepare($req);
    $sth->execute();
    $req =  "UPDATE statdb.stat_borrowers SET $column = 'X' WHERE $column IS NOT NULL AND date = CURDATE();" ;
    $sth = $dbh->prepare($req);
    $sth->execute();
    $sth->finish();
}
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;