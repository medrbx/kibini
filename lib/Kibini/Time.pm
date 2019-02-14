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

has now_dt => ( is => 'ro' );

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

    if ( not defined $args[0]->{start} ) {
        $arg->{now_dt} = _get_datetime_object();
    }

    return $arg;
}

#sub get_date {
#    my ($self, $param) = @_ ;
#    my $datetime ;
#    
#    my $dt = DateTime->now(time_zone=>'local') ;
#    
#    if ( defined $k ) {
#        if ( $k eq 'now' ) {
#            $datetime = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
#        } elsif ( $k eq 'today' ) {
#            $datetime = $dt->ymd() ; # YYYY-MM-DD
#        } elsif ( $k eq 'today YYYYMMDD' ) {
#            $datetime = $dt->ymd('') ; # YYYYMMDD
#        } elsif ( $k eq 'yesterday' ) {
#            $dt = $dt->subtract( days => 1 ) ;
#            $datetime = $dt->ymd() ; # YYYY-MM-DD
#        }
#    } else {
#        $datetime = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
#    }

#    return $datetime ;
#}

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
    
    if ( defined $value && defined $format) {
        if ($format eq 'datetime') {
            $dt = DateTime::Format::MySQL->parse_datetime($value);
        } elsif ($format eq 'date') {
            $dt = DateTime::Format::MySQL->parse_date($value);
        }
    } else {
        $dt = DateTime->now(time_zone=>'local');
    }

    return $dt;
}

1;
