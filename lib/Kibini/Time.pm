package Kibini::Time;

use Moo;
use DateTime;
use DateTime::Format::MySQL;
use DateTime::Format::Duration;

has duration => ( is => 'ro' );

sub get_duration {
    my ( $self, $param ) = @_ ;

    if ( defined $param->{datetime1} && defined $param->{datetime1} ) {
        my $dt1 = DateTime::Format::MySQL->parse_datetime($param->{datetime1}) ;
        my $dt2 = DateTime::Format::MySQL->parse_datetime($param->{datetime2}) ;
        
        if ( $param->{type} eq 'days' ) {
            $self->{duration} = $dt1->delta_days($dt2)->in_units('days') ;
        } elsif ( $param->{type} eq 'hours' ) {
            $self->{duration} = $dt1->delta_ms($dt2)->in_units('hours') ;
        } elsif ( $param->{type} eq 'minutes' ) {
            $self->{duration} = $dt1->delta_ms($dt2)->in_units('minutes') ;
        } elsif ( $param->{type} eq 'HH:MM:SS' ) {
            $self->{duration} = $dt1->delta_ms($dt2) ;
            my $formatter = DateTime::Format::Duration->new(
                pattern     => "%H:%M:%S",
                normalize   => 1,
            );
            $self->{duration} = $formatter->format_duration($self->{duration});
        }
    }
    
    return $self;
}

1;