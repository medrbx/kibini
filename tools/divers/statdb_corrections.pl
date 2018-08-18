#!/usr/bin/perl

use strict ;
use warnings ;
use Data::Dumper;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;

my $dbh = GetDbh() ;
my $req = <<SQL;
SELECT
	issuedate,
	biblionumber,
	itemnumber,
	ccode,
	itemcallnumber,
	DATE(`timestamp`) as date_modif
FROM statdb.stat_issues
WHERE ccode LIKE 'JCI%'
ORDER BY itemcallnumber
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while (my $issue = $sth->fetchrow_hashref) {
	my $resp = ModIssue($dbh, $issue->{itemnumber}) ;
	print "$issue->{issuedate} - $issue->{itemnumber} : $resp\n" ;
	
}

$sth->finish();
$dbh->disconnect();

sub ModIssue {
	my ($dbh, $itemnumber) = @_ ;
	my $req = <<SQL;
UPDATE statdb.stat_issues iss
JOIN koha_prod.items i ON iss.itemnumber = i.itemnumber
SET
	iss.ccode = i.ccode,
	iss.itemcallnumber = i.itemcallnumber
WHERE iss.itemnumber = ?
SQL
	my $sth = $dbh->prepare($req);
	my $resp = $sth->execute($itemnumber);
	return $resp ;
}