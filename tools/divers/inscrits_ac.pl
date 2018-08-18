#!/usr/bin/perl

use Modern::Perl;
use Text::CSV;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use adherents;

my $dbh = GetDbh();

my $csv = Text::CSV->new ({ binary => 1 });
open(my $fd, "<:encoding(UTF-8)", "inscrits_ac.csv");
$csv->column_names (qw( id inscrit ));
while (my $row = $csv->getline_hr ($fd)) {
    if ( $row->{inscrit} ne 'non inscrit') {
        $row->{borrowerdata} = getBorrowerData($dbh, $row->{inscrit});
        $row->{inscrit} = 'inscrit';
        # sexe
        if ($row->{borrowerdata}->{title} eq 'Madame') {
            $row->{borrowerdata}->{sexe} = 'Femme';
        } elsif ($row->{borrowerdata}->{title} eq 'Monsieur') {
            $row->{borrowerdata}->{sexe} = 'Homme';
        }
        #age
        $row->{borrowerdata}->{ages_lib1} = GetAgeLib($dbh, $row->{borrowerdata}->{age}, "trmeda");
        $row->{borrowerdata}->{ages_lib2} = GetAgeLib($dbh, $row->{borrowerdata}->{age}, "trmedb");
        $row->{borrowerdata}->{ages_lib3} = GetAgeLib($dbh, $row->{borrowerdata}->{age}, "trinsee");
        # geo
        if ($row->{borrowerdata}->{geo_ville} eq 'ROUBAIX') {
            $row->{borrowerdata}->{gentile} = 'Roubaisien';
        } else {
            $row->{borrowerdata}->{gentile} = 'Non Roubaisien';
        }
        $row->{borrowerdata}->{geo_ville_front} = GetCityFront( $row->{borrowerdata}->{geo_ville} );
        if (defined $row->{borrowerdata}->{geo_roubaix_iris}) {
            ($row->{borrowerdata}->{geo_roubaix_nom_iris}, $row->{borrowerdata}->{geo_roubaix_quartier}) = GetRbxDistrict($dbh, $row->{borrowerdata}->{geo_roubaix_iris});
        }
        # inscription
        ( $row->{borrowerdata}->{inscription_carte}, $row->{borrowerdata}->{personnalite} ) = GetCategoryDesc( $dbh, $row->{borrowerdata}->{inscription_code_carte} );
        $row->{borrowerdata}->{type_carte} = GetCardType($row->{borrowerdata}->{inscription_code_carte});
        if ($row->{borrowerdata}->{inscription_code_site} eq 'MED' ) {
            $row->{borrowerdata}->{inscription_site_inscription} = "Médiathèque";
        } elsif ( $row->{borrowerdata}->{inscription_code_site} eq 'BUS' ) { 
            $row->{borrowerdata}->{inscription_site_inscription} = "Zèbre";
        }
        $row->{borrowerdata}->{inscription_fidelite_tr} = GetTrFidelite($row->{borrowerdata}->{inscription_fidelite});
        $row->{borrowerdata}->{inscription_attribut_lib} = getEsAttribute($row->{borrowerdata}->{inscription_attribut}) if ( $row->{borrowerdata}->{inscription_attribut} );
        # venues
        $row->{borrowerdata}->{nb_venues_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues});
        #$row->{borrowerdata}->{nb_venues_prets_mediatheque_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_prets_mediatheque});
        #$row->{borrowerdata}->{nb_venues_prets_bus_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_prets_bus});
        #$row->{borrowerdata}->{nb_venues_prets} = $row->{borrowerdata}->{nb_venues_prets_mediatheque} + $row->{borrowerdata}->{nb_venues_prets_bus};
        #$row->{borrowerdata}->{nb_venues_prets_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_prets});
        #$row->{borrowerdata}->{nb_venues_postes_informatiques_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_postes_informatiques});
        #$row->{borrowerdata}->{nb_venues_wifi_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_wifi});
        #$row->{borrowerdata}->{nb_venues_salle_etude_tr} = GetTrVenue($row->{borrowerdata}->{nb_venues_salle_etude});
        #$row->{borrowerdata}->{type_use} = getTypeUse($row->{borrowerdata});
    }
    
    print Dumper($row);
}
close $fd;

sub getBorrowerData {
    my ($dbh, $cardnumber) = @_;
    my $req = <<SQL;
SELECT
    borrowernumber AS adherent_id,
    title,
    YEAR(CURDATE()) - YEAR(dateofbirth) AS age,
    city AS geo_ville,
    altcontactcountry AS geo_roubaix_iris,
    branchcode AS inscription_code_site,
    categorycode AS inscription_code_carte,
    YEAR(CURDATE()) - YEAR(dateenrolled) AS inscription_fidelite
FROM koha_prod.borrowers
WHERE cardnumber = ?    
SQL
    
    my $sth = $dbh->prepare($req);
    $sth->execute($cardnumber);
    my $data = $sth->fetchrow_hashref;
    
    return $data;
}