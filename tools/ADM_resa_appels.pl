#!/usr/bin/perl

use Modern::Perl;
#use utf8;
use Data::Dumper;
use Catmandu::Exporter::XLSX;
use MIME::Lite;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::log;
use kibini::time;


my $date_veille = GetDateTime('yesterday');

my $file_out = '/bdc_roubaix/partage_media/0_COVID/Confinement_2/Réservations/usagers_a_appeler_pour_resas_' . $date_veille . '.xlsx';

my $exporter = Catmandu::Exporter::XLSX->new(
    file => $file_out,
    fields => ['cardnumber', 'surname', 'firstname', 'mobile', 'phone', 'koha'],
    columns => 'Carte, Nom, Prénom, Mobile, Fixe, Koha',
    header => 1);

my $dbh = GetDbh();
my $req = <<SQL;
SELECT
    cardnumber, surname, firstname, mobile, phone, borrowernumber
FROM koha_prod.borrowers b
WHERE email NOT LIKE '%@%' AND (mobile RLIKE '^[0-9]' OR phone RLIKE '^[0-9]')
AND borrowernumber IN (SELECT borrowernumber FROM koha_prod.reserves WHERE waitingdate = ? )
SQL

my $sth = $dbh->prepare($req);
$sth->execute($date_veille);
while (my $row = $sth->fetchrow_hashref) {
    $row->{'koha'} = "http://koha.ntrbx.local/cgi-bin/koha/circ/circulation.pl?borrowernumber=" . $row->{'borrowernumber'};
    $exporter->add($row);
    print Dumper($file_out);
}
$sth->finish();
