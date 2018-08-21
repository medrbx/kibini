#!/usr/bin/perl

use warnings;
use strict;
use Text::CSV;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use kibini::log;
use kibini::time;
use Adherent;
use Webkiosk;

my $log_message;
my $process = "statdb_webkiosk.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);


my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

open my $fic, "<", "/home/kibini/wk_users_logs_consommations.csv";

my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    auto_diag => 1, # permet diagnostic immédiat des erreurs
});
$csv->column_names (qw( wk_heure_deb wk_heure_fin wk_espace wk_poste koha_userid ));

while ( my $row = $csv->getline_hr ($fic) ) {
    my $wk = Webkiosk->new( { dbh => $dbh, wk => $row } );
    $wk->get_wkusers_from_koha;
    $wk->mod_data_to_statdb_webkiosk;
    $wk->add_data_to_statdb_webkiosk;
    
    print Dumper($wk);
}

close $fic;
$dbh->disconnect();