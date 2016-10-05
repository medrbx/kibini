#!/usr/bin/perl

use strict;
use warnings ;
use JSON ;
use WWW::Mechanize;
use HTTP::Cookies ;
use DateTime ;
use DateTime::Format::MySQL ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile) ;
use Data::Dumper ;

use lib "$Bin/modules/" ;
use dbrequest ;
use fonctions ;

# On récupère les infos de connexion à Piwik
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $piwik_url_api = $conf->{piwik}->{url_api} ;
my $piwik_token_auth = $conf->{piwik}->{token_auth} ;

my $date_veille = date_veille() ;
my $portail_veille_sessions = portail_veille_sessions($piwik_url_api, $piwik_token_auth, $date_veille) ;
print "$portail_veille_sessions\n" ;
insertWebSessions($date_veille, "site", $portail_veille_sessions);


sub portail_veille_sessions {
	my ($piwik_url_api, $piwik_token_auth, $date) = @_ ;
	my $method = "VisitsSummary.getVisits" ;
	my $idSite = "4" ;
	my $period = "day" ;
	# my $date = "2015-09-08,2016-09-12" ;
	my $format = "json" ;
	my $url_stat = "$piwik_url_api&method=$method&idSite=$idSite&period=$period&date=$date&format=$format&token_auth=$piwik_token_auth" ;
	
	my $mech = WWW::Mechanize->new(
		agent      => => 'MedRbx',
		cookie_jar => HTTP::Cookies->new( autosave       => 1 )
	) ;
	
	$mech->get($url_stat);
	my $result = $mech->response()->decoded_content() ;
	$result = decode_json $result ;
	my %result = %$result ;
	my $value = $result{'value'} ;
	return $value ;
	#return $result ;
}

sub insertWebSessions {
	my ( $date, $site, $nbSessions ) = @_ ;
	
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = "INSERT INTO stat_web (date, site, nb_sessions) VALUES (?, ?, ?)" ;
	my $sth = $dbh->prepare($req) ;	
	$sth->execute($date, $site, $nbSessions ) ;
	$sth->finish() ;
	$dbh->disconnect() ;
}