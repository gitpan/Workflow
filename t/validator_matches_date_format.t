# -*-perl-*-

# $Id: validator_matches_date_format.t 294 2007-06-19 21:07:00Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More tests => 4;

require_ok( 'Workflow::Validator::MatchesDateFormat' );

my $validator;

dies_ok { $validator = Workflow::Validator::MatchesDateFormat->new({}) };

ok($validator = Workflow::Validator::MatchesDateFormat->new({
    date_format => '%Y-%m-%d',
}));

isa_ok($validator, 'Workflow::Validator');
