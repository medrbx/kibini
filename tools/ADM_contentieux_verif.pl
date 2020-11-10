#!/usr/bin/perl

use Modern::Perl;
use utf8;
use Data::Dumper;
use Catmandu::Exporter::XLSX;
use MIME::Lite;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::log;
use kibini::time;

my $date = GetDateTime('today');
my $file_out = '/home/kibini/kibini_prod/data/verif_contentieux_' . $date . '.xlsx';

my $exporter = Catmandu::Exporter::XLSX->new(
    file => $file_out,
    fields => ['borrowernumber', 'cardnumber', 'categorycode', 'B_address', 'B_address2', 'rendu'],
    columns => 'id_adherent, code-barres, categorie, date_appel, resultat_appel, rendu',
    header => 1);

my $dbh = GetDbh();
my $req = <<SQL;
SELECT borrowernumber, cardnumber, categorycode, B_address, B_address2 
FROM koha_prod.borrowers b
WHERE B_address LIKE '202%'
ORDER BY B_address
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $req = <<SQL;
SELECT MIN(DATE(iss.date_due))
FROM koha_prod.issues iss
WHERE borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($row->{borrowernumber});
	$row->{date_due} = $sth->fetchrow_array;
	if ($row->{date_due}) {
		my $dt_date_due = DateTime::Format::MySQL->parse_date($row->{date_due});
		if ($row->{B_address}) {
			my $dt_date_appel = DateTime::Format::MySQL->parse_date($row->{B_address});
			my $cmp = DateTime->compare($dt_date_due, $dt_date_appel);
			if ($cmp < 0) {
				$row->{rendu} = 'non';
		    } else {
				$row->{rendu} = 'oui';
			}
		}
	} else {
		$row->{rendu} = 'oui';
	}
	 
	#print Dumper($row);
	$exporter->add($row);
}
$sth->finish();
