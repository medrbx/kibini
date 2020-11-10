#! /usr/bin/perl

use Modern::Perl;
use LWP::UserAgent;
use Data::Dumper;

my $input = "b2del/xaz";
#my $input = "ADM_delete_borrowers_input_test.txt";

open( my $fd, "<", $input );

while ( my $userid = <$fd> ) {
	my $resp = delBorrower($userid);
	print Dumper($resp);
}

close $fd;

sub delBorrower {
    my ($userid) = @_;
    
    my $url = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/rest.pl";
    $url = $url . "/user/" . $userid;

    my $req = HTTP::Request->new('DELETE', $url);

    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);
    $resp = $resp->decoded_content;
    
    return $resp;
}