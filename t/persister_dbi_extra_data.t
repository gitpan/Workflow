# -*-perl-*-

# $Id: persister_dbi_extra_data.t,v 1.2 2004/01/03 22:37:03 cwinters Exp $

use strict;
use constant NUM_TESTS => 1;
use Test::More;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::DBI::ExtraData' );
