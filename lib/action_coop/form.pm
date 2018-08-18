package action_coop::form ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( GetListActionsCooperation AddActionCooperation AddEsLastAction_coop ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ; 


sub GetListActionsCooperation {
    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
*
FROM statdb.stat_action_coop
ORDER BY id DESC
SQL
    return GetAllArrayRef($req) ;
}

sub AddActionCooperation {
    my ( $date, $lieu, $type_action, $nom, $type_structure, $nom_structure, $participants, $referent_action ) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "INSERT INTO statdb.stat_action_coop (date, lieu, type, nom, type_structure, nom_structure, participants, referent_action ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute( $date, $lieu, $type_action, $nom, $type_structure, $nom_structure, $participants, $referent_action ) ;
    $sth->finish();
    $dbh->disconnect();
	AddEsLastAction_coop();
}

sub AddEsLastAction_coop {
    my $es_node = GetEsNode() ;
    my %params = ( nodes => $es_node ) ;
    my $index = "action_coop" ;
    my $type = "actions" ;
	#RegenerateIndex($es_node, $index) ;
    my $max_id = GetEsMaxId($index, $type, 'action_id') ;

    my $e = Search::Elasticsearch->new( %params ) ;

    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
    *
FROM statdb.stat_action_coop
WHERE id > ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($max_id);
    my $i = 0 ;
    while (my @row = $sth->fetchrow_array) {
        my ( $id, $date, $lieu, $type_action, $nom, $type_structure, $nom_structure, $referent_action, $participants ) = @row ;
    
        my %index = (
            index   => $index,
            type    => $type,
            id         => $id,
            body    => {
                action_id => $id,
                date => $date,
                lieu => $lieu,
                type_action => $type_action,
				nom => $nom, 
                type_structure => $type_structure,
                nom_structure => $nom_structure,
				participants => $participants,
                referent_action => $referent_action
            }
        ) ;

        $e->index(%index) ;
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}

1;
