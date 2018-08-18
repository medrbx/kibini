package kibini::email ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( SendEmail ) ;

use strict ;
use warnings ;
use Encode qw(encode) ;

sub SendEmail {
    my ($from, $to, $subject, $msg) = @_;    
    $from = Encode::encode('MIME-Q', $from);
    $to = Encode::encode('MIME-Q', $to);
    $subject = Encode::encode('MIME-Q', $subject);

    open (SENDMAIL, "| /usr/sbin/sendmail -t") or die("Failed to open pipe to sendmail: $!");
    binmode(SENDMAIL, ":utf8");
    print SENDMAIL <<"EOF";
Content-Transfer-Encoding: 8bit
Content-type: text/plain; charset=UTF-8
Subject: $subject
From: $from
To: $to
$msg
EOF
    close (SENDMAIL);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NOM

kibini::email

=head1 DESCRIPTION

Ce module permet d'envoyer des emails.

=cut