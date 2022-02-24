#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use Data::Dumper;

my @sites = (
    {
        nom => 'Grand-Plage',
        code => 'GPL',
        nom_fichier => 'grand-plage'
    },
    {
        nom => 'Médiathèque',
        code => 'MED',
        nom_fichier => 'mediatheque'
    },
    {
        nom => 'Zèbre',
        code => 'BUS',
        nom_fichier => 'zebre'
    },
    {
        nom => 'Collectivités',
        code => 'COL',
        nom_fichier => 'collectivites'
    }
) ;

my $dbh = GetDbh() ;
my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    eol => "\r\n"
});

foreach my $site (@sites) {
    my $where = GetWhereLocationBySite($site->{'code'}) ;
    exemplaires($dbh, $csv, $where, $site->{'nom_fichier'}) ;
    eliminations($dbh, $csv, $where, $site->{'nom_fichier'}) ;
    prets($dbh, $csv, $where, $site->{'nom_fichier'}) ;
}

$dbh->disconnect();



sub GetWhereLocationBySite {
    my ($site) = @_ ;
    my $where ;
    if ( $site eq 'GPL' ) {
        $where = "i.location != 'MUS1A'" ;
    } elsif ( $site eq 'MED' ) {
        $where = "i.location NOT IN ('MUS1A', 'BUS1A', 'MED0A')" ;
    } elsif ( $site eq 'BUS' ) {
        $where = "i.location = 'BUS1A'" ;
    } elsif ( $site eq 'COL' ) {
        $where = "i.location = 'MED0A'" ;
    }
    return $where ;
}

sub exemplaires {
    my ($dbh, $csv, $where, $nom_fichier) = @_ ;
 
    open(my $fd,">:encoding(utf8)","../data/collections/2021_exemplaires_$nom_fichier.csv") ;
    my @column_names = qw( collection_code collection_lib1 collection_lib2 collection_lib3 collection_lib4 support nb_exemplaires nb_exemplaires_empruntables nb_exemplaires_consultables_sur_place_uniquement nb_exemplaires_en_acces_libre nb_exemplaires_en_acces_indirect nb_exemplaires_en_commande nb_exemplaires_en_traitement nb_exemplaires_en_abîmés nb_exemplaires_en_réparation nb_exemplaires_en_retrait nb_exemplaires_en_reliure nb_exemplaires_perdus nb_exemplaires_non_restitués nb_exemplaires_créés_dans_annee nb_exemplaires_empruntables_pas_empruntés_1_an nb_exemplaires_empruntables_pas_empruntés_3_ans nb_exemplaires_en_pret ) ;
    $csv->print ($fd, \@column_names) ;
       
    my $req = <<SQL ;
SELECT
	i.ccode AS 'collection_code',
 	l.lib1 AS 'collection_lib1',
 	l.lib2 AS 'collection_lib2',
 	l.lib3 AS 'collection_lib3',
 	l.lib4 AS 'collection_lib4',
	bi.itemtype AS 'support',
	COUNT(i.itemnumber) AS 'nb_exemplaires',
 	COUNT(IF(i.notforloan = 0 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_empruntables',
 	COUNT(IF(i.notforloan = 2 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_consultables_sur_place_uniquement',
	COUNT(IF(i.notforloan IN (0, 2) AND i.damaged = 0 AND i.itemlost = 0 AND i.location NOT IN ('MED0A', 'MED2C', 'MED2D', 'MED3C', 'MED3D', 'MED3E', 'MED3F', 'MED3G', 'MED3H', 'MED3I', 'MED3J', 'MED3K'), i.itemnumber, NULL)) AS 'nb_exemplaires_en_acces_libre',
    COUNT(IF(i.notforloan IN (0, 2) AND i.damaged = 0 AND i.itemlost = 0 AND i.location IN ('MED0A', 'MED2C', 'MED2D', 'MED3C', 'MED3D', 'MED3E', 'MED3F', 'MED3G', 'MED3H', 'MED3I', 'MED3J', 'MED3K'), i.itemnumber, NULL)) AS 'nb_exemplaires_en_acces_indirect',
    COUNT(IF(i.notforloan = -1 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_commande',
    COUNT(IF(i.notforloan = -2 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_traitement',
    COUNT(IF(i.notforloan != -4 AND i.damaged = 1 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_abîmés',
    COUNT(IF(i.notforloan = -4 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_réparation',
    COUNT(IF(i.notforloan = -3 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_retrait',
    COUNT(IF(i.notforloan = 5 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_en_reliure',
    COUNT(IF(i.itemlost = 2, i.itemnumber, NULL)) AS 'nb_exemplaires_perdus',
    COUNT(IF(i.itemlost = 1, i.itemnumber, NULL)) AS 'nb_exemplaires_non_restitués',
    COUNT(IF(i.dateaccessioned > ('2022-01-01' - INTERVAL 1 YEAR), i.itemnumber, NULL)) AS 'nb_exemplaires_créés_dans_annee',
	COUNT(IF(i.notforloan NOT IN (-2, -1, 2) AND i.datelastborrowed <= ('2022-01-01' - INTERVAL 1 YEAR), i.itemnumber, NULL)) AS 'nb_exemplaires_empruntables_pas_empruntés_1_an',
    COUNT(IF(i.notforloan NOT IN (-2, -1, 2) AND i.datelastborrowed <= ('2022-01-01' - INTERVAL 3 YEAR), i.itemnumber, NULL)) AS 'nb_exemplaires_empruntables_pas_empruntés_3_ans',
    COUNT(IF(i.onloan IS NOT NULL OR i.itemlost = 1, i.itemnumber, NULL)) AS 'nb_exemplaires_en_pret'
FROM koha2021.items i
JOIN koha2021.biblioitems bi ON bi.biblionumber = i.biblionumber
JOIN statdb.lib_collections2 l ON l.ccode = i.ccode
WHERE
	$where
GROUP BY i.ccode, bi.itemtype
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $row = $sth->fetchrow_arrayref ) {
        $csv->print ($fd, $row);
    }
    close $fd ;
    $sth->finish();
}

sub prets {
    my ($dbh, $csv, $where, $nom_fichier) = @_ ;
    
    open(my $fd,">:encoding(utf8)","../data/collections/2021_prets_$nom_fichier.csv") ;
    my @column_names = qw( collection_code support nb_prets_2019 nb_prets_2019_exemplaires_distincts nb_prets_2019_emprunteurs_distincts nb_prets_2020 nb_prets_2020_exemplaires_distincts nb_prets_2020_emprunteurs_distincts nb_prets_2021 nb_prets_2021_exemplaires_distincts nb_prets_2021_emprunteurs_distincts) ;
    $csv->print ($fd, \@column_names) ;
       
    my $req = <<SQL ;
SELECT
    i.ccode,
	i.itemtype,
	COUNT(IF(YEAR(i.issuedate) = 2019, i.itemnumber, NULL)) AS 'nb_prets_2019',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2019, i.itemnumber, NULL))) AS 'nb_prets_2019_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2019, i.borrowernumber, NULL))) AS 'nb_prets_2019_emprunteurs_distincts',
	COUNT(IF(YEAR(i.issuedate) = 2020, i.itemnumber, NULL)) AS 'nb_prets_2020',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2020, i.itemnumber, NULL))) AS 'nb_prets_2020_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2020, i.borrowernumber, NULL))) AS 'nb_prets_2020_emprunteurs_distincts',
	COUNT(IF(YEAR(i.issuedate) = 2021, i.itemnumber, NULL)) AS 'nb_prets_2021',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2021, i.itemnumber, NULL))) AS 'nb_prets_2021_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2021, i.borrowernumber, NULL))) AS 'nb_prets_2021_emprunteurs_distincts'
FROM statdb.stat_issues i
WHERE
    $where
GROUP BY i.ccode, i.itemtype
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $row = $sth->fetchrow_arrayref ) {
        $csv->print ($fd, $row);
    }
    close $fd ;
    $sth->finish();
}

sub eliminations {
    my ($dbh, $csv, $where, $nom_fichier) = @_ ;
 
    open(my $fd,">:encoding(utf8)","../data/collections/2021_eliminations_$nom_fichier.csv") ;
    my @column_names = qw(collection_code support nb_exemplaires_éliminés nb_exemplaires_éliminés_non_restitués nb_exemplaires_éliminés_perdus nb_exemplaires_éliminés_abîmés nb_exemplaires_éliminés_désherbés ) ;
    $csv->print ($fd, \@column_names);
    
    my $req = <<SQL ;
SELECT
	i.ccode AS 'collection_code',
	i.itemtype AS 'support',
	COUNT(i.itemnumber) AS 'nb_exemplaires_éliminés',
    COUNT(IF(i.motif = 'non restitué', i.itemnumber, NULL)) AS 'nb_exemplaires_éliminés_non_restitués',
	COUNT(IF(i.motif = 'perdu', i.itemnumber, NULL)) AS 'nb_exemplaires_éliminés_perdus',
    COUNT(IF(i.motif = 'abîmé', i.itemnumber, NULL)) AS 'nb_exemplaires_éliminés_abîmés',
    COUNT(IF(i.motif = 'désherbé', i.itemnumber, NULL)) AS 'nb_exemplaires_éliminés_désherbés'
FROM statdb.stat_eliminations i
WHERE
	$where
    AND i.annee_mise_pilon = 2021
GROUP BY i.ccode, i.itemtype
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $row = $sth->fetchrow_arrayref ) {
        $csv->print ($fd, $row);
    }
    close $fd ;
    $sth->finish();
}