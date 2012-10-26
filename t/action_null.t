# -*-perl-*-

# $Id: action_null.t 540 2012-10-25 16:19:57Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Null' );

ok(! Workflow::Action::Null->execute());
