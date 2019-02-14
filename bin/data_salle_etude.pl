#!/usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Kibini::Log;
use SalleEtude;

my $log = Kibini::Log->new;
my $process = "statdb_freq_etude.pl";
# On log le début de l'opération
$log->add_log("$process : beginning");

# On complète les données
my $crypter = Kibini::Crypt->new;
my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;
my $req = "SELECT id AS consultation_id, cardnumber AS koha_cardnumber, datetime_entree AS consultation_date_heure_entree, datetime_sortie AS consultation_date_heure_sortie FROM statdb.stat_freq_etude WHERE DATE(datetime_entree) >= (CURDATE() - INTERVAL 21 DAY)";
my $sth = $dbh->prepare($req);
$sth->execute();

my $i = 0;
while (my $row = $sth->fetchrow_hashref) {
    my $se = SalleEtude->new( { dbh => $dbh, crypter => $crypter, se => $row } );
    $se->get_seuser_from_koha;
    $se->get_seuser_data;
    print Dumper($se);  
    $i++;
}

# On log la fin de l'opération
$log->add_log("$process : $i rows modified");
$log->add_log("$process : ending\n");
