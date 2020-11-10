#! /usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );
use Text::CSV;
use Data::Dumper;

use lib "$Bin/../lib";
use adherents;

my $in = Text::CSV->new ({ binary => 1 });
open(my $fd_in, "<:encoding(UTF-8)", "statArteVodAdherentId.csv");
$in->column_names (qw( adherent_id ));

my $out = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open(my $fd_out,">:encoding(utf8)","statArteVodWithData20.csv");
my @column_names = qw( adherent_id sexe ages_lib1 ages_lib2 ages_lib3 geo_ville geo_ville_front geo_roubaix_iris geo_roubaix_nom_iris geo_roubaix_quartier geo_gentile inscription_personnalite inscription_carte inscription_type_carte inscription_site_inscription inscription_gratuite inscription_prix inscription_fidelite inscription_fidelite_tr activite_emprunteur activite_emprunteur_med activite_emprunteur_bus activite_utilisateur_postes_informatiques activite_utilisateur_wifi activite_salle_etude activite inscription_attribut nb_venues nb_venues_tr nb_venues_prets nb_venues_prets_tr nb_venues_prets_mediatheque nb_venues_prets_mediatheque_tr nb_venues_prets_bus nb_venues_prets_bus_tr nb_venues_postes_informatiques nb_venues_postes_informatiques_tr nb_venues_wifi nb_venues_wifi_tr nb_venues_salle_etude nb_venues_salle_etude_tr );
$out->print ($fd_out, \@column_names);

while (my $adherent_arte = $in->getline_hr ($fd_in)) {
	my $adherent = getBorrowerDataByBorrowernumber($adherent_arte->{adherent_id});
	my @row_to_print = ($adherent_arte->{adherent_id}, $adherent->{sexe}, $adherent->{age_lib1}, $adherent->{age_lib2}, $adherent->{age_lib3}, $adherent->{geo_ville}, $adherent->{geo_ville_front}, $adherent->{geo_roubaix_iris}, $adherent->{geo_roubaix_nom_iris}, $adherent->{geo_roubaix_quartier}, $adherent->{gentile}, $adherent->{personnalite}, $adherent->{inscription_carte}, $adherent->{type_carte}, $adherent->{inscription_site_inscription}, $adherent->{inscription_gratuite}, $adherent->{inscription_prix}, $adherent->{inscription_fidelite}, $adherent->{inscription_fidelite_tr}, $adherent->{activite_emprunteur}, $adherent->{activite_emprunteur_med}, $adherent->{activite_emprunteur_bus}, $adherent->{activite_utilisateur_postes_informatiques}, $adherent->{activite_utilisateur_wifi}, $adherent->{activite_utilisateur_salle_etude}, $adherent->{type_use}, $adherent->{inscription_attribut_lib}, $adherent->{nb_venues}, $adherent->{nb_venues_tr}, $adherent->{nb_venues_prets}, $adherent->{nb_venues_prets_tr}, $adherent->{nb_venues_prets_mediatheque}, $adherent->{nb_venues_prets_mediatheque_tr}, $adherent->{nb_venues_prets_bus}, $adherent->{nb_venues_prets_bus_tr}, $adherent->{nb_venues_postes_informatiques}, $adherent->{nb_venues_postes_informatiques_tr}, $adherent->{nb_venues_wifi}, $adherent->{nb_venues_wifi_tr}, $adherent->{nb_venues_salle_etude}, $adherent->{nb_venues_salle_etude_tr});
	$out->print ($fd_out, \@row_to_print);
	print Dumper($adherent);
}

close $fd_in;
close $fd_out;


__END__
my $borrowernumber = "44421";
my $adherent = getBorrowerDataByBorrowernumber($borrowernumber);
print Dumper($adherent);


#! /usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );
use Text::CSV;
use Data::Dumper;

use lib "$Bin/../lib";
use adherents;

my $in = Text::CSV->new ({ binary => 1 });
open(my $fd_in, "<:encoding(UTF-8)", "statArteVod.csv") ;
$in->column_names (qw( adherent_id	arte_date_inscription	arte_derniere_mise_a_jour	arte_derniere_connexion	arte_abonnement_valide	arte_abonnement_en_cours	arte_nb_consommations ));
while (my $adherent = $in->getline_hr ($fd_in)) {
    print Dumper($adherent);
}

my $borrowernumber = "44421";
my $adherent = getBorrowerDataByBorrowernumber($borrowernumber);
print Dumper($adherent);

my $csv = Text::CSV->new ({ binary => 1 });
open(my $fd, "<:encoding(UTF-8)", "mon_fichier.csv") ;
while (my $row = $csv->getline ($fd)) {
    ...
}
close $fd ;

# Lire un fichier CSV et récupérer les lignes comme référence de hash
my $csv = Text::CSV->new ({ binary => 1 });
open(my $fd, "<:encoding(UTF-8)", "mon_fichier.csv") ;
$csv->column_names (qw( code name price description ));
while (my $row = $csv->getline_hr ($fd)) {
    ...
}
close $fd ;

# Ecrire dans un fichier csv
$csv = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open(my $fd,">:encoding(utf8)","mon_fichier.csv") ;

# On crée la première ligne avec les noms de colonnes
my @column_names = qw( collection_code collection_lib1 collection_lib2 collection_lib3 collection_lib4 support nb_exemplaires nb_exemplaires_empruntables nb_exemplaires_consultables_sur_place_uniquement nb_exemplaires_en_acces_libre nb_exemplaires_en_acces_indirect nb_exemplaires_en_commande nb_exemplaires_en_traitement nb_exemplaires_en_abîmés nb_exemplaires_en_réparation nb_exemplaires_en_retrait nb_exemplaires_en_reliure nb_exemplaires_perdus nb_exemplaires_non_restitués nb_exemplaires_créés_dans_annee nb_exemplaires_empruntables_pas_empruntés_3_ans nb_exemplaires_en_pret ) ;
$csv->print ($fd, \@column_names) ;

# On imagine qu'on récupère chaque ligne via une boucle
while ( my $row = $sth->fetchrow_arrayref ) {
    $csv->print ($fd, $row);
}
close $fd ;