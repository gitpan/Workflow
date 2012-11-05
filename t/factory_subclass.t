# -*-perl-*-

# $Id: factory_subclass.t 213 2004-10-17 15:22:26Z cwinters $

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

