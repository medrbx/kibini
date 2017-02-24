#!/usr/bin/perl

use strict;
use warnings ;
use JSON ;
use WWW::Mechanize;
use HTTP::Cookies ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile) ;
use Data::Dumper ;

use lib "$Bin/../lib" ;
use kibini::config ;
use kibini::db ;
use kibini::log ;
use kibini::time ;

my $log_message ;
my $process = "statdb_web.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupére les infos de connexion à Piwik
my $conf = GetConfig('piwik') ;
my $piwik_url_api = $conf->{url_api} ;
my $piwik_token_auth = $conf->{token_auth} ;

my $date_veille = GetDateTime('yesterday') ;
my $portail_veille_sessions = portail_veille_sessions($piwik_url_api, $piwik_token_auth, $date_veille) ;
insertWebSessions($date_veille, "site", $portail_veille_sessions);

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub portail_veille_sessions {
    my ($piwik_url_api, $piwik_token_auth, $date) = @_ ;
    my $method = "VisitsSummary.getVisits" ;
    my $idSite = "4" ;
    my $period = "day" ;
    my $format = "json" ;
    my $url_stat = "$piwik_url_api&method=$method&idSite=$idSite&period=$period&date=$date&format=$format&token_auth=$piwik_token_auth" ;
    
    my $mech = WWW::Mechanize->new(
        agent      => 'MedRbx',
        cookie_jar => HTTP::Cookies->new( autosave       => 1 )
    ) ;
    
    $mech->get($url_stat);
    my $result = $mech->response()->decoded_content() ;
    $result = decode_json $result ;
    my %result = %$result ;
    my $value = $result{'value'} ;
    
    return $value ;
}

sub insertWebSessions {
    my ( $date, $site, $nbSessions ) = @_ ;
    
    my $dbh = GetDbh() ;
    my $req = "INSERT INTO statdb.stat_web (date, site, nb_sessions) VALUES (?, ?, ?)" ;
    my $sth = $dbh->prepare($req) ;    
    $sth->execute($date, $site, $nbSessions ) ;
    $sth->finish() ;
    $dbh->disconnect() ;
}