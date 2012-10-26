package TestApp::Action::TicketUpdate;

# $Id: TicketUpdate.pm 540 2012-10-25 16:19:57Z jonasbn $

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$TestApp::Action::TicketUpdate::VERSION = '1.05';

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $ticket = $wf->context->param( 'ticket' );
    $ticket->status( $wf->state );
    $ticket->update;
}

1;
