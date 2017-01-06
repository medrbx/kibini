#! /usr/bin/perl

use strict ;
use warnings ;
use Kibini::DB ;

use Data::Dumper ;

my $dbh = Kibini::DB->new()->get_dbh() ; #->get_conf_database()->get_dbh() ;
my $sth = $dbh->prepare('SELECT city FROM koha_prod.borrowers WHERE borrowernumber = 3745') ;
$sth->execute() ;
my $city = $sth->fetchrow_array() ;


print "$city\n" ;

#my $o = Kibini::Config->new('database')->get_conf() ;
#print Dumper($o) ;