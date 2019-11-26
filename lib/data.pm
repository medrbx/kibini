package data;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( getArretsZebre ) ;

use FindBin qw( $Bin );

use lib "$Bin/../lib" ;
use Kibini::DB;

sub getArretsZebre {
	my $result;

	my $dbh = Kibini::DB->new;
    $dbh = $dbh->dbh;
	
	my $req = "SELECT idDesserte, typeDesserte, nomDesserte, adresseDesserte, jourDesserte, HeureDesserte, XDesserte, Ydesserte, irisInseeDesserte, statutDesserte, dateMaJDesserte FROM statdb.geo_arrets_bus";
	my $sth = $dbh->prepare($req);
	$sth->execute;
	while ( my $row = $sth->fetchrow_hashref) {
		push @{$result}, $row;
	}
	
	return $result;
}