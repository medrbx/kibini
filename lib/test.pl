#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin";

use liste;
use Data::Dumper;
use LWP::UserAgent ;
use JSON qw( decode_json );

my %params = (type => "d", loc => "0", public => "a");
#print Dumper(\%params);

my $date = "2020-10-30";
my $report_id = "179";
my $url = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/svc/report";
$url = $url . "?id=" . $report_id . "&sql_params=" . $date;
my $ua = LWP::UserAgent->new();
my $request = HTTP::Request->new( GET => $url );
my $rep = $ua->request($request)->{'_content'};

print Dumper($rep);
#my $rows = decode_json($rep);

	