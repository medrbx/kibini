#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
use FindBin qw( $Bin ) ;

use lib "$Bin/modules/" ;
use dbrequest ;

# Connexion à la base de données
my $bdd = "statdb" ;
my $dbh = dbh($bdd) ;

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO stat_entrees (datetime, entrees)
VALUES (?, ?)
SQL
 
# Traitement de la requête
my $sth = $dbh->prepare($req);

while (my $ligne = <>) {
	my $datetime ;
#	my $ligne =~ s/\,/\t/mg ;
	my ($date, $heure, $entrees) = split /\,/, $ligne ;
	if ($date =~ /^\(/ & $heure =~ /^[0-9]/) {
		$date =~ s/(\)|\()//g ;
		my ($jour, $mois, $annee) = split /-/, $date ;
		$heure =~ /(\d*)(h.)/ ;
		$heure = $1 ;
		if ($heure !~ /\d{2}/) {
			$heure = "0$heure" ;
		}
		$datetime = "$annee-$mois-$jour $heure:00:00" ;
		$sth->execute( $datetime, $entrees )
    			or die "Echec Requête $req : $DBI::errstr";
	}		
}

$sth->finish();
 
# Déconnexion de la base de données
$dbh->disconnect();
