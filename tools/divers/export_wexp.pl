#! /usr/bin/perl

use strict;
use warnings;
use Text::CSV ;
use utf8 ;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;

my $dbh = GetDbh();
my $dir = "../../export_wexp/";
my $date = "20171229";

my @sexes = ( 
    {
        sexe => 'Femmes',
        title => 'Madame'
    },
    {
        sexe => 'Hommes',
        title => 'Monsieur'
    }
);

my @ages = (
    {
        tranche => '18-29',
        age_min => 18,
        age_max => 29,
        lim => 100
    },
    {
        tranche => '30-39',
        age_min => 30,
        age_max => 39,
        lim => 200
    },
    {
        tranche => '40-54',
        age_min => 40,
        age_max => 54,
        lim => 200
    },
    {
        tranche => '55-64',
        age_min => 55,
        age_max => 64,
        lim => 100
    }
);

foreach my $sexe (@sexes) {
    foreach my $age (@ages) {
        my $file = $dir . "export_wexperience-" . $date . "-" . $sexe->{sexe} . "-" . $age->{tranche} . ".csv";
        my $csv = Text::CSV->new ({ binary => 1, eol => "\r\n" });
        open( my $fd, ">:encoding(UTF-8)", $file ) ;
        my @columns = qw( id Nom Prénom Courriel Téléphone );
        $csv->print ($fd, \@columns) ;
            my $req = <<SQL;
SELECT
    borrowernumber as 'id',
    surname AS 'Nom',
    firstname AS 'Prénom',
    email as 'Courriel',
    mobile as 'Mobile'
FROM statdb2.borrowers
WHERE
    dateexpiry > CURDATE()
    AND borrowernumber IN (SELECT borrowernumber FROM statdb.stat_issues WHERE YEAR(issuedate) = 2017)
    AND title = ?
    AND email IS NOT NULL AND email != ''
    AND mobile IS NOT NULL AND mobile != ''
    AND categorycode IN ('BIBL', 'MEDA', 'MEDB', 'MEDC', 'CSVT')
    AND YEAR(CURDATE()) - YEAR(dateofbirth) BETWEEN ? AND ?
ORDER BY random_id
LIMIT $age->{lim}
SQL
        my $sth = $dbh->prepare($req);
        $sth->execute($sexe->{title},$age->{age_min},$age->{age_max});
        while (my $user = $sth->fetchrow_arrayref()) {
            $csv->print ($fd, $user);
        }
        $sth->finish();
        close $fd ;
        print "$file\n";
    }
}
$dbh->disconnect;