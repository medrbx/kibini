#! /usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use Text::CSV ;
use FindBin qw( $Bin ) ;
use Data::Dumper;

use lib "$Bin/../lib" ;
use kibini::db ;

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
);

my @dates = qw (2017-01-01	2017-01-08	2017-01-15	2017-01-22	2017-01-29	2017-02-05	2017-02-12	2017-02-19	2017-02-26	2017-03-05	2017-03-12	2017-03-19	2017-03-26	2017-04-02	2017-04-09	2017-04-16	2017-04-23	2017-04-30	2017-05-07	2017-05-14	2017-05-21	2017-05-28	2017-06-04	2017-06-11	2017-06-18	2017-06-25	2017-07-02	2017-07-09	2017-07-16	2017-07-23	2017-07-30	2017-08-06	2017-08-13	2017-08-20	2017-08-27	2017-09-03	2017-09-10	2017-09-17	2017-09-24	2017-10-01	2017-10-08	2017-10-15	2017-10-22	2017-10-29	2017-11-05	2017-11-12	2017-11-19	2017-11-26	2017-12-03	2017-12-10	2017-12-17	2017-12-24	2017-12-31);

my $dbh = GetDbh() ;
my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    eol => "\r\n"
});

my $data = {};
foreach my $site (@sites) {
    my $where = GetWhereLocationBySite($site->{'code'}) ;
    my $data_site = exemplaires($dbh, $where, $site->{'nom_fichier'}) ;
	$data->{$site->{'nom_fichier'}} = $data_site;
}
print Dumper($data);

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
    my ($dbh, $where, $nom_fichier) = @_ ;
	my $data;
    my @items;   
    my $req = <<SQL ;
SELECT
	i.ccode AS 'collection_code',
	bi.itemtype AS 'support',
 	COUNT(IF(i.notforloan = 0 AND i.damaged = 0 AND i.itemlost = 0, i.itemnumber, NULL)) AS 'nb_exemplaires_empruntables'
FROM koha2017.items i
JOIN koha2017.biblioitems bi ON bi.biblionumber = i.biblionumber
JOIN statdb.lib_collections2 l ON l.ccode = i.ccode
WHERE
	$where
GROUP BY i.ccode, bi.itemtype
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
        push @items, $row;
    }
    $sth->finish();
	
	return \@items;
}

sub prets {
    my ($dbh, $csv, $where, $nom_fichier) = @_ ;
    
    open(my $fd,">:encoding(utf8)","../data/collections/2017_prets_$nom_fichier.csv") ;
    my @column_names = qw( collection_code support nb_prets_2015 nb_prets_2015_exemplaires_distincts nb_prets_2015_emprunteurs_distincts nb_prets_2016 nb_prets_2016_exemplaires_distincts nb_prets_2016_emprunteurs_distincts nb_prets_2017 nb_prets_2017_exemplaires_distincts nb_prets_2017_emprunteurs_distincts) ;
    $csv->print ($fd, \@column_names) ;
       
    my $req = <<SQL ;
SELECT
    i.ccode,
	i.itemtype,
	COUNT(IF(YEAR(i.issuedate) = 2015, i.itemnumber, NULL)) AS 'nb_prets_2015',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2015, i.itemnumber, NULL))) AS 'nb_prets_2015_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2015, i.borrowernumber, NULL))) AS 'nb_prets_2015_emprunteurs_distincts',
	COUNT(IF(YEAR(i.issuedate) = 2016, i.itemnumber, NULL)) AS 'nb_prets_2016',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2016, i.itemnumber, NULL))) AS 'nb_prets_2016_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2016, i.borrowernumber, NULL))) AS 'nb_prets_2016_emprunteurs_distincts',
	COUNT(IF(YEAR(i.issuedate) = 2017, i.itemnumber, NULL)) AS 'nb_prets_2017',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2017, i.itemnumber, NULL))) AS 'nb_prets_2017_exemplaires_distincts',
	COUNT(DISTINCT(IF(YEAR(i.issuedate) = 2017, i.borrowernumber, NULL))) AS 'nb_prets_2017_emprunteurs_distincts'
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
 
    open(my $fd,">:encoding(utf8)","../data/collections/2017_eliminations_$nom_fichier.csv") ;
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
    AND i.annee_mise_pilon = 2017
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

sub nbIssuesByDateAndCcode {
	my ($dbh, $where, $date, $ccode) = @_;
	
	my $req = <<SQL ;
SELECT COUNT(*)
FROM statdb.stat_issues
WHERE $where
AND DATE(issuedate) < ? AND DATE(returndate) > ? AND ccode = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute();
    return $sth->fetchrow_arrayref;
    $sth->finish();
}	