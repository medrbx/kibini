package Kibini::Time;

use Moo;
use DateTime;
use DateTime::Format::MySQL;
use DateTime::Format::Duration;
use Kibini::DB;

has start_value => ( is => 'ro' );
has start_format => ( is => 'ro' );
has start_dt => ( is => 'ro' );

has end_value => ( is => 'ro' );
has end_format => ( is => 'ro' );
has end_dt => ( is => 'ro' );

has duration => ( is => 'ro' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{start} ) {
        $arg->{start_value} = $args[0]->{start}->{value};
        $arg->{start_format} = $args[0]->{start}->{format};
        $arg->{start_dt} = _get_datetime_object($arg->{start_value}, $arg->{start_format});
    }

    if ( $args[0]->{end} ) {
        $arg->{end_value} = $args[0]->{end}->{value};
        $arg->{end_format} = $args[0]->{end}->{format};
        $arg->{end_dt} = _get_datetime_object($arg->{end_value}, $arg->{end_format});
    }

    return $arg;
}

sub get_duration {
    my ($self, $param) = @_;

    if ( defined $self->{start_dt} && defined $self->{end_dt} ) {
        my $dt1 = $self->{end_dt};
        my $dt2 = $self->{start_dt};
        if ( $param->{type} eq 'years' ) {
            $self->{duration} = $dt1->year - $dt2->year;
        } elsif ( $param->{type} eq 'days' ) {
            $self->{duration} = $dt1->delta_ms($dt2)->in_units('days');
        } elsif ( $param->{type} eq 'hours' ) {
            $self->{duration} = $dt1->delta_ms($dt2)->in_units('hours');
        } elsif ( $param->{type} eq 'minutes' ) {
            $self->{duration} = $dt1->delta_ms($dt2)->in_units('minutes');
        } elsif ( $param->{type} eq 'HH:MM:SS' ) {
            $self->{duration} = $dt1->delta_ms($dt2);
            my $formatter = DateTime::Format::Duration->new(
                pattern     => "%H:%M:%S",
                normalize   => 1,
            );
            $self->{duration} = $formatter->format_duration($self->{duration});
        }
    }
    
    return $self->{duration};
}

sub _get_datetime_object {
    my ($value, $format) = @_;
    my $dt;

    if ($format eq 'datetime') {
        $dt = DateTime::Format::MySQL->parse_datetime($value);
    } elsif ($format eq 'date') {
        $dt = DateTime::Format::MySQL->parse_date($value);
    }

    return $dt;
}

1;
