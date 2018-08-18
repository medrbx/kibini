package collections::biblio2 ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetMaxDateDataBiblio DelFromDataBiblio AddDataBiblio GetDataFromJson DelFromDataBiblioFromBiblionumber AddDataBiblioFromBiblionumber GetMinBiblionumberFromStatdbDataBib _DelBiblioFromES ) ;

use strict ;
use warnings ;
use Catmandu ;
use Catmandu::Util qw(:io);
use JSON ;

use kibini::db ;

sub _GetKohaBiblioitems {
    my ($dbh, $table, $biblionumber) = @_ ;
    my $req = "SELECT marcxml FROM koha_prod.$table WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my @row = $sth->fetchrow_array() ;
    $sth->finish() ;
    return @row ;
}

sub _ConvertMarcToJSON {
    my ($marcxml) = @_ ;
    my $in = io \$marcxml ;

    my $importer = Catmandu->importer( 'MARC', type => 'XML', fh => $in );
    my $outdata ;
    my $out = io \$outdata ;
    my $exporter = Catmandu->exporter( 'JSON', fh => $out, fix => '/home/kibini/kibini_prod/etc/catmandu_databib.fix', array => 0);
    $importer->each(sub {
        my $item = shift;
        $exporter->add($item);
    });
    return $outdata;
}

sub _InsertIntoDataBiblio {
    my ($dbh, $table, $biblionumber, $json) = @_ ;
    my $deleted ;
    if ( $table eq 'biblioitems' ) {
        $deleted = 0 ;
    } else {
        $deleted = 1 ;
    }
    my $req = "INSERT INTO statdb.data_bib (biblionumber, bibliodata, deleted) VALUES (?, ?, ?)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber, $json, $deleted);
    $sth->finish();
    return $deleted ;
}

sub GetMaxDateDataBiblio {
    my ($dbh) = @_ ;
    my $req = "SELECT MAX(timestamp) FROM statdb.data_bib" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $maxtimestamp = $sth->fetchrow_array() ;
    $sth->finish();
    return $maxtimestamp ;
}

sub DelFromDataBiblio {
    my ($dbh, $table, $maxtimestamp, $e) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE timestamp >= ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($maxtimestamp) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my $req = "DELETE FROM statdb.data_bib WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        my $resp = $sth->execute($biblionumber) ;
        if ( $resp == 1 ) {
            $i++ ;
        }
        _DelBiblioFromES($e, $biblionumber) ;
    }
    $sth->finish();
    return $i ;
}

sub AddDataBiblio {
    my ($dbh, $table, $maxtimestamp, $e) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE timestamp >= ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($maxtimestamp) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        deleteDeletedIfInBiblio($dbh, $biblionumber) ;
        my ($marcxml) = _GetKohaBiblioitems($dbh, $table, $biblionumber) ;
        my $json = _ConvertMarcToJSON($marcxml) ;
        my $deleted = _InsertIntoDataBiblio($dbh, $table, $biblionumber, $json) ;
        my $datecreated = _GetRecordCreationDate($dbh, $table, $biblionumber) ;
        my $items_count = _GetRecordItemsCount($dbh, $table, $biblionumber) ;
        if ( $json ) {
            my $data = from_json($json) ;
            $data->{'items'}->{'count'} = $items_count ;
            $data->{'manage'}->{'datecreated'} = $datecreated ;
            $json = to_json($data) ;
        }
        if ( $deleted == 0 && $json ) {
            _AddBiblioToES($e, $biblionumber, $json) ;
        }
        $i++ ;
    }
    $sth->finish();
    return $i ;
}

sub DelFromDataBiblioFromBiblionumber {
    my ($dbh, $table, $biblionumber) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my $req = "DELETE FROM statdb.data_bib WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        $i++ ;
    }
    $sth->finish();
    return $i ;
}

sub AddDataBiblioFromBiblionumber {
    my ($dbh, $table, $biblionumber, $e) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        deleteDeletedIfInBiblio($dbh, $biblionumber) ;
        my ($marcxml) = _GetKohaBiblioitems($dbh, $table, $biblionumber) ;
        my $json = _ConvertMarcToJSON($marcxml) ;
        my $deleted = _InsertIntoDataBiblio($dbh, $table, $biblionumber, $json) ;
        my $datecreated = _GetRecordCreationDate($dbh, $table, $biblionumber) ;
        my $items_count = _GetRecordItemsCount($dbh, $table, $biblionumber) ;
        if ( $json ) {
            my $data = from_json($json) ;
            $data->{'items'}->{'count'} = $items_count ;
            $data->{'manage'}->{'datecreated'} = $datecreated ;
            $json = to_json($data) ;
        }
        if ( $deleted == 0 && $json ) {
            _AddBiblioToES($e, $biblionumber, $json) ;
        }
        $i++ ;
    }
    $sth->finish();
    return $i ;
}

sub GetDataFromJson {
    my ($dbh, $biblionumber) = @_ ;
    my $req = "SELECT bibliodata FROM statdb.data_bib WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my $bibliodata = $sth->fetchrow_array() ;
    $bibliodata = from_json($bibliodata) ;
    $sth->finish();
    return $bibliodata ;
}

sub _AddBiblioToES {
    my ($e, $biblionumber, $json) = @_ ;
    $json = from_json($json) ;
    my %index = (
        index   => 'catalogue',
        type    => 'biblio',
        id      => $biblionumber,
        body    => $json
    ) ;
    $e->index(\%index) ;
    return \%index ;
}

sub _DelBiblioFromES {
    my ($e, $biblionumber) = @_ ;
    my %index = (
        index   => 'catalogue',
        type    => 'biblio',
        id      => $biblionumber
    ) ;
    my $exist = $e->exists(\%index) ;
    if ( $exist ) {
        $e->delete(\%index) ;
    }
}

sub _GetRecordCreationDate {
    my ($dbh, $table, $biblionumber) = @_ ;
    if ( $table eq "biblioitems" ) {
        $table = "biblio" ;
    } else {
        $table = "deletedbiblio" ;  
    }
    my $req = "SELECT datecreated FROM koha_prod.$table WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my $datecreated = $sth->fetchrow_array() ;
    $sth->finish() ;
    return $datecreated ;
}

sub _GetRecordItemsCount {
    my ($dbh, $table, $biblionumber) = @_ ;
    my $count = 0 ;
    if ( $table eq "biblioitems" ) {
        my $req = "SELECT COUNT(itemnumber) FROM koha_prod.items WHERE biblionumber = ? AND notforloan != 4 GROUP BY biblionumber" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        $count = $sth->fetchrow_array() ;
        $sth->finish() ;
    }
    return $count ;
}

sub deleteDeletedIfInBiblio {
    my ($dbh, $biblionumber) = @_ ;
    my $deleted_row = 0 ;
    my $req = "SELECT COUNT(*) FROM statdb.data_bib WHERE biblionumber = ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($biblionumber) ;
    my $count = $sth->fetchrow_array() ;
    $sth->finish() ;
    if ( $count > 0 ) {
        my $req = "DELETE FROM statdb.data_bib WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        $deleted_row = 1 ;
    }
    $sth->finish() ;
    return $deleted_row ;
}

sub GetMinBiblionumberFromStatdbDataBib {
    my ($dbh) = @_ ;
    my $req = "SELECT MIN(biblionumber) FROM statdb.data_bib" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $biblionumber = $sth->fetchrow_array() ;
    $sth->finish() ;
    return $biblionumber ;
}

1 ;