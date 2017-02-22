package salleEtude::statdb ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( ModEntranceAddingData ) ;

use strict ;
use warnings ;

use kibini::db ;

sub ModEntranceAddingData {
    my $dbh = GetDbh() ;

    # On récupère l'ensemble des fréquentants de la dernière semaine
    my $req = "SELECT DISTINCT cardnumber FROM statdb.stat_freq_etude WHERE DATE(datetime_entree) >= (CURDATE() - INTERVAL 7 DAY)" ;
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
	
	return $i ;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NOM

salleEtude::stadb

=head1 DESCRIPTION

Ce module fournit des fonctions permettant de gérer la table statdb.stat_freq_etude.

=cut