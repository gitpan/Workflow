# -*-perl-*-

# $Id: workflow.t,v 1.2 2004/05/25 00:19:21 cwinters Exp $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Condition::Evaluate' );
