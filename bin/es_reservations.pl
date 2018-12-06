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

my $log_message;
my $process = "es_reservations.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

my $date_veille = GetDateTime('yesterday');
my $i = reservations($date_veille, $es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);

sub reservations {
    my ( $date, $es_node ) = @_;
    my %params = ( nodes => $es_node );
    my $index = "reservations";
    my $type = "reserves";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();
    my $req = <<SQL;
SELECT
    r.reserve_id,
    SHA1(r.borrowernumber),
    r.reservedate,
    r.biblionumber,
    r.branchcode,
    r.notificationdate,
    r.cancellationdate,
    r.priority,
    r.found,
    r.timestamp,
    r.itemnumber,
    r.waitingdate,
    r.etat,
    r.espace,
    r.age,
    r.sexe,
    r.ville,
    r.iris,
    r.branchcode_borrower,
    r.categorycode,
    r.fidelite,
    r.motif_annulation,
    r.courriel,
    r.mobile,
    r.annulation,
    r.document_mis_cote
FROM statdb.stat_reserves r
WHERE (DATE(r.timestamp) >= ? OR DATE(r.reservedate) >= ?)
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($date, $date);
    my $i = 0;
    while (my @row = $sth->fetchrow_array) {
        my ( $reserve_id, $borrowernumber, $reservedate, $biblionumber, $branchcode, $notificationdate, $cancellationdate, $priority, $found, $timestamp, $itemnumber, $waitingdate, $etat, $espace, $age, $sexe, $ville, $iris, $branchcode_borrower, $categorycode, $fidelite, $motif_annulation, $courriel, $mobile, $annulation, $document_mis_cote ) = @row;
        
        my ($itemtype, $location, $homebranch, $ccode, $lib1, $lib2, $lib3, $lib4 ) = "NC";
        if (length $itemnumber) {
            $itemtype = GetItemtypeFromBiblionumber($biblionumber);
            $itemtype = GetLibAV($itemtype, "ccode");
            
            ($location, $homebranch, $ccode) = GetDataItemsFromItemnumber($itemnumber);
            
            $location = GetLibAV($location, "LOC");        
            $homebranch = GetLibBranches($homebranch);
            
            ( $ccode, $lib1, $lib2, $lib3, $lib4 ) = GetDataCcodeFromItemnumber($itemnumber);
        }
        
        my ( $irisNom, $quartier ) = undef;
        if (defined $iris) {
            ($irisNom, $quartier, $secteur) = GetRbxDistrict($dbh, $iris);
        }
        $branchcode = GetLibBranches($branchcode);
        $branchcode_borrower = GetLibBranches($branchcode_borrower);
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
        
        my %index = (
            index   => $index,
            type    => $type,
            id      => $reserve_id,
            body    => {
                reserve_id => $reserve_id,
                reservedate => $reservedate,
                reserveur_id => $borrowernumber,
                reserveur_age => $age,
                reserveur_age_lib1 => $age_lib1,
                reserveur_age_lib2 => $age_lib2,
                reserveur_age_lib3 => $age_lib3,
                reserveur_sexe => $sexe,
                reserveur_ville => $ville,
                reserveur_rbx_iris => $iris,
                reserveur_rbx_nom_iris => $irisNom,
                reserveur_rbx_quartier => $quartier,
				reserveur_rbx_secteur => $secteur,
                reserveur_site_inscription => $branchcode_borrower,
                reserveur_carte => $carte,
                reserveur_personnalite => $personnalite,
                reserveur_type_carte => $type_carte,
                reserveur_nb_annee_inscription => $fidelite,
                reserveur_mobile => $mobile,
                reserveur_courriel => $courriel,
                biblionumber => $biblionumber,
                site_retrait => $branchcode,
                date_notification => $notificationdate,
                date_annulation => $cancellationdate,
                date_mise_cote => $waitingdate,
                found => $found,
                etat => $etat,
                espace => $espace,
                motif_annulation => $motif_annulation,
                annulation => $annulation,
                document_mis_cote => $document_mis_cote,
                collection_ccode => $ccode,
                collection_lib1 => $lib1,
                collection_lib2 => $lib2,
                collection_lib3 => $lib3,
                collection_lib4 => $lib4,
                localisation => $location,
                site_rattach => $homebranch,
                support => $itemtype
            }
        );

        $e->index(%index);
        $i++;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}