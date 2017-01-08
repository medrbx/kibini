#! /usr/bin/perl 

use strict ;
use warnings ;
use Data::Dumper ;

use kibini::time ;

my $datetime2 = "2017-01-08 00:28:53" ;
my $datetime1 = "2017-01-07 10:28:54" ;

my $duration = GetDuration($datetime1, $datetime2, 'hours');
print Dumper($duration) ;