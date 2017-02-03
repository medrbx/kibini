#!/usr/bin/perl

use warnings ;
use strict ;
use utf8 ;
use FindBin qw( $Bin );
# use Data::Dumper

use lib "$Bin/../lib" ;
use dbrequest ;

# On détermine le coef de correction
my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;
my $req = <<SQL;
SELECT COUNT(IF(altcontactcountry LIKE '59%', borrowernumber, NULL)) / COUNT(borrowernumber)
FROM koha_prod.borrowers
WHERE city = 'ROUBAIX'
	AND categorycode IN ('BIBL', 'CSVT', 'CSLT', 'MEDA', 'MEDB', 'MEDC')
	AND dateexpiry >= CURDATE()
	AND (YEAR(CURDATE()) - YEAR(dateofbirth)) < 20 AND (YEAR(CURDATE()) - YEAR(dateofbirth)) > 10
SQL

my $sth = $dbh->prepare($req);
$sth->execute(); 	
my $coeff = $sth->fetchrow_array;
$sth->finish();

# On calcule le nb de personnes par iris
$req = <<SQL;
SELECT
	irisInsee,
    SUM(nb_hab) AS hab
FROM statdb.iris_pop
WHERE ageRev < 20 AND ageRev > 10
GROUP BY irisInsee
SQL

$sth = $dbh->prepare($req);
$sth->execute();
my %irisHab ;
while(my $iris = $sth->fetchrow_hashref()) {
	$irisHab{$iris->{irisInsee}} = $iris->{hab} ;
}
$sth->finish();

# On calcule pour chaque iris la part corrigée d'inscrits
my $result = "$Bin/../public/data/iris_pourcentage_jeunes.csv" ;
open( my $fic, ">", $result) ;
print $fic "iris_id,pc_inscrits\n" ;

foreach my $k (keys(%irisHab)) {

	$req = <<SQL;
	SELECT 
		COUNT(borrowernumber) / $coeff / $irisHab{$k}
	FROM koha_prod.borrowers
	WHERE city = 'ROUBAIX'
		AND categorycode IN ('BIBL', 'CSVT', 'CSLT', 'MEDA', 'MEDB', 'MEDC')
		AND dateexpiry >= CURDATE()
		AND (YEAR(CURDATE()) - YEAR(dateofbirth)) < 20 AND (YEAR(CURDATE()) - YEAR(dateofbirth)) > 10
		AND altcontactcountry = $k
SQL
	$sth = $dbh->prepare($req);
	$sth->execute();
	my $count = $sth->fetchrow_array;
	my $arrondi = arrondi($count, 2) ;
	print $fic "$k,$arrondi\n" ;

}
$sth->finish();
close $fic ;
$dbh->disconnect();

sub arrondi{
    my $n = shift;
    my $precision = shift;
    return int((10**$precision)*$n + 0.5) / (10**$precision);
}
