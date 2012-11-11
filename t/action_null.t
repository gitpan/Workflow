# -*-perl-*-

# $Id: action_null.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Null' );

ok(! Workflow::Action::Null->execute());
