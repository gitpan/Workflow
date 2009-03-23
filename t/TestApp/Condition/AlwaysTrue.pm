package TestApp::Condition::AlwaysTrue;

# $Id: AlwaysTrue.pm 466 2009-03-23 12:15:31Z jonasbn $

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$TestApp::Condition::AlwaysTrue::VERSION = '0.01';

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    $log->debug( 'Condition met ok' );
}

1;
