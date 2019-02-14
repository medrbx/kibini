package Kibini::Email;

use Moo;
use Encode qw(encode);

has email_data => ( is => 'ro' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{email_data} ) {
        $arg->{email_data}->{from} = $args[0]->{email_data}->{from};
        $arg->{email_data}->{to} = $args[0]->{email_data}->{to};
        $arg->{email_data}->{subject} = $args[0]->{email_data}->{subject};
        $arg->{email_data}->{message} = $args[0]->{email_data}->{message};
    }

    return $arg;
}

sub send_email {
    my ($self) = @_;    
    my $from = Encode::encode('MIME-Q', $self->{email_data}->{from});
    my $to = Encode::encode('MIME-Q', $self->{email_data}->{to});
    my $subject = Encode::encode('MIME-Q', $self->{email_data}->{subject});
    my $msg = $self->{email_data}->{message};

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
