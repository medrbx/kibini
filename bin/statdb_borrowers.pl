#!/usr/bin/perl

use warnings ;
use strict ;
use FindBin qw( $Bin ) ;

use lib "$Bin/modules/" ;
use dbrequest ;
use fonctions ;

my $log_message ;
my $process = "statdb_borrowers.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;


my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;

# On récupère la date de dernière mise à jour de la table statdb.stat_borrowers
my $req = "SELECT MAX(date) FROM statdb.stat_borrowers" ;
my $sth = $dbh->prepare($req);
$sth->execute();
my $date = $sth->fetchrow_array ;

# On récupère l'ensemble des borrowernumber
$req = "SELECT borrowernumber FROM statdb.stat_borrowers WHERE date = ?" ;
$sth = $dbh->prepare($req);
$sth->execute($date);

my $i = 0 ;
while (my $borrowernumber = $sth->fetchrow_array) {
	# On cherche la date du dernier prêt
	my $req = "SELECT MAX(DATE(issuedate)) FROM stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? " ;
	my $sth = $dbh->prepare($req);
	$sth->execute($borrowernumber, $date);
	my $date_dernier_pret = $sth->fetchrow_array ;
	$sth->finish();

	# On cherche la date de la dernière connexion webkiosk
	$req = "SELECT MAX(DATE(heure_deb)) FROM stat_webkiosk WHERE borrowernumber = ? AND DATE(heure_deb) < ? " ;
	$sth = $dbh->prepare($req);
	$sth->execute($borrowernumber, $date);
	my $date_dernier_conn = $sth->fetchrow_array ;
	$sth->finish();

        # On cherche la date de dernier prêt à la médiathèque
        $req = "SELECT MAX(DATE(issuedate)) FROM stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? AND branch = 'MED'" ;
        $sth = $dbh->prepare($req);
        $sth->execute($borrowernumber, $date);
        my $date_dernier_pret_med = $sth->fetchrow_array ;
        $sth->finish();

        # On cherche la date de dernier prêt au bus
        $req = "SELECT MAX(DATE(issuedate)) FROM stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? AND branch = 'BUS'" ;
        $sth = $dbh->prepare($req);
        $sth->execute($borrowernumber, $date);
        my $date_dernier_pret_bus = $sth->fetchrow_array ;
        $sth->finish();

	
	if (length $date_dernier_pret) {
		my $req = "UPDATE statdb.stat_borrowers SET date_dernier_pret = ? WHERE borrowernumber = ? AND date = ?" ;
		my $sth = $dbh->prepare($req);
		$sth->execute($date_dernier_pret, $borrowernumber, $date);
		$sth->finish();
	}

	if (length $date_dernier_conn) {
		my $req = "UPDATE statdb.stat_borrowers SET date_dernier_conn = ? WHERE borrowernumber = ? AND date = ?" ;
		my $sth = $dbh->prepare($req);
		$sth->execute($date_dernier_conn, $borrowernumber, $date);
		$sth->finish();
	}

        if (length $date_dernier_pret_med) {
                my $req = "UPDATE statdb.stat_borrowers SET date_dernier_pret_med = ? WHERE borrowernumber = ? AND date = ? " ;
                my $sth = $dbh->prepare($req);
                $sth->execute($date_dernier_pret_med, $borrowernumber, $date);
                $sth->finish();
        }

        if (length $date_dernier_pret_bus) {
                my $req = "UPDATE statdb.stat_borrowers SET date_dernier_pret_bus = ? WHERE borrowernumber = ? AND date = ? " ;
                my $sth = $dbh->prepare($req);
                $sth->execute($date_dernier_pret_bus, $borrowernumber, $date);
                $sth->finish();
        }

	$i++ ;
}
$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i lignes intégrées" ;
log_file($log_message) ;
$log_message = "$process : fin\n" ;
log_file($log_message) ;