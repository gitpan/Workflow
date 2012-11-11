# -*-perl-*-

# $Id: validator_has_required_field.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Validator::HasRequiredField' );
