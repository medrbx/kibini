#! /usr/bin/perl

use Modern::Perl;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use kibini::time;
use Adherent;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $adh = { koha_borrowernumber => 44421 };

my $date = GetDateTime('today');

my $adherent = Adherent->new( { dbh => $dbh, date => $date, adherent => $adh } );
my @koha_fields = ("dateofbirth", "city", "altcontactcountry", "categorycode", "branchcode");
$adherent->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'borrowernumber' } );
$adherent->mod_data_to_statdb_webkiosk;
print Dumper($adherent);