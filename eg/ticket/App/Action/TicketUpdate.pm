package App::Action::TicketUpdate;

# $Id: TicketUpdate.pm,v 1.4 2004/10/11 22:22:26 cwinters Exp $

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );
use Workflow::History;

$App::Action::TicketUpdate::VERSION  = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $ticket = $wf->context->param( 'ticket' );
    $ticket->status( $wf->state );
    $ticket->update;

    my $current_user = $wf->context->param( 'current_user' );
    $wf->add_history(
        Workflow::History->new({
            action      => 'Ticket update',
            description => sprintf( 'Ticket updated by %s', $current_user ),
            user        => $current_user,
        })
    );
    $log->info( "History record added to workflow ok" );
}

1;
