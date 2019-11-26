#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin";

use kibini::db ;
use kibini::elasticsearch ;


    my $es_node = GetEsNode() ;
    my %params = ( nodes => $es_node ) ;
    my $index = "action_culturelle" ;
    my $type = "actions" ;
    my $max_id = GetEsMaxId($index, $type, 'action_id') ;
    $max_id = 0 if ( !defined $max_id ) ;    

    my $e = Search::Elasticsearch->new( %params ) ;

    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
    *
FROM statdb.stat_action_culturelle
WHERE id > ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($max_id);
    my $i = 0 ;
    while (my @row = $sth->fetchrow_array) {
        my ( $id, $date, $action, $lieu, $type_action, $public, $partenariat, $nb_participants ) = @row ;
    
        my %index = (
            index   => $index,
            type    => $type,
            id         => $id,
            body    => {
                action_id => $id,
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
		print Dumper(\%index);
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
	