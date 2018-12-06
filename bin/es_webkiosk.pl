#!/usr/bin/perl

use Modern::Perl;
use utf8;
use Search::Elasticsearch; 
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;
use collections::poldoc;
use adherents;
use webkiosk;

my $log_message;
my $process = "es_webkiosk.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

my $es_maxdatetime = GetEsMaxDateTime("webkiosk", "sessions", "session_heure_deb");
my $i = webkiosk($es_maxdatetime, $es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);
    

sub webkiosk {
    my ( $date, $es_node ) = @_;
    my %params = ( nodes => $es_node );
    my $index = "webkiosk";
    my $type = "sessions";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    w.heure_deb,
    w.heure_fin,
    w.espace,
    w.poste,
    SHA1(w.id),
    w.age,
    w.sexe,
    w.ville,
    w.iris,
    w.branchcode,
    w.categorycode,
    w.fidelite
FROM statdb.stat_webkiosk w
WHERE w.heure_deb > ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($date);
    my $i = 0; 
    while (my @row = $sth->fetchrow_array) {
        my ( $heure_deb, $heure_fin, $groupe, $poste, $id, $age, $sexe, $ville, $iris, $branchcode, $categorycode, $fidelite ) = @row;
        my $duree;
        if (length $heure_fin) {
            $duree = GetDuration( $heure_deb, $heure_fin, "minutes" );
        }
        my $espace = GetWkLocation($groupe);
        
        my ( $age_lib1, $age_lib2, $age_lib3 );
        if ( $age eq "NP" ) { 
            $age = undef;
        } else {
            $age_lib1 = GetAgeLib($dbh, $age, "trmeda");
            $age_lib2 = GetAgeLib($dbh, $age, "trmedb");
            $age_lib3 = GetAgeLib($dbh, $age, "trinsee");
        }
        my ( $carte, $personnalite ) = GetCategoryDesc($dbh, $categorycode);
        if ( $personnalite eq "C" )    {
            $personnalite = "Personne";
        } else {
            $personnalite = "Collectivité";
        }
        
        my $type_carte = GetCardType($categorycode);
        
        $branchcode = GetLibBranches($branchcode);
        my ( $irisNom, $quartier ) = undef;
        if (defined $iris) {
            ($irisNom, $quartier, $secteur) = GetRbxDistrict($dbh, $iris);
        }
        
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                session_heure_deb => $heure_deb,
                session_heure_fin => $heure_fin,
                session_duree => $duree,
                session_espace => $espace,
                session_groupe => $groupe,
                session_poste => $poste,
                adherent_id => $id,
                adherent_age => $age,
                adherent_age_lib1 => $age_lib1,
                adherent_age_lib2 => $age_lib2,
                adherent_age_lib3 => $age_lib3,
                adherent_carte => $carte,
                adherent_type_carte => $type_carte,
                adherent_nb_annee_inscription => $fidelite,
                adherent_ville => $ville,
                adherent_rbx_iris => $iris,
                adherent_rbx_nom_iris => $irisNom,
                adherent_rbx_quartier => $quartier,
				adherent_rbx_secteur => $secteur,
                adherent_site_inscription => $branchcode,
                adherent_personnalite => $personnalite
            }
        );

        $e->index(%index);
        $i++;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}