#!/usr/bin/perl

use strict;
use warnings;
use Search::Elasticsearch; 
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;

my $log_message;
my $process = "es_entrees.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

my $es_maxdatetime = GetEsMaxDateTime("entrees", "camera", "entrees_date");
my $i = entrees($es_maxdatetime, $es_node);

# On log la fin de l'opération
$log_message = "$process : $i rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);


sub entrees {
    my ($maxdatetime, $es_node) = @_;
    my %params = ( nodes => $es_node );
    my $index = "entrees";
    my $type = "camera";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();
    #my $req = "SELECT date_heure, nb_entrees FROM statdb.stat_compteur_entrees WHERE date_heure > ?";
	my $req = "SELECT datetime as date_heure, entrees as nb_entrees FROM statdb.stat_entrees WHERE datetime > ?";
    my $sth = $dbh->prepare($req);
    $sth->execute($maxdatetime);
    $i = 0;
    while (my @row = $sth->fetchrow_array) {
        my ( $datetime, $entrees ) = @row;

        my ($entrees_year, $entrees_month, $entrees_week_number, $entrees_day, $entrees_jour_semaine, $entrees_hour) = GetSplitDateTime($datetime);
    
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                entrees_date => $datetime,
                entrees_date_annee => $entrees_year,
                entrees_date_mois => $entrees_month,
                entrees_date_semaine => $entrees_week_number,
                entrees_date_jour => $entrees_day,
                entrees_date_jour_semaine => $entrees_jour_semaine,
                entrees_date_heure => $entrees_hour,
                nb_entrees => $entrees
            }
        );

        $e->index(%index);
        #print Dumper(\%index);
        $i++;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}