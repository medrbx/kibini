#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Adherent::StatDB;


my $dbh = "toto";
my $adh = { sexe => 'M', age => 37 };
my @args = ( { dbh => $dbh, adherent => $adh } );

my $adherent = Adherent::StatDB->new( { dbh => $dbh, adherent => $adh } );
print Dumper($adherent);
