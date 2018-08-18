package collections::poldoc ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( GetLibAV GetLibBranches GetCcodeLibLevels GetDataCcodeFromItemnumber GetDataItemsFromItemnumber GetItemtypeFromBiblionumber GetLibSLL GetRbxSite GetCcode IsLoanedByItemnumber ) ;

use strict ;
use warnings ;

use kibini::db ;

sub GetLibAV {
    my ($av, $cat) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT lib FROM koha_prod.authorised_values WHERE authorised_value = ? AND category = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($av, $cat);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetLibBranches {
    my ($branchcode) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT branchname FROM koha_prod.branches WHERE branchcode = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($branchcode);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
}

sub GetCcode {
    my $dbh = GetDbh() ;
    my $req = "SELECT ccode, lib, lib1, lib2, lib3, lib4 FROM statdb.lib_collections2 WHERE ccode IS NOT NULL AND ccode != ''" ;
    my $sth = $dbh->prepare($req);
    $sth->execute();
    return $sth->fetchall_arrayref({}) ;
    $sth->finish();
    $dbh->disconnect();    
}

sub GetCcodeLibLevels {
    my ($ccode) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT lib1, lib2, lib3, lib4 FROM statdb.lib_collections2 WHERE ccode = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($ccode);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
}

sub GetDataCcodeFromItemnumber {
    my ($itemnumber) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT i.ccode, c.lib1, c.lib2, c.lib3, c.lib4 FROM koha_prod.items i JOIN statdb.lib_collections2 c ON i.ccode = c.ccode WHERE i.itemnumber = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
}

sub GetDataItemsFromItemnumber {
    my ($itemnumber) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT location, homebranch, ccode FROM koha_prod.items WHERE itemnumber = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
}

sub GetItemtypeFromBiblionumber {
    my ($biblionumber) = @_ ;
    my $dbh = GetDbh() ;
    my $req = "SELECT itemtype FROM koha_prod.biblioitems WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber);
    return $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
}

sub GetLibSLL {
    my ( $ccode, $location, $itemtype ) = @_ ;
    
    my $public ;
    my @jeunesse = qw( A143 A144 E01 E02 E03 E04 E05 E06 E07 E08 E09 E10 E11 E12 E13 E14 E15 E16 E17 E18 E19 E20 E21 E22 E23 E24 E25 E26 E27 ) ;
    if ( $ccode =~ /^J/ || grep {$_ eq $ccode} @jeunesse ) {
        $public = "enfants" ;
    } elsif ( $ccode eq "P17" && $location eq "MED2A" ) {
        $public = "enfants" ;
    } else {
        $public = "adultes" ;
    }
    
    my $acces ;
    my @libre_acces = qw( BUS1A MED0B MED0C MED1A MED2A MED2B MED3A MED3B ) ;
    if ( grep {$_ eq $location} @libre_acces ) {
        $acces = "libre accès" ;
    } else {
        $acces = "accès indirect" ;
    }

    my ($collection, $prets) ;
    if ( $itemtype eq "LI" || $itemtype eq "LG" ) {
        $collection = "D1 - Livres imprimés" ;
        $prets = "E2 – Livres" ;
    } elsif ( $itemtype eq "PE" ) {
        $collection = "D1 - Publications en série imprimées" ;
        $prets = "E2 – Publications en série imprimées " ;
    } elsif ( $itemtype eq "IC" ) {
        $collection = "D3 - Documents graphiques" ;
        $prets = "Autres documents" ;
    } elsif ( $itemtype eq "JE" ) {
        $collection = "D3 - Autres documents" ;
        $prets = "Autres documents" ;
    } elsif ( $itemtype eq "CA" ) {
        $collection = "D3 – Documents cartographiques" ;
        $prets = "Autres documents" ;
    } elsif ( $itemtype eq "PA" ) {
        $collection = "D3 – Musique imprimée" ;
        $prets = "Autres documents" ;
    } elsif ( $itemtype eq "LS" && $public eq "adultes" ) {
        $collection = "D4 - Documents audiovisuels fonds adultes / Documents sonores : livres enregistrés" ;
        $prets = "E2 – Documents sonores : livres" ;
    } elsif ( $itemtype eq "LS" && $public eq "enfants" ) {
        $collection = "D4 - Documents audiovisuels fonds enfants / Documents sonores : livres enregistrés" ;
        $prets = "E2 – Documents sonores : livres" ;
    } elsif ( ($itemtype eq "DC" || $itemtype eq "DV" || $itemtype eq "DG" || $itemtype eq "K7") && $public eq "adultes"  ) {
        $collection = "D4 - Documents audiovisuels fonds adultes / Documents sonores : musique" ;
        $prets = "E2 – Documents sonores : musique" ;
    } elsif ( ($itemtype eq "DC" || $itemtype eq "DV" || $itemtype eq "DG" || $itemtype eq "K7") && $public eq "enfants"  ) {
        $collection = "D4 - Documents audiovisuels fonds enfants / Documents sonores : musique" ;
        $prets = "E2 – Documents sonores : musique" ;
    } elsif ( ($itemtype eq "VD" || $itemtype eq "VI") && $public eq "adultes" ) {
        $collection = "D4 - Documents audiovisuels fonds adultes / documents vidéo adultes" ;
        $prets = "E2 - Documents vidéo" ;
    } elsif ( ($itemtype eq "VD" || $itemtype eq "VI") && $public eq "enfants" ) {
        $collection = "D4 - Documents audiovisuels fonds enfants / documents vidéo enfants" ;
        $prets = "E2 - Documents vidéo" ;
    } elsif ( $itemtype eq "CR" || $itemtype eq "ML" ) {
        $collection = "D4 - Total documents multimédia sur support" ;
        $prets = "Autres documents" ;
    } else {
        $collection = "D1 - Livres imprimés" ;
        $prets = "E2 – Livres" ;
    }

    my $pret_coll ;
    if ( $location eq "MED0A" ) {
        $pret_coll = "Prêt aux collectivités" ;
    } else {
        $pret_coll = "Pas de prêt aux collectivités" ;
    }        
    
    return $public, $acces, $collection, $pret_coll, $prets ;    
}

sub GetRbxSite {
    my ($location) = @_ ;
    my $site ;
    if ( $location eq 'BUS1A' ) {
        $site = 'Zèbre' ;
    } elsif ( $location eq 'MED0A' ) {
        $site = 'Collectivités' ;
    } else {
        $site = 'Médiathèque' ;
    }
    return $site ;
}

sub IsLoanedByItemnumber {
    my ($itemnumber, $months) = @_ ;
    my $req = "SELECT COUNT(itemnumber) FROM statdb.stat_issues WHERE itemnumber = ? AND DATE(issuedate) >= CURDATE() - INTERVAL ? MONTH" ;
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($itemnumber, $months) ;
    my $count = $sth->fetchrow_array() ;
    
    my $loaned = "non" ;
    if ( $count > 0 ) {
        $loaned = "oui" ;
    }
    return $loaned ;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NOM

collections::poldoc

=head1 DESCRIPTION

Ce module fournit des fonctions permettant d'obtenir le libéllé des catégories ou valeurs autorisées pour les collections.

=cut