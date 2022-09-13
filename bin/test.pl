#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
#use Kibini::DB;

use kibini::email;

my $from = 'fpichenot@ville-roubaix.fr';
my $to = 'fpichenot@ville-roubaix.fr';
my $subject = 'test';
my $msg = 'le teste';

SendEmail($from, $to, $subject, $msg);