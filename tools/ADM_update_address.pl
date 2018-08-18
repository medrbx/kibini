#! /usr/bin/perl

use Modern::Perl;
use utf8;
use LWP::UserAgent;
use JSON;
use Encode qw(encode);
use Data::Dumper;
use Time::HiRes qw(usleep);
use FindBin qw( $Bin );

use lib "$Bin/../lib";
use kibini::db;
use kibini::time;
use kibini::email;
use kibini::config;

my $date = GetDateTime('today');

my $dbh = GetDbh() ;

my $nb = getNbBorrowersToMod($date);

if ( $nb > 500 ) {
	my $mail_conf = GetConfig('mail');
	my $from = $mail_conf->{sender};
	my $koha_conf = GetConfig('koha');
	my $to = $koha_conf->{admin_mail};
    my $subject = '[Koha - ADM] Trop de fiches adhérents à mettre à jour';
    my $msg = "Attention, le nombre d'adhérents modifiés le $date est de $nb.";
    SendEmail($from, $to, $subject, $msg);
} else {
    my $users = getBorrowers($date);
    my $i = 0;
    foreach my $user (@$users) {
        my $borrower = {
            userid => $$user[0],
            address => $$user[1],
            geo_id => $$user[2],
            address_approx => $$user[3],
            geo_status => $$user[4],
            iris_id => $$user[5],
            city => $$user[6],
            mobile => $$user[7]
        };        
        my %fields_to_modify;
        
        if ( uc($borrower->{city}) eq 'ROUBAIX' ) {
            $borrower = getAdressData($borrower);
            $fields_to_modify{city} = 'ROUBAIX';
            $fields_to_modify{state} = $borrower->{geo_id};
            $fields_to_modify{altcontactcountry} = $borrower->{iris_id};
            $fields_to_modify{altcontactaddress1} = $borrower->{address_approx};
            $fields_to_modify{altcontactaddress2} = $borrower->{geo_status};
        } else {
			$fields_to_modify{city} = uc($borrower->{city});
            $fields_to_modify{state} = undef;
            $fields_to_modify{altcontactcountry} = undef;
            $fields_to_modify{altcontactaddress1} = undef;
            $fields_to_modify{altcontactaddress2} = undef;		
		}
        
        if (!$borrower->{mobile}) {
            $fields_to_modify{smsalertnumber} = undef;
        } elsif ( $borrower->{mobile} eq '' ) {
            $fields_to_modify{mobile} = undef;
            $fields_to_modify{smsalertnumber} = undef;
        } elsif ( $borrower->{mobile} =~ m/^0[67][0-9]{8}$/ ) {
            $fields_to_modify{smsalertnumber} = '0033' . substr($borrower->{mobile}, 1);
        } else {
            $fields_to_modify{smsalertnumber} = undef;
        }
        
        

        #print Dumper($borrower);
        #print Dumper(\%fields_to_modify);
    
        my $result = modBorrower($borrower->{userid}, \%fields_to_modify);
        print Dumper($result);
		usleep(500000);
    }
}

$dbh->disconnect;

sub modBorrower {
    my ($userid, $data) = @_;
    
    my $url = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/rest.pl";
    $url = $url . "/user/" . $userid;

    my $header = ['Content-Type' => 'application/x-www-form-urlencoded'];
    $data = encode_json($data);
    $data = "data=" . $data;
    my $req = HTTP::Request->new('PUT', $url, $header, $data);

    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);
    $resp = $resp->decoded_content;
    
    return $resp;
}

sub getAdressData {
    my ($borrower) = @_;
    
    # Si on a un identifiant géographique
    if ( $borrower->{geo_id} || $borrower->{geo_id} ne '' ) {
        # On cherche l'objet adresse dans le référentiel via l'identifiant
        my $address_ref = AddressRefById($dbh, $borrower->{geo_id});
        # Si l'objet adresse existe dans le référentiel
        if ( $address_ref ) {
            # On récupère l'identifiant iris
            $borrower->{iris_id} = $address_ref->{irisInsee};
            # le statut est OK
            $borrower->{geo_status} = 'Ref OK';
        # Si l'objet adresse n'existe pas dans le référentiel
        } else {
            # On récupère l'identifiant iris
            $borrower->{iris_id} = $address_ref->{irisInsee};
            # On récupère l'adresse approx
            $borrower->{address_approx} = $address_ref->{adresse};
            # le statut est Approx
            $borrower->{geo_status} = 'Ref APPROX';
        }
    } else { # Si on n'a pas d'identifiant géographique
        # On cherche l'objet adresse dans le référentiel via l'adresse
        my $address_ref = AddressRefByAddress($dbh, $borrower->{address});
        # Si l'objet adresse existe dans le référentiel
        if ( $address_ref ) {
            # On récupère l'identifiant géographique
            $borrower->{geo_id} = $address_ref->{id_cicn2};
            # On récupère l'identifiant iris
            $borrower->{iris_id} = $address_ref->{irisInsee};
            # le statut est OK
            $borrower->{geo_status} = 'Ref OK';
        # Si l'objet adresse n'existe pas dans le référentiel
        } else {
            # Si une adresse approx est renseignée
            if ( $borrower->{address_approx} || $borrower->{address_approx} ne '' ) {
                # On cherche cette adresse dans le référentiel
                my $address_ref = AddressRefByAddress($dbh, $borrower->{address_approx});    
                # Si l'objet adresse existe dans le référentiel
                if ( $address_ref ) {
                    # On récupère l'identifiant géographique
                    $borrower->{geo_id} = $address_ref->{id_cicn2};
                    # On récupère l'identifiant iris
                    $borrower->{iris_id} = $address_ref->{irisInsee};
                    # le statut est OK
                    $borrower->{geo_status} = 'Ref APPROX';
                # Si l'objet adresse n'existe pas dans le référentiel
                } else {    
                    # On récupère l'identifiant géographique
                    $borrower->{geo_id} = $address_ref->{id_cicn2};
                    # On récupère l'identifiant iris
                    $borrower->{iris_id} = $address_ref->{irisInsee};
                    # le statut est OK
                    $borrower->{geo_status} = 'Ref OK';
                }
            # En l'absence d'adresse approx
            } else {
                # le statut est KO
                $borrower->{geo_status} = 'Ref KO';
            }
        }
    }
    
    $borrower->{geo_id} = undef if ($borrower->{geo_id} eq '');
    $borrower->{iris_id} = undef if ($borrower->{iris_id} eq '');
    $borrower->{geo_status} = undef if ($borrower->{geo_status} eq '');
    $borrower->{address_approx} = undef if ($borrower->{address_approx} eq '');
    
    return $borrower;
}

sub AddressRefByAddress {
    my ($dbh, $address) = @_;
    
    my $req = <<SQL;
SELECT id_cicn2, irisInsee
FROM statdb.iris
WHERE adresse = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($address);
    my $result = $sth->fetchrow_hashref;
    $sth->finish;
    
    return $result;
}

sub AddressRefById {
    my ($dbh, $id) = @_;
    
    my $req = <<SQL;
SELECT adresse, irisInsee
FROM statdb.iris
WHERE id_cicn2 = ?
SQL
    my $sth = $dbh->prepare($req);
    $sth->execute($id);
    my $result = $sth->fetchrow_hashref;
    $sth->finish;
    
    return $result;
}

sub getBorrowers {
    my ($date) = @_;

    my $report_id = "179";
    my $url = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report";
    $url = $url . "?id=" . $report_id . "&sql_params=" . $date;
    my $req = HTTP::Request->new('GET', $url);
    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);
    my $borrowers = $resp->decoded_content;
    $borrowers = decode_json $borrowers;

    return $borrowers;
}

sub getNbBorrowersToMod {
    my ($date) = @_;

    my $report_id = "181";
    my $url = "http://webservice.mediathequederoubaix.fr/cgi-bin/koha/svc/report";
    $url = $url . "?id=" . $report_id . "&sql_params=" . $date;
    my $req = HTTP::Request->new('GET', $url);
    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);
    my $nb = $resp->decoded_content;
    $nb = decode_json $nb;
    $nb = $$nb[0];
    my $res = $$nb[0];

    return $res;
}