package TestApp::Condition::HasUser;

# $Id: HasUser.pm,v 1.1 2004/01/10 05:15:02 cwinters Exp $

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$TestApp::Condition::HasUser::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

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
