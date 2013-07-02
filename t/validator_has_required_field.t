# -*-perl-*-

# $Id: validator_has_required_field.t 213 2004-10-17 15:22:26Z cwinters $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Validator::HasRequiredField' );
