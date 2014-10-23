# -*-perl-*-

# $Id: state.t 383 2008-08-19 09:50:25Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 19;

require_ok( 'Workflow::State' );

my $factory;

$factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

# Run the tests with XML-based config.
diag "Running with XML config.";
TestUtil::run_state_tests($factory);

