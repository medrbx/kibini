#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Search::Elasticsearch ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use kibini::time ;
use adherents::details ;

my $log_message ;
my $process = "es_borrowers_synth.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

# On récupère la date de dernière mise à jour de statdb.stat_borrowers
my $dbh = GetDbh() ;
my $req = "SELECT MAX(date) FROM statdb.stat_borrowers" ;
my $sth = $dbh->prepare($req);
$sth->execute();
my $date = $sth->fetchrow_array ;
$sth->finish();
$dbh->disconnect();

# On indexe :
my $i = borrowers_synth($date) ;

# On log la fin de l'opération
$log_message = "$process : $i lignes indexées" ;
AddCrontabLog($log_message) ;
$log_message = "$process : fin\n" ;
AddCrontabLog($log_message) ;


sub borrowers_synth {
    my ( $date ) = @_ ;
    my %params = ( nodes => $es_node ) ;
    my $index = "adherents_synth" ;
    my $type = "inscrits" ;

    my $e = Search::Elasticsearch->new( %params ) ;
    
    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
    CASE WHEN b.zipcode = '59100' THEN 'Roubaisiens' ELSE 'Non Roubaisiens' END,
    b.categorycode,
    b.age,
    b.emprunteur,
    COUNT(b.borrowernumber)
FROM stat_borrowers b
WHERE b.date = ? AND b.dateexpiry >= ?
GROUP BY CASE WHEN b.zipcode = '59100' THEN 'Roubaisiens' ELSE 'Non Roubaisiens' END, b.categorycode, b.age, b.emprunteur
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($date, $date);
    my $i = 0 ;
    while (my @row = $sth->fetchrow_array) {
        my ( $roubaix, $categorycode, $age, $activite_emprunteur, $nb ) = @row ;
        
        my ( $carte, $personnalite ) = GetCategoryDesc($categorycode) ;
        
        my ( $age_lib1, $age_lib2, $age_lib3 ) ;
        if ( $age eq "NP" ) { 
            $age = undef ;
        } else {
            $age_lib1 = GetAgeLib($age, "trmeda") ;
            $age_lib2 = GetAgeLib($age, "trmedb") ;
            $age_lib3 = GetAgeLib($age, "trinsee") ;
        }
        
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                date => $date,
                ages_age => $age,
                ages_lib1 => $age_lib1,
                ages_lib2 => $age_lib2,
                ages_lib3 => $age_lib3,
                geo_ville => $roubaix,
                activite_emprunteur => $activite_emprunteur,
                inscription_carte => $carte,
                personnalite => $personnalite,
                nb_inscrits => $nb
            }
        ) ;
        
        # print "$date, $age, $age_lib1, $roubaix, $activite_emprunteur\n" ;
        $e->index(%index) ;
        $i++ ;
        }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}