#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/modules/" ;
use dbrequest ;

my $r1 = "UPDATE statdb.stat_issues SET cle = CONCAT(issuedate, '-', itemnumber) WHERE cle IS NULL ;" ;
my $r2 = "ALTER TABLE koha_prod.old_issues ADD COLUMN cle VARCHAR(75) NULL DEFAULT NULL AFTER issuedate, ADD INDEX index_cle (cle ASC)" ;
my $r3 = "UPDATE koha_prod.old_issues SET cle = CONCAT(issuedate, '-', itemnumber) WHERE DATE(returndate) = CURDATE()  - INTERVAL 1 DAY" ;

# On insère dans statdb les prêts de la veille
my $r4 = "INSERT INTO statdb.stat_issues (issuedate, date_due, returndate, renewals, branch, borrowernumber, cardnumber, age, sexe, ville, iris, branchcode, categorycode, fidelite, itemnumber, homebranch, location, ccode, itemcallnumber, itemtype, publicationyear, biblionumber, dateaccessioned) SELECT    o.issuedate,    o.date_due,    o.returndate,    o.renewals,    o.branchcode,    o.borrowernumber,    b.cardnumber,    CASE WHEN b.categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP' ELSE YEAR(o.issuedate) - YEAR(b.dateofbirth) END,    CASE WHEN b.title = 'Madame' THEN 'F' WHEN b.title = 'Monsieur' THEN 'M'    WHEN b.categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP' END,    b.city,    b.altcontactcountry,    b.branchcode,    b.categorycode,    YEAR(o.issuedate) - YEAR(b.dateenrolled),    o.itemnumber,    i.homebranch,    i.location,    i.ccode,    i.itemcallnumber,    bi.itemtype,    bi.publicationyear,    i.biblionumber,    i.dateaccessioned FROM koha_prod.issues o LEFT JOIN koha_prod.borrowers b ON o.borrowernumber = b.borrowernumber LEFT JOIN koha_prod.items i ON o.itemnumber = i.itemnumber LEFT JOIN koha_prod.biblioitems bi ON i.biblionumber = bi.biblionumber WHERE DATE(o.issuedate) = CURDATE() - INTERVAL 1 DAY" ;

# On insère dans statdb les retours de la veille
my $r5 = "UPDATE statdb.stat_issues i JOIN koha_prod.old_issues o ON i.cle = o.cle SET i.returndate = o.returndate, i.renewals = o.renewals WHERE i.returndate IS NULL AND DATE(o.returndate) = CURDATE() - INTERVAL 1 DAY" ; 

# On insère dans statdb les arrêts de bus
my $r6 = "UPDATE statdb.stat_issues SET arret_bus = CASE WHEN DAYOFWEEK(issuedate) =  '3' AND TIME(issuedate) BETWEEN '13:50:00' AND '15:08:00' THEN 'B01' WHEN DAYOFWEEK(issuedate) =  '3' AND TIME(issuedate) BETWEEN '15:08:00' AND '16:08:00' THEN 'B02' WHEN DAYOFWEEK(issuedate) =  '3' AND TIME(issuedate) BETWEEN '16:08:00' AND '17:45:00' THEN 'B03' WHEN DAYOFWEEK(issuedate) =  '4' AND TIME(issuedate) BETWEEN '10:25:00' AND '11:40:00' THEN 'B05' WHEN DAYOFWEEK(issuedate) =  '4' AND TIME(issuedate) BETWEEN '13:55:00' AND '15:15:00' THEN 'B07' WHEN DAYOFWEEK(issuedate) =  '4' AND TIME(issuedate) BETWEEN '15:15:00' AND '16:37:00' THEN 'B08' WHEN DAYOFWEEK(issuedate) =  '4' AND TIME(issuedate) BETWEEN '16:37:00' AND '18:00:00' THEN 'B09' WHEN DAYOFWEEK(issuedate) =  '5' AND TIME(issuedate) BETWEEN '14:50:00' AND '16:08:00' THEN 'B12' WHEN DAYOFWEEK(issuedate) =  '5' AND TIME(issuedate) BETWEEN '16:08:00' AND '17:30:00' THEN 'B11' WHEN DAYOFWEEK(issuedate) =  '6' AND TIME(issuedate) BETWEEN '13:50:00' AND '14:53:00' THEN 'B13' WHEN DAYOFWEEK(issuedate) =  '6' AND TIME(issuedate) BETWEEN '14:53:00' AND '16:08:00' THEN 'B14' WHEN DAYOFWEEK(issuedate) =  '6' AND TIME(issuedate) BETWEEN '16:08:00' AND '17:45:00' THEN 'B20' WHEN DAYOFWEEK(issuedate) =  '6' AND TIME(issuedate) BETWEEN '09:20:00' AND '10:23:00' THEN 'B06' WHEN DAYOFWEEK(issuedate) =  '7' AND TIME(issuedate) BETWEEN '10:23:00' AND '11:40:00' THEN 'B17' WHEN DAYOFWEEK(issuedate) =  '7' AND TIME(issuedate) BETWEEN '13:50:00' AND '15:08:00' THEN 'B18' WHEN DAYOFWEEK(issuedate) =  '7' AND TIME(issuedate) BETWEEN '15:08:00' AND '16:45:00' THEN 'B19' ELSE 'INC' END WHERE branch = 'BUS' AND arret_bus IS NULL AND DATE(issuedate) = CURDATE() - INTERVAL 1 DAY" ;

# on corrige les ccodes des périodiques
my $r7 = "UPDATE statdb.stat_issues s JOIN statdb.lib_periodiques p ON s.biblionumber = p.biblionumber SET s.ccode = p.ccode WHERE DATE(s.issuedate) = CURDATE() - INTERVAL 1 DAY" ;

my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;
my @req = ( $r1, $r2, $r3, $r4, $r5, $r6, $r7 ) ;
for my $req (@req) {
	my $sth = $dbh->prepare($req);
	$sth->execute();
	$sth->finish();
}
$dbh->disconnect();