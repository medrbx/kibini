#! /usr/bin/perl

#use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::Config;

my $conf = Kibini::Config->new->comptage;
my $directory = $conf->{directory};
my $date = "20181130";
my $file = $directory . "/" . $date . ".csv";

# 05/12/2018, 00:00:00, 0, 0, 0, 0
open(my $fh, '<', $file);
my $in = 0;
my $out = 0;
while (my $row = <$fh>) {
    chomp $row;
    if ( $row =~ m/^\d{2}\/\d{2}\/\d{4}/ ) {
		my $count = {};
		($count->{day}, $count->{month}, $count->{year}, $count->{hour}, $count->{min_in}, $count->{min_out}) = ( $row =~ m/^(\d{2})\/(\d{2})\/(\d{4}),\s(\d{2}:\d{2}:\d{2}),\s(\d+),\s(\d+)/ );
		#if ( $count->{min_in} != 0 || $count->{min_out} != 0 ) {
			$in = $in + $count->{min_in};
            $out = $out + $count->{min_out};
            $count->{presents} = $in - $out;
		    print "$count->{hour}|$count->{presents}\n";
		#}
    }
}
close $fh;
