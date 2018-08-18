#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Adherent::Diffusion;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $req = "SELECT * FROM statdb.stat_adherents WHERE DATE(date_extraction) = '2018-04-25' LIMIT 1";
my $sth = $dbh->prepare($req);
$sth->execute;
while (my $adh = $sth->fetchrow_hashref) {
    my $adherent = Adherent::Diffusion->new( { dbh => $dbh, adherent => $adh } );
    my $data_to_diff = $adherent->prepare_data_to_diff;
    print Dumper($data_to_diff);
}
