# -*-perl-*-

# $Id: validator_in_enumerated_type.t 293 2007-06-19 20:50:34Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More tests => 14;

require_ok( 'Workflow::Validator::InEnumeratedType' );

my $validator;

dies_ok { $validator = Workflow::Validator::InEnumeratedType->new({}) };

ok($validator = Workflow::Validator::InEnumeratedType->new({
    value => 'test',
}));

isa_ok($validator, 'Workflow::Validator');

ok(my @enumerated_values = $validator->get_enumerated_values());

is(scalar @enumerated_values, 1);

is($enumerated_values[0], 'test');

$validator->add_enumerated_values(qw(foo bar));

ok(@enumerated_values = $validator->get_enumerated_values());

is(scalar @enumerated_values, 3);

ok($validator->is_enumerated_value('foo'));

ok(! $validator->is_enumerated_value('baz'));

ok($validator = Workflow::Validator::InEnumeratedType->new({
    value => ['test', 'foo', 'bar'],
}));

ok(@enumerated_values = $validator->get_enumerated_values());

is(scalar @enumerated_values, 3);
