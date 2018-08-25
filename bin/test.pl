#!/usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Adherent;

my $adh = { statdb_sexe => 'H', koha_categorycode => 'TOT' };
my $adherent = Adherent->new( { adherent => $adh } );
$adherent->get_sex;

print Dumper($adherent);