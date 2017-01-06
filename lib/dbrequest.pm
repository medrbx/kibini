package dbrequest ;

# Ne plus utiliser : recourir à Kibini::DB

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( dbh fetchrow_array fetchrow_arrayref fetchrow_hashref fetchall_arrayref find ) ;

use strict ;
use warnings ;
use YAML qw(LoadFile);
use DBI ;
use FindBin qw( $Bin );


sub find {
	#my ( $Script ) = @_ ;
	print "$Bin\n" ;
}

=pod

=encoding UTF-8

=head1 NOM

dbrequest

=head1 Description

Ce module fournit des fonctions permettant de lancer des requêtes SQL sur les bases de données koha_prod et statdb.

=head1 Fonctions exportées

=head2 dbh

Cette fonction permet de créer un objet dbh pour la description et la connexion à la base de donnée choisie.

Les identifiants de connexion aux bases de données (supposant un utilisateur commun aux deux bases) sont stockés dans le fichier config.xml.

La fonction comprend un paramètre obligatoire, correspondant au nom de la base de données choisie.

Exemple :
my $dbh = dbh($bdd) ;

=cut

sub dbh {
	my ($bdd) = @_ ;
	
	# On récupère les paramètres de connexion
	# my $fic_conf = "$Bin/../conf.yaml" ; # on se place au niveau du script qui appelle 
	# On met le chemi en absolu pour qu'il puisse être appelé depuis Dancer...
	my $fic_conf = "$Bin/../etc/kibini_conf.yaml" ;
	my $conf = LoadFile($fic_conf);
	my $user = $conf->{database}->{user} ;
	my $pwd = $conf->{database}->{pwd} ;
 
	# On se connecte à la base de données
	my $dbh = DBI->connect(          
		"dbi:mysql:dbname=$bdd", 
		$user,                          
		$pwd,                          
		{ RaiseError => 1, mysql_enable_utf8 => 1},         
	) or die $DBI::errstr;
	return $dbh ;
}


=head2 fetchrow_array

Cette fonction permet d'exécuter une requête SQL et de renvoyer le résultat en ligne, sous forme de liste.

Elle utilise la fonction dbh (cf ci-dessus).

Elle comprend deux paramètres obligatoires : le nom de la base de données sur laquelle porte la requête et la requête elle-même.

Exemple :
my @result = fetchrow_array($bdd, $req) ;

=cut

sub fetchrow_array {
	my ($bdd, $req) = @_ ;
	my $dbh = dbh($bdd) ;
	my $sth = $dbh->prepare($req);
	$sth->execute(); 	
	return $sth->fetchrow_array;
	$sth->finish();
	$dbh->disconnect();
}


=head2 fetchrow_arrayref

Cette fonction permet d'exécuter une requête SQL et de renvoyer le résultat en ligne, sous forme de référence de liste.

Elle utilise la fonction dbh (cf ci-dessus).

Elle comprend deux paramètres obligatoires : le nom de la base de données sur laquelle porte la requête et la requête elle-même.

Exemple :
my $result = fetchrow_arrayref($bdd, $req) ;

=cut

sub fetchrow_arrayref {
	my ($bdd, $req) = @_ ;
	my $dbh = dbh($bdd) ;
	my $sth = $dbh->prepare($req);
	$sth->execute(); 	
	return $sth->fetchrow_arrayref;
	$sth->finish();
	$dbh->disconnect();
}


=head2 fetchrow_hashref

Cette fonction permet d'exécuter une requête SQL et de renvoyer le résultat en ligne, sous forme de référence de hash.

Elle utilise la fonction dbh (cf ci-dessus).

Elle comprend deux paramètres obligatoires : le nom de la base de données sur laquelle porte la requête et la requête elle-même.

Exemple :
my $result = fetchrow_hashref($bdd, $req) ;

=cut

sub fetchrow_hashref {
	my ($bdd, $req) = @_ ;
	my $dbh = dbh($bdd) ;
	my $sth = $dbh->prepare($req);
	$sth->execute(); 
	return $sth->fetchrow_hashref();
	$sth->finish();
	$dbh->disconnect();
}



=head2 fetchall_arrayref

Cette fonction permet d'exécuter une requête SQL et de renvoyer le résultat global, sous forme de référence de liste.

Elle utilise la fonction dbh (cf ci-dessus).

Elle comprend deux paramètres obligatoires : le nom de la base de données sur laquelle porte la requête et la requête elle-même.

Exemple :
my $result = fetchall_arrayref($bdd, $req) ;

=cut

sub fetchall_arrayref {
	my ($bdd, $req) = @_ ;
	my $dbh = dbh($bdd) ;
	my $sth = $dbh->prepare($req);
	$sth->execute(); 
	return $sth->fetchall_arrayref({});
	$sth->finish();
	$dbh->disconnect();
}

1 ;
