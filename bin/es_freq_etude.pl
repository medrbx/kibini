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
use adherents;

my $log_message;
my $process = "es_freq_etude.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

my $i = es_freq_etude($es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);

sub es_freq_etude {
    my ( $es_node ) = @_;
    my %params = ( nodes => $es_node );
    my $index = "freq_etude";
    my $type = "consultations";
    
    my $esMaxEntranceDateTime = GetEsMaxDateTime($index, $type, 'date');

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    datetime_entree,
    duree,
    SHA1(borrowernumber),
    sexe,
    age,
    categorycode,
    ville,
    iris
FROM statdb.stat_freq_etude
WHERE DATE(datetime_entree) >= ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($esMaxEntranceDateTime);
    my $i = 0; 
    while (my @row = $sth->fetchrow_array) {
        my ( $datetime_entree, $duree, $borrowernumber, $sexe, $age, $categorycode, $ville, $iris ) = @row;

        my ( $irisNom, $quartier ) = undef;
        if (defined $iris) {
            ($irisNom, $quartier, $secteur) = GetRbxDistrict($dbh, $iris);
        }
    
        my ( $age_lib1, $age_lib2, $age_lib3 );
        if ( defined $age ) { 
            $age_lib1 = GetAgeLib($dbh, $age, "trmeda");
            $age_lib2 = GetAgeLib($dbh, $age, "trmedb");
            $age_lib3 = GetAgeLib($dbh, $age, "trinsee");
        }

        my ( $carte, $personnalite ) = GetCategoryDesc($dbh, $categorycode);
        
        my $type_carte = GetCardType($categorycode);

        $duree = GetMinutesFromTime($duree);
    
        my %index = (
            index   => $index,
            type    => $type,
            #id      => $id,
            body    => {
                lecteur_age => $age,
                lecteur_age_lib1 => $age_lib1,
                lecteur_age_lib2 => $age_lib2,
                lecteur_age_lib3 => $age_lib3,
                lecteur_carte => $carte,
                lecteur_id => $borrowernumber,
                lecteur_rbx_iris => $iris,
                lecteur_rbx_nom_iris => $irisNom,
                lecteur_rbx_quartier => $quartier,
				lecteur_rbx_secteur => $secteur,
                lecteur_sexe => $sexe,
                lecteur_type_carte => $type_carte,
                lecteur_ville => $ville,
                date => $datetime_entree,
                consultation_duree => $duree
            }
        );

        $e->index(%index);
        $i++;    
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}