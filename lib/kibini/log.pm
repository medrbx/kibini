package kibini::log ;

=pod

=encoding UTF-8

=head1 NOM

kibini::log

=head1 DESCRIPTION

Ce module fournit des fonctions permettant de remplir des fichiers de log.

=cut

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( log_file ) ;

use strict ;
use warnings ;
use POSIX qw(strftime);

use kibini::config ;

sub log_file {
	my ($message) = @_ ;
	
	my $date = strftime "%Y%m%d", localtime ;
	my $datetime = strftime "%Y-%m-%d %H:%M:%S", localtime ;
	
	my $conf = GetConfig('log_crontab')
	my $directory = $conf->{directory} ;
	my $file = "$directory/crontab_lanceur_$date.txt" ;
	
	my $log = "[ $datetime ] $message\n" ;
	open( my $fd, ">>:encoding(utf8)", $file ) or die "Can't write to file '$file' [$!]\n" ;
	print ( $fd $log ) ;
	close( $fd ) ;
}

1;
