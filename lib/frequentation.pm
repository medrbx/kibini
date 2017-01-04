package frequentation ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( freq_etude lecteurs_presents ) ;

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::Duration;

use dbrequest ;
use fonctions ;

sub freq_etude {
	my ($cardnumber) = @_ ;
	my $datetime = datetime() ;
	my $dbh = dbh('statdb') ;
	my $max_id = freq_etude_max_id($dbh, $cardnumber) ;
	my $entree ;
	if (length $max_id) {
		# la personne est déjà entrée aujourd'hui, vérifier si elle est sortie :
		my $datetime_sortie = freq_etude_datetime_sortie($dbh, $max_id) ;
		if (length $datetime_sortie) {
			# la personne est déjà sortie, on recrée un renregistrement d'entrée
			freq_etude_entree($dbh, $cardnumber, $datetime) ;
			$entree = 1 ;
		} else {
			# la personne est entrée mais pas encore sortie, on note l'heure de sortie
			freq_etude_sortie($dbh, $max_id, $datetime) ;
			$entree = 0 ;
		}
	} else {
		# la personne n'est pas venue encore venue aujourd'hui,  on peut donc créer un enregistrement d'entrée
		freq_etude_entree($dbh, $cardnumber, $datetime) ;
		$entree = 1 ;
	}
	$dbh->disconnect();
	return $entree ;
}

sub freq_etude_max_id {
	my ($dbh, $cardnumber) = @_ ;
	my $req = "SELECT max(id) FROM stat_freq_etude WHERE DATE(datetime_entree) = CURDATE() AND cardnumber = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($cardnumber);
	return $sth->fetchrow_array ;
	$sth->finish();
}

sub freq_etude_datetime_entree {
	my ($dbh, $max_id) = @_ ;
	my $req = "SELECT datetime_entree FROM stat_freq_etude WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($max_id);
	return $sth->fetchrow_array ;
	$sth->finish();
}

sub freq_etude_datetime_sortie {
	my ($dbh, $max_id) = @_ ;
	my $req = "SELECT datetime_sortie FROM stat_freq_etude WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($max_id);
	return $sth->fetchrow_array ;
	$sth->finish();
}

sub freq_etude_entree {
	my ($dbh, $cardnumber, $datetime) = @_ ;
	my $req = "INSERT INTO stat_freq_etude (cardnumber, datetime_entree) VALUES (?, ?)" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($cardnumber, $datetime);
	$sth->finish();
}

sub freq_etude_sortie {
	my ($dbh, $id, $datetime_sortie) = @_ ;
	my $datetime_entree = freq_etude_datetime_entree($dbh, $id) ;
	my $duree = freq_etude_duree($datetime_entree, $datetime_sortie) ;
	my $req = "UPDATE stat_freq_etude SET datetime_sortie = ?, duree = ? WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($datetime_sortie, $duree, $id);
	$sth->finish();
}

sub freq_etude_duree {
	my ($entree, $sortie) = @_ ;
	my $duree = duree($entree, $sortie) ;
	my $formatter = DateTime::Format::Duration->new(
        pattern     => "%H:%M:%S",
        normalize   => 1,
    );
	$duree = $formatter->format_duration($duree);
	return $duree ;
}

sub lecteurs_presents {
	my $req = <<SQL;
SELECT cardnumber, TIME(datetime_entree) as entree, TIME(datetime_sortie) as sortie, duree
FROM stat_freq_etude
WHERE DATE(datetime_entree) = CURDATE()
ORDER BY datetime_entree DESC
SQL
	my $bdd = 'statdb';
	return fetchall_arrayref($bdd, $req);
}

1;