package Kibini::DB ;

use Moo ;
use DBI ;

use Kibini::Config ;

has 'dbh' => ( is  => 'ro' ) ;

around BUILDARGS => sub {
    my $orig = shift ;
    my $class = shift ;

    my $conf_database = Kibini::Config->new('database')->get_conf() ;

	my $db = $conf_database->{db} ;
	my $user = $conf_database->{user} ;
	my $pwd = $conf_database->{pwd} ;

	my $dbh = DBI->connect(          
		"dbi:mysql:dbname=$db", 
		$user,                          
		$pwd,                          
		{ RaiseError => 1, mysql_enable_utf8 => 1},         
	) or die $DBI::errstr;
	
    return $class->$orig( 
		dbh => $dbh
	);
};

sub get_dbh {
    my $self = shift;
    if(@_) {
        $self->{dbh} = $_[0];
    }
    return $self->{dbh};
}

sub get_all_arrayref {
    my $self = shift ;
    my ($req) = @_ ;
    my $dbh = $self->{dbh} ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ; 
    return $sth->fetchall_arrayref({}) ;
    $sth->finish() ;
    $dbh->disconnect() ;
}

1;