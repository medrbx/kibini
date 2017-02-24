package action_culturelle ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( insert_action_culturelle list_actions ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;

sub insert_action_culturelle {
    my ( $date, $action, $lieu, $type, $public, $partenariat, $participants ) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "INSERT INTO statdb.stat_action_culturelle (date, action, lieu, type, public, partenariat, participants) VALUES ( ?, ?, ?, ?, ?, ?, ?)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute( $date, $action, $lieu, $type, $public, $partenariat, $participants ) ;
    $sth->finish();
    $dbh->disconnect();
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