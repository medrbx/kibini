#!/usr/bin/perl

use warnings;
use strict;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::log;
use adherents;

my $log_message;
my $process = "statdb_adherents.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);


my $dbh = GetDbh();

my $req = <<SQL;
    SELECT
    CURDATE() AS date_extraction,
    b.borrowernumber AS adherent_id,
    b.title,
    YEAR(CURDATE()) - YEAR(b.dateofbirth) AS age,
    b.city AS geo_ville,
    b.altcontactcountry AS geo_roubaix_iris,
    b.branchcode AS inscription_code_site,
    b.categorycode AS inscription_code_carte,
    YEAR(CURDATE()) - YEAR(b.dateenrolled) AS inscription_fidelite
FROM koha_prod.borrowers b
WHERE b.dateexpiry > CURDATE()
    AND b.categorycode IN ("ECOL", "CLAS", "CSVT", "CSLT", "BIBL", "MEDB", "MEDA", "MEDC", "MEDP", "COLD", "COLI", "COLS")
	
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
my $i = 0;
while (my $adherent = $sth->fetchrow_hashref) {
    $i++;
    $adherent->{sexe} = getSex($adherent->{title}, $adherent->{inscription_code_carte});
    $adherent->{attributes} = getBorrowerAttributes($dbh, $adherent->{adherent_id});
    $adherent->{nb_venues} = getUses($dbh, $adherent);
    insertAdherentIntoStatdb_adherent($dbh, $adherent);
    print Dumper($adherent);
}


$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);
