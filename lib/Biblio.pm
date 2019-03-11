package Biblio;

use Moo;
use utf8;

use Kibini::DB;

has dbh => ( is => 'ro' );

has koha_biblionumber => ( is => 'ro' );
has koha_biblio_frameworkcode => ( is => 'ro' );
has koha_biblio_author => ( is => 'ro' );
has koha_biblio_title => ( is => 'ro' );
has koha_biblio_unititle => ( is => 'ro' );
has koha_biblio_notes => ( is => 'ro' );
has koha_biblio_serial => ( is => 'ro' );
has koha_biblio_seriestitle => ( is => 'ro' );
has koha_biblio_copyrightdate => ( is => 'ro' );
has koha_biblio_timestamp => ( is => 'ro' );
has koha_biblio_datecreated => ( is => 'ro' );
has koha_biblio_abstract => ( is => 'ro' );
has koha_biblioitems_biblioitemnumber => ( is => 'ro' );
has koha_biblioitems_biblionumber => ( is => 'ro' );
has koha_biblioitems_volume => ( is => 'ro' );
has koha_biblioitems_number => ( is => 'ro' );
has koha_biblioitems_itemtype => ( is => 'ro' );
has koha_biblioitems_isbn => ( is => 'ro' );
has koha_biblioitems_issn => ( is => 'ro' );
has koha_biblioitems_ean => ( is => 'ro' );
has koha_biblioitems_publicationyear => ( is => 'ro' );
has koha_biblioitems_publishercode => ( is => 'ro' );
has koha_biblioitems_volumedate => ( is => 'ro' );
has koha_biblioitems_volumedesc => ( is => 'ro' );
has koha_biblioitems_collectiontitle => ( is => 'ro' );
has koha_biblioitems_collectionissn => ( is => 'ro' );
has koha_biblioitems_collectionvolume => ( is => 'ro' );
has koha_biblioitems_editionstatement => ( is => 'ro' );
has koha_biblioitems_editionresponsibility => ( is => 'ro' );
has koha_biblioitems_timestamp => ( is => 'ro' );
has koha_biblioitems_illus => ( is => 'ro' );
has koha_biblioitems_pages => ( is => 'ro' );
has koha_biblioitems_notes => ( is => 'ro' );
has koha_biblioitems_size => ( is => 'ro' );
has koha_biblioitems_place => ( is => 'ro' );
has koha_biblioitems_lccn => ( is => 'ro' );
has koha_biblioitems_url => ( is => 'ro' );
has koha_biblioitems_cn_source => ( is => 'ro' );
has koha_biblioitems_cn_class => ( is => 'ro' );
has koha_biblioitems_cn_item => ( is => 'ro' );
has koha_biblioitems_cn_suffix => ( is => 'ro' );
has koha_biblioitems_cn_sort => ( is => 'ro' );
has koha_biblioitems_agerestriction => ( is => 'ro' );
has koha_biblioitems_totalissues => ( is => 'ro' );
has koha_biblio_metadata_id => ( is => 'ro' );
has koha_biblio_metadata_biblionumber => ( is => 'ro' );
has koha_biblio_metadata_format => ( is => 'ro' );
has koha_biblio_metadata_marcflavour => ( is => 'ro' );
has koha_biblio_metadata_metadata => ( is => 'ro' );
has koha_biblio_metadata_timestamp => ( is => 'ro' );


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

1;
