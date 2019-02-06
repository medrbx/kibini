#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Catmandu::Exporter::MARC;
use Catmandu::Fix::marc_add as => 'marc_add';
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;

my $dbh = GetDbh();
my $req = "SELECT r.borrowernumber, r.itemnumber, r.priority, r.biblionumber, b.surname, b.firstname, b.cardnumber, bi.ean FROM koha_prod.reserves r JOIN koha_prod.borrowers b ON b.borrowernumber = r.borrowernumber JOIN koha_prod.biblioitems bi ON bi.biblionumber = r.biblionumber WHERE r.biblionumber = ?";
my $sth = $dbh->prepare($req);

while ( my $biblionumber = <> ) {
	chomp $biblionumber;
	$sth->execute($biblionumber);
	my $reserve = $sth->fetchrow_hashref;
	#print Dumper($reserve) if ($reserve);
	print "$reserve->{borrowernumber}\t$reserve->{priority}\t$reserve->{biblionumber}\t$reserve->{surname}\t$reserve->{firstname}\t$reserve->{cardnumber}\t$reserve->{ean}\n" if ($reserve);
}