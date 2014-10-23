# -*-perl-*-

# $Id: factory_subclass.t,v 1.1 2004/05/24 21:17:38 cwinters Exp $

use strict;
use Test::More  tests => 5;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init({ level => $INFO,
                           file  => ">> workflow_tests.log" });

chdir 't' if ( -d 't' );
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

