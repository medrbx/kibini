#!/usr/bin/perl

use Modern::Perl;
use Text::CSV;
#use utf8;
use Data::Dumper;
use Catmandu;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Kibini::ES;
use Kibini::Log;
use kibini::time;

my $log = Kibini::Log->new;
my $process = "statdb_web2.pl";
# On log le début de l'opération
$log->add_log("$process : beginning");

my $file_ext = "/home/kibini/stat_web_externe.csv";
unless (-e $file_ext) {
    print "Attention : le fichier \"/home/kibini/stat_web_externe.csv\" n'existe pas.\n";
    exit;
}

my $file_int = "/home/kibini/stat_web_interne.csv";
unless (-e $file_int) {
    print "Attention : le fichier \"/home/kibini/stat_web_interne.csv\" n'existe pas.\n";
    exit;
}

my $periode;
if (exists $ARGV[0]) {
    unless ( $ARGV[0] eq "scolaire"  || $ARGV[0] eq "été" || $ARGV[0] eq "vacances") {
        print "Attention : il est nécessaire de spécifier le type de période en argument.\n";
        print "Trois possibiblités : 'scolaire ou 'été' ou 'vacances'\n";
        print "Par exemple : \"./statdb_web2.pl scolaire\"\n";
        exit;
    } else {
        $periode = $ARGV[0];
    }
} else {
    print "Attention : il est nécessaire de spécifier le type de période en argument.\n";
    print "Trois possibiblités : 'scolaire ou 'été' ou 'vacances'\n";
    print "Par exemple : \"./statdb_web2.pl scolaire\"\n";
    exit;
}

# Connexion à la base de données et ES
my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $e = Kibini::ES->new->e;
my $index = "web2";
my $type = "site";
# RegenerateIndex($es_node, $index);

# Requête à effectuer
my $req = <<"SQL";
INSERT INTO statdb.stat_web2 (date, periode, visites, pages_vues, utilisateurs, taux_conversion, origine)
VALUES (?, ?, ?, ?, ?, ?, ?)
SQL
my $sth = $dbh->prepare($req);

my $i = 0;
my $externe = Catmandu->importer('CSV', file => $file_ext, header => 0 );
$externe->each(sub {
    $i++;
    my $data = shift;
    if ( $data->{0} =~ m/^\d{4}/) {
        my $to_keep = {};
        $to_keep->{date} = $data->{0};
        $to_keep->{periode} = $periode;
        $to_keep->{visites} = $data->{2};
        $to_keep->{pages_vues} = $data->{24};
        $to_keep->{utilisateurs} = $data->{3};
        ($to_keep->{taux_conversion}) = ( $data->{19} =~ m/^(\d+)(.*)/ );
        $to_keep->{origine} = "externe";
        $sth->execute($to_keep->{date}, $to_keep->{periode}, $to_keep->{visites}, $to_keep->{pages_vues}, $to_keep->{utilisateurs}, $to_keep->{taux_conversion}, $to_keep->{origine});
        ($to_keep->{year}, $to_keep->{month}, $to_keep->{week_number}, $to_keep->{day}, $to_keep->{dow}) = GetSplitDate($to_keep->{date});
        ($to_keep->{year}, $to_keep->{month}, $to_keep->{week_number}, $to_keep->{day}, $to_keep->{dow}) = GetSplitDate($to_keep->{date});
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                consultation_date => $to_keep->{date},
                consultation_date_annee => $to_keep->{year},
                consultation_date_mois => $to_keep->{month},
                consultation_date_semaine => $to_keep->{week_number},
                consultation_date_jour => $to_keep->{day},
                consultation_date_jour_semaine => $to_keep->{dow},
                periode => $to_keep->{periode},
                visites => $to_keep->{visites},
                pages_vues => $to_keep->{pages_vues},
                utilisateurs => $to_keep->{utilisateurs},
                taux_conversion => $to_keep->{taux_conversion},
                origine => $to_keep->{origine}
            }
        );
        $e->index(%index); 
        print Dumper(\%index);
    }
});

my $interne = Catmandu->importer('CSV', file => $file_int, header => 0 );
$interne->each(sub {
    $i++;
    my $data = shift;
    if ( $data->{0} =~ m/^\d{4}/) {
        my $to_keep = {};
        $to_keep->{date} = $data->{0};
        $to_keep->{periode} = $periode;
        $to_keep->{visites} = $data->{2};
        $to_keep->{pages_vues} = $data->{24};
        $to_keep->{utilisateurs} = $data->{3};
        ($to_keep->{taux_conversion}) = ( $data->{19} =~ m/^(\d+)(.*)/ );
        $to_keep->{origine} = "interne";
        $sth->execute($to_keep->{date}, $to_keep->{periode}, $to_keep->{visites}, $to_keep->{pages_vues}, $to_keep->{utilisateurs}, $to_keep->{taux_conversion}, $to_keep->{origine});
        ($to_keep->{year}, $to_keep->{month}, $to_keep->{week_number}, $to_keep->{day}, $to_keep->{dow}) = GetSplitDate($to_keep->{date});
        my %index = (
            index   => $index,
            type    => $type,
            body    => {
                consultation_date => $to_keep->{date},
                consultation_date_annee => $to_keep->{year},
                consultation_date_mois => $to_keep->{month},
                consultation_date_semaine => $to_keep->{week_number},
                consultation_date_jour => $to_keep->{day},
                consultation_date_jour_semaine => $to_keep->{dow},
                periode => $to_keep->{periode},
                visites => $to_keep->{visites},
                pages_vues => $to_keep->{pages_vues},
                utilisateurs => $to_keep->{utilisateurs},
                taux_conversion => $to_keep->{taux_conversion},
                origine => $to_keep->{origine}
            }
        );
        $e->index(%index);
        print Dumper(\%index);
    }
});



# On log la fin de l'opération
$log->add_log("$process : $i rows added");
$log->add_log("$process : ending\n");

__END__
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