#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use Kibini::DB;

my $dbh = Kibini::DB->new()->dbh();

# Biblio
my $exporter = Catmandu->exporter('MARC', type => 'XML', file => "DATA_marc_koha2018_biblio_AAPCIFI.marcxml");

my $req = <<SQL;
SELECT b.metadata
FROM koha2018.biblio_metadata b
JOIN koha2018.items i ON b.biblionumber = i.biblionumber
WHERE i.ccode = "AAPCIFI"
SQL

my $sth = $dbh->prepare($req);
$sth->execute;
while (my $metadata = $sth->fetchrow_array()) {
    $metadata =~ s/<\?xml version=\"1\.0\" encoding=\"UTF-8\"\?>//;
    $metadata =~ s/^\n//;
    my $importer = Catmandu->importer('MARC', type => 'XML', file => \$metadata);
	my $biblio = $importer->first;
	$exporter->add($biblio);
	print "$biblio->{_id}\n";
}
__END__
# Auth
$exporter = Catmandu->exporter('MARC', type => 'ISO', file => "DATA_marc_koha2018_auth.marcxml");

$req = "SELECT marcxml FROM koha2018.auth_header";
$sth = $dbh->prepare($req);
$sth->execute;
while (my $metadata = $sth->fetchrow_array()) {
    $metadata =~ s/<\?xml version=\"1\.0\" encoding=\"UTF-8\"\?>//;
    $metadata =~ s/^\n//;
    my $importer = Catmandu->importer('MARC', type => 'XML', file => \$metadata);
	my $auth = $importer->first;
	$exporter->add($auth);
	print "$auth->{_id}\n";
}