#!/usr/bin/perl

use Modern::Perl;
use Text::CSV;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Kibini::Crypt;
use kibini::log;
use Webkiosk;

my $log_message;
my $process = "statdb_webkiosk.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $crypter = Kibini::Crypt->new;

open my $fic, "<", "/home/kibini/wk_users_logs_consommations.csv";

my $csv = Text::CSV->new ({
    binary    => 1, # permet caractères spéciaux (?)
    auto_diag => 1, # permet diagnostic immédiat des erreurs
});
$csv->column_names (qw( session_heure_deb session_heure_fin session_groupe session_poste koha_userid ));

while ( my $row = $csv->getline_hr ($fic) ) {
    my $wk = Webkiosk->new( { dbh => $dbh, crypter => $crypter, wk => $row } );
	$wk->get_wkuser_from_koha;
	$wk->get_wkuser_data;
	$wk->add_data_to_statdb_webkiosk;
    $wk->add_data_to_es_webkiosk;
	print Dumper($wk);
}

close $fic;
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;
