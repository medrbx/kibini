#! /usr/bin/perl

use Modern::Perl;
use Text::CSV;
use Data::Dumper;
use FindBin qw( $Bin );


use lib "$Bin/../lib";
use Kibini::DB;

my $file = "non_restitues_verif_prets_20190816.csv";
open(my $fd,">:encoding(utf8)","$file");

my $dbh = Kibini::DB->new->dbh;
my $csv = Text::CSV->new ({
    binary    => 1,
    eol => "\r\n"
});

my $req = <<SQL;
SELECT borrowernumber
FROM koha_prod.borrower_debarments
WHERE comment LIKE '%sor public%'
AND borrowernumber NOT IN (SELECT borrowernumber FROM koha_prod.issues)
ORDER BY borrowernumber DESC
SQL
my $sth = $dbh->prepare($req);
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	print Dumper(\@row);
}
$sth->finish();


__END__

my @column_names = qw(carte location itemnumber barcode notforloan issuedate returndate borrower borrowernumber cardnumber surname firstname ccode lib_ccode title author price);
$csv->print ($fd, \@column_names);
carte_ok($dbh, $fd, $csv);
carte_ko($dbh, $fd, $csv);

close $fd;
$dbh->disconnect();



sub carte_ok {
    my ($dbh, $fd, $csv) = @_;
  
    my $req = <<SQL;
SELECT
	'carte_OK',
    i.location,
    i.itemnumber,
	i.barcode,
    i.notforloan,
	DATE(iss.issuedate),
	'NP',
    'koha_prod',
    iss.borrowernumber,
    b.cardnumber,
    b.surname,
    b.firstname
FROM koha_prod.items i
JOIN koha_prod.issues iss ON iss.itemnumber = i.itemnumber
JOIN koha_prod.borrowers b ON b.borrowernumber = iss.borrowernumber
WHERE
	i.notforloan = 0
	AND i.itemlost = 1
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my @row = $sth->fetchrow_array ) {
        my $itemnumber = $row[2];
        my @biblio_data = biblio_data($dbh, $itemnumber);
        push @row, @biblio_data;    
        $csv->print ($fd, \@row);
    }
    $sth->finish();
}

sub carte_ko {
    my ($dbh, $fd, $csv) = @_;
  
    my $req = <<SQL;
SELECT
	'carte_KO',
    i.location,
    i.itemnumber,
	i.barcode,
    i.notforloan
FROM koha_prod.items i
WHERE
	i.notforloan = 0
	AND i.itemlost = 1
    AND i.itemnumber NOT IN (SELECT itemnumber FROM koha_prod.issues)
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my @row = $sth->fetchrow_array ) {
        my $itemnumber = $row[2];
        my @last_loan = last_loan($dbh, $itemnumber);
        push @row, @last_loan;
        my @borrower = accountlines($dbh, $itemnumber);
        push @row, @borrower;
        my @biblio_data = biblio_data($dbh, $itemnumber);
        push @row, @biblio_data;
        $csv->print ($fd, \@row);
    }
    $sth->finish();
}

sub last_loan {
    my ($dbh, $itemnumber) = @_;
    my $req = <<SQL;
SELECT
    DATE(MAX(issuedate)),
    DATE(MAX(returndate))
FROM koha_prod.old_issues i
WHERE
	itemnumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber);
    return $sth->fetchrow_array;
    $sth->finish();
}

sub accountlines {
    my ($dbh, $itemnumber) = @_;
    
    my $req1 = <<SQL;
SELECT borrowernumber
FROM koha_prod.accountlines
WHERE
	itemnumber = ?
    AND accounttype = 'L'
SQL

    my $req2 = <<SQL;
SELECT borrowernumber
FROM koha_prod.accountlines
WHERE
	itemnumber = ?
    AND accounttype = 'L'
SQL

    my @borrower;

    my $sth = $dbh->prepare($req1);
    $sth->execute($itemnumber);
    my $borrowernumber = $sth->fetchrow_array;
    $sth->finish();
    
    if ( defined $borrowernumber ) {
        my $db = "koha_prod";
        my @b_data = borrower($dbh, $borrowernumber, $db);
        @borrower = ( 'koha_prod', $borrowernumber, @b_data );
    } else {
        $sth = $dbh->prepare($req2);
        $sth->execute($itemnumber);
        $borrowernumber = $sth->fetchrow_array;
        if ( defined $borrowernumber ) {
            my $db = "koha2016";
            my @b_data = borrower($dbh, $borrowernumber, $db);
            @borrower = ( 'koha2016', $borrowernumber, @b_data );
        } else {
            @borrower = ( 'inconnu', 'inconnu' );
        }        
        $sth->finish(); 
    }        
    return @borrower;
}

sub borrower {
    my ($dbh, $borrowernumber, $db) = @_;
    my $req = <<SQL;
SELECT
    cardnumber,
    surname,
    firstname
FROM $db.borrowers i
WHERE
	borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
    return $sth->fetchrow_array;
    $sth->finish();
}

sub biblio_data {
    my ($dbh, $itemnumber) = @_;
    my $req = <<SQL;
SELECT
    i.ccode,
    c.lib,
    b.title,
    b.author,
    i.price
FROM koha_prod.items i
JOIN statdb.lib_collections2 c ON i.ccode = c.ccode
JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
WHERE
	itemnumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber);
    return $sth->fetchrow_array;
    $sth->finish();
}