#! /usr/bin/perl

use strict ;
use warnings ;
use YAML qw(LoadFile);
use DateTime ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use dbrequest ;
use fonctions ;

my $log_message ;
my $process = "admin_sauv_bdd.pl" ;
# On log le début de l'opération
$log_message = "$process : début" ;
log_file($log_message) ;


my $date = DateTime->now(time_zone => "local")->ymd('');

# On anonymise les données Koha
my $dbh = dbh('koha_prod') ;

# On anonymise la plupart des colonnes avec un X pour indiquer qu'elles ont été complétées
my @columns = qw( surname firstname othernames address address2 state email phone mobile emailpro phonepro B_address B_address2 B_state B_email B_phone contactname contactfirstname userid altcontactsurname altcontactfirstname altcontactaddress1 altcontactaddress2 altcontactaddress3 altcontactstate altcontactphone smsalertnumber ) ;
for my $column (@columns) { 
	my $req = "UPDATE koha_prod.borrowers SET $column = NULL WHERE $column = ''" ;
	my $sth = $dbh->prepare($req);
	$sth->execute();
	$req =  "UPDATE koha_prod.borrowers SET $column = 'X' WHERE $column IS NOT NULL" ;
	$sth = $dbh->prepare($req);
	$sth->execute();
	$sth->finish();
}

# Cas de la date de naissance : on retient juste l'année
my $req = "ALTER TABLE `koha_prod`.`borrowers` CHANGE COLUMN `dateofbirth` `dateofbirth` VARCHAR(10) NULL DEFAULT NULL" ;
my $sth = $dbh->prepare($req);
$sth->execute();
$req = "UPDATE koha_prod.borrowers SET dateofbirth = YEAR(dateofbirth)" ;
$sth = $dbh->prepare($req);
$sth->execute();
$sth->finish();
$dbh->disconnect();

# On sauvegarde les deux bases
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $user = $conf->{database}->{user} ;
my $pwd = $conf->{database}->{pwd} ;
my $dir = "$Bin/../dumps" ;
my $koha_ano = "$dir/koha_ano_$date.sql.gz" ;
my $statdb = "$dir/statdb_$date.sql.gz" ;
system( " mysqldump -u $user -p$pwd koha_prod | gzip > $koha_ano  " ) ;
system( " mysqldump -u $user -p$pwd statdb | gzip > $statdb  " ) ;

# On log la fin de l'opération
$log_message = "$process : fin\n" ;
log_file($log_message) ;