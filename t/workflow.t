# -*-perl-*-

# $Id: workflow.t 284 2007-06-01 20:16:19Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
} else {
	plan tests => 32;
}

require_ok( 'Workflow' );

my $factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

my $persister = $factory->get_persister( 'TestPersister' );
my $handle = $persister->handle;

# add a separate configuration for the observed workflow

eval {
    $factory->add_config_from_file( workflow => 'workflow_observer.xml' )
};
$@ && diag( "Error: $@" );
ok( ! $@, "Added configuration for workflow with observer" );

{
    SomeObserver->clear_observations;
    my $wf = $factory->create_workflow( 'ObservedTicket' );
    my @observations = SomeObserver->get_observations;
    is( scalar @observations, 2,
        'One observation sent on workflow create to two observers' );

    is( $observations[0]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[0]->[2], 'create',
        'Class observer sent the correct create action' );

    is( $observations[1]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[1]->[2], 'create',
        'Subroutine observer sent the correct create action' );
}

my $date = DateTime->now;
my @result_fields = ( 'state',   'last_update' );
my @result_data   = ( 'INITIAL', $date );

{
    $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];

    SomeObserver->clear_observations;
    my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
    my @observations = SomeObserver->get_observations;

    is( scalar @observations, 2,
        'One observation sent on workflow fetch to two observers' );

    is( $observations[0]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[0]->[2], 'fetch',
        'Class observer sent the correct fetch action' );

    is( $observations[1]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[1]->[2], 'fetch',
        'Subroutine observer sent the correct fetch action' );
}

{
    $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];
    my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
    SomeObserver->clear_observations;

    $factory->save_workflow( $wf );
    my @observations = SomeObserver->get_observations;
    is( scalar @observations, 2,
        'One observation sent on workflow store to two observers' );

    is( $observations[0]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[0]->[2], 'save',
        'Class observer sent the correct save action' );

    is( $observations[1]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[1]->[2], 'save',
        'Subroutine observer sent the correct save action' );
}

{
    $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];
    my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
    SomeObserver->clear_observations;
    $wf->execute_action( 'null' );
    my @observations = SomeObserver->get_observations;
    is( scalar @observations, 6,
        'Three observations sent on workflow execute to two observers' );

    is( $observations[0]->[2], 'save',
        'Save observation generated first to first observer' );
    is( $observations[1]->[2], 'save',
        'Save observation generated first to second observer' );

    is( $observations[2]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[2]->[2], 'execute',
        'Class observer sent the correct execute action' );
    is( $observations[2]->[3], 'INITIAL',
        'Class observer sent the correct old state for execute' );

    is( $observations[3]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[3]->[2], 'execute',
        'Subroutine observer sent the correct execute action' );
    is( $observations[3]->[3], 'INITIAL',
        'Subroutine observer sent the correct old state for execute' );

    is( $observations[4]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[4]->[2], 'state change',
        'Class observer sent the correct state change action' );
    is( $observations[4]->[3], 'INITIAL',
        'Class observer sent the correct old state for state change' );

    is( $observations[5]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[5]->[2], 'state change',
        'Subroutine observer sent the correct state change action' );
    is( $observations[5]->[3], 'INITIAL',
        'Subroutine observer sent the correct old state for state change' );
}
