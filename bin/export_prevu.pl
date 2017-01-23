#! /usr/bin/perl

use strict ;
use warnings ;
use Digest::SHA3 qw( sha3_256_hex );
use FindBin qw( $Bin ) ;

use lib "$Bin/../lib" ;
use kibini::db ;

#AddIssues(3) ;
#InsertPrevuBorrowers() ;
#AddItems() ;
#AddBiblio() ;
AddBiblioItems() ;

sub AddIssues {
    my ($months) = @_ ;
    my $dbh = GetDbh() ;
    my @tables = qw( issues old_issues ) ;
    foreach my $table ( @tables ) {
        my $req = "SELECT * FROM koha_prod.$table WHERE DATE(issuedate) >= CURDATE() - INTERVAL $months MONTH" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute() ;
        my $i = 0 ;
        while ( my $row = $sth->fetchrow_hashref() ) {
            $row->{'borrowernumber'} = Crypt($row->{'borrowernumber'}) ;
            AddIssuesToTable($dbh, $row, $table) ;
            $i++ ;
            print "$table : $i\n" ;
        }
    }
    $dbh->disconnect() ;
}

sub AddItems {
    my $dbh = GetDbh() ;
    my $req = "SELECT DISTINCT itemnumber FROM prevu_rbx.issues ORDER BY itemnumber ASC" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $i = 0 ;
    while ( my $itemnumber = $sth->fetchrow_array() ) {
        my $req = "SELECT * FROM koha_prod.items WHERE itemnumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($itemnumber) ;
        my $row = $sth->fetchrow_hashref() ;
        AddItemsToTable( $dbh, $row ) ;
        $sth->finish() ;
        $i++ ;
        print "$i\n" ;
    }
    $sth->finish() ;
    $dbh->disconnect() ;
}

sub AddBiblio {
    my $dbh = GetDbh() ;
    my $req = "SELECT DISTINCT biblionumber FROM prevu_rbx.items ORDER BY itemnumber ASC" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my $req = "SELECT * FROM koha_prod.biblio WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        my $row = $sth->fetchrow_hashref() ;
        AddBiblioToTable( $dbh, $row ) ;
        $sth->finish() ;
        $i++ ;
        print "$i\n" ;
    }
    $sth->finish() ;
    $dbh->disconnect() ;
}

sub AddBiblioItems {
    my $dbh = GetDbh() ;
    my $req = "SELECT DISTINCT biblionumber FROM prevu_rbx.items ORDER BY itemnumber ASC" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my $req = "SELECT * FROM koha_prod.biblioitems WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        my $row = $sth->fetchrow_hashref() ;
        AddBiblioItemsToTable( $dbh, $row ) ;
        $sth->finish() ;
        $i++ ;
        print "$i\n" ;
    }
    $sth->finish() ;
    $dbh->disconnect() ;
}

sub InsertPrevuBorrowers {
    my $dbh = GetDbh() ;
    my $req = "SELECT * FROM koha_prod.borrowers" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $borrowernumber = Crypt($row->{'borrowernumber'}) ;
        my $isBorrower = IsBorrower( $dbh, $borrowernumber ) ;
        if ( $isBorrower == 1 ) {
            $row = AnonymiseBorrowerRow( $row ) ;
            AddBorrowers( $dbh, $row ) ;
            print "$row->{'borrowernumber'}\n" ;
        }
    }
    $sth->finish() ;
    $dbh->disconnect() ;
}

sub AnonymiseBorrowers {
    my $dbh = GetDbh() ;
    my $req = "SELECT * FROM prevu_rbx.borrowers" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $isBorrower = IsBorrower( $dbh, $row->{'borrowernumber'} ) ;
        if ( $isBorrower == 1 ) {
            $row = AnonymiseBorrowerRow( $row ) ;
            ModBorrowers( $dbh, $row ) ;
        } else {
            DelBorrowers( $dbh, $row ) ;
        }
        print "$row->{'borrowernumber'}\n" ;
    }
    $sth->finish() ;
    $dbh->disconnect() ;
}

sub AnonymiseBorrowerRow {
    my ($row) = @_ ;
    $row->{'borrowernumber'} = Crypt($row->{'borrowernumber'}) ;
    $row->{'cardnumber'} = Crypt($row->{'cardnumber'}) ;
    $row->{'surname'} = StringToX($row->{'surname'}) ;
    $row->{'firstname'} = StringToX($row->{'firstname'}) ;
    $row->{'title'} = $row->{'title'} ;
    $row->{'othernames'} = StringToX($row->{'othernames'}) ;
    $row->{'initials'} = StringToX($row->{'initials'}) ;
    $row->{'streetnumber'} = StringToX($row->{'streetnumber'}) ;
    $row->{'streettype'} = StringToX($row->{'streettype'}) ;
    $row->{'address'} = StringToX($row->{'address'}) ;
    $row->{'address2'} = StringToX($row->{'address2'}) ;
    $row->{'city'} = $row->{'city'} ;
    $row->{'state'} = StringToX($row->{'state'}) ;
    $row->{'zipcode'} = $row->{'zipcode'} ;
    $row->{'country'} = StringToX($row->{'country'}) ;
    $row->{'email'} = StringToX($row->{'email'}) ;
    $row->{'phone'} = StringToX($row->{'phone'}) ;
    $row->{'mobile'} = StringToX($row->{'mobile'}) ;
    $row->{'fax'} = StringToX($row->{'fax'}) ;
    $row->{'emailpro'} = StringToX($row->{'emailpro'}) ;
    $row->{'phonepro'} = StringToX($row->{'phonepro'}) ;
    $row->{'B_streetnumber'} = StringToX($row->{'B_streetnumber'}) ;
    $row->{'B_streettype'} = StringToX($row->{'B_streettype'}) ;
    $row->{'B_address'} = StringToX($row->{'B_address'}) ;
    $row->{'B_address2'} = StringToX($row->{'B_address2'}) ;
    $row->{'B_city'} = StringToX($row->{'B_city'}) ;
    $row->{'B_state'} = StringToX($row->{'B_state'}) ;
    $row->{'B_zipcode'} = StringToX($row->{'B_zipcode'}) ;
    $row->{'B_country'} = StringToX($row->{'B_country'}) ;
    $row->{'B_email'} = StringToX($row->{'B_email'}) ;
    $row->{'B_phone'} = StringToX($row->{'B_phone'}) ;
    $row->{'dateofbirth'} = AnoDate($row->{'dateofbirth'}) ;
    $row->{'branchcode'} = StringToX($row->{'branchcode'}) ;
    $row->{'categorycode'} = StringToX($row->{'categorycode'}) ;
    $row->{'dateenrolled'} = AnoDate($row->{'dateenrolled'}) ;
    $row->{'dateexpiry'} = AnoDate($row->{'dateexpiry'}) ;
    $row->{'gonenoaddress'} = StringToX($row->{'gonenoaddress'}) ;
    $row->{'lost'} = StringToX($row->{'lost'}) ;
    $row->{'debarred'} = AnoDate($row->{'debarred'}) ;
    $row->{'debarredcomment'} = StringToX($row->{'debarredcomment'}) ;
    $row->{'contactname'} = StringToX($row->{'contactname'}) ;
    $row->{'contactfirstname'} = StringToX($row->{'contactfirstname'}) ;
    $row->{'contacttitle'} = StringToX($row->{'contacttitle'}) ;
    $row->{'guarantorid'} = IntegerTo0($row->{'guarantorid'}) ;
    $row->{'borrowernotes'} = StringToX($row->{'borrowernotes'}) ;
    $row->{'relationship'} = StringToX($row->{'relationship'}) ;
    $row->{'ethnicity'} = StringToX($row->{'ethnicity'}) ;
    $row->{'ethnotes'} = StringToX($row->{'ethnotes'}) ;
    $row->{'sex'} = StringToX($row->{'sex'}) ;
    $row->{'password'} = StringToX($row->{'password'}) ;
    $row->{'flags'} = IntegerTo0($row->{'flags'}) ;
    $row->{'userid'} = StringToX($row->{'userid'}) ;
    $row->{'opacnote'} = StringToX($row->{'opacnote'}) ;
    $row->{'contactnote'} = StringToX($row->{'contactnote'}) ;
    $row->{'sort1'} = StringToX($row->{'sort1'}) ;
    $row->{'sort2'} = StringToX($row->{'sort2'}) ;
    $row->{'altcontactfirstname'} = StringToX($row->{'altcontactfirstname'}) ;
    $row->{'altcontactsurname'} = StringToX($row->{'altcontactsurname'}) ;
    $row->{'altcontactaddress1'} = StringToX($row->{'altcontactaddress1'}) ;
    $row->{'altcontactaddress2'} = StringToX($row->{'altcontactaddress2'}) ;
    $row->{'altcontactaddress3'} = StringToX($row->{'altcontactaddress3'}) ;
    $row->{'altcontactstate'} = StringToX($row->{'altcontactstate'}) ;
    $row->{'altcontactzipcode'} = StringToX($row->{'altcontactzipcode'}) ;
    $row->{'altcontactcountry'} = $row->{'altcontactcountry'} ;
    $row->{'altcontactphone'} = StringToX($row->{'altcontactphone'}) ;
    $row->{'smsalertnumber'} = StringToX($row->{'smsalertnumber'}) ;
    $row->{'privacy'} = IntegerTo0($row->{'privacy'}) ;
    return $row ;
}

sub AnoDate {
    my ($date) = @_ ;
    if ( defined $date ) {
        my ($year, $month, $day) = split /-/, $date ;
        $date = $year . "-01-01" ;
    } else {
        $date = "0000-00-00" ;
    }
    return $date ;
}

sub StringToX {
    my ($string) = @_ ;
    if ( $string eq '' ) {
        $string = undef ;
    } else {
        $string = 'X' ;
    }
    return $string ;
}

sub IntegerTo0 {
    my ($int) = @_ ;
    if ( $int eq '' ) {
        $int = undef ;
    } else {
        $int = 0 ;
    }
    return $int ;
}

sub ModBorrowers {
    my ( $dbh, $row ) = @_ ;
    my $req = <<SQL ;
UPDATE prevu_rbx.borrowers
SET
    borrowernumber = ?,
    cardnumber = ?,
    surname = ?,
    firstname = ?,
    title = ?,
    othernames = ?,
    initials = ?,
    streetnumber = ?,
    streettype = ?,
    address = ?,
    address2 = ?,
    city = ?,
    state = ?,
    zipcode = ?,
    country = ?,
    email = ?,
    phone = ?,
    mobile = ?,
    fax = ?,
    emailpro = ?,
    phonepro = ?,
    B_streetnumber = ?,
    B_streettype = ?,
    B_address = ?,
    B_address2 = ?,
    B_city = ?,
    B_state = ?,
    B_zipcode = ?,
    B_country = ?,
    B_email = ?,
    B_phone = ?,
    dateofbirth = ?,
    branchcode = ?,
    categorycode = ?,
    dateenrolled = ?,
    dateexpiry = ?,
    gonenoaddress = ?,
    lost = ?,
    debarred = ?,
    debarredcomment = ?,
    contactname = ?,
    contactfirstname = ?,
    contacttitle = ?,
    guarantorid = ?,
    borrowernotes = ?,
    relationship = ?,
    ethnicity = ?,
    ethnotes = ?,
    sex = ?,
    password = ?,
    flags = ?,
    userid = ?,
    opacnote = ?,
    contactnote = ?,
    sort1 = ?,
    sort2 = ?,
    altcontactfirstname = ?,
    altcontactsurname = ?,
    altcontactaddress1 = ?,
    altcontactaddress2 = ?,
    altcontactaddress3 = ?,
    altcontactstate = ?,
    altcontactzipcode = ?,
    altcontactcountry = ?,
    altcontactphone = ?,
    smsalertnumber = ?,
    privacy = ?
WHERE borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'borrowernumber'},
        $row->{'cardnumber'},
        $row->{'surname'},
        $row->{'firstname'},
        $row->{'title'},
        $row->{'othernames'},
        $row->{'initials'},
        $row->{'streetnumber'},
        $row->{'streettype'},
        $row->{'address'},
        $row->{'address2'},
        $row->{'city'},
        $row->{'state'},
        $row->{'zipcode'},
        $row->{'country'},
        $row->{'email'},
        $row->{'phone'},
        $row->{'mobile'},
        $row->{'fax'},
        $row->{'emailpro'},
        $row->{'phonepro'},
        $row->{'B_streetnumber'},
        $row->{'B_streettype'},
        $row->{'B_address'},
        $row->{'B_address2'},
        $row->{'B_city'},
        $row->{'B_state'},
        $row->{'B_zipcode'},
        $row->{'B_country'},
        $row->{'B_email'},
        $row->{'B_phone'},
        $row->{'dateofbirth'},
        $row->{'branchcode'},
        $row->{'categorycode'},
        $row->{'dateenrolled'},
        $row->{'dateexpiry'},
        $row->{'gonenoaddress'},
        $row->{'lost'},
        $row->{'debarred'},
        $row->{'debarredcomment'},
        $row->{'contactname'},
        $row->{'contactfirstname'},
        $row->{'contacttitle'},
        $row->{'guarantorid'},
        $row->{'borrowernotes'},
        $row->{'relationship'},
        $row->{'ethnicity'},
        $row->{'ethnotes'},
        $row->{'sex'},
        $row->{'password'},
        $row->{'flags'},
        $row->{'userid'},
        $row->{'opacnote'},
        $row->{'contactnote'},
        $row->{'sort1'},
        $row->{'sort2'},
        $row->{'altcontactfirstname'},
        $row->{'altcontactsurname'},
        $row->{'altcontactaddress1'},
        $row->{'altcontactaddress2'},
        $row->{'altcontactaddress3'},
        $row->{'altcontactstate'},
        $row->{'altcontactzipcode'},
        $row->{'altcontactcountry'},
        $row->{'altcontactphone'},
        $row->{'smsalertnumber'},
        $row->{'privacy'},
        $row->{'borrowernumber'}
    ) ;
    $sth->finish() ;
}

sub DelBorrowers {
    my ( $dbh, $row ) = @_ ;
    my $req = "DELETE FROM prevu_rbx.borrowers WHERE borrowernumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    my $r = $sth->execute( $row->{'borrowernumber'} ) ;
    $sth->finish() ;
    $sth->finish() ;
}

sub IsBorrower {
    my ($dbh, $borrowernumber) = @_  ;
    my $req1 = <<SQL ;
SELECT COUNT(*)
FROM prevu_rbx.issues
WHERE borrowernumber = ?
SQL
    my $req2 = <<SQL ;
SELECT COUNT(*)
FROM prevu_rbx.old_issues
WHERE borrowernumber = ?
SQL
    my $sth = $dbh->prepare($req1) ;
    $sth->execute($borrowernumber) ;
    my $count = $sth->fetchrow_array() ;
    $sth->finish() ;
    $sth = $dbh->prepare($req2) ;
    $sth->execute($borrowernumber) ;
    my $count2 = $sth->fetchrow_array() ;
    $count = $count + $count2 ;
    
    my $borrower = 0 ;
    if ( $count > 0 ) {
        $borrower = 1 ;
    }
    return $borrower ;
}

sub Crypt {
    my ($string) = @_ ;
    my $hashed_string = sha3_256_hex($string) ;
    return $hashed_string ;
}

sub AddBorrowers {
    my ( $dbh, $row ) = @_ ;
    my $req = <<SQL ;
INSERT INTO prevu_rbx.borrowers 
VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'borrowernumber'},
        $row->{'cardnumber'},
        $row->{'surname'},
        $row->{'firstname'},
        $row->{'title'},
        $row->{'othernames'},
        $row->{'initials'},
        $row->{'streetnumber'},
        $row->{'streettype'},
        $row->{'address'},
        $row->{'address2'},
        $row->{'city'},
        $row->{'state'},
        $row->{'zipcode'},
        $row->{'country'},
        $row->{'email'},
        $row->{'phone'},
        $row->{'mobile'},
        $row->{'fax'},
        $row->{'emailpro'},
        $row->{'phonepro'},
        $row->{'B_streetnumber'},
        $row->{'B_streettype'},
        $row->{'B_address'},
        $row->{'B_address2'},
        $row->{'B_city'},
        $row->{'B_state'},
        $row->{'B_zipcode'},
        $row->{'B_country'},
        $row->{'B_email'},
        $row->{'B_phone'},
        $row->{'dateofbirth'},
        $row->{'branchcode'},
        $row->{'categorycode'},
        $row->{'dateenrolled'},
        $row->{'dateexpiry'},
        $row->{'gonenoaddress'},
        $row->{'lost'},
        $row->{'debarred'},
        $row->{'debarredcomment'},
        $row->{'contactname'},
        $row->{'contactfirstname'},
        $row->{'contacttitle'},
        $row->{'guarantorid'},
        $row->{'borrowernotes'},
        $row->{'relationship'},
        $row->{'ethnicity'},
        $row->{'ethnotes'},
        $row->{'sex'},
        $row->{'password'},
        $row->{'flags'},
        $row->{'userid'},
        $row->{'opacnote'},
        $row->{'contactnote'},
        $row->{'sort1'},
        $row->{'sort2'},
        $row->{'altcontactfirstname'},
        $row->{'altcontactsurname'},
        $row->{'altcontactaddress1'},
        $row->{'altcontactaddress2'},
        $row->{'altcontactaddress3'},
        $row->{'altcontactstate'},
        $row->{'altcontactzipcode'},
        $row->{'altcontactcountry'},
        $row->{'altcontactphone'},
        $row->{'smsalertnumber'},
        $row->{'privacy'}
    ) ;
    $sth->finish() ;
}

sub AddIssuesToTable {
    my ( $dbh, $row, $table ) = @_ ;
    my $req = <<SQL ;
INSERT INTO prevu_rbx.$table 
VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'borrowernumber'},
        $row->{'itemnumber'},
        $row->{'date_due'},
        $row->{'branchcode'},
        $row->{'issuingbranch'},
        $row->{'returndate'},
        $row->{'lastreneweddate'},
        $row->{'return'},
        $row->{'renewals'},
        $row->{'auto_renew'},
        $row->{'timestamp'},
        $row->{'issuedate'},
        $row->{'onsite_checkout'},
    ) ;
    $sth->finish() ;
}

sub AddItemsToTable {
    my ( $dbh, $row ) = @_ ;
    my $req = <<SQL ;
INSERT INTO prevu_rbx.items
VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'itemnumber'},
        $row->{'biblionumber'},
        $row->{'biblioitemnumber'},
        $row->{'barcode'},
        $row->{'dateaccessioned'},
        $row->{'booksellerid'},
        $row->{'homebranch'},
        $row->{'price'},
        $row->{'replacementprice'},
        $row->{'replacementpricedate'},
        $row->{'datelastborrowed'},
        $row->{'datelastseen'},
        $row->{'stack'},
        $row->{'notforloan'},
        $row->{'damaged'},
        $row->{'itemlost'},
        $row->{'itemlost_on'},
        $row->{'withdrawn'},
        $row->{'withdrawn_on'},
        $row->{'itemcallnumber'},
        $row->{'coded_location_qualifier'},
        $row->{'issues'},
        $row->{'renewals'},
        $row->{'reserves'},
        $row->{'restricted'},
        $row->{'itemnotes'},
        $row->{'holdingbranch'},
        $row->{'paidfor'},
        $row->{'timestamp'},
        $row->{'location'},
        $row->{'permanent_location'},
        $row->{'onloan'},
        $row->{'cn_source'},
        $row->{'cn_sort'},
        $row->{'ccode'},
        $row->{'materials'},
        $row->{'uri'},
        $row->{'itype'},
        $row->{'more_subfields_xml'},
        $row->{'enumchron'},
        $row->{'copynumber'},
        $row->{'stocknumber'}
    ) ;
    $sth->finish() ;
}

sub AddBiblioToTable {
    my ( $dbh, $row ) = @_ ;
    my $req = <<SQL ;
INSERT INTO prevu_rbx.biblio
VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'biblionumber'},
        $row->{'frameworkcode'},
        $row->{'author'},
        $row->{'title'},
        $row->{'unititle'},
        $row->{'notes'},
        $row->{'serial'},
        $row->{'seriestitle'},
        $row->{'copyrightdate'},
        $row->{'timestamp'},
        $row->{'datecreated'},
        $row->{'abstract'}
    ) ;
    $sth->finish() ;
}

sub AddBiblioItemsToTable {
    my ( $dbh, $row ) = @_ ;
    my $req = <<SQL ;
INSERT INTO prevu_rbx.biblioitems
VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL
    my $sth = $dbh->prepare($req) ;
    $sth->execute(
        $row->{'biblioitemnumber'},
        $row->{'biblionumber'},
        $row->{'volume'},
        $row->{'number'},
        $row->{'itemtype'},
        $row->{'isbn'},
        $row->{'issn'},
        $row->{'ean'},
        $row->{'publicationyear'},
        $row->{'publishercode'},
        $row->{'volumedate'},
        $row->{'volumedesc'},
        $row->{'collectiontitle'},
        $row->{'collectionissn'},
        $row->{'collectionvolume'},
        $row->{'editionstatement'},
        $row->{'editionresponsibility'},
        $row->{'timestamp'},
        $row->{'illus'},
        $row->{'pages'},
        $row->{'notes'},
        $row->{'size'},
        $row->{'place'},
        $row->{'lccn'},
        $row->{'marc'},
        $row->{'url'},
        $row->{'cn_source'},
        $row->{'cn_class'},
        $row->{'cn_item'},
        $row->{'cn_suffix'},
        $row->{'cn_sort'},
        $row->{'agerestriction'},
        $row->{'totalissues'},
        $row->{'marcxml'}
    ) ;
    $sth->finish() ;
}