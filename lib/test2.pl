#! /usr/bin/perl

use strict ;
use warnings ;
use frequentationSalleEtude ;

use Data::Dumper ;
my $lecteurs = GetTodayEntrance() ;
print Dumper($lecteurs) ;
