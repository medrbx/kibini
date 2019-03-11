#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Biblio;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;
my $req = <<SQL;
SELECT
    b.biblionumber AS koha_biblio_biblionumber,
    b.frameworkcode AS koha_biblio_frameworkcode,
    b.author AS koha_biblio_author,
    b.title AS koha_biblio_title,
    b.unititle AS koha_biblio_unititle,
    b.notes AS koha_biblio_notes,
    b.serial AS koha_biblio_serial,
    b.seriestitle AS koha_biblio_seriestitle,
    b.copyrightdate AS koha_biblio_copyrightdate,
    b.timestamp AS koha_biblio_timestamp,
    b.datecreated AS koha_biblio_datecreated,
    b.abstract AS koha_biblio_abstract,
    bi.biblioitemnumber AS koha_biblioitems_biblioitemnumber,
    bi.biblionumber AS koha_biblioitems_biblionumber,
    bi.volume AS koha_biblioitems_volume,
    bi.number AS koha_biblioitems_number,
    bi.itemtype AS koha_biblioitems_itemtype,
    bi.isbn AS koha_biblioitems_isbn,
    bi.issn AS koha_biblioitems_issn,
    bi.ean AS koha_biblioitems_ean,
    bi.publicationyear AS koha_biblioitems_publicationyear,
    bi.publishercode AS koha_biblioitems_publishercode,
    bi.volumedate AS koha_biblioitems_volumedate,
    bi.volumedesc AS koha_biblioitems_volumedesc,
    bi.collectiontitle AS koha_biblioitems_collectiontitle,
    bi.collectionissn AS koha_biblioitems_collectionissn,
    bi.collectionvolume AS koha_biblioitems_collectionvolume,
    bi.editionstatement AS koha_biblioitems_editionstatement,
    bi.editionresponsibility AS koha_biblioitems_editionresponsibility,
    bi.timestamp AS koha_biblioitems_timestamp,
    bi.illus AS koha_biblioitems_illus,
    bi.pages AS koha_biblioitems_pages,
    bi.notes AS koha_biblioitems_notes,
    bi.size AS koha_biblioitems_size,
    bi.place AS koha_biblioitems_place,
    bi.lccn AS koha_biblioitems_lccn,
    bi.url AS koha_biblioitems_url,
    bi.cn_source AS koha_biblioitems_cn_source,
    bi.cn_class AS koha_biblioitems_cn_class,
    bi.cn_item AS koha_biblioitems_cn_item,
    bi.cn_suffix AS koha_biblioitems_cn_suffix,
    bi.cn_sort AS koha_biblioitems_cn_sort,
    bi.agerestriction AS koha_biblioitems_agerestriction,
    bi.totalissues AS koha_biblioitems_totalissues,
    m.id AS koha_biblio_metadata_id,
    m.biblionumber AS koha_biblio_metadata_biblionumber,
    m.format AS koha_biblio_metadata_format,
    m.marcflavour AS koha_biblio_metadata_marcflavour,
    m.metadata AS koha_biblio_metadata_metadata,
    m.timestamp AS koha_biblio_metadata_timestamp
FROM koha_prod.biblio b
JOIN koha_prod.biblioitems bi ON bi.biblionumber = b.biblionumber
JOIN koha_prod.biblio_metadata m ON m.biblionumber = b.biblionumber
LIMIT 10
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while ( my $data = $sth->fetchrow_hashref) {
    my $biblio = Biblio->new( { dbh => $dbh, biblio => $data } );    
    print Dumper($biblio);    
}


__END__

#my $importer = Catmandu->importer('CSV', file => $file_in, fix => 'WK_new_db.fix');

#$importer->each(sub {
#    my $data = shift;
    print Dumper($data);
});
