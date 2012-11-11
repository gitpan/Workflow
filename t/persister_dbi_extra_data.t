# -*-perl-*-

# $Id: persister_dbi_extra_data.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use constant NUM_TESTS => 1;
use Test::More;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::DBI::ExtraData' );
