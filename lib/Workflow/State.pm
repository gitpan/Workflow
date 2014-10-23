package Workflow::State;

# $Id: State.pm,v 1.8 2004/10/12 05:11:33 cwinters Exp $

use strict;
use base qw( Workflow::Base );
use Log::Log4perl       qw( get_logger );
use Workflow::Condition::Evaluate;
use Workflow::Exception qw( workflow_error );
use Workflow::Factory   qw( FACTORY );

$Workflow::State::VERSION  = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( state description );
__PACKAGE__->mk_accessors( @FIELDS );

my ( $log );

########################################
# PUBLIC

sub get_conditions {
    my ( $self, $action_name ) = @_;
    $self->_contains_action_check( $action_name );
    return @{ $self->{_conditions}{ $action_name } };
}

sub contains_action {
    my ( $self, $action_name ) = @_;
    return $self->{_actions}{ $action_name };
}

sub get_all_action_names {
    my ( $self ) = @_;
    return keys %{ $self->{_actions} };
}

sub get_available_action_names {
    my ( $self, $wf ) = @_;
    my @all_actions = $self->get_all_action_names;
    my @available_actions = ();
    foreach my $action_name ( @all_actions ) {
        if ( $self->is_action_available( $wf, $action_name ) ) {
            push @available_actions, $action_name;
        }
    }
    return @available_actions;
}

sub is_action_available {
    my ( $self, $wf, $action_name ) = @_;
    eval { $self->evaluate_action( $wf, $action_name ) };
    return ( ! $@ );
}

sub evaluate_action {
    my ( $self, $wf, $action_name ) = @_;
    $log ||= get_logger();

    my $state = $self->state;

    # NOTE: this will throw an exception if C<$action_name> is not
    # contained in this state, so there's no need to do it explicitly

    my @conditions = $self->get_conditions( $action_name );
    foreach my $condition ( @conditions ) {
        my $condition_name = $condition->name;
        $log->is_debug &&
            $log->debug( "Evaluating condition '$condition_name'" );
        eval { $condition->evaluate( $wf ) };
        if ( $@ ) {
            # TODO: We may just want to pass the error up without wrapping it...
            workflow_error "No access to action '$action_name' in ",
                           "state '$state' because: $@";
        }
        $log->is_debug &&
            $log->debug( "Condition '$condition_name' evaluated successfully" );
    }
}

sub get_next_state {
    my ( $self, $action_name, $action_return ) = @_;
    $self->_contains_action_check( $action_name );
    my $resulting_state = $self->{_actions}{ $action_name }{resulting_state};
    return $resulting_state unless ( ref( $resulting_state ) eq 'HASH' );

    if ( defined $action_return ) {
        # TODO: Throw exception if $action_return not found and no '*' defined?
        return $resulting_state->{ $action_return } || $resulting_state->{'*'};
    }
    else {
        return %{ $resulting_state };
    }
}

sub get_autorun_action_name {
    my ( $self, $wf ) = @_;
    my $state = $self->state;
    unless ( $self->autorun ) {
        workflow_error "State '$state' is not marked for automatic ",
                       "execution. If you want it to be run automatically ",
                       "set the 'autorun' property to 'yes'.";
    }
    $log ||= get_logger();

    my @actions = $self->get_available_action_names( $wf );
    my $pre_error = "State '$state' should be automatically executed but ";
    if ( scalar @actions > 1 ) {
        workflow_error "$pre_error there are multiple actions available ",
                       "for execution. Actions are: ", join( @actions, ', ' );
    }
    if ( scalar @actions == 0 ) {
        workflow_error "$pre_error there are no actions available for execution.";
    }
    $log->is_debug &&
        $log->debug( "Auto-running state '$state' with action '$actions[0]'" );
    return $actions[0];
}

sub autorun {
    my ( $self, $setting ) = @_;
    if ( defined $setting ) {
        if ( $setting =~ /^(true|1|yes)$/i ) {
            $self->{autorun} = 'yes';
        }
        else {
            $self->{autorun} = 'no';
        }
    }
    return ( $self->{autorun} eq 'yes' );
}


########################################
# INTERNAL

sub init {
    my ( $self, $config ) = @_;
    $log ||= get_logger();
    my $name = $config->{name};

    my $class = ref( $self );

    $log->is_debug &&
        $log->debug( "Constructing '$class' object for state $name" );

    $self->state( $name );
    $self->description( $config->{description} );
    if ( $config->{autorun} ) {
        $self->autorun( $config->{autorun} );
    }
    else {
        $self->autorun( 'no' );
    }
    foreach my $state_action_config ( @{ $config->{action} } ) {
        my $action_name = $state_action_config->{name};
        my $resulting = $state_action_config->{resulting_state};
        if ( my $resulting_type = ref( $resulting ) ) {
            if ( $resulting_type eq 'ARRAY' ) {
                $state_action_config->{resulting_state} =
                    $self->_assign_resulting_state_from_array( $action_name, $resulting );
            }
        }
        $log->debug( "Adding action '$action_name' to '$class' '$name'" );
        $self->_add_action_config( $action_name, $state_action_config );
    }
}

sub _assign_resulting_state_from_array {
    my ( $self, $action_name, $resulting ) = @_;
    my $name = $self->state;
    my @errors = ();
    my %new_resulting = ();
    foreach my $map ( @{ $resulting } ) {
        if ( ! $map->{state} or ! defined $map->{return} ) {
            push @errors, "Must have both 'state' ($map->{state}) and 'return' " .
                          "($map->{return}) keys defined.";
        }
        elsif ( $new_resulting{ $map->{return} } ) {
            push @errors, "The 'return' value ($map->{return}) must be " .
                          "unique among the resulting states.";
        }
        else {
            $new_resulting{ $map->{return} } = $map->{state};
        }
    }
    if ( scalar @errors ) {
        workflow_error "Errors found assigning 'resulting_state' to ",
                       "action '$action_name' in state '$name': ",
                       join( '; ', @errors );
    }
    $log->is_debug &&
        $log->debug( "Assigned multiple resulting states in '$name' and ",
                     "action '$action_name' from array ok" );
    return \%new_resulting;
}

sub _add_action_config {
    my ( $self, $action_name, $action_config ) = @_;
    $log ||= get_logger();
    my $state = $self->state;
    unless ( $action_config->{resulting_state} ) {
        my $no_change_value = Workflow->NO_CHANGE_VALUE;
        workflow_error "Action '$action_name' in state '$state' does not ",
                       "have the key 'resulting_state' defined. This key ",
                       "is required -- if you do not want the state to ",
                       "change, use the value '$no_change_value'.";
    }
    $log->is_debug &&
        $log->debug( "Adding '$state' '$action_name' config" );
    $self->{_actions}{ $action_name } = $action_config;
    my @action_conditions = $self->_create_condition_objects( $action_config );
    $self->{_conditions}{ $action_name } = \@action_conditions;
}

sub _create_condition_objects {
    my ( $self, $action_config ) = @_;
    $log ||= get_logger();
    my @conditions = $self->normalize_array( $action_config->{condition} );
    my @condition_objects = ();
    foreach my $condition_info ( @conditions ) {

        # Special case: a 'test' denotes our 'evaluate' condition
        if ( $condition_info->{test} ) {
            push @condition_objects, Workflow::Condition::Evaluate->new({
                name  => 'evaluate',
                class => 'Workflow::Condition::Evaluate',
                test  => $condition_info->{test},
            });
        }
        else {
            $log->is_info &&
                $log->info( "Fetching condition '$condition_info->{name}'" );
            push @condition_objects, FACTORY->get_condition( $condition_info->{name} );
        }
    }
    return @condition_objects;
}

sub _contains_action_check {
    my ( $self, $action_name ) = @_;
    unless ( $self->contains_action( $action_name ) ) {
        workflow_error "State '", $self->state, "' does not contain ",
                       "action '$action_name'"
    }
}

1;

__END__

=head1 NAME

Workflow::State - Information about an individual state in a workflow

=head1 SYNOPSIS

 # This is an internal object...
 <workflow...>
   <state name="Start">
     <action ... resulting_state="Progress" />
   </state>
      ...
   <state name="Progress" description="I am in progress">
     <action ... >
        <resulting_state return="0" state="Needs Affirmation" />
        <resulting_state return="1" state="Approved" />
        <resulting_state return="*" state="Needs More Info" />
     </action>
   </state>
      ...
   <state name="Approved" autorun="yes">
     <action ... resulting_state="Completed" />
      ...

=head1 DESCRIPTION

Each L<Workflow::State> object represents a state in a workflow. Each
state can report its name, description and all available
actions. Given the name of an action it can also report what
conditions are attached to the action and what state will result from
the action (the 'resulting state').

=head2 Resulting State

The resulting state is action-dependent. For instance, in the
following example you can perform two actions from the state 'Ticket
Created' -- 'add comment' and 'edit issue':

  <state name="Ticket Created">
     <action name="add comment"
             resulting_state="NOCHANGE" />
     <action name="edit issue"
             resulting_state="Ticket In Progress" />
   </state>

If you execute 'add comment' the new state of the workflow will be the
same ('NOCHANGE' is a special state). But if you execute 'edit issue'
the new state will be 'Ticket In Progress'.

You can also have multiple return states for a single action. The one
chosen by the workflow system will depend on what the action
returns. For instance we might have something like:

  <state name="create user">
     <action name="create">
         <resulting_state return="admin"    state="Assign as Admin" />
         <resulting_state return="helpdesk" state="Assign as Helpdesk" />
         <resulting_state return="*"        state="Assign as Luser" />
     </action>
   </state>

So if we execute 'create' the workflow will be in one of three states:
'Assign as Admin' if the return value of the 'create' action is
'admin', 'Assign as Helpdesk' if the return is 'helpdesk', and 'Assign
as Luser' if the return is anything else.

=head2 Autorun State

You can also indicate that the state should be automatically executed
when the workflow enters it using the 'autorun' property. Note the
slight change in terminology -- typically we talk about executing an
action, not a state. But we can use both here because an automatically
run state requires that one and only one action is available for
running. That doesn't mean a state contains only one action. It just
means that only one action is available when the state is entered. For
example, you might have two actions with mutually exclusive conditions
within the autorun state.

=head1 PUBLIC METHODS

B<get_conditions( $action_name )>

Returns a list of L<Workflow::Condition> objects for action
C<$action_name>. Throws exception if object does not contain
C<$action_name> at all.

B<contains_action( $action_name )>

Returns true if this state contains action C<$action_name>, false if
not.

B<is_action_available( $workflow, $action_name )>

Returns true if C<$action_name> is contained within this state B<and>
it matches any conditions attached to it, using the data in the
context of the C<$workflow> to do the checks.

B<evaluate_action( $workflow, $action_name )>

Throws exception if action C<$action_name> is either not contained in
this state or if it does not pass any of the attached conditions,
using the data in the context of C<$workflow> to do the checks.

B<get_all_action_names()>

Returns list of all action names available in this state.

B<get_available_action_names( $workflow )>

Returns all actions names that are available given the data in
C<$workflow>. Each action name returned will return true from
B<is_action_available()>.

B<get_next_state( $action_name, [ $action_return ] )>

Returns the state(s) that will result if action C<$action_name>
is executed. If you've specified multiple return states in the
configuration then you need to specify the C<$action_return>,
otherwise we return a hash with action return values as the keys and
the action names as the values.

B<get_autorun_action_name( $workflow )>

Retrieve the action name to be autorun for this state. If the state
does not have the 'autorun' property enabled this throws an
exception. It also throws an exception if there are multiple actions
available or if there are no actions available.

Returns name of action to be used for autorunning the state.

=head1 PROPERTIES

All property methods act as a getter and setter. For example:

 my $state_name = $state->state;
 $state->state( 'some name' );

B<state>

Name of this state (required).

B<description>

Description of this state (optional).

B<autorun>

Returns true if the state should be automatically run, false if
not. To set to true the property value should be 'yes', 'true' or 1.

=head1 INTERNAL METHODS

B<init( $config )>

Assigns 'state', 'description', and 'autorun' properties from
C<$config>. Also assigns configuration for all actions in the state,
performing some sanity checks like ensuring every action has a
'resulting_state' key.

=head1 SEE ALSO

L<Workflow>

L<Workflow::Condition>

L<Workflow::Factory>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
