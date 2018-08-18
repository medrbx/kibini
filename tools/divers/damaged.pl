#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use FindBin qw( $Bin ) ;
use Data::Dumper ;

use lib "$Bin/../lib" ;
use kibini::db ;
use collections::poldoc ;


my $csv = Text::CSV->new ({
    binary    => 1,
    eol => "\r\n"
});
open(my $fd,">:encoding(utf8)","damaged_jeunesse.csv") ;
my @column_names = ("code-barres", "date création exemplaire", "date dernier retour exemplaire", "nb prêts", "code collection", "lib1", "lib2", "lib3", "lib4",  ) ; #, "nb retours mensuels pour collection") ;
$csv->print ($fd, \@column_names) ;

my $dbh = GetDbh() ;
#my $returns = GetReturns($dbh) ;
my @tables = qw( items deleteditems ) ;
foreach my $table (@tables) {
	my $req = <<SQL;
SELECT k.barcode, k.itemnumber, k.dateaccessioned, k.issues, ccode
FROM koha_prod.$table k
WHERE notforloan = 4 AND damaged = 1 AND ccode LIKE 'J%' AND location LIKE 'MED2%'
SQL
	my $sth = $dbh->prepare($req) ;
	$sth->execute() ;
    while ( my $item = $sth->fetchrow_hashref ) {
		$item->{last_return} = GetLastReturnDate($dbh, $item->{itemnumber}) ;
		($item->{collection}->{lib1}, $item->{collection}->{lib2}, $item->{collection}->{lib3}, $item->{collection}->{lib4} ) = GetCcodeLibLevels($item->{ccode}) ;
		#$item->{return_month_ccode} = $returns->{$item->{last_return}->{year_month}}->{$item->{ccode}} ;
	    my @row = ( $item->{barcode}, $item->{dateaccessioned}, $item->{last_return}->{year_month}, $item->{issues}, $item->{ccode}, $item->{collection}->{lib1}, $item->{collection}->{lib2}, $item->{collection}->{lib3}, $item->{collection}->{lib4} ) ;
		$csv->print ($fd, \@row);
		print Dumper($item) ;
    }
}

close $fd ;




sub GetLastReturnDate {
	my ($dbh, $itemnumber) = @_ ;
	
	my $req = "SELECT DATE(MAX(returndate)) FROM statdb.stat_issues WHERE itemnumber = ?" ;
	my $sth = $dbh->prepare($req) ;
	$sth->execute($itemnumber) ;
	my $date = $sth->fetchrow_array ;
	$sth->finish ;
	
	my $year_month = substr $date, 0, 7 ;
	
	my $last_return = {
		date => $date,
		year_month => $year_month
	} ;
	
	return $last_return ;
}


sub GetReturns {
	my ($dbh) = @_ ;
	my $returns = {} ;
	my $req = <<SQL;
SELECT SUBSTRING(returndate, 1, 7) AS return_month, ccode, COUNT(itemnumber) as nb_returns
FROM statdb.stat_issues
WHERE location LIKE 'MED2%' AND returndate IS NOT NULL AND ccode IS NOT NULL
GROUP BY SUBSTRING(returndate, 1, 7), ccode
SQL
	my $sth = $dbh->prepare($req) ;
	$sth->execute() ;
    while ( my $count = $sth->fetchrow_hashref ) {
		$returns->{$count->{return_month}}->{$count->{ccode}} = $count->{nb_returns} ;
	}
	$sth->finish ;
	
	return $returns ;
}