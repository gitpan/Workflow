# -*-perl-*-

# $Id: action_null.t 330 2007-08-12 11:01:58Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Null' );

ok(! Workflow::Action::Null->execute());
