package Kibini::Config;

use Moo;

use FindBin qw( $Bin );
use YAML qw(LoadFile);

has dataconf => ( is => 'ro', builder => '_get_dataconf' );

sub crypt {
    my ($self) = @_;
    return $self->{dataconf}->{crypt};
}

sub database {
    my ($self) = @_;
    return $self->{dataconf}->{database};
}

sub elasticsearch {
    my ($self) = @_;
    return $self->{dataconf}->{elasticsearch};
}

sub ftp_logs_portail {
    my ($self) = @_;
    return $self->{dataconf}->{ftp_logs_portail};
}

sub koha {
    my ($self) = @_;
    return $self->{dataconf}->{koha};
}

sub log_crontab {
    my ($self) = @_;
    return $self->{dataconf}->{log_crontab};
}

sub nedap {
    my ($self) = @_;
    return $self->{dataconf}->{nedap};
}

sub piwik {
    my ($self) = @_;
    return $self->{dataconf}->{piwik};
}

sub suggestions {
    my ($self) = @_;
    return $self->{dataconf}->{suggestions};
}

sub _get_dataconf {
    my $file = "$Bin/../etc/kibini_conf.yaml";
    my $dataconf = LoadFile($file);
    return $dataconf;
}

1;
