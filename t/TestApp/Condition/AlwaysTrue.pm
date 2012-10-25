package TestApp::Condition::AlwaysTrue;

# $Id: AlwaysTrue.pm 539 2012-10-25 16:19:14Z jonasbn $

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
