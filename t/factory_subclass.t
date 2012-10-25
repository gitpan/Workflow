# -*-perl-*-

# $Id: factory_subclass.t 539 2012-10-25 16:19:14Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 5;

require_ok( 'FactorySubclass' );
my $factory = FactorySubclass->instance();
is( ref( $factory ), 'FactorySubclass',
    "Return from subclassed instance() correct type" );
my $other_factory = FactorySubclass->instance();
is( $other_factory, $factory,
    'Another call to instance() returns same object' );
my $factory_new = eval { FactorySubclass->new() };
is( ref( $@ ), 'Workflow::Exception',
    'Call to new() throws proper exception' );

my $i_factory = FactorySubclass->import( 'FACTORY' );
is( $i_factory, $factory,
    'Imported factory returns the same object' );

