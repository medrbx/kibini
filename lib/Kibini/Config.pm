package Kibini::Config ;

use Moo ;
use FindBin qw( $Bin );
use YAML qw(LoadFile) ;

has 'conf' => ( is  => 'ro' ) ;

around BUILDARGS => sub {
    my $orig = shift ;
    my $class = shift ;
	my ($k) = @_ ;

    my $file = "$Bin/../etc/kibini_conf.yaml" ;
    my $file_conf = LoadFile($file);
	my %config = (
		database => $file_conf->{'database'},
		piwik => $file_conf->{'conf'}->{'piwik'} 
	) ;
	
	my $conf = $config{$k} ;

    return $class->$orig( 
		conf => $conf
	);
};

sub get_conf {
    my $self = shift;
    if(@_) {
        $self->{conf} = $_[0];
    }
    return $self->{conf};
}

1;