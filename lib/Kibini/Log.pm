package Kibini::Log;

use Moo;
use Kibini::Config ;
use Kibini::Time ;

has log_file => ( is => 'ro', default => sub { _get_log_file() } );
has log_message => ( is => 'ro' );

sub add_log {
    my ($self, $message) = @_;

    my $datetime = Kibini::Time->new->get_date_and_time;
    $self->{log_message} = "[ $datetime ] $message\n" ;

    open( my $fd, ">>:encoding(utf8)", $self->{log_file} ) or die "Can't write to file \"$self->{file}\" [$!]\n" ;
    print ( $fd $self->{log_message} ) ;
    close( $fd ) ;
    
    return $self;
}

sub _get_log_file {
    my $conf = Kibini::Config->new->log_crontab;
    my $directory = $conf->{directory};
    my $date = Kibini::Time->new->get_date_and_time('today YYYYMMDD');
    my $file = "$directory/crontab_lanceur_$date.txt";
    return $file;
}

1;

__END__

sub add_crontab_log {
    my ($self, $message) = @_ ;
    
    my $date = GetDateTime('today YYYYMMDD') ;
    my $datetime = GetDateTime('now') ; ;
    
    my $conf = GetConfig('log_crontab') ;
    my $directory = $conf->{directory} ;
    my $file = "$directory/crontab_lanceur_$date.txt" ;
    
    my $log = "[ $datetime ] $message\n" ;
    open( my $fd, ">>:encoding(utf8)", $file ) or die "Can't write to file '$file' [$!]\n" ;
    print ( $fd $log ) ;
    close( $fd ) ;
}

1;
