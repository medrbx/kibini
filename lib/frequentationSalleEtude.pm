package frequentationSalleEtude ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( IsEntrance GetTodayEntrance ) ;

use strict ;
use warnings ;
use DateTime ;
use DateTime::Format::Duration;

use Kibini::DB ;
use fonctions ;

sub IsEntrance {
	my ($cardnumber) = @_ ;
	my $datetime = datetime() ;
	my $dbh = Kibini::DB->new()->get_dbh() ;
	my $borrowerTodayLastEntranceId = _GetBorrowerTodayLastEntranceId($dbh, $cardnumber) ;
	my $entrance ;
	if (length $borrowerTodayLastEntranceId) {
		# la personne est déjà entrée aujourd'hui, vérifier si elle est sortie :
		my $datetime_exit = _ModEntranceWithExit($dbh, $borrowerTodayLastEntranceId) ;
		if (length $datetime_exit) {
			# la personne est déjà sortie, on recrée un renregistrement d'entrée
			_AddEntrance($dbh, $cardnumber, $datetime) ;
			$entrance = 1 ;
		} else {
			# la personne est entrée mais pas encore sortie, on note l'heure de sortie
			_ModEntranceWithExit($dbh, $borrowerTodayLastEntranceId, $datetime) ;
			$entrance = 0 ;
		}
	} else {
		# la personne n'est pas venue encore venue aujourd'hui,  on peut donc créer un enregistrement d'entrée
		_AddEntrance($dbh, $cardnumber, $datetime) ;
		$entrance = 1 ;
	}
	$dbh->disconnect();
	return $entrance ;
}


sub GetTodayEntrance {
	my $req = <<SQL;
SELECT cardnumber, TIME(datetime_entree) as entree, TIME(datetime_sortie) as sortie, duree
FROM stat_freq_etude
WHERE DATE(datetime_entree) = CURDATE()
ORDER BY datetime_entree DESC
SQL
	return Kibini::DB->new()->get_all_arrayref($req);
}

sub _GetBorrowerTodayLastEntranceId {
	my ($dbh, $cardnumber) = @_ ;
	my $req = "SELECT max(id) FROM statdb.stat_freq_etude WHERE DATE(datetime_entree) = CURDATE() AND cardnumber = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($cardnumber);
	return $sth->fetchrow_array ;
	$sth->finish();
}

sub _GetDatetimeEntranceById {
	my ($dbh, $max_id) = @_ ;
	my $req = "SELECT datetime_entree FROM stat_freq_etude WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($max_id);
	return $sth->fetchrow_array ;
	$sth->finish();
}

sub _GetDatetimeExitById {
	my ($dbh, $max_id) = @_ ;
	my $req = "SELECT datetime_sortie FROM stat_freq_etude WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($max_id);
	return $sth->fetchrow_array ;
	$sth->finish();
}


sub _AddEntrance {
	my ($dbh, $cardnumber, $datetime) = @_ ;
	my $req = "INSERT INTO stat_freq_etude (cardnumber, datetime_entree) VALUES (?, ?)" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($cardnumber, $datetime);
	$sth->finish();
}

sub _ModEntranceWithExit {
	my ($dbh, $id, $datetime_sortie) = @_ ;
	my $datetime_entree = _GetDatetimeEntranceById($dbh, $id) ;
	my $duree = _GetDuration($datetime_entree, $datetime_sortie) ;
	my $req = "UPDATE stat_freq_etude SET datetime_sortie = ?, duree = ? WHERE id = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($datetime_sortie, $duree, $id);
	$sth->finish();
}

sub _GetDuration {
	my ($entree, $sortie) = @_ ;
	my $duree = duree($entree, $sortie) ;
	my $formatter = DateTime::Format::Duration->new(
        pattern     => "%H:%M:%S",
        normalize   => 1,
    );
	$duree = $formatter->format_duration($duree);
	return $duree ;
}

1;
