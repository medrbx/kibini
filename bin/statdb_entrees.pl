#!/usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;

my $log_message ;
my $process = "statdb_entrees.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# Connexion à la base de données
my $dbh = GetDbh() ;

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO statdb.stat_entrees (datetime, entrees)
VALUES (?, ?)
SQL
 
# Traitement de la requête
my $sth = $dbh->prepare($req);

my $i = 0 ;
while (my $ligne = <>) {
    my $datetime ;
	chomp $ligne;
    my ($date, $heure, $entrees) = split /\,/, $ligne ;
    $date =~ s/(\)|\()//g ;
    my ($annee, $mois, $jour) = split /-/, $date ;
    $heure =~ /(\d*)(h.)/ ;
    $heure = $1 ;
    if ($heure !~ /\d{2}/) {
        $heure = "0$heure" ;
    }
    $datetime = "$annee-$mois-$jour $heure:00:00" ;
	if ( $datetime =~ m/\d{4}-\d{2}-\d{2} \d{2}:00:00/) {
	    $sth->execute( $datetime, $entrees )
        	or die "Echec Requête $req : $DBI::errstr";
        $i++ ;
	}        
}

$sth->finish();
 
# Déconnexion de la base de données
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;
