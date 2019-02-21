#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin";
use Exemplaire;


my $ex = Exemplaire->new({ document => {koha_itemnumber => '107926'}});
my $req = $ex->get_exemplaire_from_koha;

print Dumper($req);