package Biblio;

use Moo;
use utf8;

use Kibini::DB;
use Catmandu;

has dbh => ( is => 'ro' );

has koha_biblionumber => ( is => 'ro' );
has koha_biblio_frameworkcode => ( is => 'ro' );
has koha_biblio_timestamp => ( is => 'ro' );
has koha_biblio_datecreated => ( is => 'ro' );
has koha_biblioitems_itemtype => ( is => 'ro' );
has koha_biblioitems_timestamp => ( is => 'ro' );
has koha_biblioitems_totalissues => ( is => 'ro' );
has koha_biblio_metadata_metadata => ( is => 'ro' );
has koha_biblio_metadata_timestamp => ( is => 'ro' );

has statdb_biblionumber => ( is => 'ro' );
has statdb_biblio_metadata => ( is => 'ro' );
has statdb_date_creation => ( is => 'ro' );
has statdb_date_derniere_modification => ( is => 'ro' );
has statdb_titre => ( is => 'ro' );
has statdb_support => ( is => 'ro' );
has statdb_biblio_deleted => ( is => 'ro' );

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
    
    if ( $args[0]->{biblio} ) {
        my %doc = %{$args[0]->{biblio}};
        foreach my $k (keys(%doc)) {
                $arg->{$k} = $doc{$k};
        }
    }

    return $arg;
}

sub get_statdb_biblio_specific_data {
    my ($self) = @_;

    $self->get_statdb_biblionumber;
    $self->get_statdb_biblio_metadata;
    $self->get_statdb_date_creation;
    $self->get_statdb_date_derniere_modification;
    $self->get_statdb_support;
    $self->get_statdb_biblio_deleted;

    my $biblio_data = {
        statdb_biblionumber => $self->statdb_biblionumber,
        statdb_biblio_metadata => $self->statdb_biblio_metadata,
        statdb_date_creation => $self->statdb_date_creation,
        statdb_date_derniere_modification => $self->statdb_date_derniere_modification,
        statdb_support => $self->statdb_support,
        statdb_biblio_deleted => $self->statdb_biblio_deleted
    };
    
    return $biblio_data;
}

sub get_statdb_biblionumber {
    my ($self) = @_;
    if ($self->{koha_biblionumber}) {
        $self->{statdb_biblionumber} = $self->{koha_biblionumber};
    }

    return $self;
}

sub get_statdb_date_creation {
    my ($self) = @_;
    if ($self->{koha_biblio_datecreated}) {
        $self->{statdb_date_creation} = $self->{koha_biblio_datecreated};
    }
    return $self;
}

sub get_statdb_date_derniere_modification {
    my ($self) = @_;
    if ($self->{koha_biblio_metadata_timestamp}) {
        $self->{statdb_date_derniere_modification} = $self->{koha_biblio_metadata_timestamp};
    }
    return $self;
}

sub get_statdb_titre {
    my ($self) = @_;

    return $self;
}

sub get_statdb_support {
    my ($self) = @_;
    if ($self->{koha_biblioitems_itemtype}) {
        $self->{statdb_support} = $self->{koha_biblioitems_itemtype};
    }
    return $self;
}

sub get_statdb_biblio_deleted {
    my ($self) = @_;
    $self->{statdb_biblio_deleted} = 0;
    return $self;
}

sub get_statdb_biblio_metadata {
    my ($self) = @_ ;
    
    my $marcxml = $self->{koha_biblio_metadata_metadata};
    chomp($marcxml);

    my $importer = Catmandu->importer( 'MARC', type => 'XML', file => \$marcxml );
    my $outdata ;
    my $exporter = Catmandu->exporter( 'JSON', file => \$outdata, fix => '/home/fpichenot/Documents/projets/kibini/etc/catmandu_databib.fix', array => 0);
    $importer->each(sub {
        my $item = shift;
        $exporter->add($item);
    });
    
    $self->{statdb_biblio_metadata} = $outdata;
    return $self;
}

1;
