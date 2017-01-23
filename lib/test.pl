#! /usr/bin/perl

use strict ;
use warnings ;

use kibini::db ;
use kibini::Crypt ;

my $crypt = kibini::Crypt->new() ;

my $dbh = GetDbh() ;
my $req = "SELECT borrowernumber FROM koha_prod.borrowers" ;
my $sth = $dbh->prepare($req) ;
$sth->execute() ;
while ( my $borrowernumber = $sth->fetchrow_array() ) {
    $borrowernumber = $crypt->crypt($borrowernumber) ;
    print "$borrowernumber\n" ;
}
$sth->finish() ;
$dbh->disconnect() ;