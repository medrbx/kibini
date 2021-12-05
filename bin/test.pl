#! /usr/bin/perl

use Modern::Perl;
use utf8;
use Search::Elasticsearch;
use FindBin qw( $Bin );
use Data::Dumper;

use lib "$Bin/../lib";
use kibini::db;
use kibini::elasticsearch;
use kibini::log;
use kibini::time;
use adherents;
use collections::poldoc;
