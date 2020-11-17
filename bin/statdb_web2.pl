#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;

my $log_message;
my $process = "statdb_web2.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

my $file = "/home/kibini/stat_web.csv";
if ( defined $ARGV[0] ) {
    $file = $ARGV[0];
} 

# Connexion à la base de données et ES
my $dbh = GetDbh();
my $es_node = GetEsNode();
my $e = Search::Elasticsearch->new( nodes => $es_node );
my $index = "web2";
my $type = "site";
# RegenerateIndex($es_node, $index);

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO statdb.stat_web2 (date, periode, visites, pages_vues, utilisateurs, taux_conversion, origine)
VALUES (?, ?, ?, ?, ?, ?, ?)
SQL

# Traitement de la requête
my $sth = $dbh->prepare($req);

# Lire un fichier CSV et récupérer les lignes comme référence de hash
my $csv = Text::CSV->new ({ binary => 1 });
open(my $fd, "<:encoding(UTF-8)", $file);
$csv->column_names (qw( date periode visites pages_vues utilisateurs taux_conversion origine ));
my $i = 0;
while (my $row = $csv->getline_hr ($fd)) {
    if ( $row->{date} =~ m/^\d{4}-\d{2}-\d{2}$/ ) {
        $sth->execute( $row->{date}, $row->{periode}, $row->{visites}, $row->{pages_vues}, $row->{utilisateurs}, $row->{taux_conversion}, $row->{origine} );
        ($row->{year}, $row->{month}, $row->{week_number}, $row->{day}, $row->{dow}) = GetSplitDate($row->{date});
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                consultation_date => $row->{date},
                consultation_date_annee => $row->{year},
                consultation_date_mois => $row->{month},
                consultation_date_semaine => $row->{week_number},
                consultation_date_jour => $row->{day},
                consultation_date_jour_semaine => $row->{dow},
                periode => $row->{periode},
                visites => $row->{visites},
                pages_vues => $row->{pages_vues},
                utilisateurs => $row->{utilisateurs},
                taux_conversion => $row->{taux_conversion},
                origine => $row->{origine}
            }
        );

        $e->index(%index);    
    }
}
close $fd;

$sth->finish();

# Déconnexion de la base de données
$dbh->disconnect();

# On log la fin de l'opération
$log_message = "$process : $i rows added";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);