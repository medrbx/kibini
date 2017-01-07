package Kibini::Log ;

use Moo ;
use DBI ;

use Kibini::Config ;

has 'log' => ( is  => 'ro' ) ;

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

sub log_file {
	my ($message) = @_ ;
	
	my $date = strftime "%Y%m%d", localtime ;
	my $datetime = strftime "%Y-%m-%d %H:%M:%S", localtime ;
	
	my $fic_conf = "$Bin/../etc/kibini_conf.yaml" ;
	my $conf = LoadFile($fic_conf);
	my $directory = $conf->{log_crontab}->{directory} ;
	my $file = "$directory/crontab_lanceur_$date.txt" ;
	
	my $log = "[ $datetime ] $message\n" ;
	open( my $fd, ">>:encoding(utf8)", $file ) or die "Can't write to file '$file' [$!]\n" ;
	print ( $fd $log ) ;
	close( $fd ) ;
}



1;