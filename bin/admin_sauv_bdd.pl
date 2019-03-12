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

# On sauvegarde statdb
my $conf = GetConfig('database') ;
my $user = $conf->{user} ;
my $pwd = $conf->{pwd} ;
my $dir = "$Bin/../data" ;

my $statdb = "$dir/statdb_$date.sql.gz" ;
system( " mysqldump -u $user -p$pwd statdb | gzip > $statdb  " ) ;

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;