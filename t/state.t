# -*-perl-*-

# $Id: state.t 361 2008-04-05 13:23:31Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 20;

require_ok( 'Workflow::State' );

my $factory;

$factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

# Run the tests with XML-based config.
diag "Running with XML config.";
TestUtil::run_state_tests($factory);

