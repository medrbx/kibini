#! /usr/bin/perl

use strict ;
use warnings ;
use Data::Dumper ;

use kibini::config ;

my $conf = GetConfig('database') ;
print Dumper($conf) ;
