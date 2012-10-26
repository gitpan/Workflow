# -*-perl-*-

# $Id: condition_evaluate.t 540 2012-10-25 16:19:57Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

my $wf;

require_ok( 'Workflow::Condition::Evaluate' );

#ok(my $condition = Workflow::Condition::Evaluate->new( test => '' ));

#isa_ok($condition, 'Workflow::Condition::Evaluate');

#ok($condition->evaluate($wf));
