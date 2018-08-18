#!/usr/bin/perl

#use warnings ;
use strict ;
use utf8 ;
use FindBin qw( $Bin ) ;
use Data::Dumper ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;
use kibini::time ;

my $reserve = 0 ; 
my $isItemnumber = 0 ;
my $isLoc = 0 ;

my $dbh = GetDbh() ;

my @reserves ;
my $req = "SELECT reserve_id FROM stat_reserves WHERE etat IS NULL" ;
my $sth = $dbh->prepare($req);
$sth->execute();
while ( my $row = $sth->fetchrow_array ) {
    push @reserves, $row ;
}

print Dumper(\@reserves) ;

foreach my $reserve_id ( @reserves ) {
    my $infos = reserves_infos( $reserve_id ) ;
    $infos->{update} = 0 ;
    if ( $infos->{itemnumber} ) {
        my $test = testExEmpruntes( $infos->{itemnumber}, $infos->{reservedate} ) ;
        if ( $test == 1 ) {
            $infos->{update} = updateEtatReservation($dbh, $reserve_id, "empr" ) ;
        }
    }
    $reserve++ ;
    print Dumper($infos) ;
}

print "Nb de réservations : $reserve\n" ;






sub reserves_infos {
    my ( $reserve_id ) = @_ ;

    my $dbh = GetDbh() ;
    my $req = "SELECT reserve_id, branchcode, biblionumber, itemnumber, DATE(reservedate) As reservedate FROM statdb.stat_reserves WHERE reserve_id = ? " ;
    my $sth = $dbh->prepare($req);
    $sth->execute($reserve_id);
    my $infos = $sth->fetchrow_hashref ;
    $sth->finish();
    $dbh->disconnect();
    return $infos ;
}

sub localisation {
    my ( $itemnumber ) = @_ ;
    my $req = "SELECT location FROM koha_prod.items WHERE itemnumber = ? " ;
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber);
    my $localisation = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect() ;
    if ( $localisation =~ "MED0" ) {
        $localisation = "RDC" ;
    } elsif ( $localisation =~ "MED0" ) {
        $localisation = "RDC" ;
    } elsif ( $localisation =~ "MED1" ) {
        $localisation = "Etage 1" ;
    } elsif ( $localisation =~ "MED2" ) {
        $localisation = "Etage 2" ;
    } elsif ( $localisation eq "MED3A" ) {
        $localisation = "Etage 3" ;
    } elsif ( $localisation eq "BUS1A" ) {
        $localisation = "Zèbre" ;
    } else {
        $localisation = "Magasins"
    } 
    return $localisation ;
}

sub updateLocReservation {
    my ($dbh, $infos) = @_ ;
    my $req = <<SQL ;
UPDATE statdb.stat_reserves
SET espace = ?
WHERE reserve_id = ? ;
SQL
    my $sth = $dbh->prepare($req);
    my $resp = $sth->execute($infos->{espace}, $infos->{reserve_id});
    $sth->finish();
    return $resp ; 
}

sub updateEtatReservation {
    my ($dbh, $id, $etat) = @_ ;
    my $req = <<SQL ;
UPDATE statdb.stat_reserves
SET etat = ?
WHERE reserve_id = ? ;
SQL
    my $sth = $dbh->prepare($req);
    my $resp = $sth->execute($etat, $id);
    $sth->finish();
    return $resp ; 
}


# Exemplaires réservables
sub ExReservables {
    my ( $branch, $biblionumber ) = @_ ;
    my $notloc ;
    if ( $branch eq "MED" ) {
        $notloc = "location NOT IN ('BUS1A','MED0A')" ;
    } elsif ( $branch eq "BUS" ) {
        $notloc = "location != 'MED0A'" ;
    }
    my @itemnumber ;
    my $req = "SELECT itemnumber FROM koha_prod.items WHERE biblionumber = ? AND notforloan IN (0, -1, -2, -3, -4) AND itemlost = 0 AND ".$notloc ;
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber);
    while ( my $itemnumber = $sth->fetchrow_array ) {
        push @itemnumber, $itemnumber ;
    }
    $sth->finish();
    $dbh->disconnect();
    return @itemnumber ;
}

# On regarde si l'exemplaire n'est pas en traitement
sub ExPasTrait {
    my ( $branch, $itemnumber ) = @_ ;
    my $notloc ;
    if ( $branch eq "MED" ) {
        $notloc = "('BUS1A','MED0A')" ;
    } elsif ( $branch eq "BUS" ) {
        $notloc = "('MED0A')" ;
    }

    my $req = <<SQL;
SELECT COUNT(*)
FROM koha_prod.items
WHERE 
    itemnumber = ?
    AND location NOT IN $notloc
    AND notforloan = 0
    AND itemlost = 0
SQL
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber );
    my $count = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
    my $test ;
    if ( $count > 0 ) {
        $test = 1 ;
    } else {
        $test = 0 ;
    }
    return $test ;
}

# On regarde si l'exemplaire est en traitement
sub ExTrait {
    my ( $branch, $itemnumber ) = @_ ;
    my $notloc ;
    if ( $branch eq "MED" ) {
        $notloc = "('BUS1A','MED0A')" ;
    } elsif ( $branch eq "BUS" ) {
        $notloc = "('MED0A')" ;
    }
    my $req = <<SQL;
SELECT COUNT(*)
FROM koha_prod.items
WHERE 
    itemnumber = ?
    AND location NOT IN $notloc
    AND notforloan IN (-1, -2, -3, -4)
    AND itemlost = 0
SQL
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber );
    my $count = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
    my $test ;
    if ( $count > 0 ) {
        $test = 1 ;
    } else {
        $test = 0 ;
    }
    return $test ;
}

# On regarde si l'exemplaire est emprunté
sub testExEmpruntes {
    my ( $itemnumber, $reservedate ) = @_ ;
    my $test ;
    my $req = "SELECT COUNT(*) FROM statdb.stat_issues WHERE itemnumber = ? AND issuedate <= ? AND returndate > ? " ;
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber, $reservedate, $reservedate );
    my $count = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
    if ( $count > 0 ) {
        $test = 1 ;
    } else {
        $test = 0 ;
    }
    return $test ;
}

# On test si un exemplaire est en attente de retrait après réservation
sub testExAttenteRetrait {
    my ( $itemnumber ) = @_ ;
    my $test ;
    my $req = "SELECT COUNT(*) FROM koha_prod.reserves WHERE found = 'W' AND itemnumber = ?" ;
    my $dbh = GetDbh() ;
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber );
    my $count = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();    
    if ( $count > 0 ) {
        $test = 1 ;
    } else {
        $test = 0 ;
    }
    return $test ;
}

# On cherche le statut de la réservation
sub statutReservation {
    my ( $branch, $biblionumber ) = @_ ;

    my $testDispo = 0 ;
    my $testTrait = 0 ;
    my $testEmpr = 0 ;
    my $testRese = 0 ;    
    
    # On récupère la liste des itemnumbers réservables
    my @itemnumber = ExReservables($branch, $biblionumber) ;
    
    my $localisation = "indéterminé" ;    
    
    # On regarde si les réservations ont le statut disponible
    foreach my $itemnumber ( @itemnumber ) {
        # On vérifie que le document n'est pas en traitement
        my $ExPasTrait = ExPasTrait($branch, $itemnumber) ;
        # On regarde si le document est emprunté
        my $testExEmpruntes = testExEmpruntes($itemnumber) ;
        # On regarde si le document est en attente de retrait
        my $testExAttenteRetrait = testExAttenteRetrait($itemnumber) ;

        if ( $ExPasTrait == 1 && $testExEmpruntes == 0 && $testExAttenteRetrait == 0 ) {
            $testDispo = 1 ;
            $localisation = localisation($itemnumber) ;
        }
        # On arrête la boucle dès que l'on trouve un document dispo
        last if ( $testDispo == 1 ) ;
    }

    # Si on ne trouve pas de document dispo, on regarde si les réservations ont le statut en traitement
    if ( $testDispo == 0 ) {
        foreach my $itemnumber ( @itemnumber ) {
            # On regarde si le document est en traitement
            my $ExTrait = ExTrait($branch, $itemnumber) ;
            # On regarde si le document est emprunté
            my $testExEmpruntes = testExEmpruntes($itemnumber) ;
            # On regarde si le document est en attente de retrait
            my $testExAttenteRetrait = testExAttenteRetrait($itemnumber) ;
    
            if ( $ExTrait == 1 && $testExEmpruntes == 0 && $testExAttenteRetrait == 0 ) {
                $testTrait = 1 ;
                $localisation = localisation($itemnumber) ;
            }
            # On arrête la boucle dès que l'on trouve un document en traitement
            last if ( $testTrait == 1 ) ;
        }
    }

    # Si on ne trouve pas de document dispo ou en traitement, on regarde si les réservations ont le statut empruntés
    if ( $testDispo == 0 && $testTrait == 0 ) {
        foreach my $itemnumber ( @itemnumber ) {
            # On regarde si le document est emprunté
            my $testExEmpruntes = testExEmpruntes($itemnumber) ;
            # On regarde si le document est en attente de retrait
            my $testExAttenteRetrait = testExAttenteRetrait($itemnumber) ;
    
            if ( $testExEmpruntes == 1 && $testExAttenteRetrait == 0 ) {
                $testEmpr = 1 ;
                $localisation = localisation($itemnumber) ;
            }
            # On arrête la boucle dès que l'on trouve un document emprunté
            last if ( $testEmpr == 1 ) ;
        }
    }

    # Si on ne trouve pas de document dispo, en traitement ou emprunté, on regarde si les réservations ont le statut en attent de retrait (déjà réservé)
    if ( $testDispo == 0 && $testTrait == 0 && $testEmpr == 0 ) {
        foreach my $itemnumber ( @itemnumber ) {
            # On regarde si le document est en attente de retrait
            my $testExAttenteRetrait = testExAttenteRetrait($itemnumber) ;
    
            if ( $testExAttenteRetrait == 1 ) {
                $testRese = 1 ;
                $localisation = localisation($itemnumber) ;
            }
            # On arrête la boucle dès que l'on trouve un document en attente de retrait
            last if ( $testRese == 1 ) ;
        }
    }

    # On établit le statut de la réservation et on récupère la localisation
    my $statutReservation ;
    if ( $testDispo == 1 ) {
        $statutReservation = "disp" ;
    } elsif ( $testTrait == 1 ) {
        $statutReservation = "trait" ;
    } elsif ( $testEmpr == 1 ) {
        $statutReservation = "empr" ;
    } elsif ( $testRese == 1 ) {
        $statutReservation = "rese" ;
    } else {
        $statutReservation = "ind" ;
    }
    
    return $statutReservation, $localisation ;
}