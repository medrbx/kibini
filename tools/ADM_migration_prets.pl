#! /usr/bin/perl

use warnings;
use strict;
use utf8;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;

my $dbh = GetDbh();
my $req = "SELECT pret_id FROM statdb.stat_prets_1 WHERE pret_koha_id IS NULL";
my $sth = $dbh->prepare($req);
$sth->execute;

my $new_pret_koha_id = 90000000;
while (my $pret_id = $sth->fetchrow_array) {
    my $req = "UPDATE statdb.stat_prets_1 SET pret_koha_id = ? WHERE pret_id = ?";
    my $sth = $dbh->prepare($req);
    $sth->execute($new_pret_koha_id, $pret_id);
    $new_pret_koha_id++;
    print "$pret_id : $new_pret_koha_id\n";
}


