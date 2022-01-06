#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use Data::Dumper;

my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    eol => "\r\n"
});

open(my $fd,">:encoding(utf8)","toto");
