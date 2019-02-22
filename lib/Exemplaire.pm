package Exemplaire;

use Moo;
use utf8;

with 'Document';

sub add_data_to_statdb_data_exemplaires {
    my ($self) = @_;
     
    my $dbh = $self->{dbh};
    my $req = <<SQL;
INSERT INTO statdb.data_exemplaires
(ex_item_id, ex_biblio_annee_publication, ex_biblio_id, ex_biblio_prix, ex_biblio_support_code, ex_biblio_titre, ex_item_annee_mise_pilon, ex_item_code_barre, ex_item_collection_ccode, ex_item_cote, ex_item_date_creation, ex_item_localisation_code, ex_item_site_detenteur_code, ex_item_site_rattachement_code, ex_statut_code, ex_statut_abime_code, ex_statut_desherbe_code, ex_statut_desherbe_date, ex_statut_perdu_code, ex_statut_perdu_date, ex_usage_emprunt_code, ex_usage_date_dernier_pret, ex_item_deleted)
VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
    my $sth = $dbh->prepare($req);
    my $res = $sth->execute(
		$self->{statdb_item_id},
		$self->{statdb_biblio_annee_publication},
		$self->{statdb_biblio_id},
		$self->{statdb_biblio_prix},
		$self->{statdb_biblio_support_code},
		$self->{statdb_biblio_titre},
		$self->{statdb_item_annee_mise_pilon},
		$self->{statdb_item_code_barre},
		$self->{statdb_item_collection_ccode},
		$self->{statdb_item_cote},
		$self->{statdb_item_date_creation},
		$self->{statdb_item_localisation_code},
		$self->{statdb_item_site_detenteur_code},
		$self->{statdb_item_site_rattachement_code},
		$self->{statdb_statut_code},
		$self->{statdb_statut_abime_code},
		$self->{statdb_statut_desherbe_code},
		$self->{statdb_statut_desherbe_date},
		$self->{statdb_statut_perdu_code},
		$self->{statdb_statut_perdu_date},
		$self->{statdb_usage_emprunt_code},
		$self->{statdb_usage_date_dernier_pret},
		$self->{statdb_item_deleted}
    );
    $sth->finish();
    return $res;
}

sub update_data_in_statdb_data_exemplaires {
    my ($self) = @_;
     
    my $dbh = $self->{dbh};
    my $req = <<SQL;
UPDATE statdb.data_exemplaires
SET
	ex_biblio_annee_publication = ?,
    ex_biblio_id = ?,
    ex_biblio_prix = ?,
    ex_biblio_support_code = ?,
    ex_biblio_titre = ?,
    ex_item_annee_mise_pilon = ?,
    ex_item_code_barre = ?,
    ex_item_collection_ccode = ?,
    ex_item_cote = ?,
    ex_item_date_creation = ?,
    ex_item_localisation_code = ?,
    ex_item_site_detenteur_code = ?,
    ex_item_site_rattachement_code = ?,
    ex_statut_code = ?,
    ex_statut_abime_code = ?,
    ex_statut_desherbe_code = ?,
    ex_statut_desherbe_date = ?,
    ex_statut_perdu_code = ?,
    ex_statut_perdu_date = ?,
    ex_usage_emprunt_code = ?,
    ex_usage_date_dernier_pret = ?,
    ex_item_deleted = ?
WHERE ex_item_id = ?
SQL
    my $sth = $dbh->prepare($req);
    my $res = $sth->execute(
		$self->{statdb_biblio_annee_publication},
		$self->{statdb_biblio_id},
		$self->{statdb_biblio_prix},
		$self->{statdb_biblio_support_code},
		$self->{statdb_biblio_titre},
		$self->{statdb_item_annee_mise_pilon},
		$self->{statdb_item_code_barre},
		$self->{statdb_item_collection_ccode},
		$self->{statdb_item_cote},
		$self->{statdb_item_date_creation},
		$self->{statdb_item_localisation_code},
		$self->{statdb_item_site_detenteur_code},
		$self->{statdb_item_site_rattachement_code},
		$self->{statdb_statut_code},
		$self->{statdb_statut_abime_code},
		$self->{statdb_statut_desherbe_code},
		$self->{statdb_statut_desherbe_date},
		$self->{statdb_statut_perdu_code},
		$self->{statdb_statut_perdu_date},
		$self->{statdb_usage_emprunt_code},
		$self->{statdb_usage_date_dernier_pret},
		$self->{statdb_item_deleted},
		$self->{statdb_item_id}
    );
    $sth->finish();
    return $res;
}

sub isStatdb_item_idInStatdb {
	my ($self) = @_;
	my $res;
	
	my $dbh = $self->{dbh};
	my $req = "SELECT COUNT(*) FROM statdb.data_exemplaires WHERE ex_item_id = ?";
	my $sth = $dbh->prepare($req);
    $sth->execute($self->{statdb_item_id});
	my $count = $sth->fetchrow_array;
	if ($count == 0) {
		$res = 'n';
	} else {
		$res = 'y';	
	}
	
	return $res;
}

1;

__END__