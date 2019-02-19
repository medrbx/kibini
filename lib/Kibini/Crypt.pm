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

    my $conf = Kibini::Config->new->crypt;
    $arg->{type} = $conf->{type};
    
    if ( $arg->{type} eq 'Bcrypt' ) {
        $arg->{salt} = $conf->{salt};
    }

    return $arg;
}

sub crypt {
    my ($self, $param) = @_;

    my $crypted_string;    
    if ($self->{type} eq 'Bcrypt' ) {
        my $salt = $self->{'salt'};
        my $settings = '$2a$08$'. $salt;
        $crypted_string = Crypt::Eksblowfish::Bcrypt::bcrypt($param->{string}, $settings);
        $crypted_string =~ s/^\$2a\$\d{2}\$[A-Za-z0-9+\\.]{22}(.+)/$1/;
    } elsif ($self->{type} eq 'SHA1' ) {
        $crypted_string = sha1_hex($param->{string});
    }
    return $crypted_string;
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
