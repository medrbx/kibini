package salleEtude::statdb ;

=pod

=encoding UTF-8

=head1 NOM

salleEtude::stadb

=head1 DESCRIPTION

Ce module fournit des fonctions permettant de g�rer la table statdb.stat_freq_etude.

=cut

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( ModEntranceAddingData ) ;

use strict ;
use warnings ;

use kibini::db ;
use fonctions ;

=head1 FONCTIONS EXPORTEES
=cut

sub ModEntranceAddingData {
    my $dbh = GetDbh() ;

    # On r�cup�re l'ensemble des fr�quentants de la veille
    my $req = "SELECT DISTINCT cardnumber FROM statdb.stat_freq_etude WHERE DATE(datetime_entree) <= (CURDATE() - INTERVAL 1 DAY)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute();

    my $i = 0 ;
    while (my $cardnumber = $sth->fetchrow_array) {
	    # On cherche le borrowernumber, le sexe, l'�ge, la ville, l'iris et le type de carte
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
	
		    # On insert ces donn�es dans statdb.stat_freq_etude
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

=head1 FONCTIONS INTERNES
=cut

1;