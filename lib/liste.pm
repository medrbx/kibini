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
    my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/svc/report?id=$rapport" ;
    my $ua = LWP::UserAgent->new() ;
    my $request = HTTP::Request->new( GET => $ws ) ;
    my $rep = $ua->request($request)->{'_content'} ;
    my $rows = decode_json($rep);
    return $rows ;
}

sub GetListData {
    my ($params) = @_;
    
    my @p = qw ( type loc public wk resbranch );
    foreach my $p (@p) {
        $params->{$p} = 'z' if ( !defined $params->{$p} );
    }
    
    # On forme une clé sur les positions suivantes :
    #    - 0 : type (d = dispo, t = en traitement, e = expiré, p = perdu, m = mis de côté)
    #    - 1 : localisation,
    #    - 2 : semaine,
    #    - 3 : public,
    #    - 4 : site de réservation
    
    my $key = $params->{type} . $params->{loc} . $params->{public} . $params->{wk} . $params->{resbranch};
    
    my %titre = (
        "d0azz" => "Réservations sur documents disponibles, public, RDC",
        "d0pzz" => "Réservations sur documents disponibles, personnel, RDC",
        "d1azz" => "Réservations sur documents disponibles, public, 1er étage",
        "d1pzz" => "Réservations sur documents disponibles, personnel, 1er étage",        
        "d2azz" => "Réservations sur documents disponibles, public, 2e étage",
        "d2pzz" => "Réservations sur documents disponibles, personnel, 2e étage",
        "d3azz" => "Réservations sur documents disponibles, public, 3e étage",
        "d3pzz" => "Réservations sur documents disponibles, personnel, 3e étage",
        "d4azz" => "Réservations sur documents disponibles, public, Zèbre",
        "d4pzz" => "Réservations sur documents disponibles, personnel, Zèbre",
		"d5azz" => "Réservations sur documents disponibles, public, Quarantaine",
        "d5pzz" => "Réservations sur documents disponibles, personnel, Quarantaine",
        "t0azz" => "Réservations sur documents en traitement, public, RDC",
        "t0pzz" => "Réservations sur documents en traitement, personnel, RDC",
        "t1azz" => "Réservations sur documents en traitement, public, 1er étage",
        "t1pzz" => "Réservations sur documents en traitement, personnel, 1er étage",        
        "t2azz" => "Réservations sur documents en traitement, public, 2e étage",
        "t2pzz" => "Réservations sur documents en traitement, personnel, 2e étage",
        "t3azz" => "Réservations sur documents en traitement, public, 3e étage",
        "t3pzz" => "Réservations sur documents en traitement, personnel, 3e étage",
        "t4azz" => "Réservations sur documents en traitement, public, Zèbre",
        "t4pzz" => "Réservations sur documents en traitement, personnel, Zèbre",
        "e0azz" => "Réservations expirées, pour retrait Médiathèque, public",
        "e0pzz" => "Réservations expirées, pour retrait Médiathèque, personnel",
        "e4zzz" => "Réservations expirées, pour retrait Zèbre",
        "e0zzz" => "Réservations annulées la veille, pour retrait Médiathèque",
        "m0zzz" => "Réservations mises de côté, pour retrait Médiathèque",
        "m4zzz" => "Réservations mises de côté, pour retrait Zèbre",
        "p_et0_s1" => "Documents perdus depuis une semaine, RDC",
        "p_et1_s1" => "Documents perdus depuis une semaine, 1er étage",
        "p_et2_s1" => "Documents perdus depuis une semaine, 2e étage",
        "p_et3_s1" => "Documents perdus depuis une semaine, 3e étage",    
        "p_et0_s3" => "Documents perdus depuis trois semaines, RDC",
        "p_et1_s3" => "Documents perdus depuis trois semaines, 1er étage",
        "p_et2_s3" => "Documents perdus depuis trois semaines, 2e étage",
        "p_et3_s3" => "Documents perdus depuis trois semaines, 3e étage",
        "p_et0_s5" => "Documents perdus depuis cinq semaines, RDC",
        "p_et1_s5" => "Documents perdus depuis cinq semaines, 1er étage",
        "p_et2_s5" => "Documents perdus depuis cinq semaines, 2e étage",
        "p_et3_s5" => "Documents perdus depuis cinq semaines, 3e étage",
		"aazzz" => "Contentieux, personnes à appeler",
		"bbzzz" => "Contentieux, titres de recettes à créer"
    );

    my %rap = (
        "d0azz" => "128",
        "d0pzz" => "187",
        "d1azz" => "131",
        "d1pzz" => "188",
        "d2azz" => "132",
        "d2pzz" => "189",
        "d3azz" => "133",
        "d3pzz" => "190",
        "d4azz" => "170",
        "d4pzz" => "191",
		"d5azz" => "205",
		"d5pzz" => "206",
        "t0azz" => "144",
        "t0pzz" => "192",
        "t1azz" => "145",
        "t1pzz" => "193",
        "t2azz" => "146",
        "t2pzz" => "194",
        "t3azz" => "147",
        "t3pzz" => "195",
        "t4azz" => "172",
        "t4pzz" => "196",
        "e0azz" => "134",
        "e0pzz" => "198",
        "e4zzz" => "164",
        "e0zzz" => "177",
        "m0zzz" => "135",
        "m4zzz" => "201",
        "p_et0_s1" => "140",
        "p_et1_s1" => "141",
        "p_et2_s1" => "142",
        "p_et3_s1" => "143",    
        "p_et0_s1" => "149",
        "p_et1_s1" => "150",
        "p_et2_s1" => "151",
        "p_et3_s1" => "148",
        "p_et0_s1" => "152",
        "p_et1_s1" => "153",
        "p_et2_s1" => "154",
        "p_et3_s1" => "155",
		"aazzz" => "207",
		"bbzzz" => "208"
    );

    my %template = (
		"a" => 'liste_contentieux',
		"b" => 'liste_contentieuxb',
        "d" => 'liste_reservations',
        "t" => 'liste_reservations',
        "e" => 'liste_reservations',        
        "m" => 'liste_reservations',
        "p" => 'liste_perdus'
    );
    
    # On récupère le titre
    my $titre = $titre{$key};
    
    # On récupère le template
    my $template = $template{$params->{type}};
    
    # On récupère les lignes
    my $rapport = $rap{$key};
    my $ws = "http://cataloguekoha.ntrbx.local/cgi-bin/koha/svc/report?id=$rapport";
    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new( GET => $ws );
    my $rep = $ua->request($request)->{'_content'};
    my $rows = decode_json($rep);
    
    my $data = {
        titre => $titre,
        template => $template,
        rows => $rows
    };
    
    return $data;
}

1;

__END__

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
