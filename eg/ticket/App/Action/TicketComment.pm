package App::Action::TicketComment;

# $Id: TicketComment.pm,v 1.3 2004/10/11 22:22:26 cwinters Exp $

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$App::Action::TicketComment::VERSION  = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

    $log->info( "Entering comment for workflow ", $wf->id );

    $wf->add_history(
        Workflow::History->new({
            action      => "Ticket comment",
            description => $wf->context->param( 'comment' ),
            user        => $wf->context->param( 'current_user' ),
        })
    );
}

1;
