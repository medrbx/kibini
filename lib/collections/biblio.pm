package collections::biblio ;

use Exporter ;
@ISA = qw(Exporter) ;
@EXPORT = qw( GetMaxDateDataBiblio DelFromDataBiblio AddDataBiblio ) ;

use strict ;
use warnings ;
use Catmandu ;
use Catmandu::Util qw(:io);

use kibini::db ;

sub _GetKohaBiblioitems {
    my ($dbh, $table, $biblionumber) = @_ ;
    my $req = "SELECT itemtype, marcxml FROM koha_prod.$table WHERE biblionumber = ?" ;
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
    my $exporter = Catmandu->exporter( 'JSON', fh => $out, fix => 'catmandu_marc2dc.fix', array => 0);
    $importer->each(sub {
        my $item = shift;
        $exporter->add($item);
    });
    return $outdata;
}

sub _InsertIntoDataBiblio {
    my ($dbh, $table, $biblionumber, $itemtype, $json) = @_ ;
    my $deleted ;
    if ( $table eq 'biblioitems' ) {
        $deleted = 0 ;
    } else {
        $deleted = 1 ;
    }
    my $req = "INSERT INTO statdb.data_biblio (biblionumber, itemtype, bibliodata, deleted) VALUES (?, ?, ?, ?)" ;
    my $sth = $dbh->prepare($req);
    $sth->execute($biblionumber, $itemtype, $json, $deleted);
    $sth->finish();
}

sub GetMaxDateDataBiblio {
    my ($dbh) = @_ ;
    my $req = "SELECT MAX(timestamp) FROM statdb.data_biblio" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute() ;
    my $maxtimestamp = $sth->fetchrow_array() ;
    $sth->finish();
    return $maxtimestamp ;
}

sub DelFromDataBiblio {
    my ($dbh, $table, $maxtimestamp) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE timestamp >= ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($maxtimestamp) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my $req = "DELETE FROM statdb.data_biblio WHERE biblionumber = ?" ;
        my $sth = $dbh->prepare($req) ;
        $sth->execute($biblionumber) ;
        $i++ ;
    }
    $sth->finish();
    return $i ;
}

sub AddDataBiblio {
    my ($dbh, $table, $maxtimestamp) = @_ ;
    my $req = "SELECT biblionumber FROM koha_prod.$table WHERE timestamp >= ?" ;
    my $sth = $dbh->prepare($req) ;
    $sth->execute($maxtimestamp) ;
    my $i = 0 ;
    while ( my $biblionumber = $sth->fetchrow_array() ) {
        my ($itemtype, $marcxml) = _GetKohaBiblioitems($dbh, $table, $biblionumber) ;
        my $json = _ConvertMarcToJSON($marcxml) ;
        _InsertIntoDataBiblio($dbh, $table, $biblionumber, $itemtype, $json) ;
        $i++ ;
    }
    $sth->finish();
    return $i ;
}

1 ;