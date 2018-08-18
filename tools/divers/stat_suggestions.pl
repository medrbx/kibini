#! /usr/bin/perl

use strict;
use warnings;
use Text::CSV ;
use utf8 ;
use Data::Dumper;
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib";
use kibini::db;

my $dbh = GetDbh();
my $out = "stat_suggestions.csv" ;
my $csv_out = Text::CSV->new ({ binary => 1, eol => "\r\n" });
open( my $fd_out, ">:encoding(UTF-8)", $out ) ;
my @column_out = ( 'date suggestion', 'site', 'titre', 'auteur', 'éditeur', 'note', 'statut', 'raison_refus', 'géré par', 'id_adherent', 'age_adhérent', 'sexe_adhérent', 'ville_adhérent', 'fidélité_adhérent' ) ;
$csv_out->print ($fd_out, \@column_out) ;

my @req = ("SELECT * FROM koha_prod.suggestions", "SELECT * FROM statdb.stat_suggestions" );
foreach my $req (@req) {
my $sth = $dbh->prepare($req) ;
$sth->execute() ;
while (my $suggestion = $sth->fetchrow_hashref() ) {
	$suggestion->{librarian} = GetLibrarian($dbh, $suggestion->{managedby});
	$suggestion->{borrower} = GetBorrower($dbh, $suggestion->{suggestedby}, $suggestion->{suggesteddate});
	my @suggestion_out = ( $suggestion->{suggesteddate}, $suggestion->{branchcode}, $suggestion->{title}, $suggestion->{author}, $suggestion->{publishercode}, $suggestion->{note}, $suggestion->{STATUS}, $suggestion->{reason}, $suggestion->{librarian}, $suggestion->{suggestedby}, $suggestion->{borrower}->{age}, $suggestion->{borrower}->{sexe}, $suggestion->{borrower}->{ville}, $suggestion->{borrower}->{fidelite} );
	$csv_out->print ($fd_out, \@suggestion_out) ;
	print Dumper($suggestion);
}
$sth->finish();
}
close $fd_out ;
$dbh->disconnect;

sub GetBorrower {
	my ($dbh, $borrowernumber, $suggesteddate) = @_;
	my $req = <<SQL;
SELECT
	IF(title IS NOT NULL AND title = 'Madame','F','H') AS 'sexe',
	YEAR(?) - YEAR(dateofbirth) AS age,
	city AS ville,
	YEAR(?) - YEAR(dateenrolled) as fidelite
FROM koha_prod.borrowers
WHERE borrowernumber = ?
SQL
	my $sth = $dbh->prepare($req);
	$sth->execute($suggesteddate,$suggesteddate,$borrowernumber);
	my $borrower = $sth->fetchrow_hashref();
	return $borrower;	
}

sub GetLibrarian {
	my ($dbh, $borrowernumber) = @_;
	my $req = "SELECT CONCAT(firstname, \" \", surname) FROM koha_prod.borrowers WHERE borrowernumber = ?";
	my $sth = $dbh->prepare($req);
	$sth->execute($borrowernumber);
	my $librarian = $sth->fetchrow_array();
	return $librarian;
}