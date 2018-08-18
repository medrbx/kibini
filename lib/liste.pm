package liste ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetListRows GetListData TestParams) ;

use strict ;
use warnings ;
use utf8 ;
use LWP::UserAgent ;
use JSON qw( decode_json );

sub TestParams {
    my $params = @_;
    my $label = $params->{etage} . " - " . $params->{type};
    return $label;
}

sub GetListRows {
    my ($rapport ) = @_ ;
    my $ws = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report?id=$rapport" ;
    my $ua = LWP::UserAgent->new() ;
    my $request = HTTP::Request->new( GET => $ws ) ;
    my $rep = $ua->request($request)->{'_content'} ;
    my $rows = decode_json($rep);
    return $rows ;
}

sub GetListData {
    my ($type, $etage, $semaine ) = @_ ;
    
    my $key ;
    if ( $semaine eq 's0' ) {
        $key = $type . "_" . $etage ;
    } else {
        $key = $type . "_" . $etage . "_" . $semaine ;
    }
    
    my %titre = (
        "dispo_et0" => "Réservations sur documents disponibles, RDC",
        "dispo_et1" => "Réservations sur documents disponibles, 1er étage",
        "dispo_et2" => "Réservations sur documents disponibles, 2e étage",
        "dispo_et3" => "Réservations sur documents disponibles, 3e étage",
        "trait_et0" => "Réservations sur documents en traitement, RDC",
        "trait_et1" => "Réservations sur documents en traitement, 1er étage",
        "trait_et2" => "Réservations sur documents en traitement, 2e étage",
        "trait_et3" => "Réservations sur documents en traitement, 3e étage",
        "expir_sm" => "Réservations expirées, pour retrait Médiathèque, public",
		"expir_smp" => "Réservations expirées, pour retrait Médiathèque, personnel",
        "expir_sz" => "Réservations expirées, pour retrait Zèbre",
        "mcote_sgp" => "Réservations mises de côté",
        "perdu_et0_s1" => "Documents perdus depuis une semaine, RDC",
        "perdu_et1_s1" => "Documents perdus depuis une semaine, 1er étage",
        "perdu_et2_s1" => "Documents perdus depuis une semaine, 2e étage",
        "perdu_et3_s1" => "Documents perdus depuis une semaine, 3e étage",    
        "perdu_et0_s3" => "Documents perdus depuis trois semaines, RDC",
        "perdu_et1_s3" => "Documents perdus depuis trois semaines, 1er étage",
        "perdu_et2_s3" => "Documents perdus depuis trois semaines, 2e étage",
        "perdu_et3_s3" => "Documents perdus depuis trois semaines, 3e étage",
        "perdu_et0_s5" => "Documents perdus depuis cinq semaines, RDC",
        "perdu_et1_s5" => "Documents perdus depuis cinq semaines, 1er étage",
        "perdu_et2_s5" => "Documents perdus depuis cinq semaines, 2e étage",
        "perdu_et3_s5" => "Documents perdus depuis cinq semaines, 3e étage"
    ) ;

    my %rap = (
        "dispo_et0" => "128",
        "dispo_et1" => "131",
        "dispo_et2" => "132",
        "dispo_et3" => "133",
        "trait_et0" => "144",
        "trait_et1" => "145",
        "trait_et2" => "146",
        "trait_et3" => "147",
        "expir_sm" => "134",
		"expir_smp" => "198",
        "expir_sz" => "164",
        "mcote_sgp" => "135",
        "perdu_et0_s1" => "140",
        "perdu_et1_s1" => "141",
        "perdu_et2_s1" => "142",
        "perdu_et3_s1" => "143",    
        "perdu_et0_s1" => "149",
        "perdu_et1_s1" => "150",
        "perdu_et2_s1" => "151",
        "perdu_et3_s1" => "148",
        "perdu_et0_s1" => "152",
        "perdu_et1_s1" => "153",
        "perdu_et2_s1" => "154",
        "perdu_et3_s1" => "155"
    );

    my %template = (
        "dispo" => 'liste_reservations',
        "trait" => 'liste_reservations',
        "expir" => 'liste_reservations',        
        "mcote" => 'liste_reservations',
        "perdu" => 'liste_perdus'
    ) ;
    
    # On récupère le titre
    my $titre = $titre{$key} ;
    
    # On récupère le template
    my $template = $template{$type} ;
    
    # On récupère les lignes
    my $rapport = $rap{$key} ;
    my $ws = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report?id=$rapport" ;
    my $ua = LWP::UserAgent->new() ;
    my $request = HTTP::Request->new( GET => $ws ) ;
    my $rep = $ua->request($request)->{'_content'} ;
    my $rows = decode_json($rep);
    
    my @data = ($titre, $template, $rows) ;
    return @data ;
}

1;
