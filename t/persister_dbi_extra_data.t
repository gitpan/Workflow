# -*-perl-*-

# $Id: persister_dbi_extra_data.t 539 2012-10-25 16:19:14Z jonasbn $

use strict;
use constant NUM_TESTS => 1;
use Test::More;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::DBI::ExtraData' );
