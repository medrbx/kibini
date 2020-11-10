#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;

my $file = "non_restitues_20200630.csv";
my $exporter = Catmandu->exporter("CSV", file => $file);

my $dbh = Kibini::DB->new->dbh;

carte_ok($dbh);
carte_ko($dbh);

$dbh->disconnect();



sub carte_ok {
    my ($dbh) = @_;
  
    my $req = <<SQL;
SELECT
    'carte_OK' AS statut_carte,
    i.location AS localisation,
    i.itemnumber AS itemnumber,
    i.barcode AS barcode,
    DATE(iss.issuedate) AS date_pret,
    'NP' AS date_retour,
    'koha_prod' AS bdd,    
    iss.borrowernumber AS borrowernumber,
    b.cardnumber AS cardnumber,
    b.categorycode AS categorycode,
    b.surname AS prenom,
    b.firstname AS nom
FROM koha_prod.items i
JOIN koha_prod.issues iss ON iss.itemnumber = i.itemnumber
JOIN koha_prod.borrowers b ON b.borrowernumber = iss.borrowernumber
WHERE
    i.notforloan = 0
    AND i.itemlost = 1
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $item = $sth->fetchrow_hashref ) {
        my $biblio_data = biblio_data($dbh, $item->{itemnumber});
		foreach my $k (keys %$biblio_data) {
			$item->{$k} = $biblio_data->{$k};
		}
		$item->{isTp} = isTp($dbh, $item->{borrowernumber});
        $exporter->add($item);
    }
    $sth->finish();
}

sub carte_ko {
    my ($dbh, $fd, $csv) = @_;
  
    my $req = <<SQL;
SELECT
    'carte_KO' AS statut_carte,
    i.location AS localisation,
    i.itemnumber AS itemnumber,
    i.barcode AS barcode
FROM koha_prod.items i
WHERE
    i.notforloan = 0
    AND i.itemlost = 1
    AND i.itemnumber NOT IN (SELECT itemnumber FROM koha_prod.issues)
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $item = $sth->fetchrow_hashref ) {
        ($item->{date_pret}, $item->{date_retour}) = last_loan($dbh, $item->{itemnumber});
        my $borrower = accountlines($dbh, $item->{itemnumber});
		foreach my $k (keys %$borrower) {
			$item->{$k} = $borrower->{$k};
		}
		if ($item->{borrowernumber} ne 'N/A') {
		    $item->{isTp} = isTp($dbh, $item->{borrowernumber});
		}
        my $biblio_data = biblio_data($dbh, $item->{itemnumber});
		foreach my $k (keys %$biblio_data) {
			$item->{$k} = $biblio_data->{$k};
		}
		$exporter->add($item);
		print Dumper($item);
    }
    $sth->finish();
}

sub isTp {
    my ($dbh, $borrowernumber) = @_;
  
    my $req = <<SQL;
SELECT COUNT(*)
FROM koha_prod.borrower_debarments
WHERE comment LIKE '%sor publi%'
AND borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
	my $count = $sth->fetchrow_array();
	my $isTp;
	if ( $count > 0 ) {
		$isTp = 1;
	} else {
	    $isTp = 0;
	}
    $sth->finish();
	return $isTp;
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

    my $borrower = {};

    my $sth = $dbh->prepare($req1);
    $sth->execute($itemnumber);
    my $borrowernumber = $sth->fetchrow_array;
    $sth->finish();
    
    if ( defined $borrowernumber ) {
        my $db = "koha_prod";
        $borrower = borrower($dbh, $borrowernumber, $db);
        $borrower->{bdd} = 'koha_prod';
    } else {
        $sth = $dbh->prepare($req2);
        $sth->execute($itemnumber);
        $borrowernumber = $sth->fetchrow_array;
        if ( defined $borrowernumber ) {
            my $db = "koha2016";
            $borrower = borrower($dbh, $borrowernumber, $db);
            $borrower->{bdd} = 'koha2016';
        } else {
			$borrower->{bdd} = 'N/A';
			$borrower->{borrowernumber} = 'N/A';
			$borrower->{cardnumber} = 'N/A';
			$borrower->{categorycode} = 'N/A';
			$borrower->{surname} = 'N/A';
			$borrower->{firstname} = 'N/A';
        }        
        $sth->finish(); 
    }        
    return $borrower;
}

sub borrower {
    my ($dbh, $borrowernumber, $db) = @_;
    my $req = <<SQL;
SELECT
    borrowernumber,
    cardnumber,
    surname,
    firstname
FROM $db.borrowers i
WHERE
    borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber);
    return $sth->fetchrow_hashref;
    $sth->finish();
}

sub biblio_data {
    my ($dbh, $itemnumber) = @_;
    my $req = <<SQL;
SELECT
    i.ccode,
    c.lib AS lib_ccode,
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
    return $sth->fetchrow_hashref;
    $sth->finish();
}