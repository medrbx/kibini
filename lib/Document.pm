package Document;

use Moo::Role;
use utf8;

use Kibini::DB;

has dbh => ( is => 'ro' );

has koha_publicationyear => ( is => 'ro' );
has koha_biblionumber => ( is => 'ro' );
has koha_price => ( is => 'ro' );
has koha_itemtype => ( is => 'ro' );
has koha_title => ( is => 'ro' );
has koha_barcode => ( is => 'ro' );
has koha_ccode => ( is => 'ro' );
has koha_itemcallnumber => ( is => 'ro' );
has koha_dateaccessioned => ( is => 'ro' );
has koha_itemnumber => ( is => 'ro' );
has koha_location => ( is => 'ro' );
has koha_homebranch => ( is => 'ro' );
has koha_holdingbranch => ( is => 'ro' );
has koha_notforloan => ( is => 'ro' );
has koha_damaged => ( is => 'ro' );
has koha_withdrawn => ( is => 'ro' );
has koha_withdrawn_on => ( is => 'ro' );
has koha_itemlost => ( is => 'ro' );
has koha_itemlost_on => ( is => 'ro' );
has koha_onloan => ( is => 'ro' );
has koha_datelastborrowed => ( is => 'ro' );

has statdb_biblio_annee_publication => ( is => 'ro' );
has statdb_biblio_id => ( is => 'ro' );
has statdb_biblio_prix => ( is => 'ro' );
has statdb_biblio_support_code => ( is => 'ro' );
has statdb_biblio_titre => ( is => 'ro' );
has statdb_item_annee_mise_pilon => ( is => 'ro' );
has statdb_item_code_barre => ( is => 'ro' );
has statdb_item_collection_ccode => ( is => 'ro' );
has statdb_item_cote => ( is => 'ro' );
has statdb_item_date_creation => ( is => 'ro' );
has statdb_item_id => ( is => 'ro' );
has statdb_item_localisation_code => ( is => 'ro' );
has statdb_item_site_detenteur_code => ( is => 'ro' );
has statdb_item_site_rattachement_code => ( is => 'ro' );
has statdb_statut_code => ( is => 'ro' );
has statdb_statut_abime_code => ( is => 'ro' );
has statdb_statut_desherbe_code => ( is => 'ro' );
has statdb_statut_desherbe_date => ( is => 'ro' );
has statdb_statut_perdu_code => ( is => 'ro' );
has statdb_statut_perdu_date => ( is => 'ro' );
has statdb_usage_emprunt_code => ( is => 'ro' );
has statdb_usage_date_dernier_pret => ( is => 'ro' );
has statdb_item_deleted => ( is => 'ro' );

has es_biblio_annee_publication => ( is => 'ro' );
has es_biblio_id => ( is => 'ro' );
has es_biblio_prix => ( is => 'ro' );
has es_biblio_support => ( is => 'ro' );
has es_biblio_titre => ( is => 'ro' );
has es_item_annee_mise_pilon => ( is => 'ro' );
has es_item_code_barre => ( is => 'ro' );
has es_item_collection_ccode => ( is => 'ro' );
has es_item_collection_lib1 => ( is => 'ro' );
has es_item_collection_lib2 => ( is => 'ro' );
has es_item_collection_lib3 => ( is => 'ro' );
has es_item_collection_lib4 => ( is => 'ro' );
has es_item_cote => ( is => 'ro' );
has es_item_date_creation => ( is => 'ro' );
has es_item_id => ( is => 'ro' );
has es_item_localisation => ( is => 'ro' );
has es_item_site_detenteur => ( is => 'ro' );
has es_item_site_rattachement => ( is => 'ro' );
has es_sll_acces => ( is => 'ro' );
has es_sll_collection => ( is => 'ro' );
has es_sll_prets => ( is => 'ro' );
has es_sll_prets_coll => ( is => 'ro' );
has es_sll_public => ( is => 'ro' );
has es_statut => ( is => 'ro' );
has es_statut_abime => ( is => 'ro' );
has es_statut_desherbe => ( is => 'ro' );
has es_statut_desherbe_date => ( is => 'ro' );
has es_statut_perdu => ( is => 'ro' );
has es_statut_perdu_date => ( is => 'ro' );
has es_usage_emprunt => ( is => 'ro' );
has es_usage_date_dernier_pret => ( is => 'ro' );
has es_item_deleted => ( is => 'ro' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{dbh} ) {
        $arg->{dbh} = $args[0]->{dbh};
    } else {
        my $dbh = Kibini::DB->new;
        $dbh = $dbh->dbh;
        $arg->{dbh} = $dbh;
    }
    
    if ( $args[0]->{document} ) {
        my %doc = %{$args[0]->{document}};
        foreach my $k (keys(%doc)) {
            $arg->{$k} = $doc{$k};
        }
    }

    return $arg;
}

sub get_exemplaire_from_koha_by_itemnumber {
    my ($self) = @_;

    my @koha_fields = ("bi.publicationyear", "i.biblionumber", "i.price", "bi.itemtype", "b.title", "i.barcode", "i.ccode", "i.itemcallnumber", "i.dateaccessioned", "i.itemnumber", "i.location", "i.homebranch", "i.holdingbranch", "i.notforloan", "i.damaged", "i.withdrawn", "i.withdrawn_on", "i.itemlost", "i.itemlost_on", "i.onloan", "i.datelastborrowed");
   $self->get_document_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'itemnumber' } );
    
    return $self;
}

sub get_document_data_from_koha_by_id {
    my ($self, $param) = @_;
    
    my $dbh = $self->{dbh};
	my ($req, $sth, $res, $data);
    
    my $select = join ", ", @{ $param->{koha_fields} };
    my $id = $param->{koha_id};
	$id = "koha_" . $id;
	
	# On regarde si on trouve l'exemplaire dans items :
	$req = "SELECT COUNT(*) FROM koha_prod.items WHERE $param->{koha_id} = ?";
	$sth = $dbh->prepare($req);
	$sth->execute($self->$id);
	$res = $sth->fetchrow_array;
	if ($res == 0) {
		# si non, on regarde si on trouve l'exemplaire dans deleteditems
		$req = "SELECT COUNT(*) FROM koha_prod.deleteditems WHERE $param->{koha_id} = ?";
		$sth = $dbh->prepare($req);
		$sth->execute($self->$id);
		$res = $sth->fetchrow_array;
		if ($res == 1) {
			# si oui, on regarde si on trouve la notice dans biblio
			$self->{statdb_item_deleted} = 1;
			$req = "SELECT COUNT(*) FROM koha_prod.deleteditems i JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber WHERE i.$param->{koha_id} = ?";
			$sth = $dbh->prepare($req);
			$sth->execute($self->$id);
			$res = $sth->fetchrow_array;
			if ($res == 1) {
				$req = <<SQL;
SELECT $select
FROM koha_prod.deleteditems i
LEFT JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
LEFT JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
WHERE i.$param->{koha_id} = ?
SQL
				$sth = $dbh->prepare($req);
				$sth->execute($self->$id);
				$data = $sth->fetchrow_hashref;
			} else {
				# si on ne trouve pas la notice dans biblio, on regarde dans deletedbiblio
				$req = <<SQL;
SELECT $select
FROM koha_prod.deleteditems i
LEFT JOIN koha_prod.deletedbiblioitems bi ON bi.biblionumber = i.biblionumber
LEFT JOIN koha_prod.deletedbiblio b ON b.biblionumber = i.biblionumber
WHERE i.$param->{koha_id} = ?
SQL
				$sth = $dbh->prepare($req);
				$sth->execute($self->$id);
				$data = $sth->fetchrow_hashref;
			}
		}
	} else {
		$self->{statdb_item_deleted} = 0;
		$req = <<SQL;
SELECT $select
FROM koha_prod.items i
LEFT JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
LEFT JOIN koha_prod.biblio b ON b.biblionumber = i.biblionumber
WHERE i.$param->{koha_id} = ?
SQL
		$sth = $dbh->prepare($req);
		$sth->execute($self->$id);
		$data = $sth->fetchrow_hashref;
	}
    
	foreach my $k (keys(%$data)) {
		my $key = "koha_" . $k;
		$self->{$key} = $data->{$k};
	}    
    
    return $self;
}

1;

__END__