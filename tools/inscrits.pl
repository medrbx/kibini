#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Adherent;
use adherents;
use Kibini::DB;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;

my $importer = Catmandu->importer('CSV', file => "adherents_20170927.csv");
my $exporter = Catmandu->exporter('CSV', file => "adherents_inscrits2.csv");

$importer->each(sub {
    my $data = shift;
	my $borrower = Adherent->new( { dbh => $dbh, adherent => $data } );
	$borrower->get_sex;
	$borrower->get_age_at_time_of_event( {format_date_event => 'date', date_event_field => 'statdb_date_extraction'} );
	$borrower->get_fidelite( {format_date_event => 'date', date_event_field => 'statdb_date_extraction'} );
	
    my $adherent = {};
	$adherent->{borrowernumber} = $borrower->koha_borrowernumber;
	$adherent->{isEnrolled} = isEnrolled($dbh, $adherent->{borrowernumber});
	$adherent->{sexe} = $borrower->es_sexe;
	#age
	$adherent->{age} = $borrower->statdb_age;
	$adherent->{age_lib1} = GetAgeLib($dbh, $adherent->{age}, "trmeda");
    $adherent->{age_lib2} = GetAgeLib($dbh, $adherent->{age}, "trmedb");
    $adherent->{age_lib3} = GetAgeLib($dbh, $adherent->{age}, "trinsee");
	# geo
	$adherent->{geo_ville} = $borrower->koha_city;
    if ($adherent->{geo_ville} eq 'ROUBAIX') {
        $adherent->{gentile} = 'Roubaisien';
    } else {
        $adherent->{gentile} = 'Non Roubaisien';
    }
    $adherent->{geo_ville_front} = GetCityFront( $adherent->{geo_ville} );
	
	$adherent->{geo_roubaix_iris} = $borrower->koha_altcontactcountry;
    if (defined $adherent->{geo_roubaix_iris}) {
        ($adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}) = GetRbxDistrict($dbh, $adherent->{geo_roubaix_iris});
    }
	# inscription
	$adherent->{inscription_code_carte} = $borrower->koha_categorycode;
    ( $adherent->{inscription_carte}, $adherent->{personnalite} ) = GetCategoryDesc( $dbh, $adherent->{inscription_code_carte} );
    $adherent->{type_carte} = GetCardType($adherent->{inscription_code_carte});
	$adherent->{inscription_code_site} = $borrower->koha_branchcode;
    if ( $adherent->{inscription_code_site} eq 'MED' ) {
        $adherent->{inscription_site_inscription} = "Médiathèque";
    } elsif ( $adherent->{inscription_code_site} eq 'BUS' ) { 
        $adherent->{inscription_site_inscription} = "Zèbre";
    }
	$adherent->{inscription_fidelite} = $borrower->statdb_fidelite;
    $adherent->{inscription_fidelite_tr} = GetTrFidelite($adherent->{inscription_fidelite});
	$adherent->{inscription_attribut} = $borrower->koha_attribute;
	if ( $adherent->{inscription_attribut} ) {
		$adherent->{inscription_attribut_lib} = getEsAttribute($adherent->{inscription_attribut});
		#$adherent->{inscription_attribut_lib} = join( '', @{$adherent->{inscription_attribut_lib}->{action}});
	}
	
	# prix inscription
    ($adherent->{inscription_gratuite}, $adherent->{inscription_prix}) = getPrixAdhesion($adherent->{inscription_code_carte});
	
	
	print Dumper($adherent);
	$exporter->add($adherent);
});



sub isEnrolled {
	my ($dbh, $borrowernumber) = @_;
	
	my $req = "SELECT CASE WHEN dateexpiry >= CURDATE() THEN 'oui' ELSE 'non' END FROM koha_prod.borrowers WHERE borrowernumber = ?";
	my $sth = $dbh->prepare($req);
	$sth->execute($borrowernumber);
	
	my $isEnrolled = $sth->fetchrow_array;
	
	if ($isEnrolled ne 'oui') {
		$isEnrolled = 'non';
	}
	
	return $isEnrolled;
}