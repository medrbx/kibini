package action_culturelle ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( insert_action_culturelle list_actions ) ;

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::Duration;
use FindBin qw( $Bin );

use lib "$Bin/../../scripts/modules/" ;
use dbrequest ;
use fonctions ;

sub insert_action_culturelle {
	my ( $date, $action, $lieu, $type, $public, $partenariat, $participants ) = @_ ;
	my $dbh = dbh('statdb') ;
	my $req = "INSERT INTO stat_action_culturelle (date, action, lieu, type, public, partenariat, participants) VALUES ( ?, ?, ?, ?, ?, ?, ?)" ;
	my $sth = $dbh->prepare($req);
	$sth->execute( $date, $action, $lieu, $type, $public, $partenariat, $participants ) ;
	$sth->finish();
	$dbh->disconnect();
}

sub list_actions {
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
	my $bdd = 'statdb';
	return fetchall_arrayref($bdd, $req);
}

1;