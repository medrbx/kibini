#!/usr/bin/perl

use warnings ;
use strict ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use dbrequest ;
use fonctions ;

my $log_message ;
my $process = "statdb_freq_etude.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;


my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;

# On récupère l'ensemble des fréquentants de la veille
my $req = "SELECT DISTINCT cardnumber FROM statdb.stat_freq_etude WHERE DATE(datetime_entree) <= (CURDATE() - INTERVAL 1 DAY)" ;
my $sth = $dbh->prepare($req);
$sth->execute();

my $i = 0 ;
while (my $cardnumber = $sth->fetchrow_array) {
	# On cherche le borrowernumber, le sexe, l'âge, la ville, l'iris et le type de carte
	my $req = <<SQL ;
SELECT
	borrowernumber,
	CASE WHEN title = 'Madame' THEN 'Femme' WHEN title = 'Monsieur' THEN 'Homme' WHEN categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP' END,
	YEAR(CURDATE()) - YEAR(dateofbirth),
	city,
	altcontactcountry,
	categorycode
FROM koha_prod.borrowers
WHERE cardnumber = ?
SQL
	my $sth = $dbh->prepare($req);
	$sth->execute($cardnumber);
	my ($borrowernumber, $sexe, $age, $ville, $iris, $categorycode) = $sth->fetchrow_array ;
	$sth->finish();
	
	if (defined $borrowernumber) {
		if (!defined $sexe) {$sexe = 'INC' ;}
		if (!defined $age) {$age = 'INC' ;}
		if (!defined $ville) {$ville = 'INC' ;}
		if (!defined $iris) {$iris = 'INC' ;}
		if (!defined $categorycode) {$categorycode = 'INC' ;}
	
		# On insert ces données dans statdb.stat_freq_etude
		my $req = <<SQL ;
UPDATE statdb.stat_freq_etude
SET
	borrowernumber = ?,
	sexe = ?,
	age = ?,
	ville = ?,
	iris = ?,
	categorycode = ?
WHERE cardnumber = ? AND DATE(datetime_entree) <= (CURDATE() - INTERVAL 1 DAY)
SQL
		my $sth = $dbh->prepare($req);
		$sth->execute( $borrowernumber, $sexe, $age, $ville, $iris, $categorycode, $cardnumber );
		$sth->finish();
	}
	
	$i++ ;
}
$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i lignes intégrées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;