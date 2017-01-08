package kibini::config ;

=pod

=encoding UTF-8

=head1 NOM

kibini::config

=head1 DESCRIPTION

Ce module permet d'extraire les éléments de configuration depuis le fichier etc/kibini_conf.yaml.

=cut

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetConfig ) ;

use FindBin qw( $Bin );
use YAML qw(LoadFile) ;

=head1 FONCTIONS EXPORTEES

=head2 GetConfig

Utilisée sans paramètre, cette fonction renvoie l'ensemble des renseignements de configuration sous forme de référence de hash.

Exemple : my $conf = GetConfig() ;

Utilisée avec un paramètre, cette fonction renvoie uniquement les renseignements de configuration de l'élément souhaité sous forme de référence de hash.

Exemple : my $conf_database = GetConfig('database') ;

=cut

sub GetConfig {
	my ($k) = @_ ;

    my $file = "$Bin/../etc/kibini_conf.yaml" ;
    my $file_conf = LoadFile($file);
	
    my $conf ;
    if ( defined $k ) {
        my %config = (
            database => $file_conf->{'database'},
            elasticsearch => $file_conf->{'conf'}->{'elasticsearch'}
            nedap => $file_conf->{'conf'}->{'nedap'},
            piwik => $file_conf->{'conf'}->{'piwik'},
            log_crontab => $file_conf->{'conf'}->{'log_crontab'},
            suggestions => $file_conf->{'conf'}->{'suggestions'}
        ) ;
        $conf = $config{$k} ;
    } else {
        $conf = $file_conf ;
    }

    return $conf
};

1;
