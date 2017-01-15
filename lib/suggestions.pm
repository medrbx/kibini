package suggestions ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( suggestions modSuggestion suggestionInfos constructionCourriel acquereurs ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin );
use YAML qw(LoadFile);
use LWP::UserAgent ;
use Encode qw(encode);
use JSON ;
use REST::Client ;


sub suggestions {
	# On récupère par webservice toutes les suggestions
	#my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/rest.pl/suggestions?suggestedby=3745" ;
	my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/rest.pl/suggestions?STATUS=asked" ;
	#my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/rest.pl/suggestions/2145" ;
	my $ua = LWP::UserAgent->new() ;
	my $request = HTTP::Request->new( GET => $ws ) ;
	my $rep = $ua->request($request)->{'_content'} ;
	my $suggestions = decode_json($rep);
	# pb : si une seule suggestion, koha ne renvoie pas un array mais directement un hash. On recrée donc un array d'un élément
	eval {
		my @sug = @$suggestions ;
	} ;
	if ($@) {
		my @suggestions ;
		push @suggestions, $suggestions ;
		$suggestions = \@suggestions ;
	}
	
	return $suggestions ;
}

sub modSuggestion {
	my ($suggestionid, $managedby) = @_ ;
	my $host = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/rest.pl" ;
	my $api = "/suggestions/$suggestionid" ;
	my $data = { managedby => $managedby } ;
	$data = encode_json $data ;
	$data = "data=".$data ;
	
	my $client = REST::Client->new(host => $host);
	$client->PUT($api, $data );
}

sub acquereurs {
	my ($managedby, $title) = @_ ;
	my $fic_conf = "$Bin/../etc/kibini_conf.yaml" ;
	my $conf = LoadFile($fic_conf);
	my $acquereurs = $conf->{suggestions}->{acquereur_id} ;
	return $acquereurs ;
}

# Obtenir des infos sur une suggestion
sub suggestionInfos {
	my ($suggestionid) = @_ ;
	my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/rest.pl/suggestions/$suggestionid" ;
	my $ua = LWP::UserAgent->new() ;
	my $request = HTTP::Request->new( GET => $ws ) ;
	my $rep = $ua->request($request)->{'_content'} ;
	my $suggestion = decode_json($rep);
	return $suggestion->{title} ; 
}

# On envoie un mail à l'acquéreur
sub constructionCourriel {
	my ($managedby, $title) = @_ ;
	my $fic_conf = "$Bin/../etc/kibini_conf.yaml" ;
	my $conf = LoadFile($fic_conf);
	my $acquereur_mail = $conf->{suggestions}->{acquereur_mail} ;
	my %acquereur = %$acquereur_mail ;
	my $email = $acquereur{$managedby} . "\@ville-roubaix.fr" ;
	
	my $from = "Koha suggestions<mediatheque\@ville-roubaix.fr" ;
	my $to = $email ;
	my $subject = "Nouvelle suggestion : $title" ;
	my $msg = "Nouvelle suggestion : $title\n\nVoir http://koha.ntrbx.local/cgi-bin/koha/suggestion/suggestion.pl#ASKED" ;
	return $from, $to, $subject, $msg ;
}

1;