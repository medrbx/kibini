#! /usr/bin/perl

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile);
use DateTime ;

# On récupère les éléments de connexion MySQL
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $user = $conf->{database}->{user} ;
my $pwd = $conf->{database}->{pwd} ;

my $date = DateTime->now(time_zone => "local")->ymd('');
my $dir = "$Bin/../dumps" ;
my $file = "$dir/koha_prod_$date.sql" ;

# script initialement écrit en bash : on récupère tel quel...
system( "gunzip $file.gz" ) ;
system( "mysql -u $user -p$pwd koha_prod < $file" ) ;

# on corrige les ccodes des périodiques
system( "mysql -u $user -p$pwd koha_prod -e \"UPDATE koha_prod.items s JOIN statdb.lib_periodiques p ON s.biblionumber = p.biblionumber SET s.ccode = p.ccode\"" ) ;

system( "rm $file" ) ;
