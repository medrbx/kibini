#!/usr/bin/perl

use strict ;
use warnings ;
use Search::Elasticsearch ; 
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;
use kibini::log ;
use kibini::time ;

my $log_message ;
my $process = "es_action_culturelle.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode() ;

# my $es_maxId = GetEsMaxId() ;
my $i = action_culturelle($es_node) ;

# On log la fin de l'opération
$log_message = "$process : $i rows indexed" ;
AddCrontabLog($log_message) ;
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;


sub action_culturelle {
    my ($maxdatetime, $es_node) = @_ ;
    my %params = ( nodes => $es_node ) ;
    my $index = "action_culturelle" ;
    my $type = "actions" ;

    my $e = Search::Elasticsearch->new( %params ) ;

    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
	*
FROM statdb.stat_action_culturelle
-- WHERE id > ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute();
    $i = 0 ;
    while (my @row = $sth->fetchrow_array) {
        my ( $id, $date, $action, $lieu, $type_action, $public, $partenariat, $nb_participants ) = @row ;
    
        my %index = (
            index   => $index,
            type    => $type,
			id 		=> $id,
            body    => {
                date => $date,
                action => $action,
				lieu => $lieu,
                type_action => $type_action,
                public => $public,
                partenariat => $partenariat,
                nb_participants => $nb_participants
            }
        ) ;

        $e->index(%index) ;
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}