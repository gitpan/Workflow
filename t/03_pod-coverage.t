
# $Id: 03_pod-coverage.t 539 2012-10-25 16:19:14Z jonasbn $

#pod test courtesy of petdance
#http://use.perl.org/~petdance/journal/17412

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();
