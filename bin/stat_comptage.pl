#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;

my $filename = "/home/kibini/comptage/20190607.csv";
open(my $fh, '<:encoding(UTF-8)', $filename);
my $count = {};
while (my $string = <$fh>) {
	chomp $string;
	if ( $string =~ m/\d{2}\/\d{2}\/\d{4}/ ) {
		$string =~ s/\s+//g;
		my $row = {};
		($row->{date}, $row->{heure}, $row->{entrees}, $row->{sorties} ) = split /,/, $string;
		if ( $row->{entrees} != 0 ) {
			my ($day, $month, $year) = split /\//, $row->{date};
			my $hour = substr($row->{heure}, 0, 2);
			my $datetime = $year . "-" . $month . "-" . $day . " " . $hour . ":00:00" ;
			if ($count->{$datetime}) {
				$count->{$datetime} = $count->{$datetime} + $row->{entrees};
			} else {
			    $count->{$datetime} = $row->{entrees};
			}
		}
	}
}
print Dumper($count);