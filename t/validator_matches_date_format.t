# -*-perl-*-

# $Id: validator_matches_date_format.t,v 1.2 2004/10/17 15:22:26 cwinters Exp $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Validator::MatchesDateFormat' );
