package adherents::details ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetAgeLib GetCategoryDesc GetCountVisitsByLoans GetCardType GetCity15 GetRbxDistrict ) ;

use strict ;
use warnings ;

use kibini::db ;

sub GetAgeLib {
    my ($age, $lib) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT libelle FROM statdb.lib_age WHERE age = ? AND type = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($age, $lib);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCategoryDesc {
    my ($categorycode) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT description, category_type FROM koha_prod.categories WHERE categorycode = ? " ;
    my $sth = $dbh->prepare($req);
    $sth->execute($categorycode);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCountVisitsByLoans {
    my ($borrowernumber) = @_ ;
    my $dbh = GetDbh() ;
    my $req = <<SQL ;
SELECT
    COUNT(DISTINCT DATE(issuedate))
FROM statdb.stat_issues
WHERE DATE(issuedate) >= CURDATE() - INTERVAL 1 YEAR
    AND borrowernumber = ?
GROUP BY borrowernumber
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCardType {
    my ( $categorycode ) = @_ ;
    my $type_carte ;
    if ($categorycode eq "BIBL" ) { $type_carte = "Médiathèque" ; }
    my @liste = qw( MEDA MEDB MEDC CSVT MEDP ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Médiathèque Plus" ; }
    if ($categorycode eq "CSLT" ) { $type_carte = "Consultation sur place" ; }
    @liste = qw( COLI COLD ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Prêt en nombre" ; }
    @liste = qw( ECOL CLAS  ) ;
    if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Structures scolaires" ; }
    if ($categorycode eq "COLS" ) { $type_carte = "Structures non scolaires" ; }
    return $type_carte ;
}

sub GetCity15 {
    my ( $city ) = @_ ;
    my $ville15 ;
    my @liste = qw( CROIX HEM LEERS LILLE LYS-LEZ-LANNOY MARCQ-EN-BAROEUL MONS-EN-BAROEUL MOUVAUX NEUVILLE-EN-FERRAIN ROUBAIX TOUFFLERS TOURCOING VILLENEUVE-D'ASCQ WASQUEHAL WATTRELOS ) ;
    if ( grep {$_ eq $city} @liste ) {
        $ville15 = $city ;
    } else {
        $ville15 = "AUTRE" ;
    }
    return $ville15 ;
}

sub GetRbxDistrict {
    my ($iris) = @_ ;
    my $bdd = "statdb" ;
    my $dbh = dbh($bdd) ;
    my $req = "SELECT irisNom, quartier FROM iris_lib WHERE irisInsee = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($iris);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

1 ;
