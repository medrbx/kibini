package Kibini::DB;

use Moo;
use DBI ;

use Kibini::Config ;

has dbh => ( is => 'ro', builder => '_get_dbh' );

sub _get_dbh {
    my $conf_database = Kibini::Config->new->database;
    my $db = $conf_database->{db} ;
    my $user = $conf_database->{user} ;
    my $pwd = $conf_database->{pwd} ;
 
    my $dbh = DBI->connect(          
        "dbi:mysql:dbname=$db", 
        $user,
        $pwd,                          
        {
            RaiseError => 1,
            mysql_enable_utf8 => 1
        }
    );

    return $dbh ;
}

1;
