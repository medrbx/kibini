#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::config ;
use kibini::db ;
use kibini::time ;
use kibini::log ;

my $log_message ;
my $process = "admin_sauv_bdd.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;


my $date = GetDateTime('today YYYYMMDD') ;

# On anonymise les données Koha
my $dbh = GetDbh() ;

# On anonymise la plupart des colonnes avec un X pour indiquer qu'elles ont été complétées
my @columns = qw( surname firstname othernames address address2 state email phone mobile emailpro phonepro B_address B_address2 B_state B_email B_phone contactname contactfirstname altcontactsurname altcontactfirstname altcontactaddress1 altcontactaddress2 altcontactaddress3 altcontactstate altcontactphone smsalertnumber ) ;
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


# Cas du userid : on le met à null
$req = "UPDATE koha_prod.borrowers SET userid = NULL WHERE userid IS NOT NULL";
$sth = $dbh->prepare($req);
$sth->execute();
$dbh->disconnect();

# On sauvegarde les deux bases
my $conf = GetConfig('database') ;
my $user = $conf->{user} ;
my $pwd = $conf->{pwd} ;
my $dir = "$Bin/../data" ;
my $koha_ano = "$dir/koha_ano_$date.sql.gz" ;
my $statdb = "$dir/statdb_$date.sql.gz" ;
system( " mysqldump -u $user -p$pwd koha_prod | gzip > $koha_ano  " ) ;
system( " mysqldump -u $user -p$pwd statdb | gzip > $statdb  " ) ;

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;