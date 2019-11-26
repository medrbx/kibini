#! /usr/bin/perl

use Modern::Perl;

my $str = "51.22%";
my ($to_keep) = ( $str =~ m/^(\d+)(.*)/ );
print "$to_keep\n";