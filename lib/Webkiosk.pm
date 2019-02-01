package Webkiosk;

use Moo;

extends 'Adherent';

has wk_heure_deb => ( is => 'ro' );
has wk_heure_fin => ( is => 'ro' );
has wk_espace => ( is => 'ro' );
has wk_poste => ( is => 'ro' );

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
    
    if ( $args[0]->{wk} ) {
        my %wk = %{$args[0]->{wk}};
        foreach my $k (keys(%wk)) {
            $arg->{$k} = $wk{$k};
        }
    }
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    return $arg;
}

sub get_wkuser_from_koha {
    my ($self) = @_;

    my @koha_fields = ("dateofbirth", "city", "altcontactcountry", "categorycode", "branchcode", "borrowernumber", "dateenrolled");
    $self->get_data_from_koha_by_id( { koha_fields => \@koha_fields, koha_id => 'userid' } );
    
    return $self;
}

sub get_wkuser_data {
    my ($self) = @_;
    
#	$self->get_statdb_adherentid;	# Pour mise en place cryptage	
	$self->get_statdb_userid;
	$self->get_statdb_borrowernumber;
	$self->get_statdb_age( {format_date_event => 'datetime', date_event_field => 'wk_heure_deb'} );
	$self->get_statdb_sexe;
	$self->get_statdb_ville;
	$self->get_statdb_rbx_iris;
	$self->get_statdb_branchcode;
	$self->get_statdb_categorycode;
	$self->get_statdb_nb_annees_adhesion( {format_date_event => 'datetime', date_event_field => 'wk_heure_deb'} );
	
	$self->get_es_age_labels;

    return $self;
}

sub add_data_to_statdb_webkiosk {
    my ($self) = @_;
    
    my $dbh = $self->{dbh};
    my $req = <<SQL;
INSERT INTO statdb.stat_webkiosk (
	heure_deb,
	heure_fin,
	espace,
	poste,
	id,
	borrowernumber,
	age,
	sexe,
	ville,
	iris,
	branchcode,
	categorycode,
	fidelite)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute(
		$self->{wk_heure_deb},
		$self->{wk_heure_fin},
		$self->{wk_espace},
		$self->{wk_poste},
		$self->{statdb_userid},
		$self->{statdb_borrowernumber},
		$self->{statdb_age},
		$self->{statdb_sexe},
		$self->{statdb_ville},
		$self->{statdb_rbx_iris},
		$self->{statdb_branchcode},
		$self->{statdb_categorycode},
		$self->{statdb_nb_annees_adhesion}
	);
    $sth->finish();

    return $self;
}

1;