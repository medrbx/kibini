#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;
use Kibini::ES;

my $dbh = Kibini::DB->new()->dbh;
my $kes = Kibini::ES->new();
my $e = $kes->e;
# Si besoin régénérer index
#$kes->get_mappings();
#$kes->regenerate_index('magasin');

my $file = "stage_mag_20190504.csv";
my $exporter = Catmandu->exporter('CSV', file => $file);

# On récupère les libellés de code dans une variable "description"
my $description = {};
#ccode
my $req = "SELECT ccode, lib FROM statdb.lib_collections2";
my $sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    $description->{ccode}->{$row->{ccode}} = $row->{lib};
}
# location
$req = "SELECT authorised_value, lib FROM koha_prod.authorised_values WHERE category = 'LOC'";
$sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    $description->{location}->{$row->{authorised_value}} = $row->{lib};
}
# itemtype
$req = "SELECT authorised_value, lib FROM koha_prod.authorised_values WHERE category = 'ccode'";
$sth = $dbh->prepare($req);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    $description->{itemtype}->{$row->{authorised_value}} = $row->{lib};
}

# On cherche les exemplaires

$req = <<SQL;
SELECT
    i.biblionumber,
    i.itemnumber,
    i.barcode,
    i.location,    
    i.itemcallnumber,
    i.ccode,
    bi.itemtype,
    bi.publicationyear,
    i.datelastborrowed,
    i.dateaccessioned,
    i.issues,
    bm.metadata AS 'metadata'
FROM koha_prod.items i
JOIN koha_prod.biblioitems bi ON bi.biblionumber = i.biblionumber
JOIN koha_prod.biblio_metadata bm ON bm.biblionumber = i.biblionumber
WHERE i.ccode = 'AZZMAZZ' OR i.location IN ('MED3E', 'MED3F', 'MED3G', 'MED3H')
ORDER BY biblionumber
SQL

$sth = $dbh->prepare($req);
$sth->execute();
while (my $item = $sth->fetchrow_hashref) {
    my $marc = $item->{metadata};
    
    my $fix = [
        'marc_map(200aegi, title, join:", ")',
        'marc_map(210c, publisher)',
        'marc_map(700abf, creator.$append, join:", ")',
        'marc_map(701abf, creator.$append, join:", ")',
        'marc_map(702abf, contributor.$append, join:", ")',
        'marc_map(710af, creator.$append, join:", ")',
        'marc_map(711af, creator.$append, join:", ")',
        'marc_map(712af, contributor.$append, join:", ")',
        'marc_map(60.a, subject.$append, join:", ")',
        'retain(title, publisher, creator, contributor, subject)'
    ];
    my $importer = Catmandu->importer('MARC', type => 'XML', fix => $fix, file => \$marc);
    $importer->each(sub {
        my $record = shift;
        $item->{title} = $record->{title};
        $item->{publisher} = $record->{publisher};
        $item->{creator} = $record->{creator};
        $item->{contributor} = $record->{contributor};
        $item->{subject} = $record->{subject};
    });
    delete $item->{metadata};
        
    $item->{collection} = $description->{ccode}->{$item->{ccode}};
    $item->{location} = $description->{location}->{$item->{location}};
    $item->{itemtype} = $description->{itemtype}->{$item->{itemtype}};
    
    my @years = qw(2015 2016 2017 2018 2019);
    foreach my $year (@years) {
        my $lib = 'nb_issues' . $year;
        $item->{$lib} = count_issues($dbh, $year, $item->{itemnumber});
    }
    
    my %index = (
        index   => 'magasin',
        type    => 'documents',
        id     => $item->{itemnumber},
        body    => $item
    );
    $e->index(\%index);
    
    $item->{creator} = join('|', @{$item->{creator}}) if $item->{creator};
    $item->{contributor} = join('|', @{$item->{contributor}}) if $item->{contributor};
    $item->{subject} = join('|', @{$item->{subject}}) if $item->{subject};
    $exporter->add($item);
    
    print Dumper($item);
}

sub count_issues {
    my ($dbh, $year, $itemnumber) = @_;
    
    my $start = $year - 1 . '-07-01';
    my $end = $year . '-06-30';
    
    my $req = "SELECT COUNT(*) FROM statdb.stat_issues WHERE itemnumber = ? AND issuedate >= ? AND issuedate <= ?";
    my $sth = $dbh->prepare($req);
    $sth->execute($itemnumber, $start, $end);

    return $sth->fetchrow_array;
}
