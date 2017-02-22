#! /usr/bin/perl
use strict ;
use warnings ;
use kibini::crypt ;

my $borrowernumber = 3745 ;
my $toto = kibini::crypt->crypt($borrowernumber) ;

print "$toto\n" ;