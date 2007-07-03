# -*-perl-*-

# $Id: action.t 304 2007-07-03 14:56:43Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More  tests => 2;

require_ok( 'Workflow::Action' );

my $action;

dies_ok { $action = Workflow::Action->new({}) };

#ok($action = Workflow::Action->new({}));

#isa_ok($action, 'Workflow::Action');