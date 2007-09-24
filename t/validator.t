# -*-perl-*-

# $Id: validator.t 330 2007-08-12 11:01:58Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
