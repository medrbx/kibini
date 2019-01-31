#! /usr/bin/perl

use Modern::Perl;
use Catmandu;
use Statistics::Descriptive;
use List::MoreUtils qw(uniq);
use Data::Dumper;
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::elasticsearch;
use Kibini::DB;

my $dbh =  Kibini::DB->new();
$dbh = $dbh->dbh();

my @sites = (
    {
        nom => 'Grand-Plage',
        code => 'GPL',
        nom_fichier => 'grand-plage'
    },
    {
        nom => 'Médiathèque',
        code => 'MED',
        nom_fichier => 'mediatheque'
    },
    {
        nom => 'Zèbre',
        code => 'BUS',
        nom_fichier => 'zebre'
    },
    {
        nom => 'Collectivités',
        code => 'COL',
        nom_fichier => 'collectivites'
    }
);

foreach my $site (@sites) {
	my $file_in = "poldoc_profils_usagers_in_" . $site->{nom_fichier} . ".csv";
	my $importer = Catmandu->importer('CSV', file => $file_in);
	
	my $file_out = "/home/kibini/kibini_prod/data/collections/poldoc_profils_usagers_out_2017_" . $site->{nom_fichier} . "_totaux.csv";
	my $exporter = Catmandu->exporter('CSV', file => $file_out);
	
	my $whereLocation = GetWhereLocationBySite($site->{code}) ;

	$importer->each(sub {
		my $collection = shift;
		my $where = getWhereClause($collection, $whereLocation);
		my $borrowers = getBorrowersData($where);
		$collection->{nb_emprunteurs_distincts} = $borrowers->{emprunteurs_distincts};
		$collection->{age_median} = $borrowers->{age_median};
		$collection->{age_median_emprunteurs_distincts} = $borrowers->{age_median_emprunteurs_distincts};
		$collection->{fidelite_mediane} = $borrowers->{fidelite_mediane};
		$collection->{fidelite_mediane_emprunteurs_distincts} = $borrowers->{fidelite_mediane_emprunteurs_distincts};
		$collection->{nb_rbx} = $borrowers->{nb_rbx};
		$collection->{nb_villes} = $borrowers->{nb_villes};
		$collection->{nb_rbx_emprunteurs_distincts} = $borrowers->{nb_rbx_emprunteurs_distincts};
		$collection->{nb_villes_emprunteurs_distincts} = $borrowers->{nb_villes_emprunteurs_distincts};

		print Dumper($collection);
		$exporter->add($collection);
	});
}


sub getBorrowersData {
	my ($where) = @_;
	
	my $borrowers;
	my @borrowernumbers_distincts;
	my @ages;
	my @ages_emprunteurs_distincts;
	my @fidelites;
	my @fidelites_emprunteurs_distincts;
	my @villes;
	my @villes_emprunteurs_distincts;
	
	my $stat = Statistics::Descriptive::Full->new();
	
	my $req = <<SQL;
SELECT iss.borrowernumber, iss.age, iss.fidelite, iss.ville
FROM statdb.stat_issues iss
JOIN statdb.lib_collections2 c ON c.ccode = iss.ccode
$where
ORDER BY borrowernumber
SQL
	my $sth = $dbh->prepare($req);
	$sth->execute();
	while ( my $borrower = $sth->fetchrow_hashref) {
		push @ages, $borrower->{age} if ( $borrower->{age} =~ /^[0-9]+$/ );
		push @fidelites, $borrower->{fidelite} if ( $borrower->{fidelite} =~ /^[0-9]+$/ );
		push @villes, $borrower->{ville};
		unless (grep{$_ == $borrower->{borrowernumber}} @borrowernumbers_distincts) {
			push @borrowernumbers_distincts, $borrower->{borrowernumber};
			push @ages_emprunteurs_distincts, $borrower->{age} if ( $borrower->{age} =~ /^[0-9]+$/ );
			push @fidelites_emprunteurs_distincts, $borrower->{fidelite} if ( $borrower->{fidelite} =~ /^[0-9]+$/ );
			push @villes_emprunteurs_distincts, $borrower->{ville};
		}		
	}
    $sth->finish();
	
	# emprunteurs distincts
	$borrowers->{emprunteurs_distincts} = scalar @borrowernumbers_distincts;
	
	# âge
	$stat->add_data(@ages);
	$borrowers->{age_median} = $stat->median();
	$stat->clear();
	
	$stat->add_data(@ages_emprunteurs_distincts);
	$borrowers->{age_median_emprunteurs_distincts} = $stat->median();
	$stat->clear();
	
	# fidélité
	$stat->add_data(@fidelites);
	$borrowers->{fidelite_mediane} = $stat->median();
	$stat->clear();
	
	$stat->add_data(@fidelites_emprunteurs_distincts);
	$borrowers->{fidelite_mediane_emprunteurs_distincts} = $stat->median();
	$stat->clear();
	
	# villes
	my $nb_villes = 0;
	my $nb_rbx = 0;
	foreach my $ville (@villes) {
		$nb_villes ++;
		$ville = uc $ville;
		if ($ville eq 'ROUBAIX') {
			$nb_rbx ++;
		}
	}
	$borrowers->{nb_rbx} = $nb_rbx;
	$borrowers->{nb_villes} = $nb_villes;
	
	$nb_villes = 0;
	$nb_rbx = 0;
	foreach my $ville (@villes_emprunteurs_distincts) {
		$nb_villes ++;
		$ville = uc $ville;
		if ($ville eq 'ROUBAIX') {
			$nb_rbx ++;
		}
	}
	$borrowers->{nb_rbx_emprunteurs_distincts} = $nb_rbx;
	$borrowers->{nb_villes_emprunteurs_distincts} = $nb_villes;
	
	return $borrowers;
}

sub getWhereClause {
	my ($collection, $whereLocation) = @_;
	my $where;
	my @conditions;
	my @fields = qw( lib1 lib2 lib3 lib4 itemtype );
	foreach my $field (@fields) {
		if ($collection->{$field} ne 'NA') {
			my $condition;
			if ($collection->{$field} eq 'NULL') {
				if ($field eq "itemtype") {
					$condition = "iss.". $field . " IS NULL";
				} else {
					$condition = "c.". $field . " IS NULL";
				}
				push @conditions, $condition;
			} else {
				if ($field eq "itemtype") {
					$condition = "iss.". $field . " = '". $collection->{$field} . "'";
				} else {
					$condition = "c.". $field . " = '". $collection->{$field} . "'";
				}
				push @conditions, $condition;
			}
		}
	}
	
	$where = join " AND ", @conditions;
	$where = "WHERE YEAR(iss.issuedate) = 2017 AND " . $whereLocation . " AND " . $where;

	return $where;
}

sub GetWhereLocationBySite {
    my ($site) = @_ ;
    my $where ;
    if ( $site eq 'GPL' ) {
        $where = "iss.location != 'MUS1A'" ;
    } elsif ( $site eq 'MED' ) {
        $where = "iss.location NOT IN ('MUS1A', 'BUS1A', 'MED0A')" ;
    } elsif ( $site eq 'BUS' ) {
        $where = "iss.location = 'BUS1A'" ;
    } elsif ( $site eq 'COL' ) {
        $where = "iss.location = 'MED0A'" ;
    }
    return $where ;
}