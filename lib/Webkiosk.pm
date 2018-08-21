package Webkiosk;

use Moo;

use Kibini::DB;
use kibini::time;

has dbh => ( is => 'ro' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{dbh} ) {
        $arg->{dbh} = $args[0]->{dbh};
    } else {
        my $dbh = Kibini::DB->new;
        $dbh = $dbh->dbh;
        $arg->{dbh} = $dbh;
    }
	
	if ( $args[0]->{adherent} ) {
        my %adh = %{$args[0]->{adherent}};
        foreach my $k (keys(%adh)) {
            $arg->{$k} = $adh{$k};
        }
    }
	
    if ( $args[0]->{date} ) {
        $arg->{date} = $args[0]->{date};
    } else {
        $arg->{date} = GetDateTime('today');
    }

    return $arg;
}


1;