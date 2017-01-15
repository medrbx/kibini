package kibini::config::koha ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetKohaProUrl GetKohaOpacUrl GetKohaRestUrl GetKohaIlsdiUrl ) ;

use kibini::config ;

sub GetKohaProUrl {
    my $conf = GetConfig('koha') ;
    return $conf->{'pro'} ;
}

sub GetKohaOpacUrl {
    my $conf = GetConfig('koha') ; ;
    return $conf->{'opac'} ;
}

sub GetKohaRestUrl {
    my $conf = GetConfig('koha') ;
    my $opac = $conf->{'opac'} ;
    my $rest = $conf->{'rest'} ;
    my $resturl = $opac . "/" . $rest ;
    return $resturl ;
}

sub GetKohaIlsdiUrl {
    my $conf = GetConfig('koha') ;
    my $opac = $conf->{'opac'} ;
    my $ilsdi = $conf->{'ilsdi'} ;
    my $ilsdiurl = $opac . "/" . $ilsdi ;
    return $ilsdiurl ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::config::koha

=head1 DESCRIPTION

Ce module permet de construire des url Koha pour l'utilisation de web services.

=cut