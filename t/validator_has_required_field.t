# -*-perl-*-

# $Id: validator_has_required_field.t 539 2012-10-25 16:19:14Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Validator::HasRequiredField' );
