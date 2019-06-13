#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::Config;
use Kibini::DB;
use Kibini::Time;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;
my $req = "INSERT INTO statdb.stat_compteur_entrees (date_heure, nb_entrees) VALUES (?, ?)";
my $sth = $dbh->prepare($req);

my $time = Kibini::Time->new;
my $date = $time->get_date_and_time('yesterday YYYYMMDD');

my $conf = Kibini::Config->new->comptage;
my $directory = $conf->{directory};
my $file = $directory . "/" . $date . ".csv";

open(my $fh, '<:encoding(UTF-8)', $file);
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
            my $datetime = $year . "-" . $month . "-" . $day . " " . $hour . ":00:00";
            if ($count->{$datetime}) {
                $count->{$datetime} = $count->{$datetime} + $row->{entrees};
            } else {
                $count->{$datetime} = $row->{entrees};
            }
        }
    }
}

my @keys = sort keys %$count;
foreach my $k (@keys) {
    $sth->execute($k, $count->{$k});
}