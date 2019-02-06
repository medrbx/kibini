#! /usr/bin/perl

use Modern::Perl;
use FindBin qw( $Bin );
use Text::CSV;
use Data::Dumper;

use lib "$Bin/../lib";
use adherents;

my $in = Text::CSV->new ({ binary => 1 });
open(my $fd_in, "<:encoding(UTF-8)", "wk_logs_prints.csv");
$in->column_names (qw( id_log_print	user_id	login	media_name	space_name	station_name	printer_name	isColor	date_print	week_print	used_print	used_pages ));

my $out = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open(my $fd_out,">:encoding(utf8)","wk_logs_printsWithData.csv");
my @column_names = qw( wk_id_log_print	wk_user_id	wk_login	wk_media_name	wk_space_name	wk_station_name	wk_printer_name	wk_isColor	wk_date_print	wk_week_print	wk_used_print	wk_used_pages sexe ages_lib1 ages_lib2 ages_lib3 geo_ville geo_ville_front geo_roubaix_iris geo_roubaix_nom_iris geo_roubaix_quartier geo_gentile inscription_personnalite inscription_carte inscription_type_carte inscription_site_inscription inscription_gratuite inscription_prix inscription_fidelite inscription_fidelite_tr activite_emprunteur activite_emprunteur_med activite_emprunteur_bus activite_utilisateur_postes_informatiques activite_utilisateur_wifi activite_salle_etude activite inscription_attribut nb_venues nb_venues_tr nb_venues_prets nb_venues_prets_tr nb_venues_prets_mediatheque nb_venues_prets_mediatheque_tr nb_venues_prets_bus nb_venues_prets_bus_tr nb_venues_postes_informatiques nb_venues_postes_informatiques_tr nb_venues_wifi nb_venues_wifi_tr nb_venues_salle_etude nb_venues_salle_etude_tr );
$out->print ($fd_out, \@column_names);

while (my $adherent = $in->getline_hr ($fd_in)) {
	my $data = getBorrowerDataByUserid($adherent->{login});
	$adherent->{data} = $data;
	my @row_to_print = ($adherent->{id_log_print}, $adherent->{user_id}, $adherent->{login}, $adherent->{media_name}, $adherent->{space_name}, $adherent->{station_name}, $adherent->{printer_name}, $adherent->{isColor}, $adherent->{date_print}, $adherent->{week_print}, $adherent->{used_print}, $adherent->{used_pages}, $adherent->{data}->{sexe}, $adherent->{data}->{age_lib1}, $adherent->{data}->{age_lib2}, $adherent->{data}->{age_lib3}, $adherent->{data}->{geo_ville}, $adherent->{data}->{geo_ville_front}, $adherent->{data}->{geo_roubaix_iris}, $adherent->{data}->{geo_roubaix_nom_iris}, $adherent->{data}->{geo_roubaix_quartier}, $adherent->{data}->{gentile}, $adherent->{data}->{personnalite}, $adherent->{data}->{inscription_carte}, $adherent->{data}->{type_carte}, $adherent->{data}->{inscription_site_inscription}, $adherent->{data}->{inscription_gratuite}, $adherent->{data}->{inscription_prix}, $adherent->{data}->{inscription_fidelite}, $adherent->{data}->{inscription_fidelite_tr}, $adherent->{data}->{activite_emprunteur}, $adherent->{data}->{activite_emprunteur_med}, $adherent->{data}->{activite_emprunteur_bus}, $adherent->{data}->{activite_utilisateur_postes_informatiques}, $adherent->{data}->{activite_utilisateur_wifi}, $adherent->{data}->{activite_utilisateur_salle_etude}, $adherent->{data}->{type_use}, $adherent->{data}->{inscription_attribut_lib}, $adherent->{data}->{nb_venues}, $adherent->{data}->{nb_venues_tr}, $adherent->{data}->{nb_venues_prets}, $adherent->{data}->{nb_venues_prets_tr}, $adherent->{data}->{nb_venues_prets_mediatheque}, $adherent->{data}->{nb_venues_prets_mediatheque_tr}, $adherent->{data}->{nb_venues_prets_bus}, $adherent->{data}->{nb_venues_prets_bus_tr}, $adherent->{nb_venues_postes_informatiques}, $adherent->{data}->{nb_venues_postes_informatiques_tr}, $adherent->{data}->{nb_venues_wifi}, $adherent->{data}->{nb_venues_wifi_tr}, $adherent->{data}->{nb_venues_salle_etude}, $adherent->{data}->{nb_venues_salle_etude_tr});
	$out->print ($fd_out, \@row_to_print);
	print Dumper(\@row_to_print);
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