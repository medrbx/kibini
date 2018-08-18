#!/usr/bin/perl

use warnings;
use strict;
use Text::CSV ;
use FindBin qw( $Bin ) ;
use Data::Dumper;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;

my $log_message ;
my $process = "statdb_wifi.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# Connexion à la base de données
my $dbh = GetDbh() ;

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO statdb.stat_wifi (wifi_id, start_wifi, end_wifi, login, borrowernumber)
VALUES (?, ?, ?, ?, ?)
SQL

# Traitement de la requête
open my $fic, "<", "/home/kibini/wk_web_wifi_logs.csv";

my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    auto_diag => 1, # permet diagnostic immédiat des erreurs
    });

my $sth = $dbh->prepare($req);

$csv->column_names (qw( wifi_id start_wifi end_wifi login ));
while (my $row = $csv->getline_hr ($fic)) {
	$row->{borrowernumber} = getBorrowernumberFromConnexionId($dbh, $row->{login});
	print Dumper($row) ;
	$sth->execute( $row->{wifi_id}, $row->{start_wifi}, $row->{end_wifi}, $row->{login}, $row->{borrowernumber} ) or die "Echec Requête $req : $DBI::errstr";
}
close $fic;

$sth->finish();
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;

sub getBorrowernumberFromConnexionId {
	my ($dbh, $connexion_id) = @_;
	my $req = "SELECT borrowernumber FROM koha_prod.borrowers WHERE userid = ?";
	my $sth = $dbh->prepare($req);
	$sth->execute( $connexion_id );
	my $borrowernumber = $sth->fetchrow_array();
	return $borrowernumber;	
}