#!/usr/bin/perl

use warnings ;
use strict ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;

my $log_message ;
my $process = "statdb_borrowers.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;


my $dbh = GetDbh() ;

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
    my $req = "SELECT MAX(DATE(issuedate)) FROM statdb.stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? " ;
    my $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_pret = $sth->fetchrow_array ;
    $sth->finish();

    # On cherche la date de la dernière connexion webkiosk
    $req = "SELECT MAX(DATE(heure_deb)) FROM statdb.stat_webkiosk WHERE borrowernumber = ? AND DATE(heure_deb) < ? " ;
    $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_conn = $sth->fetchrow_array ;
    $sth->finish();

    # On cherche la date de dernier prêt à la médiathèque
    $req = "SELECT MAX(DATE(issuedate)) FROM statdb.stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? AND branch = 'MED'" ;
    $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_pret_med = $sth->fetchrow_array ;
    $sth->finish();

    # On cherche la date de dernier prêt au bus
    $req = "SELECT MAX(DATE(issuedate)) FROM statdb.stat_issues WHERE borrowernumber = ? AND DATE(issuedate) < ? AND branch = 'BUS'" ;
    $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_pret_bus = $sth->fetchrow_array ;
    $sth->finish();
	
	# On cherche la date de la dernière connexion wifi
    $req = "SELECT MAX(DATE(start_wifi)) FROM statdb.stat_wifi WHERE borrowernumber = ? AND DATE(start_wifi) < ?" ;
    $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_conn_wifi = $sth->fetchrow_array ;
    $sth->finish();
	
	# On cherche la date de la dernière fréquentation de la salle d'étude
    $req = "SELECT MAX(DATE(datetime_entree)) FROM statdb.stat_freq_etude WHERE borrowernumber = ? AND DATE(datetime_entree) < ?" ;
    $sth = $dbh->prepare($req);
    $sth->execute($borrowernumber, $date);
    my $date_dernier_conn_freq_etude = $sth->fetchrow_array ;
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

    if (length $date_dernier_conn_wifi) {
        my $req = "UPDATE statdb.stat_borrowers SET date_dernier_conn_wifi = ? WHERE borrowernumber = ? AND date = ? " ;
        my $sth = $dbh->prepare($req);
        $sth->execute($date_dernier_conn_wifi, $borrowernumber, $date);
        $sth->finish();
    }
	
	if (length $date_dernier_pret_bus) {
        my $req = "UPDATE statdb.stat_borrowers SET date_dernier_pret_bus = ? WHERE borrowernumber = ? AND date = ? " ;
        my $sth = $dbh->prepare($req);
        $sth->execute($date_dernier_pret_bus, $borrowernumber, $date);
        $sth->finish();
    }
	
	if (length $date_dernier_conn_freq_etude) {
        my $req = "UPDATE statdb.stat_borrowers SET date_dernier_freq_etude = ? WHERE borrowernumber = ? AND date = ? " ;
        my $sth = $dbh->prepare($req);
        $sth->execute($date_dernier_conn_freq_etude, $borrowernumber, $date);
        $sth->finish();
    }

    $i++ ;
}
$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;