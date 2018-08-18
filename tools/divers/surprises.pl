#!/usr/bin/perl

use strict;
use warnings ;
use WWW::Mechanize;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::elasticsearch ;

my $dbh = GetDbh() ;

my $es_node = GetEsNode() ;
my $e = Search::Elasticsearch->new( nodes => $es_node ) ;

my $surprises = GetSurprisesStat() ;
while( my ($biblionumber, $d) = each(%$surprises) ) {
    my @dates = @$d ;
    if ( $biblionumber=~m/^\d+$/ ) {
        my $count = GetSurprisesIssues($e, $biblionumber, $dates[0], "6M", $dbh) ;
		$count->{surprise_datecreated} = $dates[0] ;
        print "$count->{biblionumber},$count->{surprise_datecreated},$count->{biblio_datecreated},$count->{before},$count->{after}\n" ;
    }
}


# Fonction qui permet d'obtenir la liste des surprises sous forme de référence de hash avec pour clés le biblionumber et pour valeurs la liste des dates auxquelles les surprises ont été poussées
sub GetSurprisesStat {
    my $url = "http://www.mediathequederoubaix.fr/osiros/front/stats.php" ;

    my $mech = WWW::Mechanize->new( agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.4.0' ) ;
    $mech->get($url);
    
    my $result = $mech->response()->decoded_content() ;
    $result =~s/^Stat surprises<br>//;
    
    my %surprises ;
    my @result = split(/<br \/>/, $result) ;
    foreach my $res (@result) {
        my ($biblionumber, $date) = split(/;/, $res);
        my @dates ;
        
        if ( $surprises{$biblionumber} ) {
            my $dates = $surprises{$biblionumber} ;
            @dates = @$dates ;
            push @dates, $date ;
            my @dates = sort(@dates) ; # on classe les dates par ordre croissant
            $surprises{$biblionumber} = \@dates ;
        } else {
            push @dates, $date ;
            $surprises{$biblionumber} = \@dates ;
        }
    }

    return \%surprises ;
}

# Fonction qui ramène les nbs de prêts pour un biblionumber n mois avant puis un temps donné après une date spécifiée. On utilise Elasticsearch plutôt que MySQL.
sub GetSurprisesIssues {
    my ($e, $biblionumber, $date, $t, $dbh) = @_ ;
    my %issues = ( biblionumber => $biblionumber ) ;
    
    my @times = qw( before after) ;
    
    foreach my $time (@times) {
        my %range ;
        if ( $time eq 'before' ) {
            %range = (
                pret_date_pret => {
                    gte => "$date||-$t/d",
                    lt => "$date||/d",
                    format => "yyyy-MM-dd"
                }
            ) ;
        } elsif ( $time eq 'after' ) {
            %range = (
                pret_date_pret => {
                    gte => "$date||/d",
                    lt => "$date||+$t/d",
                    format => "yyyy-MM-dd"
                }
            ) ;
        }
        
        my %body = (
            query => {
                bool => {
                    must => { term => { doc_biblionumber => $biblionumber } },
                    filter => { range => \%range }
                }
            }
        ) ;
    
        my $result  = $e->count(
            index => 'prets',
            body  => \%body
        );
    
        $issues{$time} = $result->{'count'} ;
    }
	
	$issues{biblio_datecreated} = GetBiblioCreationDate($dbh, $biblionumber) ;
    
    return \%issues ;
}

# Fonction qui permet d'obtenir la date de création de la notice pour un biblionumber donné
sub GetBiblioCreationDate {
	my ($dbh, $biblionumber) = @_ ;
	my $req = "SELECT datecreated FROM koha_prod.biblio WHERE biblionumber = ?" ;
	my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber);
	return $sth->fetchrow_array ;
    $sth->finish();
}