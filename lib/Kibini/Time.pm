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

sub get_date_and_time {
    my ($self, $param) = @_;

    my $date_and_time;
    
    my $dt = $self->{now_dt};
    
    if ( defined $param ) {
        if ( $param eq 'now' ) {
            $date_and_time = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
        } elsif ( $param eq 'today' ) {
            $date_and_time = $dt->ymd() ; # YYYY-MM-DD
        } elsif ( $param eq 'today YYYYMMDD' ) {
            $date_and_time = $dt->ymd('') ; # YYYYMMDD
        } elsif ( $param eq 'yesterday' ) {
            $dt = $dt->subtract( days => 1 ) ;
            $date_and_time = $dt->ymd() ; # YYYY-MM-DD
        } elsif ( $param eq 'yesterday YYYYMMDD' ) {
            $dt = $dt->subtract( days => 1 ) ;
            $date_and_time = $dt->ymd('') ; # YYYYMMDD
        }
    } else {
        $date_and_time = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
    }

    return $date_and_time;
}

sub get_date_and_time_by_element {
    my ($self, $param) = @_;
    my $element = {};

    my $dt;
    if ( $param->{date_to_plit} ) {
        if ( $param->{date_to_plit} eq 'start') {
            $dt = $self->{start_dt};
        } elsif ( $param->{date_to_plit} eq 'end') {
            $dt = $self->{end_dt};
        } elsif ( $param->{date_to_plit} eq 'now') {
            $dt = $self->{now_dt};
        }
    } else {
        $dt = $self->{now_dt};
    }

    if ( $param->{element_to_get} ) {
        my $element_to_get = $param->{element_to_get};
        $element->{$element_to_get} = $dt->$element_to_get;
    } else {
        my @elements_to_get = qw (year month week_number day dow hour);
        foreach my $element_to_get (@elements_to_get) {;
            $element->{$element_to_get} = $dt->$element_to_get;
        }
    }

    my @elements_to_mod = qw (month week_number hour);
    foreach my $element_to_mod (@elements_to_mod) {
        if ($element->{$element_to_mod}) {
            if ($element->{$element_to_mod} < 10) {
                $element->{$element_to_mod} = "0" . $element->{$element_to_mod};
            }
        }
    }

    if ($element->{dow}) {
        my %dowfr = (
            1 => "1 Lundi",
            2 => "2 Mardi",
            3 => "3 Mercredi",
            4 => "4 Jeudi",
            5 => "5 Vendredi",
            6 => "6 Samedi",
            7 => "7 Dimanche"
        );
        $element->{dow} = $dowfr{$element->{dow}}
    }
        

    return $element;
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
