#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::Log;
use Exemplaire;

my $log = Kibini::Log->new;
my $process = "statdb_exemplaires.pl";
$log->add_log("$process : beginning");

my $dbh = Kibini::DB->new->dbh;

my @tables = qw( items deleteditems );
my $y = 0;
my $n = 0;
foreach my $table (@tables) {
    my $req = "SELECT itemnumber AS koha_itemnumber FROM koha_prod.$table WHERE DATE(timestamp) = CURDATE()-INTERVAL 1 DAY";
    my $sth = $dbh->prepare($req);
    $sth->execute;
    while (my $row = $sth->fetchrow_hashref) {
        my $ex = Exemplaire->new({ dbh=> $dbh, document => $row});
        $ex->get_exemplaire_from_koha_by_itemnumber;
        $ex->get_statdb_document_generic_data;
        my $res = $ex->isStatdb_item_idInStatdb;
        if ($res eq 'y') {
            $y++;
            $ex->get_statdb_item_annee_mise_pilon_from_statdb_data_exemplaires;
            $ex->update_data_in_statdb_data_exemplaires;
        } elsif ($res eq 'n') {
            $n++;
            $ex->add_data_to_statdb_data_exemplaires;
        }
    }
}

$log->add_log("$process : $n rows added");
$log->add_log("$process : $y rows updated");
$log->add_log("$process : ending\n");