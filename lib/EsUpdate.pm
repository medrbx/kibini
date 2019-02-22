package EsUpdate;

use Moo;
use utf8;

use Kibini::Log;
use Webkiosk;

has dbh => ( is => 'ro' );
has crypter => ( is => 'ro' );
has logger => ( is => 'ro' );
has date => ( is => 'ro' );

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
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    if ( $args[0]->{logger} ) {
        $arg->{logger} = $args[0]->{logger};
    } else {
        $arg->{logger} = Kibini::Log->new;
    }

    if ( $args[0]->{date} ) {
        $arg->{date} = $args[0]->{date};
    } else {
        my $time = Kibini::Time->new;
        $arg->{date} = $time->get_date_and_time('today');
    }

    return $arg;
}

sub update_es_sessions_webkiosk {
    my ($self) = @_;
    
    my $log = $self->logger;
    $log->add_log("update_es_sessions_webkiosk : beginning");
    
    my $dbh = $self->dbh;
    my $crypter = $self->crypter;
    my $date = $self->date;
    $date = "'" . $date . "'";
    
    my $req = <<SQL;
SELECT 
    session_id AS statdb_session_id,
    session_date_heure_debut AS statdb_date_heure_a,
    session_date_heure_fin AS statdb_date_heure_b, 
    session_groupe AS statdb_session_groupe,
    session_poste AS statdb_session_poste,
    adherent_adherentid AS statdb_adherentid,
    adherent_age_code AS statdb_age_code,
    adherent_attributes AS statdb_attributes,
    adherent_geo_rbx_iris AS statdb_geo_rbx_iris,
    adherent_geo_ville AS statdb_geo_ville,
    adherent_inscription_carte_code AS statdb_inscription_carte_code,
    adherent_inscription_nb_annees_adhesion AS statdb_inscription_nb_annees_adhesion,
    adherent_inscription_site_code AS statdb_inscription_site_code,
    adherent_sexe_code AS statdb_sexe_code
FROM statdb.stat_sessions_webkiosk
WHERE DATE(updated_on) >= $date;
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute;
    my $i = 0;
    while (my $row = $sth->fetchrow_hashref) {
        my $wk = Webkiosk->new( { dbh => $dbh, crypter => $crypter, wk => $row } );
        $wk->get_wkuser_data;
        my $index = $wk->add_data_to_es_webkiosk;
        $i++;
		$log->add_log("update_es_sessions_webkiosk : $i rows updated") if $i % 10000 == 0;
    }
    $log->add_log("update_es_sessions_webkiosk : $i rows updated");
    $log->add_log("update_es_sessions_webkiosk : ending");
}

1;
