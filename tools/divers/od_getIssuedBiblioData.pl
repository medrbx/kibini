#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Text::CSV;
use Data::Dumper;

use lib "/home/kibini/kibini_prod/lib";
use kibini::db;

my $file_in = 'biblionumber_uniq.txt';
my $file_out = 'IssuedBiblioData.csv';
open(my $fh, '<', $file_in);

my $csv = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open(my $fd,">:encoding(utf8)",$file_out);

# On crée la première ligne avec les noms de colonnes
my @column_names = qw( biblionumber identifiant document_titre document_editeur document_createur document_contributeur );
$csv->print ($fd, \@column_names) ;

my $dbh = GetDbh();
my $i = 0;
while (my $biblionumber = <$fh>) {
  chomp $biblionumber;
  my $marcxml = _GetMarcxml($dbh, $biblionumber);
  my $csv_record = _ModMarcxmlToCsv($marcxml);
  $csv->print ($fd, $csv_record);
  $i++;
  print "$i\n";
}

close $fd;
close $fh;

sub _GetMarcxml{
    my ($dbh, $biblionumber) = @_;
    my $req = "SELECT marcxml FROM koha_prod.biblioitems WHERE biblionumber = ?";
    my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber);
    my @row = $sth->fetchrow_array();
	if (scalar @row == 0) {
		$req = "SELECT marcxml FROM koha_prod.deletedbiblioitems WHERE biblionumber = ?";
		$sth = $dbh->prepare($req);
		$sth->execute($biblionumber);
		@row = $sth->fetchrow_array();
	};
    $sth->finish();
    return $row[0];
}

sub _ModMarcxmlToCsv {
	my ($marcxml) = @_;
	
    my @fix = (
		"marc_map(200ae,document_titre.\$append, join:', ')",
		"marc_map(210c,document_editeur.\$append, join:', ')",
		"marc_map(700abf,document_createur.\$append, join:', ')",
		"marc_map(701abf,document_createur.\$append, join:', ')",
		"marc_map(710af,document_createur.\$append, join:', ')",
		"marc_map(711af,document_createur.\$append, join:', ')",
		"marc_map(702abf,document_contributeur.\$append, join:', ')",
		"marc_map(712af,document_contributeur.\$append, join:', ')",
		"marc_map(033a,ark_bnf)",
		"marc_map(010a,isbn)",
		"marc_map(011a,issn)",
		"marc_map(073a,ean)",
        "retain(_id,document_titre, document_editeur, document_createur, document_contributeur, ark_bnf, isbn, issn, ean)"
	);
	
	my $importer = Catmandu->importer( 'MARC', type => 'XML', fix => \@fix, file => \$marcxml );
	
	my $record;
	$importer->each(sub {
        $record = shift;
		$record->{document_titre} = join '|', @{$record->{document_titre}} if $record->{document_titre};
		$record->{document_editeur} = join '|', @{$record->{document_editeur}} if $record->{document_editeur};
		$record->{document_createur} = join '|', @{$record->{document_createur}} if $record->{document_createur};
		$record->{document_contributeur} = join '|', @{$record->{document_contributeur}} if $record->{document_contributeur};
		if ( $record->{ark_bnf} ) {
			$record->{identifiant} = "ark:'" . $record->{ark_bnf} . "'";
		} elsif ( $record->{ean} ) {
			$record->{identifiant} = "ean:'" . $record->{ean} . "'";
		} elsif ( $record->{isbn} ) {
			$record->{identifiant} = "isbn''" . $record->{isbn} . "'";
		} elsif ( $record->{issn} ) {
			$record->{identifiant} = "issn:'" . $record->{issn} . "'";
		}
	});
	
	my @csv_record = ( $record->{_id}, $record->{identifiant}, $record->{document_titre}, $record->{document_editeur}, $record->{document_createur}, , $record->{document_contributeur} );
	return \@csv_record;
}

