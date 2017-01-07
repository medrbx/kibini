package kibini::db ;

=pod

=encoding UTF-8

=head1 NOM

kibini::db

=head1 DESCRIPTION

Ce module fournit des fonctions permettant d'accéder aux bases de données de Kibini.

=cut

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetDbh GetAllArrayRef ) ;

use strict ;
use warnings ;
use DBI ;

use kibini::config ;

sub GetDbh {
	# On récupère les paramètres de connexion
	my $conf_database = GetConfig('database') ;
	my $db = $conf_database->{db} ;
	my $user = $conf_database->{user} ;
	my $pwd = $conf_database->{pwd} ;
 
	# On se connecte à la base de données
	my $dbh = DBI->connect(          
		"dbi:mysql:dbname=$db", 
		$user,                          
		$pwd,                          
		{ RaiseError => 1, mysql_enable_utf8 => 1},         
	) or die $DBI::errstr;
	return $dbh ;
}


sub GetAllArrayRef {
    my ($req) = @_ ;
	
	my $dbh = GetDbh() ;
	my $sth = $dbh->prepare($req) ;
    $sth->execute() ; 
    my $result = $sth->fetchall_arrayref({}) ;
	$sth->finish() ;
	$dbh->disconnect() ;

	return $result ;    
}

1;