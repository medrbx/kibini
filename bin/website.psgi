#!/usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use website::dancer ;

website::dancer->dance ;