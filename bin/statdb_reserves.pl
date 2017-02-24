#!/usr/bin/perl

use warnings ;
use strict ;
use utf8 ;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;
use kibini::log ;
use kibini::time ;

my $log_message ;
my $process = "statdb_reserves.pl" ;
# On log le début de l'opération
$log_message = "$process : beginning" ;
AddCrontabLog($log_message) ;


my $date_veille = GetDateTime('yesterday') ;
reserves_new($date_veille) ;
reserves_maj($date_veille) ;

# On log la fin de l'opération
$log_message = "$process : ending\n" ;
AddCrontabLog($log_message) ;

# my @new_reserve_id = new_reserve_id($date_veille) ;
# foreach my $new_reserve_id (@new_reserve_id) {
#     my ($branchcode, $biblionumber ) = reserves_infos($new_reserve_id) ;
#     my ($statutReservation, $localisation ) = statutReservation($branchcode, $biblionumber) ;
#     updateStatutLocReservation($new_reserve_id, $statutReservation, $localisation) ;
#    print "$new_reserve_id, $statutReservation, $localisation\n" ;
# }

##################################################################
# On insère les réservations de la veille
sub reserves_new {
    my ( $date ) = @_ ;
    
    my $dbh = GetDbh() ;
    my $req ;
    my $sth ;
    my @tables = qw( reserves old_reserves ) ;
    foreach my $table (@tables) {
        $req = <<SQL ;
INSERT INTO statdb.stat_reserves (reserve_id, borrowernumber, reservedate, biblionumber, branchcode, notificationdate, cancellationdate, priority, found, timestamp, itemnumber, waitingdate, expirationdate, age, sexe, ville, iris, branchcode_borrower, categorycode, fidelite, mobile, courriel)
SELECT
    r.reserve_id,
    r.borrowernumber,
    r.reservedate,
    r.biblionumber,
    r.branchcode,
    r.notificationdate,
    r.cancellationdate,
    r.priority,
    r.found,
    r.timestamp,
    r.itemnumber,
    r.waitingdate,
    r.expirationdate,
    CASE WHEN b.categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP' ELSE YEAR(r.reservedate) - YEAR(b.dateofbirth) END,
    CASE WHEN b.title = 'Madame' THEN 'F' WHEN b.title = 'Monsieur' THEN 'M' WHEN b.categorycode NOT IN ('BIBL', 'CSLT','CSVT','MEDA','MEDB','MEDC','MEDP') THEN 'NP' END,
    b.city,
    b.altcontactcountry,
    b.branchcode,
    b.categorycode,
    YEAR(r.reservedate) - YEAR(b.dateenrolled),
    CASE WHEN b.mobile LIKE '0%' THEN 'oui' ELSE 'non' END,
    CASE WHEN b.email LIKE '%@%' THEN 'oui' ELSE 'non' END
FROM koha_prod.$table r
JOIN koha_prod.borrowers b ON b.borrowernumber = r.borrowernumber
WHERE r.reservedate = ? ;
SQL
        $sth = $dbh->prepare($req);
        $sth->execute($date);
        $sth->finish();
    }
    $dbh->disconnect() ;
}

##################################################################
# On met à jour les champs ayant été modifiés la veille
sub reserves_maj {
    my ( $date ) = @_ ;

    my $dbh = GetDbh() ;
    my $req ;
    my $sth ;
    
    my @tables = qw( reserves old_reserves ) ;
    foreach my $table (@tables) {
        # On extrait les id des réservations à mettre à jour
        $req = "SELECT reserve_id FROM koha_prod.$table WHERE DATE(timestamp) = ? AND reservedate != ?" ;
        $sth = $dbh->prepare($req);
        $sth->execute($date, $date);
        my @reserve_id ;
        while ( my $reserve_id = $sth->fetchrow_array ) {
            push @reserve_id, $reserve_id ;
        }
        $sth->finish();
    
        # On met à jour stat_reserves
        $req = <<SQL ;
UPDATE statdb.stat_reserves s 
JOIN koha_prod.$table r ON r.reserve_id = s.reserve_id
SET
    s.notificationdate = r.notificationdate,
    s.cancellationdate = r.cancellationdate,
    s.priority = r.priority,
    s.found = r.found,
    s.timestamp = r.timestamp,
    s.itemnumber = r.itemnumber,
    s.waitingdate = r.waitingdate,
    s.expirationdate = r.expirationdate,
    s.annulation = CASE WHEN s.cancellationdate IS NULL THEN 'non' ELSE 'oui' END,
    s.document_mis_cote = CASE WHEN s.waitingdate IS NULL THEN 'non' ELSE 'oui' END
WHERE s.reserve_id = ? ;
SQL
        $sth = $dbh->prepare($req);
        foreach my $reserve_id (@reserve_id) {
            $sth->execute($reserve_id);
            # print "$reserve_id\n" ;
        }
        $sth->finish();
    }
    $dbh->disconnect() ;
}

##################################################################
# On complète les informations sur l'état

# On récupère les reserve_id créés la veille
sub new_reserve_id {
    my ( $date ) = @_ ;

    my $dbh = GetDbh() ;
    my $req = "SELECT reserve_id FROM statdb.stat_reserves WHERE reservedate = ? " ;
    my $sth = $dbh->prepare($req);
    $sth->execute($date);
    my @reserve_id ;
    while ( my $reserve_id = $sth->fetchrow_array ) {
        push @reserve_id, $reserve_id ;
    }
    $sth->finish();
    $dbh->disconnect() ;
    return @reserve_id ;
}

# On récupère des informations sur la réservation
sub reserves_infos {
    my ( $reserve_id ) = @_ ;

    my $dbh = GetDbh() ;
    my $req = "SELECT branchcode, biblionumber FROM statdb.stat_reserves WHERE reserve_id = ? " ;
    my $sth = $dbh->prepare($req);
    $sth->execute($reserve_id);
    my ( $branchcode, $biblionumber ) = $sth->fetchrow_array ;
    $sth->finish();
    $dbh->disconnect();
    return $branchcode, $biblionumber ;
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
    my ( $itemnumber ) = @_ ;
    my $test ;
    my $req = "SELECT COUNT(*) FROM koha_prod.issues WHERE itemnumber = ?" ;
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

# On renseigne le statut
sub updateStatutLocReservation {
    my ($reserve_id, $statutReservation, $localisation) = @_ ;
    my $dbh = GetDbh() ;
    my $req = <<SQL ;
UPDATE statdb.stat_reserves s 
SET etat = ?, espace = ?
WHERE reserve_id = ? ;
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($statutReservation, $localisation, $reserve_id);
    $sth->finish();
    $dbh->disconnect() ;
}

# On récupère la localisation de l'exemplaire
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