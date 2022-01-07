#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Search::Elasticsearch;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use collections::poldoc;

my $log_message;
my $process = "es_eliminations.pl";
# On log le début de l'opération
$log_message = "$process : beginning";
AddCrontabLog($log_message);

# On récupère l'adresse d'Elasticsearch
my $es_node = GetEsNode();

# V1 : On recrée l'ensemble de l'index

# On supprime l'index items puis on le recrée :
#my $result = RegenerateIndex($es_node, "eliminations");

#my $itemnumbermax = GetMaxItemnumber();
#my $delta = 100;

#my $nb = 0;
#while ( $itemnumbermax > 0 ) {
#    my $i = items($itemnumbermax, $delta, $es_node);
#    $itemnumbermax = $itemnumbermax - $delta;
#    $nb = $nb + $i;
#}

# V2 : On ajoute uniquement les éliminations de l'année
my $year = 2021;
my $nb = itemsByYear($es_node, $year);

# On log la fin de l'opération
$log_message = "$process : $nb rows indexed";
AddCrontabLog($log_message);
$log_message = "$process : ending\n";
AddCrontabLog($log_message);


sub items {
    my ($itemnumbermax, $delta, $es_node ) = @_;
    my $minitemnumber = $itemnumbermax - $delta;

    my %params = ( nodes => $es_node );
    my $index = "eliminations";
    my $type = "exemplaires";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();

    my $req = <<SQL;
SELECT
    e.itemnumber,
    e.biblionumber,
    e.barcode,
    e.dateaccessioned,
    e.homebranch,
    e.price,
    e.replacementprice,
    e.datelastborrowed,
    e.datelastseen,
    e.notforloan,
    e.damaged,
    e.itemlost,
    e.withdrawn,
    e.itemcallnumber,
    e.issues,
    e.renewals,
    e.reserves,
    e.holdingbranch,
    e.location,
    e.onloan,
    e.ccode,
    e.itype,
    e.annee_mise_pilon,
    e.itemtype,
    e.title,
    e.motif,
    c.lib1,
    c.lib2,
    c.lib3,
    c.lib4
FROM statdb.stat_eliminations e
JOIN statdb.lib_collections2 c ON e.ccode = c.ccode
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute();
    my $i = 0;
    while (my $row = $sth->fetchrow_hashref) {
        if (!defined $row->{lib2}) {
            $row->{lib2} = "NP";
        } 
        if (!defined $row->{lib3}) {
            $row->{lib3} = "NP";
        }
        if (!defined $row->{lib4}) {
            $row->{lib4} = "NP";
        }

        $row->{homebranch} = GetLibBranches($row->{homebranch});
        $row->{holdingbranch} = GetLibBranches($row->{holdingbranch});

#    if (!defined $price) {
#        $price = 0;
#    }

#    if (!defined $replacementprice) {
#        $replacementprice = 0;
#    }

        if (!defined $row->{datelastborrowed}) {
            $row->{datelastborrowed} = "1970-01-01";
        }

        if (!defined $row->{onloan}) {
            $row->{onloan} = "Non emprunté";
        } else {
            $row->{onloan} = "Emprunté";
        }

        if (!defined $row->{itemcallnumber}) {
            $row->{itemcallnumber} = "Non renseigné";
        }
    
        ( $row->{sll_public}, $row->{sll_acces}, $row->{sll_collection}, $row->{sll_prets_coll}, $row->{sll_prets} ) = GetLibSLL( $row->{ccode}, $row->{location}, $row->{itemtype} );

        $row->{itemtype} = GetLibAV($row->{itemtype}, "ccode");
        $row->{location} = GetLibAV($row->{location}, "LOC");
        $row->{notforloan} = GetLibAV($row->{notforloan}, "ETAT");
        $row->{damaged} = GetLibAV($row->{damaged}, "DAMAGED");
        $row->{withdrawn} = GetLibAV($row->{withdrawn}, "RETIRECOLL");
        $row->{itemlost} = GetLibAV($row->{itemlost}, "LOST");
        
        $row->{pret12} = IsLoanedByItemnumber($row->{itemnumber}, 12);
		
		
		my $index = {
		    index   => $index,
			type    => $type,
            id      => $row->{itemnumber},
            body    => $row
        };
		print Dumper($index);
        $e->index($index);
        $i++;
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}

sub itemsByYear {
    my ($es_node, $year) = @_;
	
    my %params = ( nodes => $es_node );
    my $index = "eliminations";
    my $type = "exemplaires";

    my $e = Search::Elasticsearch->new( %params );

    my $dbh = GetDbh();

    my $req = <<SQL;
SELECT
    e.itemnumber,
    e.biblionumber,
    e.barcode,
    e.dateaccessioned,
    e.homebranch,
    e.price,
    e.replacementprice,
    e.datelastborrowed,
    e.datelastseen,
    e.notforloan,
    e.damaged,
    e.itemlost,
    e.withdrawn,
    e.itemcallnumber,
    e.issues,
    e.renewals,
    e.reserves,
    e.holdingbranch,
    e.location,
    e.onloan,
    e.ccode,
    e.itype,
    e.annee_mise_pilon,
    e.itemtype,
    e.title,
    e.motif,
    c.lib1,
    c.lib2,
    c.lib3,
    c.lib4
FROM statdb.stat_eliminations e
JOIN statdb.lib_collections2 c ON e.ccode = c.ccode
WHERE e.annee_mise_pilon = ?
SQL

    my $sth = $dbh->prepare($req);
    $sth->execute($year);
    my $i = 0;
    while (my $row = $sth->fetchrow_hashref) {
        if (!defined $row->{lib2}) {
            $row->{lib2} = "NP";
        } 
        if (!defined $row->{lib3}) {
            $row->{lib3} = "NP";
        }
        if (!defined $row->{lib4}) {
            $row->{lib4} = "NP";
        }

        $row->{homebranch} = GetLibBranches($row->{homebranch});
        $row->{holdingbranch} = GetLibBranches($row->{holdingbranch});

#    if (!defined $price) {
#        $price = 0;
#    }

#    if (!defined $replacementprice) {
#        $replacementprice = 0;
#    }

        if (!defined $row->{datelastborrowed}) {
            $row->{datelastborrowed} = "1970-01-01";
        }

        if (!defined $row->{onloan}) {
            $row->{onloan} = "Non emprunté";
        } else {
            $row->{onloan} = "Emprunté";
        }

        if (!defined $row->{itemcallnumber}) {
            $row->{itemcallnumber} = "Non renseigné";
        }
    
        ( $row->{sll_public}, $row->{sll_acces}, $row->{sll_collection}, $row->{sll_prets_coll}, $row->{sll_prets} ) = GetLibSLL( $row->{ccode}, $row->{location}, $row->{itemtype} );

        $row->{itemtype} = GetLibAV($row->{itemtype}, "ccode");
        $row->{location} = GetLibAV($row->{location}, "LOC");
        $row->{notforloan} = GetLibAV($row->{notforloan}, "ETAT");
        $row->{damaged} = GetLibAV($row->{damaged}, "DAMAGED");
        $row->{withdrawn} = GetLibAV($row->{withdrawn}, "RETIRECOLL");
        $row->{itemlost} = GetLibAV($row->{itemlost}, "LOST");
        
        $row->{pret12} = IsLoanedByItemnumber($row->{itemnumber}, 12);
		
		
		my $index = {
		    index   => $index,
			type    => $type,
            id      => $row->{itemnumber},
            body    => $row
        };
		#print Dumper($index);
        $e->index($index);
        $i++;
		print "$i\n";
    }
    $sth->finish();
    $dbh->disconnect();
    return $i;
}

sub GetMaxItemnumber {
    my $dbh = GetDbh();
    my $req = "SELECT max(itemnumber) FROM koha_prod.items";
    my $sth = $dbh->prepare($req);
    $sth->execute();
    return $sth->fetchrow_array;
    $sth->finish();
    $dbh->disconnect();    
}