#!/usr/bin/perl

use Modern::Perl;
use Text::CSV;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Kibini::Crypt;
use Kibini::Log;
use Webkiosk;

my $log = Kibini::Log->new;
my $process = "data_webkiosk.pl";
# On log le début de l'opération
$log->add_log("$process : beginning");

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $crypter = Kibini::Crypt->new;

open my $fic, "<", "/home/kibini/wk_users_logs_consommations.csv";

my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    auto_diag => 1, # permet diagnostic immédiat des erreurs
});
$csv->column_names (qw( date_heure_a date_heure_b session_groupe session_poste koha_userid ));

my $i = 0;
while ( my $row = $csv->getline_hr ($fic) ) {
    
    my $wk = Webkiosk->new( { dbh => $dbh, crypter => $crypter, wk => $row } );
    $wk->evenement_complete_data({date_heure_a_format => 'datetime', date_heure_b_format => 'datetime'});
    $wk->get_wkuser_from_koha;
    $wk->get_wkuser_data;
    my $res = $wk->add_data_to_statdb_webkiosk;
    $wk->add_data_to_es_webkiosk;
#    print Dumper($wk);
    $i++;
}

close $fic;
$dbh->disconnect();

# On log la fin de l'opération
$log->add_log("$process : $i rows added");
$log->add_log("$process : ending\n");
