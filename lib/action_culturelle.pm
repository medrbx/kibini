package action_culturelle ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( insert_action_culturelle list_actions AddEsLastAction_culturelle ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;

sub AddEsLastAction_culturelle {
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
		
		if (defined $date) {
    
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
			);
        }

        $e->index(%index) ;
        $i++ ;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i ;
}

sub insert_action_culturelle {
    my ( $date, $action, $lieu, $type, $public, $partenariat, $participants ) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "INSERT INTO statdb.stat_action_culturelle (date, action, lieu, type, public, partenariat, participants) VALUES ( ?, ?, ?, ?, ?, ?, ?)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute( $date, $action, $lieu, $type, $public, $partenariat, $participants ) ;
    $sth->finish();
    $dbh->disconnect();
    AddEsLastAction_culturelle() ;
}

sub list_actions {
    my $dbh = GetDbh() ;
    my $req = <<SQL;
SELECT
    id,
    date,
    action,
    lieu,
    type,
    public,
    partenariat,
    participants
FROM statdb.stat_action_culturelle
ORDER BY id DESC
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute(); 
    return $sth->fetchall_arrayref({});
    $sth->finish();
    $dbh->disconnect();
}

1;