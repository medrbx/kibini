#! /usr/bin/perl

# script à placer dans le répertoire tools de kibini

use strict ;
use warnings ;
use Text::CSV ;
use utf8 ;
use Data::Dumper ; # pour débuguer uniquement
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;

# on crée une connexion à statdb et ES
my $dbh = GetDbh() ;
my $es_node = GetEsNode() ;
my $e = Search::Elasticsearch->new( nodes => $es_node ) ;
my $firsdate = '2017-09-01' ;

# on prépare le fichier d'entrée
my $in = "stat_perio_in.csv" ;
my $csv_in = Text::CSV->new ({ binary => 1 });
open( my $fd_in, "<:encoding(UTF-8)", $in ) ;
my @column_in = qw( thematique ccode collection titre biblionumber dest1 dest2 empruntable infos periodicite prix nb_issues nb_emprunteurs_dist nb_items_dist_emp nb_items tx_rot tx_actif ) ;
$csv_in->column_names(@column_in);

# on prépare le fichier de sortie
my $out = "stat_perio_out.csv" ;
my $csv_out = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open( my $fd_out, ">:encoding(UTF-8)", $out ) ;
my @column_out = ( 'Thématique', 'Code collection', 'Collection', 'Titre', 'Numéro notice bib', '1er destination', '2e destination', 'empruntable ?', 'infos', 'Périodicité', 'prix de l\'abt', 'Nb prêts', 'Emprunteurs', 'Prêts ex dist', 'Ex', 'Tx rot', 'Tx actif' ) ;
$csv_out->print ($fd_out, \@column_out) ;

# on calcule le nb de prêts, ... pour chaque ligne et on remplit le fichier de sortie
my $i = 0 ;
while (my $row = $csv_in->getline_hr ($fd_in)) {
    $i++ ;
    #$row->{nb_issues} = GetNbIssues($dbh, $row->{biblionumber}) ;
    $row->{nb_issues} = GetNbIssuesES($e, $row->{biblionumber}, $firsdate) if ($row->{biblionumber}) ;
    $row->{nb_emprunteurs_dist} = GetNbDistBorrowers($dbh, $row->{biblionumber}) ;
    $row->{nb_items_dist_emp} = GetNbDistItemsLoaned($dbh, $row->{biblionumber}) ;
    $row->{nb_items} = GetNbItems($dbh, $row->{biblionumber}) ;
    my @row_out = ($row->{thematique}, $row->{ccode}, $row->{collection}, $row->{titre}, $row->{biblionumber}, $row->{dest1}, $row->{dest2}, $row->{empruntable}, $row->{infos}, $row->{periodicite}, $row->{prix}, $row->{nb_issues}, $row->{nb_emprunteurs_dist}, $row->{nb_items_dist_emp}, $row->{nb_items}, $row->{tx_rot}, $row->{tx_actif} ) ;
    $csv_out->print ($fd_out, \@row_out) ;
    print Dumper($row) ;
    #print "$i\n" ;
}

close $fd_in ;
close $fd_out ;
$dbh->disconnect() ;

##########################
# Fonctions

sub GetNbIssues {
    my ($dbh, $biblionumber) = @_ ;
    
    my $req = "SELECT COUNT(issue_id) FROM statdb.stat_issues  WHERE biblionumber = ? AND DATE(issuedate) BETWEEN '2017-09-01' AND '2018-08-31'" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    return $sth->fetchrow_array() ;
    $sth->finish() ;     
}

sub GetNbDistBorrowers {
    my ($dbh, $biblionumber) = @_ ;
    
    my $req = "SELECT COUNT(DISTINCT borrowernumber) FROM statdb.stat_issues  WHERE biblionumber = ? AND DATE(issuedate) BETWEEN '2017-09-01' AND '2018-08-31'" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    return $sth->fetchrow_array() ;
    $sth->finish() ;     
}

sub GetNbDistItemsLoaned {
    my ($dbh, $biblionumber) = @_ ;
    
    my $req = "SELECT COUNT(DISTINCT itemnumber) FROM statdb.stat_issues  WHERE biblionumber = ? AND DATE(issuedate) BETWEEN '2017-09-01' AND '2018-08-31'" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    return $sth->fetchrow_array() ;
    $sth->finish() ;     
}

sub GetNbItems {
    my ($dbh, $biblionumber) = @_ ;
    
    my $nb_items = 0 ;
    my @tables = qw (items deleteditems ) ;
    foreach my $table (@tables) {
        my $req = "SELECT COUNT(itemnumber) FROM koha_prod.$table  WHERE biblionumber = ? AND DATE(dateaccessioned) BETWEEN '2017-09-01' AND '2018-08-31'" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        my $result = $sth->fetchrow_array() ;
        $sth->finish() ;
        $nb_items = $nb_items + $result ;
    }
    return $nb_items ;
}

sub GetNbIssuesES {
    my ($e, $biblionumber, $firstdate) = @_ ;
    
    my $body = {
        query => {
            bool => {
                must => [
                    { term => { doc_biblionumber => $biblionumber } }
                ],
                filter => [
                    { range => { pret_date_pret => { gte => "$firstdate||/d", lt => "$firstdate||+1y/d", format => "yyyy-MM-dd" } } }
                ]
            }
        }
    } ;
    
    my $result  = $e->count(
        index => 'prets',
        body  => $body
    );
    
    return $result->{'count'} ;
}