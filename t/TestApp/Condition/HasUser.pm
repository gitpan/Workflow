package TestApp::Condition::HasUser;

# $Id: HasUser.pm 538 2011-01-29 17:01:04Z jonasbn $

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$TestApp::Condition::HasUser::VERSION = '0.01';

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    unless ( $wf->context->param( 'current_user' ) ) {
        condition_error "No value for 'current_user' set";
    }
    $log->debug( 'Condition met ok' );
}

1;
