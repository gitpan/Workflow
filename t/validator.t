# -*-perl-*-

# $Id: validator.t 540 2012-10-25 16:19:57Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
