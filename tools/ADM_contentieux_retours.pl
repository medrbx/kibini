#! /usr/bin/perl;

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
my $file_out = '/home/kibini/kibini_prod/data/verif_contentieux_retours' . $date . '.xlsx';

my $exporter = Catmandu::Exporter::XLSX->new(
    file => $file_out,
    fields => ['borrowernumber', 'cardnumber', 'barcode', 'B_country', 'returndate'],
    columns => 'id_adherent, code-barres_lecteur, code-barres_document, date_creation_titre, date_retour',
    header => 1);

my $dbh = GetDbh();
my $req = <<SQL;
SELECT oi.borrowernumber, b.cardnumber, i.barcode, b.B_country, DATE(oi.returndate)
FROM koha_prod.old_issues oi
JOIN koha_prod.borrowers b ON b.borrowernumber = oi.borrowernumber
LEFT JOIN koha_prod.items i ON i.itemnumber = oi.itemnumber
WHERE YEAR(oi.returndate) = YEAR(CURDATE()) AND b.B_country LIKE '20%'
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	print Dumper($row);
	$exporter->add($row);
}