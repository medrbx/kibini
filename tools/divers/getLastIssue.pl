#! /usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use Data::Dumper;

my $input = "getLastIssue.txt";

my $dbh = GetDbh();

open( my $fd, "<", $input );

while ( my $barcode = <$fd> ) {
	chomp $barcode;
	my $lastIssue = getLastIssue($dbh, $barcode);
	print "$lastIssue->{barcode}|$lastIssue->{issuedate}|$lastIssue->{cardnumber}\n" if ($lastIssue->{cardnumber}) ;
}

close $fd;
$dbh->disconnect;

sub getLastIssue {
	my ($dbh, $barcode) = @_;
	my $req = <<SQL;
SELECT
	iss.issuedate, b.cardnumber
FROM statdb.stat_issues iss
JOIN koha_prod.items i ON i.itemnumber = iss.itemnumber
JOIN koha_prod.borrowers b ON b.borrowernumber = iss.borrowernumber
WHERE i.barcode = ?
ORDER BY iss.issuedate DESC
LIMIT 1
SQL

	my $sth = $dbh->prepare($req);
	$sth->execute($barcode);
	my $lastIssue = {}; 
	$lastIssue = $sth->fetchrow_hashref;
	$sth->finish;
	
	$lastIssue->{barcode} = $barcode;
	
	return $lastIssue;
}