package kibini::time ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetDateTime GetSplitDateTime GetSplitDate GetDuration GetEsMaxDateTime GetMinutesFromTime ) ;

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::MySQL ;
use DateTime::Format::Duration ;

use kibini::elasticsearch ;

sub GetDateTime {
    my ($k) = @_ ;
    my $datetime ;
    
    my $dt = DateTime->now(time_zone=>'local') ;
    
    if ( defined $k ) {
        if ( $k eq 'now' ) {
            $datetime = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
        } elsif ( $k eq 'today' ) {
            $datetime = $dt->ymd() ; # YYYY-MM-DD
        } elsif ( $k eq 'today YYYYMMDD' ) {
            $datetime = $dt->ymd('') ; # YYYYMMDD
        } elsif ( $k eq 'yesterday' ) {
            $dt = $dt->subtract( days => 1 ) ;
            $datetime = $dt->ymd() ; # YYYY-MM-DD
        }
    } else {
        $datetime = DateTime::Format::MySQL->format_datetime($dt) ; # YYYY-MM-DD HH:MM:SS
    }

    return $datetime ;
}


sub GetSplitDateTime {
    my ($datetime) = @_ ;

    my $dt = DateTime::Format::MySQL->parse_datetime($datetime) ;
    
    my $year =  $dt->year() ;
    
    my $month = $dt->month() ;
    if ($month < 10 ) {
        $month = "0".$month ;
    }
    
    my $week_number = $dt->week_number() ;
    if ($week_number < 10 ) {
        $week_number = "0".$week_number ;
    }
    
    my $day = $dt->day() ;
    
    my $dow = $dt->dow() ;
    my %dowfr = (
        1 => "1 Lundi",
        2 => "2 Mardi",
        3 => "3 Mercredi",
        4 => "4 Jeudi",
        5 => "5 Vendredi",
        6 => "6 Samedi",
        7 => "7 Dimanche"
    ) ;
    $dow = $dowfr{$dow} ;
    
    my $hour = $dt->hour() ;
    if ($hour < 10 ) {
        $hour = "0".$hour ;
    }
    
    return $year, $month, $week_number, $day, $dow, $hour ;
}

sub GetSplitDate {
    my ($date) = @_ ;

    my $dt = DateTime::Format::MySQL->parse_date($date) ;
    
    my $year =  $dt->year() ;
    
    my $month = $dt->month() ;
    if ($month < 10 ) {
        $month = "0".$month ;
    }
    
    my $week_number = $dt->week_number() ;
    if ($week_number < 10 ) {
        $week_number = "0".$week_number ;
    }
    
    my $day = $dt->day() ;
    
    my $dow = $dt->dow() ;
    my %dowfr = (
        1 => "1 Lundi",
        2 => "2 Mardi",
        3 => "3 Mercredi",
        4 => "4 Jeudi",
        5 => "5 Vendredi",
        6 => "6 Samedi",
        7 => "7 Dimanche"
    ) ;
    $dow = $dowfr{$dow} ;
    
    return $year, $month, $week_number, $day, $dow ;
}


sub GetDuration {
    my ( $datetime1, $datetime2, $type ) = @_ ;

    my $duration ;
    if ( defined $datetime1 && defined $datetime2 ) {
        my $dt1 = DateTime::Format::MySQL->parse_datetime($datetime1) ;
        my $dt2 = DateTime::Format::MySQL->parse_datetime($datetime2) ;
        
        if ( $type eq 'days' ) {
            $duration = $dt1->delta_days($dt2)->in_units('days') ;
        } elsif ( $type eq 'hours' ) {
            $duration = $dt1->delta_ms($dt2)->in_units('hours') ;
        } elsif ( $type eq 'minutes' ) {
            $duration = $dt1->delta_ms($dt2)->in_units('minutes') ;
        } elsif ( $type eq 'HH:MM:SS' ) {
            $duration = $dt1->delta_ms($dt2) ;
            my $formatter = DateTime::Format::Duration->new(
                pattern     => "%H:%M:%S",
                normalize   => 1,
            );
            $duration = $formatter->format_duration($duration);
        }
    }
    
    return $duration ;
}


sub GetEsMaxDateTime {
    my ( $index, $type, $field ) = @_ ;
    my $nodes = GetEsNode() ;
    my %params = ( nodes => $nodes ) ;

    my $e = Search::Elasticsearch->new( %params ) ;

    my $result =  $e->search(
        index => $index,
        type  => $type,
        body    => {
            aggs       => {
                max_datetime => {
                    max => {
                        field => $field
                    }
                }
            }
        }
    );

    return $result->{aggregations}->{max_datetime}->{value_as_string} ; 
}


sub GetMinutesFromTime {
    my ($time_str) = @_;
    my ($hours, $minutes, $seconds) = split(/:/, $time_str);
    return $hours * 60 + $minutes ;
}

1 ;

__END__

=pod

=encoding UTF-8


=head1 NOM

kibini::time


=head1 DESCRIPTION

Ce module fournit des fonctions permettant de gérer les dates et durée.


=head1 FONCTIONS EXPORTEES

=over 4

=item * GetDateTime

Cette fonction renvoie une date ou un datetime.

=over 4

=item *  C<$datetime = GetDateTime('now') ;>

renvoie le datetime au format YYYY-MM-DD HH:MM:SS

=item *  C<$date = GetDateTime('today') ;>

renvoie la date au format YYYY-MM-DD

=item *  C<$date = GetDateTime('today YYYYMMDD') ;>

renvoie la date au format YYYYMMDD

=item *  C<$date = GetDateTime('yesterday') ;>

renvoie la date de la veille au format YYYY-MM-DD

=back

=item * GetSplitDateTime

Cette fonction renvoie, à partir d'un datetime passé en paramètre, les différents éléments de date et d'heure.

=over 4

=item *  C<($year, $month, $week_number, $day, $dayofweek, $hour) = GetSplitDateTime($datetime) ;>

=back

=item * GetDuration

Cette fonction renvoie une durée à partir d'un datetime de début et de fin.

=over 4

=item *  C<$duration = GetDuration($datetime1, $datetime2, 'days')>

renvoie la durée en jours

=item *  C<$duration = GetDuration($datetime1, $datetime2, 'hours')>

renvoie la durée en heures

=item *  C<$duration = GetDuration($datetime1, $datetime2, 'minutes')>

renvoie la durée en minutes

=item *  C<$duration = GetDuration($datetime1, $datetime2, 'HH:MM:SS')>

renvoie la durée au format HH:MM:SS

=back

=item * GetEsMaxDateTime

Cette fonction renvoie la date maximale pour un champ donné d'un index d'Elasticsearch.

=over 4

=item *  C<$esMaxDateTime = GetEsMaxDateTime($index, $type, $field)>

=back

=item * GetMinutesFromTime

Cette fonction renvoie le nombre de minutes à partir d'une heure au format HH:MM:SS.

=over 4

=item *  C<$nb_minutes = GetMinutesFromTime($time)>

=back

=back

=cut
