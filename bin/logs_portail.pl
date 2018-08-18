#!/usr/bin/perl

use strict;
use warnings ;
use Net::FTP ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::config ;
use kibini::log ;

my $log_message ;
my $process = "logs_portail.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

my $conf = GetConfig('ftp_logs_portail') ;
my $host = $conf->{host} ;
my $user = $conf->{user} ;
my $password = $conf->{password} ;
my $dir = $conf->{dir_logs_portail} ;

my $ftp = Net::FTP->new($host) or die "Impossible d'ouvrir $host\n";
$ftp->login($user, $password) or die "Impossible de connecter $user\n";

my @logs = qw (access error watchdog ) ;
foreach my $log ( @logs ) {
    my $glob = "*$log*" ;
    my @files = $ftp->ls($glob);
    foreach my $file (@files) {
        my $file_mdtm = $ftp->mdtm($file) ;
        my $time = 3600*24*1;  # 1 jour en secondes
        if (time - $file_mdtm <= $time) {
            $ftp->get($file, "$dir/$log/$file") or die "Impossible de télécharger $file\n" ;
            $log_message = "$process : $file downloaded" ;
            AddCrontabLog($log_message) ;
        }
    }
}

$ftp->quit ;

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;