#!/usr/bin/perl

use Modern::Perl;
use Search::Elasticsearch; 
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;
use collections::poldoc;
use adherents;

my $log_message;
my $process = "es_prets.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

my $date_veille = GetDateTime('yesterday');
my $i = prets($date_veille, $es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);

sub prets {
    my ( $date, $es_node ) = @_;
    my %params = ( nodes => $es_node );
    my $index = "prets";
    my $type = "issues";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    iss.issue_id,
    iss.issuedate,
    iss.date_due,
    iss.returndate,
    iss.biblionumber,
    iss.itemnumber,
    iss.renewals,
    iss.branch,
    iss.arret_bus,
    SHA1(iss.borrowernumber),
    iss.age,
    CASE WHEN iss.sexe = "M" THEN 'Homme' WHEN iss.sexe = "F" THEN 'Femme' END AS 'sexe',
    iss.ville,
    iss.iris,
    iss.branchcode,
    iss.categorycode,
    iss.fidelite,
    iss.itemtype,
    iss.homebranch,
    iss.location,
    iss.ccode,
    iss.itemcallnumber,
    iss.publicationyear,
    iss.dateaccessioned,
    c.lib1,
    c.lib2,
    c.lib3,
    c.lib4
FROM statdb.stat_issues iss
JOIN statdb.lib_collections2 c ON iss.ccode = c.ccode
-- WHERE iss.ccode IN ('AAPATLC')
-- WHERE iss.timestamp > NOW() - INTERVAL 1 HOUR
WHERE(DATE(iss.returndate) >= ? OR DATE(iss.issuedate) >= ?)
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($date, $date);
	#$sth->execute();
    my $i = 1; 
    while (my @row = $sth->fetchrow_array) {
        my ( $id, $issuedate, $date_due, $returndate, $biblionumber, $itemnumber, $renewals, $branch, $arret_bus, $borrowernumber, $age, $sexe, $ville, $iris, $branchcode, $categorycode, $fidelite, $itemtype, $homebranch, $location, $ccode, $itemcallnumber, $publicationyear, $dateaccessioned, $lib1, $lib2, $lib3, $lib4 ) = @row;
        
        my ( $sll_public, $sll_acces, $sll_collection, $sll_prets_coll, $sll_prets ) = GetLibSLL( $ccode, $location, $itemtype );

        $itemtype = GetLibAV($itemtype, "ccode");
        $branch = GetLibBranches($branch);
        if ( $location eq "MED0A" ) { $branch = "Collectivités"; }
        $location = GetLibAV($location, "LOC");        
        $homebranch = GetLibBranches($homebranch);
        $branchcode = GetLibBranches($branchcode);
        my ( $irisNom, $quartier, $secteur ) = undef;
        if (defined $iris) {
            ($irisNom, $quartier, $secteur) = GetRbxDistrict($dbh, $iris);
        }
    
        my $duree_pret = GetDuration($issuedate, $returndate, 'days');
        my $retard = GetDuration($date_due, $returndate, 'days');
    
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
        
        my ($pret_year, $pret_month, $pret_week_number, $pret_day, $pret_jour_semaine, $pret_hour) = GetSplitDateTime($issuedate);
        my ( $retour_year, $retour_month, $retour_week_number, $retour_day, $retour_jour_semaine, $retour_hour );
        if ( defined $returndate ) {
            ( $retour_year, $retour_month, $retour_week_number, $retour_day, $retour_jour_semaine, $retour_hour ) = GetSplitDateTime($returndate);
        }
        
    
        my %index = (
            index   => $index,
            type    => $type,
            id      => $id,
            body    => {
                pret_date_pret => $issuedate,
                pret_date_pret_annee => $pret_year,
                pret_date_pret_mois => $pret_month,
                pret_date_pret_semaine => $pret_week_number,
                pret_date_pret_jour => $pret_day,
                pret_date_pret_jour_semaine => $pret_jour_semaine,
                pret_date_pret_heure => $pret_hour,
                pret_date_retour => $returndate,
                pret_date_retour_annee => $retour_year,
                pret_date_retour_mois => $retour_month,
                pret_date_retour_semaine => $retour_week_number,
                pret_date_retour_jour => $retour_day,
                pret_date_retour_jour_semaine => $retour_jour_semaine,
                pret_date_retour_heure => $retour_hour,
                pret_site => $branch,
                pret_arret_bus => $arret_bus,
                pret_nb_renouvellements => $renewals,
                pret_duree => $duree_pret,
                pret_retard => $retard,
                doc_biblionumber => $biblionumber,
                doc_itemnumber => $itemnumber,
                doc_support => $itemtype,
                doc_site_rattachement => $homebranch,
                doc_localisation => $location,
                doc_cote => $itemcallnumber,
                doc_date_publication => $publicationyear,
                doc_date_acquisition => $dateaccessioned,
                doc_collection_ccode => $ccode,
                doc_collection_lib1 => $lib1,
                doc_collection_lib2 => $lib2,
                doc_collection_lib3 => $lib3,
                doc_collection_lib4 => $lib4,
                sll_public => $sll_public,
                sll_acces => $sll_acces,
                sll_collection => $sll_collection,
                sll_prets_coll => $sll_prets_coll,
                sll_prets => $sll_prets,
                emprunteur_id => $borrowernumber,
                emprunteur_age => $age,
                emprunteur_age_lib1 => $age_lib1,
                emprunteur_age_lib2 => $age_lib2,
                emprunteur_age_lib3 => $age_lib3,
		        emprunteur_sexe => $sexe,
                emprunteur_ville => $ville,
                emprunteur_rbx_iris => $iris,
                emprunteur_rbx_nom_iris =>$irisNom,
                emprunteur_rbx_quartier => $quartier,
		        emprunteur_rbx_secteur => $secteur,
                emprunteur_site_inscription => $branchcode,
                emprunteur_carte => $carte,
                emprunteur_personnalite => $personnalite,
                emprunteur_type_carte => $type_carte,
                emprunteur_nb_annee_inscription => $fidelite
            }
        );

        $e->index(%index);
        $i++;	
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}
