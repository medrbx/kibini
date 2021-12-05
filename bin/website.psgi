#!/usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use website::dancer;

website::dancer->dance;
