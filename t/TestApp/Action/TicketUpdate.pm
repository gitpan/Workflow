package TestApp::Action::TicketUpdate;

# $Id: TicketUpdate.pm,v 1.1 2004/01/10 05:15:02 cwinters Exp $

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$TestApp::Action::TicketUpdate::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $ticket = $wf->context->param( 'ticket' );
    $ticket->status( $wf->state );
    $ticket->update;
}

1;
