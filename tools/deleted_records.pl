#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Catmandu::Exporter::MARC;
use Catmandu::Fix::marc_add as => 'marc_add';
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;

my $exporter = Catmandu->exporter('MARC', file => "deleted_records.mrc", type => "ISO" );

my $dbh = GetDbh();
my $req = "SELECT marcxml FROM koha_prod.biblioitems WHERE biblionumber = ?";
my $sth = $dbh->prepare($req);

while ( my $biblionumber = <> ) {
	chomp $biblionumber;
	$sth->execute($biblionumber);
	my $marcxml = $sth->fetchrow_array;
	my $importer = Catmandu->importer('MARC', file => \$marcxml, type => "XML" );
	$importer->each(sub {
		my $record = shift;
		$record->{item} = getItems($dbh, $biblionumber);
		$record = marc_add($record,'995','b',$record->{item}->{homebranch},'c',$record->{item}->{holdingbranch},'e',$record->{item}->{location},'h','ALTROZZ','o','-2','r','PRETLIV');
		$exporter->add($record);
		print Dumper($biblionumber);
    });
	
	#print Dumper($importer);
	
}

sub getItems {
	my ($dbh, $biblionumber) = @_;
	my $req = "SELECT notforloan, homebranch, holdingbranch, location FROM koha_prod.items WHERE biblionumber = ?";
	my $sth = $dbh->prepare($req);
	$sth->execute($biblionumber);
	my $item = $sth->fetchrow_hashref;
	$sth->finish;
	return $item;
}