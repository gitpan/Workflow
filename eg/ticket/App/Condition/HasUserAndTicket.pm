package App::Condition::HasUserAndTicket;

# $Id: HasUserAndTicket.pm,v 1.2 2004/05/14 00:08:13 cwinters Exp $

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

my ( $log );

$App::Condition::HasUserAndTicket::VERSION  = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

sub evaluate {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    my $current_user = $wf->context->param( 'current_user' );
    my $ticket = $wf->context->param( 'ticket' );
    $log->info( "[Current user: $current_user] [Ticket: $ticket]" );
    unless ( $current_user and $ticket ) {
        condition_error "Values for 'current_user' and 'ticket' must be available";
    }
}

1;
