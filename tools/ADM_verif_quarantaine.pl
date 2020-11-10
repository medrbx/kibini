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


my $date_veille = GetDateTime('yesterday');

my $file_out = '/bdc_roubaix/partage_media/Collections/Quarantaine/verif_quarantaine_' . $date_veille . '.xlsx';

my $exporter = Catmandu::Exporter::XLSX->new(
    file => $file_out,
    fields => ['itemnumber', 'barcode', 'returndate', 'dateaccessioned', 'permanent_location', 'itemcallnumber'],
    columns => 'id_exemplaire, code-barres, date_retour, date_creation_exemplaire, localisation, cote',
    header => 1);

my $dbh = GetDbh();
my $req = <<SQL;
SELECT i.barcode, i.itemnumber, i.dateaccessioned, i.permanent_location, i.itemcallnumber
FROM koha_prod.items i
WHERE i.location = 'CART'
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $req = <<SQL;
SELECT MAX(DATE(iss.returndate))
FROM koha_prod.old_issues iss
WHERE itemnumber = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($row->{itemnumber});
	$row->{returndate} = $sth->fetchrow_array;
	print Dumper($row);
	$exporter->add($row);
}
$sth->finish(); 