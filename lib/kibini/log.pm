package kibini::log ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( AddCrontabLog ) ;

use strict ;
use warnings ;

use kibini::config ;
use kibini::time ;

sub AddCrontabLog {
	my ($message) = @_ ;
	
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

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::log

=head1 DESCRIPTION

Ce module fournit des fonctions permettant de remplir des fichiers de log.

=cut