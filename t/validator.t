# -*-perl-*-

# $Id: validator.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
