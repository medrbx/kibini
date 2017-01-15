#! /usr/bin/perl

use strict ;
use warnings ;
use kibini::email ;
use utf8 ;

my $from = 'fpichenot@ville-roubaix.fr' ;
my $to = 'francois.pichenot@laposte.net' ;
my $subject = 'coucou hé hé' ;
my $msg = 'Bonjour François' ;

SendEmail($from, $to, $subject, $msg) ;