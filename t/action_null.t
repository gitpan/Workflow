# -*-perl-*-

# $Id: action_null.t,v 1.1 2004/12/09 16:02:44 cwinters Exp $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Action::Null' );
