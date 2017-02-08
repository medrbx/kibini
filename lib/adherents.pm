package adherents ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetAgeLib GetCountVisitsByLoans ) ;

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