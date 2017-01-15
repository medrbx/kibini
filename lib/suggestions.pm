package suggestions ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( suggestions modSuggestion suggestionInfos constructionCourriel acquereurs ) ;

use strict ;
use warnings ;
use LWP::UserAgent ;
use JSON ;
use REST::Client ;

use kibini::config ;
use kibini::config::koha ;


sub suggestions {
	# On récupère par webservice toutes les suggestions
    my $restUrl = GetKohaRestUrl() ;
	my $ws = $restUrl . "/suggestions?STATUS=asked" ;
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
	my $restUrl = GetKohaRestUrl() ;
	my $api = "/suggestions/$suggestionid" ;
	my $data = { managedby => $managedby } ;
	$data = encode_json $data ;
	$data = "data=".$data ;
	
	my $client = REST::Client->new(host => $restUrl);
	$client->PUT($api, $data );
}

sub acquereurs {
	my ($managedby, $title) = @_ ;
	my $conf = GetConfig('suggestions') ;
	my $acquereurs = $conf->{acquereur_id} ;
	return $acquereurs ;
}

# Obtenir des infos sur une suggestion
sub suggestionInfos {
	my ($suggestionid) = @_ ;
    my $restUrl = GetKohaRestUrl() ;
	my $ws = $restUrl . "/suggestions/$suggestionid" ;
	my $ua = LWP::UserAgent->new() ;
	my $request = HTTP::Request->new( GET => $ws ) ;
	my $rep = $ua->request($request)->{'_content'} ;
	my $suggestion = decode_json($rep);
	return $suggestion->{title} ; 
}

# On envoie un mail à l'acquéreur
sub constructionCourriel {
	my ($managedby, $title) = @_ ;
	my $conf = GetConfig('suggestions');
	my $acquereur_mail = $conf->{acquereur_mail} ;
	my %acquereur = %$acquereur_mail ;
	my $email = $acquereur{$managedby} . "\@ville-roubaix.fr" ;
    
    my $kohaPro =  GetKohaProUrl() ;
	
	my $from = "Koha suggestions<mediatheque\@ville-roubaix.fr" ;
	my $to = $email ;
	my $subject = "Nouvelle suggestion : $title" ;
	my $msg = "Nouvelle suggestion : $title\n\nVoir $kohaPro/cgi-bin/koha/suggestion/suggestion.pl#ASKED" ;
	return $from, $to, $subject, $msg ;
}

1;