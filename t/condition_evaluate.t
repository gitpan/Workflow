# -*-perl-*-

# $Id: workflow.t,v 1.2 2004/05/25 00:19:21 cwinters Exp $

use strict;
use Test::More  tests => 1;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init({ level => $WARN,
                           file  => ">> workflow_tests.log" });

require_ok( 'Workflow::Condition::Evaluate' );
