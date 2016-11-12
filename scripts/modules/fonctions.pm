package fonctions ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( age av branches category datetime date_form date_veille duree_pret es_maxdatetime getdataccode getdataitem getitemtype itemnumbermax lib_sll quartier_rbx retard type_carte ville15 ) ;

use strict ;
use warnings ;
use DBI ;
use utf8 ;
use DateTime ;
use DateTime::Format::MySQL ;
use FindBin qw( $Bin );

use lib "$Bin/../src/modules/" ;
use dbrequest ;

sub age {
	my ($age, $lib) = @_ ;
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT libelle FROM lib_age WHERE age = ? AND type = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($age, $lib);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();
}

sub av {
	my ($av, $cat) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT lib FROM authorised_values WHERE authorised_value = ? AND category = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($av, $cat);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();
}

sub branches {
	my ($branchcode) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT branchname FROM branches WHERE branchcode = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($branchcode);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();
}

sub category {
	my ($categorycode) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT description, category_type FROM categories WHERE categorycode = ? " ;
	my $sth = $dbh->prepare($req);
	$sth->execute($categorycode);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();
}

sub datetime {
	my $dt = DateTime->now ;
	$dt = DateTime::Format::MySQL->format_datetime($dt) ;
	return $dt ;
}

sub date_form {
		my ( $date_transaction ) = @_ ;
		my $dt_date_transaction = DateTime::Format::MySQL->parse_datetime($date_transaction) ;
		
		my $year = $dt_date_transaction->year() ;
		
		my $month = $dt_date_transaction->month() ;
		if ($month < 10 ) { $month = "0".$month ; }
		
		my $week_number = $dt_date_transaction->week_number() ;
		if ($week_number < 10 ) { $week_number = "0".$week_number ; }
		
		my $day = $dt_date_transaction->day() ;
		
		my $dow = $dt_date_transaction->dow() ;
		my %dicdow = (
			"1" => "1 Lundi",
			"2" => "2 Mardi",
			"3" => "3 Mercredi",
			"4" => "4 Jeudi",
			"5" => "5 Vendredi",
			"6" => "6 Samedi",
			"7" => "7 Dimanche"
		) ;
		my $jour_semaine = $dicdow{$dow} ;
		
		my $hour = $dt_date_transaction->hour() ;
		if ($hour < 10 ) { $hour = "0".$hour ; }
		
		return $year, $month, $week_number, $day, $jour_semaine, $hour ;
}

sub date_veille {
	my $dt = DateTime->today() ;
	my $date = $dt->subtract( days => 1	) ;
	$date = DateTime::Format::MySQL->format_date($date) ;
	return $date
}

sub duree_pret {
	my ( $issuedate, $returndate ) = @_ ;
	if (defined $returndate ) {
		my $dt_returndate = DateTime::Format::MySQL->parse_datetime($returndate) ;
		my $dt_issuedate = DateTime::Format::MySQL->parse_datetime($issuedate) ;
		my $duration = $dt_returndate->delta_days($dt_issuedate);
		return $duration->days ;
	}
}

sub es_maxdatetime {
	my ( $index, $type, $field ) = @_ ;
	my %params = ( nodes => 'http://localhost:9200' ) ;

	my $e = Search::Elasticsearch->new( %params ) ;

	my $result =  $e->search(
		index => $index,
		type  => $type,
		body    => {
			aggs       => {
				max_datetime => {
					max => {
						field => $field
					}
				}
			}
		}
	);

	return $result->{aggregations}->{max_datetime}->{value_as_string} ; 
}

sub getdataccode {
	my ($itemnumber) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT i.ccode, c.lib1, c.lib2, c.lib3, c.lib4 FROM koha_prod.items i JOIN statdb.lib_collections2 c ON i.ccode = c.ccode WHERE i.itemnumber = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($itemnumber);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();	
}

sub getdataitem {
	my ($itemnumber) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT location, homebranch, ccode FROM items WHERE itemnumber = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($itemnumber);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();	
}

sub getitemtype {
	my ($biblionumber) = @_ ;
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT itemtype FROM biblioitems WHERE biblionumber = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($biblionumber);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();	
}

sub lib_sll {
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

sub itemnumbermax {
	my $bdd = "koha_prod" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT max(itemnumber) FROM items" ;
	my $sth = $dbh->prepare($req);
	$sth->execute();
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();	
}

sub quartier_rbx {
	my ($iris) = @_ ;
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	my $req = "SELECT irisNom, quartier FROM iris_lib WHERE irisInsee = ?" ;
	my $sth = $dbh->prepare($req);
	$sth->execute($iris);
	return $sth->fetchrow_array ;
	$sth->finish();
	$dbh->disconnect();
}

sub retard {
	my ( $date_due, $returndate ) = @_ ;
	if (defined $returndate ) {
		my $dt_returndate = DateTime::Format::MySQL->parse_datetime($returndate) ;
		my $dt_date_due = DateTime::Format::MySQL->parse_datetime($date_due) ;
		my $duration = $dt_returndate->delta_days($dt_date_due);
		return $duration->days ;
	}
}

sub type_carte {
        my ( $categorycode ) = @_ ;
        my $type_carte ;
        if ($categorycode eq "BIBL" ) { $type_carte = "Médiathèque" ; }
        my @liste = qw( MEDA MEDB MEDC CSVT MEDP ) ;
        if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Médiathèque Plus" ; }
        if ($categorycode eq "CSLT" ) { $type_carte = "Consultation sur place" ; }
        @liste = qw( COLI COLD ) ;
        if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Prêt en nombre" ; }
        @liste = qw( ECOL CLAS  ) ;
        if ( grep {$_ eq $categorycode} @liste ) { $type_carte = "Structures scolaires" ; }
        if ($categorycode eq "COLS" ) { $type_carte = "Structures non scolaires" ; }
        return $type_carte ;
}

sub ville15 {
        my ( $city ) = @_ ;
        my $ville15 ;
        my @liste = qw( CROIX HEM LEERS LILLE LYS-LEZ-LANNOY MARCQ-EN-BAROEUL MONS-EN-BAROEUL MOUVAUX NEUVILLE-EN-FERRAIN ROUBAIX TOUFFLERS TOURCOING VILLENEUVE-D'ASCQ WASQUEHAL WATTRELOS ) ;
        if ( grep {$_ eq $city} @liste ) {
                $ville15 = $city ;
        } else {
                $ville15 = "AUTRE" ;
        }
        return $ville15 ;
}

1;
