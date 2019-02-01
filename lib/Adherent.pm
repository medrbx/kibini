package Adherent;

use Moo;
use List::MoreUtils qw(any uniq);

use Kibini::DB;
use Kibini::Crypt;
use kibini::time;

has crypter => ( is => 'ro' );

has dbh => ( is => 'ro' );

has koha_borrowernumber => ( is => 'ro' );
has koha_cardnumber => ( is => 'ro' );
has koha_surname => ( is => 'ro' );
has koha_firstname => ( is => 'ro' );
has koha_title => ( is => 'ro' );
has koha_othernames => ( is => 'ro' );
has koha_initials => ( is => 'ro' );
has koha_streetnumber => ( is => 'ro' );
has koha_streettype => ( is => 'ro' );
has koha_address => ( is => 'ro' );
has koha_address2 => ( is => 'ro' );
has koha_city => ( is => 'ro' );
has koha_state => ( is => 'ro' );
has koha_zipcode => ( is => 'ro' );
has koha_country => ( is => 'ro' );
has koha_email => ( is => 'ro' );
has koha_phone => ( is => 'ro' );
has koha_mobile => ( is => 'ro' );
has koha_fax => ( is => 'ro' );
has koha_emailpro => ( is => 'ro' );
has koha_phonepro => ( is => 'ro' );
has koha_B_streetnumber => ( is => 'ro' );
has koha_B_streettype => ( is => 'ro' );
has koha_B_address => ( is => 'ro' );
has koha_B_address2 => ( is => 'ro' );
has koha_B_city => ( is => 'ro' );
has koha_B_state => ( is => 'ro' );
has koha_B_zipcode => ( is => 'ro' );
has koha_B_country => ( is => 'ro' );
has koha_B_email => ( is => 'ro' );
has koha_B_phone => ( is => 'ro' );
has koha_dateofbirth => ( is => 'ro' );
has koha_branchcode => ( is => 'ro' );
has koha_categorycode => ( is => 'ro' );
has koha_dateenrolled => ( is => 'ro' );
has koha_dateexpiry => ( is => 'ro' );
has koha_gonenoaddress => ( is => 'ro' );
has koha_lost => ( is => 'ro' );
has koha_debarred => ( is => 'ro' );
has koha_debarredcomment => ( is => 'ro' );
has koha_contactname => ( is => 'ro' );
has koha_contactfirstname => ( is => 'ro' );
has koha_contacttitle => ( is => 'ro' );
has koha_guarantorid => ( is => 'ro' );
has koha_borrowernotes => ( is => 'ro' );
has koha_relationship => ( is => 'ro' );
has koha_sex => ( is => 'ro' );
has koha_password => ( is => 'ro' );
has koha_flags => ( is => 'ro' );
has koha_userid => ( is => 'ro' );
has koha_opacnote => ( is => 'ro' );
has koha_contactnote => ( is => 'ro' );
has koha_sort1 => ( is => 'ro' );
has koha_sort2 => ( is => 'ro' );
has koha_altcontactfirstname => ( is => 'ro' );
has koha_altcontactsurname => ( is => 'ro' );
has koha_altcontactaddress1 => ( is => 'ro' );
has koha_altcontactaddress2 => ( is => 'ro' );
has koha_altcontactaddress3 => ( is => 'ro' );
has koha_altcontactstate => ( is => 'ro' );
has koha_altcontactzipcode => ( is => 'ro' );
has koha_altcontactcountry => ( is => 'ro' );
has koha_altcontactphone => ( is => 'ro' );
has koha_smsalertnumber => ( is => 'ro' );
has koha_sms_provider_id => ( is => 'ro' );
has koha_privacy => ( is => 'ro' );
has koha_privacy_guarantor_checkouts => ( is => 'ro' );
has koha_checkprevcheckout => ( is => 'ro' );
has koha_updated_on => ( is => 'ro' );
has koha_lastseen => ( is => 'ro' );

has statdb_age => ( is => 'ro' );
has statdb_acode => ( is => 'ro' );
has statdb_ville => ( is => 'ro' );
has statdb_iris => ( is => 'ro' );
has statdb_categorycode => ( is => 'ro' );
has statdb_branchcode => ( is => 'ro' );
has statdb_fidelite => ( is => 'ro' );
has statdb_sexe => ( is => 'ro' );
has statdb_adherentid => ( is => 'ro' );

has es_sexe => ( is => 'ro' );
has es_age_lib1 => ( is => 'ro' );
has es_age_lib2 => ( is => 'ro' );
has es_age_lib3 => ( is => 'ro' );

sub BUILDARGS {
    my ($class, @args) = @_;
    my $arg;

    if ( $args[0]->{dbh} ) {
        $arg->{dbh} = $args[0]->{dbh};
    } else {
        my $dbh = Kibini::DB->new;
        $dbh = $dbh->dbh;
        $arg->{dbh} = $dbh;
    }
    
    if ( $args[0]->{adherent} ) {
        my %adh = %{$args[0]->{adherent}};
        foreach my $k (keys(%adh)) {
            $arg->{$k} = $adh{$k};
        }
    }
    
    if ( $args[0]->{crypter} ) {
        $arg->{crypter} = $args[0]->{crypter};
    } else {
        $arg->{crypter} = Kibini::Crypt->new;
    }

    return $arg;
}

sub get_data_from_koha_by_id {
    my ($self, $param) = @_;
    
    my $dbh = $self->{dbh};
    
    my $select = join ", ", @{ $param->{koha_fields} };
    my $id = $param->{koha_id};
    my $req = "SELECT $select FROM koha_prod.borrowers WHERE $id = ?";
    my $sth = $dbh->prepare($req);
    $id = "koha_" . $id;
    $sth->execute($self->$id);
    my $result = $sth->fetchrow_hashref ;
    $sth->finish();
    
    foreach my $k (keys(%$result)) {
        my $key = "koha_" . $k;
        $self->{$key} = $result->{$k};
    }

    return $self;
}

sub get_age_at_time_of_event {
    my ($self, $param) = @_;
    
    my $date_event = $self->{$param->{date_event_field}};
    
    if ( $self->{koha_dateofbirth} ) {
        my $yearofevent;
        if ( $param->{format_date_event} eq 'datetime' ) {
            $yearofevent = DateTime::Format::MySQL->parse_datetime($date_event)->year();
        } elsif ( $param->{format_date_event} eq 'date' ) {
            $yearofevent = DateTime::Format::MySQL->parse_date($date_event)->year();
        }

        my $yearofbirth = DateTime::Format::MySQL->parse_date($self->{koha_dateofbirth})->year();
    
        $self->{statdb_age} = $yearofevent - $yearofbirth;
    }
     
    return $self;
}

sub get_age_data {
    my ($self, $type) = @_;
    
    if ( $self->{statdb_acode} ) {
        my $req = "SELECT trmeda, trmedb, trinsee FROM statdb.lib_age2 WHERE acode = ?";
        my $sth = $self->{dbh}->prepare($req);
        $sth->execute($self->{statdb_acode});
        ($self->{es_age_lib1}, $self->{es_age_lib2}, $self->{es_age_lib3} ) = $sth->fetchrow_array;
        $sth->finish;    
    } elsif ( $self->{statdb_age} ) {
        my $req = "SELECT acode, trmeda, trmedb, trinsee FROM statdb.lib_age2 WHERE age = ?";
        my $sth = $self->{dbh}->prepare($req);
        $sth->execute($self->{statdb_age});
        ($self->{statdb_acode}, $self->{es_age_lib1}, $self->{es_age_lib2}, $self->{es_age_lib3} ) = $sth->fetchrow_array;
        $sth->finish;    
    }
    
    return $self;
}

sub get_fidelite {
    my ($self, $param) = @_;
    
    if ($self->{koha_dateenrolled}) {
        my $date_event = $self->{$param->{date_event_field}};
    
        my $yearofevent;
        if ( $param->{format_date_event} eq 'datetime' ) {
            $yearofevent = DateTime::Format::MySQL->parse_datetime($date_event)->year();
        } elsif ( $param->{format_date_event} eq 'date' ) {
            $yearofevent = DateTime::Format::MySQL->parse_date($date_event)->year();
        }

        my $yearenrolled = DateTime::Format::MySQL->parse_date($self->{koha_dateenrolled})->year();
    
        $self->{statdb_fidelite} = $yearofevent - $yearenrolled;
    }
    
    return $self;
}

sub get_sex {
    my ($self) = @_;
    
    my @categorycodes = qw( MEDA MEDB MEDC CSVT MEDP BIBL CSLT );
    my $categorycode;
    if ($self->{koha_categorycode} ) {
        $categorycode = $self->{koha_categorycode};
    } elsif ($self->{statdb_categorycode} ) {
        $categorycode = $self->{statdb_categorycode};
    }
    
    if ( any { /$categorycode/ } @categorycodes ) {
        if ( $self->{koha_title} ) {
            if ( $self->{koha_title} eq 'Madame' ) {
                $self->{statdb_sexe} = 'F';
                $self->{es_sexe} = 'Femme';
            } elsif ( $self->{koha_title} eq 'Monsieur' ) {
                $self->{statdb_sexe} = 'M';
                $self->{es_sexe} = 'Homme';
            } else {
                $self->{statdb_sexe} = 'NC';
                $self->{es_sexe} = 'Inconnu';
            }
        } elsif ( $self->{statdb_sexe} ) {
            if ( $self->{statdb_sexe} eq 'F' ) {
                $self->{es_sexe} = 'Femme';
            } elsif ( $self->{statdb_sexe} eq 'H' ) {
                $self->{es_sexe} = 'Homme';
            } else {
                $self->{es_sexe} = 'Inconnu';
            }
        }
    } else {
        $self->{statdb_sexe} = 'NP';
        $self->{es_sexe} = 'NP';
    }
    
    return $self;
}

sub get_adherentid {
    my ($self) = @_;
    
    my $crypter = $self->{crypter};
    
    $self->{statdb_adherentid} = $crypter->crypt($self->{koha_borrowernumber});
    
    return $self;
}

1;

__END__