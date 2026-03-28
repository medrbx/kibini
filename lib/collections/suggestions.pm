package collections::suggestions ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( suggestions suggestions2 modSuggestion modSuggestion2 constructionCourriel acquereurs ) ;

use strict ;
use warnings ;
use LWP::UserAgent ;
use JSON ;
use REST::Client ;
use MIME::Base64 ;

use kibini::config ;
use kibini::config::koha ;

use Data::Dumper;


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

sub suggestions2 {
    # On récupère par webservice toutes les suggestions
	my $user = GetKohaAuthUser() ;
	my $pwd = GetKohaAuthPwd() ;
	my $auth = 'Basic ' . encode_base64("$user:$pwd");
	my $url = GetKohaOpacUrl() ;
    $url = $url . "/api/v1/suggestions?_per_page=1000" ;
	
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get(
		$url,
		'Authorization' => $auth,
		'x-koha-query' => '{ "status": "ASKED"}'
	) ;
	my $rep = $response->decoded_content ;
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
    
	my $acquereurs = acquereurs() ;
	my @suggestions2 ;
	foreach my $suggestion (@$suggestions) {
		if (exists $acquereurs->{$suggestion->{managed_by}}) {
            $suggestion->{firstnamemanagedby} = $acquereurs->{$suggestion->{managed_by}};
        }
		push @suggestions2, $suggestion ;
	}
	
    return \@suggestions2 ;
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

sub modSuggestion2 {
    my ($suggestionid, $managedby) = @_ ;
	
	my $user = GetKohaAuthUser() ;
	my $pwd = GetKohaAuthPwd() ;
	my $auth = 'Basic ' . encode_base64("$user:$pwd");
	my $url = GetKohaOpacUrl() ;
	$url = $url . "/api/v1/suggestions/$suggestionid" ;
	my $data = { managed_by => $managedby } ;
    $data = encode_json $data ;
	
	my $ua = LWP::UserAgent->new;
	my $response = $ua->put(
		$url,
		'Authorization' => $auth,
        'Content-Type' => 'application/json',
        'Content'      => $data
    );
	
}

sub acquereurs {
    my ($managedby, $title) = @_ ;
    my $conf = GetConfig('suggestions') ;
    my $acquereurs = $conf->{acquereur_id} ;
    return $acquereurs ;
}

#Obtenir des infos sur une suggestion
# sub suggestionInfos {
    # my ($suggestionid) = @_ ;
    # my $restUrl = GetKohaRestUrl() ;
    # my $ws = $restUrl . "/suggestions/$suggestionid" ;
    # my $ua = LWP::UserAgent->new() ;
    # my $request = HTTP::Request->new( GET => $ws ) ;
    # my $rep = $ua->request($request)->{'_content'} ;
    # my $suggestion = decode_json($rep);
    # return $suggestion->{title} ; 
# }

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
