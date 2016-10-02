#!/usr/bin/perl

use strict;
use warnings ;
use WWW::Mechanize;
use HTTP::Cookies ;
use DateTime ;
use DateTime::Format::MySQL ;
use FindBin qw( $Bin ) ;
use YAML qw(LoadFile) ;

use lib "$Bin/modules/" ;
use dbrequest ;

# On récupère les infos de connexion à Librixonline
my $fic_conf = "$Bin/../conf.yaml" ;
my $conf = LoadFile($fic_conf);
my $url = $conf->{nedap}->{url} ;
my $user = $conf->{nedap}->{user} ;
my $pwd = $conf->{nedap}->{pwd} ;

my @transType = qw( pret retour );
my $filename = "statdb_nedapV2.txt" ;

my ( $date_deb, $date_fin ) = dates() ;
foreach my $transType (@transType) {
	nedapTransDoc( $transType, $date_deb, $date_fin, $filename, $url, $user, $pwd ) ;
	insertNedapStatdb( $transType, $filename ) ;
}
unlink($filename);


sub dates {
    my $date_fin = DateTime->today()->subtract( days => 1 );
    $date_fin = DateTime::Format::MySQL->format_date($date_fin) ;

    my $bdd = "statdb" ;
    my $req = "SELECT DATE(MAX(date)) FROM stat_nedap" ;
    my $date_deb = fetchrow_array( $bdd, $req ) ;
    $date_deb = DateTime::Format::MySQL->parse_date($date_deb) ;
    $date_deb->add( days => 1 );
    $date_deb = DateTime::Format::MySQL->format_date($date_deb) ;

    return $date_deb, $date_fin ;
}


sub nedapTransDoc {
	my ( $transType, $date_deb, $date_fin, $filename, $url, $user, $pwd ) = @_ ;
	my $transTypeN ;	
	if ( $transType eq "pret" ) {
		$transTypeN = "checkout_books" ;
	} elsif ( $transType eq "retour" ) {
		$transTypeN = "checkin_books" ;
	}	
	my $url_token = "$url/user_sessions/new" ;
	my $url_auth = "$url/user_sessions" ;
	my $url_stat = "$url/statistics/csv?graph%5Btype_label%5D=$transTypeN&graph%5Bdevice%5D%5B3965%5D=1&graph%5Bdevice%5D%5B3969%5D=1&graph%5Bdevice%5D%5B3966%5D=1&graph%5Bdevice%5D%5B3964%5D=1&graph%5Bdevice%5D%5B3967%5D=1&graph%5Bdevice%5D%5B3968%5D=1&graph%5Bdevice%5D%5B3971%5D=1&graph%5Bdevice%5D%5B3970%5D=1&graph%5Bdevice%5D%5B3934%5D=1&graph%5Bgranularity_name%5D=hour&graph%5Bstart_date%5D=$date_deb&graph%5Bend_date%5D=$date_fin" ;



	my $mech = WWW::Mechanize->new(
		agent      => 'Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.4.0',
		cookie_jar => HTTP::Cookies->new( autosave       => 1 )
	) ;

	$mech->get($url_token);
	my $authenticity_token = $mech->field('authenticity_token');

	my %auth = (
		'authenticity_token' => $authenticity_token,
		'user_session[login]' => $user,
		'user_session[password]' => $pwd
	) ;
	$mech->post($url_auth, \%auth) ;
	
	$mech->get($url_stat);
	my $result = $mech->response()->decoded_content() ;
	open my $fic, ">", $filename ;
	print $fic $result ;
	close $fic ;
}

sub insertNedapStatdb {
	my ( $transType, $filename ) = @_ ;
	
	my $bdd = "statdb" ;
	my $dbh = dbh($bdd) ;
	open my $fic, "<", $filename ;
	while ( my $ligne = <$fic> ) {
		my ( @donnees ) = split /\;/, $ligne ;
		if ( length $donnees[0]) {
			$donnees[0] =~ s/\"// ;
			for ( my $i = 1 ; $i <= 9 ; $i++) { 
				if ($donnees[$i] != 0 ) {
					my $automate = "Automate $i" ;
					my $req = "INSERT INTO stat_nedap VALUES (?, \"$automate\", ?, \"$transType\")" ;
					my $sth = $dbh->prepare($req) ;	
					$sth->execute($donnees[0], $donnees[$i]) ;
					$sth->finish() ;
				}
			}
		}
	}

	$dbh->disconnect() ;
	close $fic ;
}