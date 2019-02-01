package Kibini::Crypt;

use Moo;
use Crypt::Eksblowfish::Bcrypt;
use Digest::SHA1 qw(sha1_hex);

use Kibini::Config;

has 'type' => ( is  => 'rw' );
has 'salt' => ( is  => 'rw' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{type} ) {
        $arg->{type} = $args[0]->{type};
    } else {
        my $conf = Kibini::Config->new->crypt;
        $arg->{salt} = $conf->{'salt'};
    }

    return $arg;
}

sub crypt {
    my ($self, $string) = @_;
    
    my $salt = $self->{'salt'};
    my $settings = '$2a$08$'.$salt;
    
    return Crypt::Eksblowfish::Bcrypt::bcrypt($string, $settings);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::crypt

=head1 DESCRIPTION

Ce module fournit un objet et une méthode permettant de crypter un champ.

=cut
