package qa ;

use Exporter ;
@ISA = qw( Exporter ) ;
@EXPORT = qw( qa_borrowers ) ;

use strict ;
use warnings ;
use FindBin qw( $Bin );
use LWP::UserAgent ;
use Encode qw(encode);
use JSON ;

sub qa_borrowers {
	# On récupère par webservice tous les adhérents répondant aux conditions fixées dans la requête
	my $ws = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report?id=166" ;
	my $ua = LWP::UserAgent->new() ;
	my $request = HTTP::Request->new( GET => $ws ) ;
	my $rep = $ua->request($request)->{'_content'} ;
	my $borrowers = decode_json($rep);

	# On ne garde que ceux présentant un "PB" et on les pousse dans la variable @ko
	my @ko ;
	foreach my $borrower (@$borrowers) {
		my @b = @$borrower ;
		my $ko = 0 ;
		for (my $i = 3 ; $i <= 10 ; $i++) {
			if ( $b[$i] eq 'PB' ) {
				$ko = 1 ;
				last ;
			} 
		}
		if ($ko == 1) {
			push @ko, $borrower ;
		}
	}
	return \@ko ;
}

1;
