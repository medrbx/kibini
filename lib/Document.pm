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

sub get_statdb_document_generic_data {
    my ($self) = @_;
    
    $self->get_statdb_biblio_annee_publication;
    $self->get_statdb_biblio_id;
    $self->get_statdb_biblio_prix;
    $self->get_statdb_biblio_support_code;
    $self->get_statdb_biblio_titre;
    $self->get_statdb_item_annee_mise_pilon;
    $self->get_statdb_item_code_barre;
    $self->get_statdb_item_collection_ccode;
    $self->get_statdb_item_cote;
    $self->get_statdb_item_date_creation;
    $self->get_statdb_item_id;
    $self->get_statdb_item_localisation_code;
    $self->get_statdb_item_site_detenteur_code;
    $self->get_statdb_item_site_rattachement_code;
    $self->get_statdb_statut_code;
    $self->get_statdb_statut_abime_code;
    $self->get_statdb_statut_desherbe_code;
    $self->get_statdb_statut_desherbe_date;
    $self->get_statdb_statut_perdu_code;
    $self->get_statdb_statut_perdu_date;
    $self->get_statdb_usage_emprunt_code;
    $self->get_statdb_usage_date_dernier_pret;

    return $self;
}

sub get_statdb_biblio_annee_publication {
    my ($self) = @_;
    
    unless ($self->{statdb_biblio_annee_publication}) {
        if ($self->{koha_publicationyear}) {
            $self->{statdb_biblio_annee_publication} = $self->{koha_publicationyear};
        } elsif ($self->{es_biblio_annee_publication}) {
            $self->{statdb_biblio_annee_publication} = $self->{es_biblio_annee_publication};
        }
    }
    
    return $self;
}

sub get_statdb_biblio_id {
    my ($self) = @_;
    
    unless ($self->{statdb_biblio_id}) {
        if ($self->{koha_biblionumber}) {
            $self->{statdb_biblio_id} = $self->{koha_biblionumber};
        } elsif ($self->{es_biblio_id}) {
            $self->{statdb_biblio_id} = $self->{es_biblio_id};
        }
    }
    
    return $self;
}

sub get_statdb_biblio_prix {
    my ($self) = @_;
    
    unless ($self->{statdb_biblio_prix}) {
        if ($self->{koha_price}) {
            $self->{statdb_biblio_prix} = $self->{koha_price};
        } elsif ($self->{es_biblio_prix}) {
            $self->{statdb_biblio_prix} = $self->{es_biblio_prix};
        }
    }
    
    return $self;
}

sub get_statdb_biblio_support_code {
    my ($self) = @_;
    
    unless ($self->{statdb_biblio_support_code}) {
        if ($self->{koha_itemtype}) {
            $self->{statdb_biblio_support_code} = $self->{koha_itemtype};
        }
    }
    
    return $self;
}

sub get_statdb_biblio_titre {
    my ($self) = @_;
    
    unless ($self->{statdb_biblio_titre}) {
        if ($self->{koha_title}) {
            $self->{statdb_biblio_titre} = $self->{koha_title};
        } elsif ($self->{es_biblio_titre}) {
            $self->{statdb_biblio_titre} = $self->{es_biblio_titre};
        }
    }
    
    return $self;
}

#to do
sub get_statdb_item_annee_mise_pilon {
    my ($self) = @_;
    
    return $self;
}

sub get_statdb_item_code_barre {
    my ($self) = @_;
    
    unless ($self->{statdb_item_code_barre}) {
        if ($self->{koha_barcode}) {
            $self->{statdb_item_code_barre} = $self->{koha_barcode};
        } elsif ($self->{es_item_code_barre}) {
            $self->{statdb_item_code_barre} = $self->{es_item_code_barre};
        }
    }
    
    return $self;
}

sub get_statdb_item_collection_ccode {
    my ($self) = @_;
    
    unless ($self->{statdb_item_collection_ccode}) {
        if ($self->{koha_ccode}) {
            if (koha_itemtype) {
                $self->_get_perio_ccode;
            }            
            $self->{statdb_item_collection_ccode} = $self->{koha_ccode};
        } elsif ($self->{es_item_collection_ccode}) {
            $self->{statdb_item_collection_ccode} = $self->{es_item_collection_ccode};
        }
    }
    
    return $self;
}

sub get_statdb_item_cote {
    my ($self) = @_;
    
    unless ($self->{statdb_item_cote}) {
        if ($self->{koha_itemcallnumber}) {
            $self->{statdb_item_cote} = $self->{koha_itemcallnumber};
        } elsif ($self->{es_item_cote}) {
            $self->{statdb_item_cote} = $self->{es_item_cote};
        }
    }
    
    return $self;
}

sub get_statdb_item_date_creation {
    my ($self) = @_;
    
    unless ($self->{statdb_item_date_creation}) {
        if ($self->{koha_dateaccessioned}) {
            $self->{statdb_item_date_creation} = $self->{koha_dateaccessioned};
        } elsif ($self->{es_item_date_creation}) {
            $self->{statdb_item_date_creation} = $self->{es_item_date_creation};
        }
    }
    
    return $self;
}

sub get_statdb_item_id {
    my ($self) = @_;
    
    unless ($self->{statdb_item_id}) {
        if ($self->{koha_itemnumber}) {
            $self->{statdb_item_id} = $self->{koha_itemnumber};
        } elsif ($self->{es_item_id}) {
            $self->{statdb_item_id} = $self->{es_item_id};
        }
    }
    
    return $self;
}

sub get_statdb_item_localisation_code {
    my ($self) = @_;
    
    unless ($self->{statdb_item_localisation_code}) {
        if ($self->{koha_location}) {
            $self->{statdb_item_localisation_code} = $self->{koha_location};
        }
    }
    
    return $self;
}

sub get_statdb_item_site_detenteur_code {
    my ($self) = @_;
    
    unless ($self->{statdb_item_site_detenteur_code}) {
        if ($self->{koha_homebranch}) {
            $self->{statdb_item_site_detenteur_code} = $self->{koha_homebranch};
        }
    }
    
    return $self;
}

sub get_statdb_item_site_rattachement_code {
    my ($self) = @_;
    
    unless ($self->{statdb_item_site_rattachement_code}) {
        if ($self->{koha_holdingbranch}) {
            $self->{statdb_item_site_rattachement_code} = $self->{koha_holdingbranch};
        }
    }
    
    return $self;
}

sub get_statdb_statut_code {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_code}) {
        if ($self->{koha_notforloan}) {
            $self->{statdb_statut_code} = $self->{koha_notforloan};
        }
    }
    
    return $self;
}

sub get_statdb_statut_abime_code {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_abime_code}) {
        if ($self->{koha_damaged}) {
            $self->{statdb_statut_abime_code} = $self->{koha_damaged};
        }
    }
    
    return $self;
}

sub get_statdb_statut_desherbe_code {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_desherbe_code}) {
        if ($self->{koha_withdrawn}) {
            $self->{statdb_statut_desherbe_code} = $self->{koha_withdrawn};
        }
    }
    
    return $self;
}

sub get_statdb_statut_desherbe_date {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_desherbe_date}) {
        if ($self->{koha_withdrawn_on}) {
            $self->{statdb_statut_desherbe_date} = $self->{koha_withdrawn_on};
        } elsif ($self->{es_statut_desherbe_date}) {
            $self->{statdb_statut_desherbe_date} = $self->{es_statut_desherbe_date};
        }
    }
    
    return $self;
}

sub get_statdb_statut_perdu_code {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_perdu_code}) {
        if ($self->{koha_itemlost}) {
            $self->{statdb_statut_perdu_code} = $self->{koha_itemlost};
        }
    }
    
    return $self;
}

sub get_statdb_statut_perdu_date {
    my ($self) = @_;
    
    unless ($self->{statdb_statut_perdu_date}) {
        if ($self->{koha_itemlost_on}) {
            $self->{statdb_statut_perdu_date} = $self->{koha_itemlost_on};
        } elsif ($self->{es_statut_perdu_date}) {
            $self->{statdb_statut_perdu_date} = $self->{es_statut_perdu_date};
        }
    }
    
    return $self;
}

sub get_statdb_usage_emprunt_code {
    my ($self) = @_;
    
    unless ($self->{statdb_usage_emprunt_code}) {
        if ($self->{koha_onloan}) {
            if ($self->{koha_onloan} =~ m/^\d{4}-\d{2}-\d{2}/ ) {
                $self->{statdb_usage_emprunt_code} = 1;
            }
        } else {
            $self->{statdb_usage_emprunt_code} = 0;
        }
    }
    
    return $self;
}

sub get_statdb_usage_date_dernier_pret {
    my ($self) = @_;
    
    unless ($self->{statdb_usage_date_dernier_pret}) {
        if ($self->{koha_datelastborrowed}) {
            $self->{statdb_usage_date_dernier_pret} = $self->{koha_datelastborrowed};
        } elsif ($self->{es_usage_date_dernier_pret}) {
            $self->{statdb_usage_date_dernier_pret} = $self->{es_usage_date_dernier_pret};
        }
    }
    
    return $self;
}

sub _get_perio_ccode {
    my ($self) = @_;
    
    if ($self->{koha_itemtype} eq 'PE') {
        my $req = "SELECT COUNT(*) FROM koha_prod.deleteditems WHERE $param->{koha_id} = ?";
        my $sth = $dbh->prepare($req);
        $sth->execute($self->$id);
        my $res = $sth->fetchrow_array;
        $sth->finish;
        if ($res) {
            $self->{statdb_item_collection_ccode} = $res;
        }
    }
    
#UPDATE koha_prod.items s JOIN statdb.lib_periodiques p ON s.biblionumber = p.biblionumber SET s.ccode = p.ccode
    return $self;
}

1;

__END__
