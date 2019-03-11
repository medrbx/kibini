#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;

my $dbh = Kibini::DB->new;
$dbh = $dbh->dbh;
my $req = <<SQL;
SELECT *
FROM koha_prod.biblio b
JOIN koha_prod.biblioitems bi ON bi.biblionumber = b.biblionumber
JOIN koha_prod.biblio_metadata m ON m.biblionumber = b.biblionumber
LIMIT 10
SQL

my $sth = $dbh->prepare($req);
$sth->execute();
while ( my $data = $sth->fetchrow_hashref) {
    print Dumper($data);
}


__END__

#my $importer = Catmandu->importer('CSV', file => $file_in, fix => 'WK_new_db.fix');

#$importer->each(sub {
#    my $data = shift;
    print Dumper($data);
});
