#!/usr/bin/perl

use warnings;
use strict;
use Text::CSV ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;

my $log_message ;
my $process = "statdb_webkiosk.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# Connexion à la base de données
my $dbh = GetDbh() ;

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO statdb.stat_webkiosk (heure_deb, heure_fin, espace, poste, id)
VALUES (?, ?, ?, ?, ?)
SQL

# Traitement de la requête
open my $fic, "<", "/home/kibini/wk_users_logs_consommations.csv";

my $csv = Text::CSV->new ({
	binary    => 1, # permet caractères spéciaux (?)
	auto_diag => 1, # permet diagnostic immédiat des erreurs
	});

my $sth = $dbh->prepare($req);

while ( my $row = $csv->getline ($fic) ) {
  my ( $heure_deb, $heure_fin, $espace, $poste, $id ) = @$row ;
  $sth->execute( $heure_deb, $heure_fin, $espace, $poste, $id ) or die "Echec Requête $req : $DBI::errstr";
}
close $fic;

# On met à jour les données lecteurs
$req = "UPDATE statdb.stat_webkiosk w JOIN koha_prod.borrowers b ON w.id = b.userid SET w.borrowernumber = b.borrowernumber WHERE w.borrowernumber IS NULL" ;
$sth = $dbh->prepare($req);
$sth->execute() ;

$req = "UPDATE statdb.stat_webkiosk wk JOIN statdb.stat_borrowers b ON wk.borrowernumber = b.borrowernumber SET wk.age = b.age, wk.sexe = b.title, wk.ville = b.city, wk.iris = b.altcontactcountry, wk.branchcode = b.branchcode, wk.categorycode = b.categorycode, wk.fidelite = b.fidelite WHERE b.date = (SELECT MAX(DATE) FROM statdb.stat_borrowers) AND wk.age IS NULL" ;
$sth = $dbh->prepare($req);
$sth->execute() ;

$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;