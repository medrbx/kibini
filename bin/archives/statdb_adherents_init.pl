#!/usr/bin/perl

use warnings;
use strict;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use adherents;

my @dates = qw (2017-11-28	2017-10-31	2017-09-26	2017-08-29	2017-07-25	2017-06-27	2017-05-30	2017-04-25	2017-03-28	2017-02-28	2017-01-31	2016-12-27	2016-11-29	2016-10-25	2016-09-27	2016-08-30	2016-07-26	2016-06-28	2016-05-31	2016-04-26	2016-03-29	2016-02-23	2016-01-26	2015-12-29	2015-11-24	2015-10-27	2015-09-29	2015-08-11	2015-07-28);
my $dbh = GetDbh();

my $req = <<SQL;
SELECT
    ? AS date_extraction,
    b.borrowernumber AS adherent_id,
    b.title,
    YEAR(date) - YEAR(b.dateofbirth) AS age,
    b.city AS geo_ville,
    b.altcontactcountry AS geo_roubaix_iris,
    b.branchcode AS inscription_code_site,
    b.categorycode AS inscription_code_carte,
    YEAR(b.date) - YEAR(b.dateenrolled) AS inscription_fidelite
FROM statdb.stat_borrowers b
WHERE b.dateexpiry > ?
	AND b.categorycode IN ("ECOL", "CLAS", "CSVT", "CSLT", "BIBL", "MEDB", "MEDA", "MEDC", "MEDP", "COLD", "COLI", "COLS")
	AND b.date = ?
SQL

my $sth = $dbh->prepare($req);

foreach my $date (@dates) {
$sth->execute($date, $date, $date);
	my $i = 0;
	while (my $adherent = $sth->fetchrow_hashref) {
		$i++;
		$adherent->{sexe} = getSex($adherent->{title}, $adherent->{inscription_code_carte});
		$adherent->{attributes} = getBorrowerAttributes($dbh, $adherent->{adherent_id});
		$adherent->{nb_venues} = getUses($dbh, $adherent);
		insertAdherentIntoStatdb_adherent($dbh, $adherent);
		print "$date : $i\n";
	}
}
$sth->finish();
$dbh->disconnect();