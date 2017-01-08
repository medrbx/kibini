package kibini::time ;

=pod

=encoding UTF-8

=head1 NOM

kibini::time

=head1 DESCRIPTION

Ce module fournit des fonctions de gérer les dates et durée.
Sont nécessaires l'obtention de :
- durée en jour
- durée en minute

=cut

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetDateTime GetSplitDateTime GetDuration ) ; # duree_pret duree

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::MySQL ;

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
        }
    }
	
    return $duration ;
}

1 ;