#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Adherent;

my $adh = { koha_borrowernumber => 3745 };


my $adherent = Adherent->new( { adherent => $adh } );
print Dumper($adherent);