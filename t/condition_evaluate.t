# -*-perl-*-

# $Id: condition_evaluate.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

my $wf;

require_ok( 'Workflow::Condition::Evaluate' );

#ok(my $condition = Workflow::Condition::Evaluate->new( test => '' ));

#isa_ok($condition, 'Workflow::Condition::Evaluate');

#ok($condition->evaluate($wf));
