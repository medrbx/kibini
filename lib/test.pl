#! /usr/bin/perl

use strict ;
use warnings ;

use kibini::config::koha ;

my $k = GetKohaRestUrl() ;
print "$k\n" ;
