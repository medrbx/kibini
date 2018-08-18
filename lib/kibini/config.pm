package kibini::config ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetConfig ) ;

use FindBin qw( $Bin );
use YAML qw(LoadFile) ;

sub GetConfig {
    my ($k) = @_ ;

    my $file = "$Bin/../etc/kibini_conf.yaml" ;
    my $file_conf = LoadFile($file);
    
    my $conf ;
    if ( defined $k ) {
        my %config = (
            database => $file_conf->{'database'},
            elasticsearch => $file_conf->{'elasticsearch'},
            nedap => $file_conf->{'nedap'},
            piwik => $file_conf->{'piwik'},
            log_crontab => $file_conf->{'log_crontab'},
            ftp_logs_portail => $file_conf->{'ftp_logs_portail'},
            suggestions => $file_conf->{'suggestions'},
            koha => $file_conf->{'koha'},
			crypt => $file_conf->{'crypt'},
			mail => $file_conf->{'mail'}
        ) ;
        $conf = $config{$k} ;
    } else {
        $conf = $file_conf ;
    }

    return $conf
};

1;

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::config

=head1 DESCRIPTION

Ce module permet d'extraire les éléments de configuration depuis le fichier etc/kibini_conf.yaml.

=head1 FONCTIONS EXPORTEES

=head2 GetConfig

Utilisée sans paramètre, cette fonction renvoie l'ensemble des renseignements de configuration sous forme de référence de hash.

Exemple : my $conf = GetConfig() ;

Utilisée avec un paramètre, cette fonction renvoie uniquement les renseignements de configuration de l'élément souhaité sous forme de référence de hash.

Exemple : my $conf_database = GetConfig('database') ;

=cut