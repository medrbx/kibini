#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use FindBin qw( $Bin ) ;
use Data::Dumper ;

use lib "$Bin/../lib" ;
use kibini::db ;


my $dbh = GetDbh() ;

my $req = <<SQL;
SELECT issue_id, DATE(returndate) as returndate, borrowernumber, itemnumber
FROM statdb.stat_issues
ORDER BY returndate DESC
SQL
my $sth = $dbh->prepare($req) ;
$sth->execute() ;
while ( my $return = $sth->fetchrow_hashref ) {
	$return->{returnbranch} = GetReturnBranch($dbh, $return) ;
	AddReturnBranch($dbh, $return) ;
	print Dumper($return) ;
}



sub GetReturnBranch {
	my ($dbh, $return) = @_ ;
	my $req = "SELECT branch FROM koha_prod.statistics WHERE DATE(datetime) = ? AND borrowernumber = ? AND itemnumber = ? AND type = 'return'" ;
	my $sth = $dbh->prepare($req) ;
	$sth->execute($return->{returndate}, $return->{borrowernumber}, $return->{itemnumber}) ;
	my $returnbranch = $sth->fetchrow_array ;
	$sth->finish ;
	
	return $returnbranch ;	
}

sub AddReturnBranch {
	my ($dbh, $return) = @_ ;
	my $req = "UPDATE statdb.stat_issues SET returnbranch = ? WHERE issue_id = ?" ;
	my $sth = $dbh->prepare($req) ;
	$sth->execute($return->{returnbranch}, $return->{issue_id}) ;
	$sth->finish ;
}