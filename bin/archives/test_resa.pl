#! /usr/bin/perl

use Modern::Perl;
use utf8;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::log;
use kibini::time;

    my $dbh = GetDbh();
    my $req = "SELECT reserve_id, itemnumber, borrowernumber, waitingdate, issuedate, waiting_duration FROM statdb.stat_reserves WHERE reservedate >= '2018-04-09' AND issuedate IS NOT NULL ORDER BY issuedate DESC";
    my $sth = $dbh->prepare($req);
    $sth->execute();
    while (my $res = $sth->fetchrow_hashref ) {
        #$res->{issuedate} = GetReserveIssueDate($dbh, $res);
        #$res->{waiting_duration} = GetWaitingDuration( $res->{waitingdate}, $res->{issuedate}, 'days' );
        #AddReserveIssueDate($dbh, $res);
        print Dumper($res);
    }
    $sth->finish();
    $dbh->disconnect();


sub GetReserveIssueDate {
    my ($dbh, $res) = @_;
    
    my $req = <<SQL;
SELECT issuedate
FROM statdb.stat_issues
WHERE itemnumber = ?
AND borrowernumber = ?
AND DATE(issuedate) BETWEEN ? AND ? + INTERVAL 10 DAY
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($res->{itemnumber}, $res->{borrowernumber}, $res->{waitingdate}, $res->{waitingdate});
    my $issuedate = $sth->fetchrow_array;
    $sth->finish();
    
    return $issuedate;
}

sub AddReserveIssueDate {
    my ($dbh, $res) = @_;
    
    my $req = <<SQL;
UPDATE statdb.stat_reserves
SET
    issuedate = ?,
    waiting_duration = ?
WHERE reserve_id = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($res->{issuedate}, $res->{waiting_duration}, $res->{reserve_id});
    $sth->finish();
}

sub GetWaitingDuration {
    my ( $datetime1, $datetime2, $type ) = @_;

    my $duration;
    if ( defined $datetime1 && defined $datetime2 ) {
        my $dt1 = DateTime::Format::MySQL->parse_date($datetime1);
        my $dt2 = DateTime::Format::MySQL->parse_datetime($datetime2);
        
        if ( $type eq 'days' ) {
            $duration = $dt1->delta_days($dt2)->in_units('days');
        } elsif ( $type eq 'hours' ) {
            $duration = $dt1->delta_ms($dt2)->in_units('hours');
        } elsif ( $type eq 'minutes' ) {
            $duration = $dt1->delta_ms($dt2)->in_units('minutes');
        } elsif ( $type eq 'HH:MM:SS' ) {
            $duration = $dt1->delta_ms($dt2);
            my $formatter = DateTime::Format::Duration->new(
                pattern     => "%H:%M:%S",
                normalize   => 1,
            );
            $duration = $formatter->format_duration($duration);
        }
    }
    
    return $duration;
}