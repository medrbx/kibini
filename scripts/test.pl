#!/usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/modules/" ;
use esrbx ;

my $es_node = es_node() ;
print "$es_node\n" ;