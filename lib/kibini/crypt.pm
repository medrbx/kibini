package kibini::crypt ;

use Moo ;
use Crypt::Eksblowfish::Bcrypt ;

use kibini::config ;

has 'salt' => (
    is  => 'rw'
) ;

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $conf = GetConfig('cryptage') ;
    my $salt = $conf->{'salt'} ;

    return $class->$orig(salt => $salt);
};

sub crypt {
    my ($self) = shift ;
    my ($string) = @_ ;
    
    my $salt = $self->{'salt'} ;
    my $settings = '$2a$08$'.$salt ;
    
    return Crypt::Eksblowfish::Bcrypt::bcrypt($string, $settings) ;
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