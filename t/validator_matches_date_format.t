# -*-perl-*-

# $Id: validator_matches_date_format.t 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use DateTime;
use Test::More tests => 6;

require_ok( 'Workflow::Validator::MatchesDateFormat' );

my $validator;
my $wf;

dies_ok { $validator = Workflow::Validator::MatchesDateFormat->new({}) };

ok($validator = Workflow::Validator::MatchesDateFormat->new({
    date_format => '%Y-%m-%d',
}));

isa_ok($validator, 'Workflow::Validator');

ok($validator->validate($wf, '2005-05-13'));

my $dt = DateTime->new( year   => 1964,
                     month  => 10,
                     day    => 16,
                     hour   => 16,
                     minute => 12,
                     second => 47,
                     nanosecond => 500000000,
                     time_zone => 'Asia/Taipei',
                   );
         
lives_ok { $validator->validate($wf, $dt) };

