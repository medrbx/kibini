#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;
use Data::Dumper ;

use lib "$Bin/modules/" ;
use frequentation ;

my $lecteurs_presents = lecteurs_presents() ;
print Dumper($lecteurs_presents) ;
