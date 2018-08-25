#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use Text::CSV;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;

my $output = "od_syntheses_activites_MEL.csv";
open(my $fd,">:encoding(utf8)","$output");
my $csv = Text::CSV->new ({ binary => 1, eol => "\r\n" });

my @column_names = qw( categorie site datetime gentilite nb_utilisateurs nb_operations ) ;
$csv->print ($fd, \@column_names) ;

my $dbh = GetDbh();
my $req;
my $sth;

# Connexions webkiosk
print "Traitement connexion webkiosk\n";
$req = <<SQL;
SELECT
    "Connexions",
    "Médiathèque",
    CONCAT(SUBSTRING(s.heure_deb, 1, 13), ":00:00") AS "Date - Heure",
    s.ville AS ville,
    COUNT( DISTINCT borrowernumber),
    COUNT(*) AS "Nb"
FROM statdb.stat_webkiosk s
WHERE YEAR(s.heure_deb) IN (2016, 2017)
GROUP BY SUBSTRING(s.heure_deb, 1, 13), ville
SQL

$sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_arrayref) {
    #$csv->print ($fd, $row);
}
 
$sth->finish();

print "Traitement connexion webkiosk ok\n";

# Prêts et retours
my $prets = {
    type => "'Prêts'",
    field => "s.issuedate"
};
my $retours = {
    type => "'Retours'",
    field => "s.returndate"
};
my @types = ( $prets, $retours );

my $med = {
    site => "'Médiathèque'",
    location => "s.location NOT IN ('MED0A', 'BUS1A')"
};
my $bus = {
    site => "'Zèbre'",
    location => "s.location = 'BUS1A'"
};
my $col = {
    site => "'Collectivités'",
    location => "s.location = 'MED0A'"
};

my @sites = ( $med, $bus, $col);

foreach my $type (@types) {
    foreach my $site (@sites) {
        print "Traitement $type->{type} $site->{site}\n";
        $req = <<SQL;    
SELECT
    $type->{type},
    $site->{site},
    CONCAT(SUBSTRING($type->{field}, 1, 13), ":00:00") AS "date",
    s.ville AS ville,
    COUNT( DISTINCT borrowernumber),
    COUNT(*) AS "Nb"
FROM statdb.stat_issues s
WHERE YEAR($type->{field}) IN (2016, 2017) AND $site->{location}
GROUP BY SUBSTRING($type->{field}, 1, 13), ville
SQL

        $sth = $dbh->prepare($req);
        $sth->execute();
        while (my $row = $sth->fetchrow_arrayref) {
            $csv->print ($fd, $row);
        }
        $sth->finish();
        print "Traitement $type->{type} $site->{site} ok\n";
    }
}

close $fd;
$dbh->disconnect();