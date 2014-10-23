package Workflow::Factory;

# $Id: Factory.pm,v 1.16 2005/11/30 03:10:52 cwinters Exp $

use strict;
use base qw( Workflow::Base );
use DateTime;
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error workflow_error );

$Workflow::Factory::VERSION  = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

my ( $log );
my ( %INSTANCES );

sub import {
    my $class = shift;
    $log ||= get_logger();

    $class = ref $class || $class; # just in case
    my $package = caller;

    if ( $_[0] eq 'FACTORY' ) {
        $log->is_debug &&
            $log->debug( "Trying to import 'FACTORY' of type '$class' to '$package'" );
        shift;
        my $instance = _initialize_instance( $class );

        my $import_target = $package . '::FACTORY';
        no strict 'refs';
        unless ( defined &{ $import_target } ) {
            $log->is_debug &&
                $log->debug( "Target '$import_target' not yet defined, ",
                             "creating subroutine on the fly" );
            *{ $import_target } = sub { return $instance };
        }
        return $instance;
    }
    $class->SUPER::import( @_ );
}

require Workflow;
require Workflow::Action;
require Workflow::Condition;
require Workflow::Config;
require Workflow::Context;
require Workflow::History;
require Workflow::Persister;
require Workflow::State;
require Workflow::Validator;

my $INITIAL_STATE = 'INITIAL';

my @FIELDS = qw();
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my $class = ref $_[0] || $_[0];
    workflow_error
        "Please call 'instance()' or import the 'FACTORY' object ",
        "to get the '$class' object rather than instantiating a ",
        "new one directly."
}

sub instance {
    my $class = ref $_[0] || $_[0];
    return _initialize_instance( $class );
}

sub _initialize_instance {
    my ( $class ) = @_;
    unless ( $INSTANCES{ $class } ) {
        $log->is_debug &&
            $log->debug( "Creating empty instance of '$class' factory for ",
                         "singleton use" );
        $INSTANCES{ $class } = bless( {} => $class );
    }
    return $INSTANCES{ $class };
}

my %CONFIG = ( 'Workflow::Config' => 1 );

sub add_config_from_file {
    my ( $self, %params ) = @_;
    return unless ( scalar keys %params );

    $log ||= get_logger();

    _check_config_keys( %params );

    foreach my $type ( sort keys %params ) {
        $log->is_debug &&
            $log->debug( "Using '$type' configuration file(s): ",
                         join( ', ', _flatten( $params{ $type } ) ) );
    }

    $log->is_debug &&
        $log->debug( "Adding condition configurations..." );
    $self->_add_condition_config(
        Workflow::Config->parse_all_files( 'condition', $params{condition} )
    );

    $log->is_debug &&
        $log->debug( "Adding validator configurations..." );
    $self->_add_validator_config(
        Workflow::Config->parse_all_files( 'validator', $params{validator} )
    );

    $log->is_debug &&
        $log->debug( "Adding persister configurations..." );
    $self->_add_persister_config(
        Workflow::Config->parse_all_files( 'persister', $params{persister} )
    );

    $log->is_debug &&
        $log->debug( "Adding action configurations..." );
    $self->_add_action_config(
        Workflow::Config->parse_all_files( 'action', $params{action} )
    );

    $log->is_debug &&
        $log->debug( "Adding workflow configurations..." );
    $self->_add_workflow_config(
        Workflow::Config->parse_all_files( 'workflow', $params{workflow} )
    );
    return;
}

sub add_config {
    my ( $self, %params ) = @_;
    return unless ( scalar keys %params );
    _check_config_keys( %params );
    $self->_add_condition_config( _flatten( $params{condition} ) );
    $self->_add_validator_config( _flatten( $params{validator} ) );
    $self->_add_persister_config( _flatten( $params{persister} ) );
    $self->_add_action_config( _flatten( $params{action} ) );
    $self->_add_workflow_config( _flatten( $params{workflow} ) );
    return;
}

sub _check_config_keys {
    my ( %params ) = @_;
    my @bad_keys = grep { ! Workflow::Config->is_valid_config_type( $_ ) } keys %params;
    if ( scalar @bad_keys ) {
        workflow_error "You tried to add configuration information to the ",
                       "workflow factory with one or more bad keys: ",
                       join( ', ', @bad_keys ), ". The following are the ",
                       "keys you have to choose from: ",
                       join( ', ', Workflow::Config->get_valid_config_types ), '.';
    }
}

sub _flatten {
    my ( $item ) = @_;
    return ( ref $item eq 'ARRAY' ) ? @{ $item } : ( $item );
}

########################################
# WORKFLOW

sub _add_workflow_config {
    my ( $self, @all_workflow_config ) = @_;
    return unless ( scalar @all_workflow_config );
    $log ||= get_logger();

    foreach my $workflow_config ( @all_workflow_config ) {
        next unless ( ref $workflow_config eq 'HASH' );
        my $wf_type = $workflow_config->{type};
        $self->{_workflow_config}{ $wf_type } = $workflow_config;

        # Create Workflow::State objects for each configured state.
        # When we instantiate a new workflow we pass these objects

        foreach my $state_conf ( @{ $workflow_config->{state} } ) {
            my $wf_state = Workflow::State->new( $state_conf );
            push @{ $self->{_workflow_state}{ $wf_type } }, $wf_state;
        }

        $log->is_info &&
            $log->info( "Added all workflow states..." );

        $self->_load_observers( $workflow_config );
        $log->is_info &&
            $log->info( "Added all workflow observers..." );
    }
}

# Load all the observers so they're available when we instantiate the
# workflow

sub _load_observers {
    my ( $self, $workflow_config ) = @_;
    my $wf_type = $workflow_config->{type};
    my $observer_specs = $workflow_config->{observer} || [];
    my @observers = ();
    foreach my $observer_info ( @{ $observer_specs } ) {
        if ( my $observer_class = $observer_info->{class} ) {
            $self->_load_class( $observer_class,
                    "Cannot require observer '%s' to watch observer " .
                    "of type '$wf_type': %s" );
            push @observers, $observer_class;
        }
        elsif ( my $observer_sub = $observer_info->{sub} ) {
            my ( $observer_class, $observer_sub ) = $observer_sub =~ /^(.*)::(.*)$/;
            $self->_load_class( $observer_class,
                    "Cannot require observer '%s' with sub '$observer_sub' to " .
                    "watch observer of type '$wf_type': %s" );
            my ( $o_sub );
            eval {
                no strict 'refs';
                $o_sub = \&{ $observer_class . '::' . $observer_sub };
            };
            if ( $@ or ref( $o_sub ) ne 'CODE' ) {
                my $error = $@ || 'subroutine not found';
                $log->error( "Error loading subroutine '$observer_sub' in ",
                             "class '$observer_class': $error" );
                workflow_error $error;
            }
            push @observers, $o_sub;
        }
        else {
            workflow_error "Cannot add observer to '$wf_type': you must ",
                           "have either 'class' or 'sub' defined. (See ",
                           "Workflow::Factory docs for details.)";
        }
    }
    $log->is_info &&
        $log->info( "Added observers to '$wf_type': ",
                    join( ', ', @observers ) );
    $self->{_workflow_observers}{ $wf_type } = ( scalar @observers )
                                                 ? \@observers : undef;
}

sub _load_class {
    my ( $self, $class_to_load, $msg ) = @_;
    eval "require $class_to_load";
    if ( $@ ) {
        my $full_msg = sprintf( $msg, $class_to_load, $@ );
        $log->error( $full_msg );
        workflow_error $full_msg;
    }

}

sub create_workflow {
    my ( $self, $wf_type ) = @_;
    $log ||= get_logger();

    my $wf_config = $self->_get_workflow_config( $wf_type );
    unless ( $wf_config ) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $wf = Workflow->new( undef,
                            $INITIAL_STATE,
                            $wf_config,
                            $self->{_workflow_state}{ $wf_type } );
    $wf->context( Workflow::Context->new );
    $wf->last_update( DateTime->now );
    $log->is_info &&
        $log->info( "Instantiated workflow object properly, persisting..." );
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id = $persister->create_workflow( $wf );
    $wf->id( $id );
    $log->is_info &&
        $log->info( "Persisted workflow with ID '$id'; creating history..." );
    $persister->create_history(
        $wf, Workflow::History->new({
            workflow_id => $id,
            action      => 'Create workflow',
            description => 'Create new workflow',
            user        => 'n/a',
            state       => $wf->state,
            date        => DateTime->now,
        })
    );
    $log->is_info && $log->info( "Created history object ok" );

    $self->associate_observers_with_workflow( $wf );
    $wf->notify_observers( 'create' );

    return $wf;
}

sub fetch_workflow {
    my ( $self, $wf_type, $wf_id ) = @_;
    $log ||= get_logger();

    my $wf_config = $self->_get_workflow_config( $wf_type );
    unless ( $wf_config ) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $wf_info = $persister->fetch_workflow( $wf_id );
    return undef unless ( $wf_info );
    $wf_info->{last_update} ||= '';
    $log->is_debug &&
        $log->debug( "Fetched data for workflow '$wf_id' ok: ",
                     "[State: $wf_info->{state}] ",
                     "[Last update: $wf_info->{last_update}]" );
    my $wf = Workflow->new( $wf_id,
                            $wf_info->{state},
                            $wf_config,
                            $self->{_workflow_state}{ $wf_type } );
    $wf->context( Workflow::Context->new );
    $wf->last_update( $wf_info->{last_update} );

    $persister->fetch_extra_workflow_data( $wf );

    $self->associate_observers_with_workflow( $wf );
    $wf->notify_observers( 'fetch' );

    return $wf;
}

sub associate_observers_with_workflow {
    my ( $self, $wf ) = @_;
    my $observers = $self->{_workflow_observers}{ $wf->type };
    return unless ( ref $observers eq 'ARRAY' );
    $wf->add_observer( $_ ) for ( @{ $observers } );
}

sub _get_workflow_config {
    my ( $self, $wf_type ) = @_;
    return $self->{_workflow_config}{ $wf_type };
}

sub _insert_workflow {
    my ( $self, $wf ) = @_;
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id = $persister->create_workflow( $wf );
    $wf->id( $id );
    return $wf;

}

sub save_workflow {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();

    my $old_update = $wf->last_update;
    $wf->last_update( DateTime->now );

    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    eval {
        $persister->update_workflow( $wf );
        $log->is_info &&
            $log->info( "Workflow '", $wf->id, "' updated ok" );
        my @unsaved = $wf->get_unsaved_history;
        foreach my $h ( @unsaved ) {
            $h->set_new_state( $wf->state );
        }
        $persister->create_history( $wf, @unsaved );
        $log->is_info &&
            $log->info( "Created necessary history objects ok" );
    };
    if ( $@ ) {
        $wf->last_update( $old_update );
        die $@;
    }

    $wf->notify_observers( 'save' );

    return $wf;
}

sub get_workflow_history {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    $log->is_debug &&
        $log->debug( "Trying to fetch history for workflow ", $wf->id );
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    return $persister->fetch_history( $wf );
}


########################################
# ACTIONS

sub _add_action_config {
    my ( $self, @all_action_config ) = @_;
    $log ||= get_logger();
    return unless ( scalar @all_action_config );

    foreach my $action_config ( @all_action_config ) {
        next unless ( ref $action_config eq 'HASH' );
        my $name = $action_config->{name};
        $log->is_debug &&
            $log->debug( "Adding configuration for action '$name'" );
        $self->{_action_config}{ $name } = $action_config;
        my $action_class = $action_config->{class};
        unless ( $action_class ) {
            configuration_error "Action '$name' must be associated with a ",
                                "class using the 'class' attribute."
        }
        $log->is_debug &&
            $log->debug( "Trying to include action class '$action_class'..." );
        eval "require $action_class";
        if ( $@ ) {
            configuration_error "Cannot include action class '$action_class': $@";
        }
        $log->is_debug &&
            $log->debug( "Included action '$name' class '$action_class' ok" );
    }
}

sub get_action {
    my ( $self, $wf, $action_name ) = @_;
    my $config = $self->{_action_config}{ $action_name };
    unless ( $config ) {
        workflow_error "No action with name '$action_name' available";
    }
    my $action_class = $config->{class};
    return $action_class->new( $wf, $config );
}


########################################
# PERSISTERS

sub _add_persister_config {
    my ( $self, @all_persister_config ) = @_;
    $log ||= get_logger();
    return unless ( scalar @all_persister_config );

    foreach my $persister_config ( @all_persister_config ) {
        next unless ( ref $persister_config eq 'HASH' );
        my $name = $persister_config->{name};
        $log->is_debug &&
            $log->debug( "Adding configuration for persister '$name'" );
        $self->{_persister_config}{ $name } = $persister_config;
        my $persister_class = $persister_config->{class};
        unless ( $persister_class ) {
            configuration_error "You must specify a 'class' in persister ",
                                "'$name' configuration";
        }
        $log->is_debug &&
            $log->debug( "Trying to include persister class '$persister_class'..." );
        eval "require $persister_class";
        if ( $@ ) {
            configuration_error "Cannot include persister class ",
                                "'$persister_class': $@";
        }
        $log->is_debug &&
            $log->debug( "Included persister '$name' class '$persister_class' ",
                         "ok; now try to instantiate persister..." );
        my $persister = eval { $persister_class->new( $persister_config ) };
        if ( $@ ) {
            configuration_error "Failed to create instance of persister ",
                                "'$name' of class '$persister_class': $@";
        }
        $self->{_persister}{ $name } = $persister;
        $log->is_debug &&
            $log->debug( "Instantiated persister '$name' ok" );
    }
}

sub get_persister {
    my ( $self, $persister_name ) = @_;
    my $persister = $self->{_persister}{ $persister_name };
    unless ( $persister ) {
        workflow_error "No persister with name '$persister_name' available";
    }
    return $persister;
}


########################################
# CONDITIONS

sub _add_condition_config {
    my ( $self, @all_condition_config ) = @_;
    return unless ( scalar @all_condition_config );
    $log ||= get_logger();

    foreach my $condition_config ( @all_condition_config ) {
        next unless ( ref $condition_config eq 'HASH' );
        my $name = $condition_config->{name};
        $log->is_debug &&
            $log->debug( "Adding configuration for condition '$name'" );
        $self->{_condition_config}{ $name } = $condition_config;
        my $condition_class = $condition_config->{class};
        unless ( $condition_class ) {
            configuration_error "Condition '$name' must be associated ",
                                "with a class using the 'class' attribute";
        }
        $log->is_debug &&
            $log->debug( "Trying to include condition class '$condition_class'" );
        eval "require $condition_class";
        if ( $@ ) {
            configuration_error "Cannot include condition class ",
                                "'$condition_class': $@";
        }
        $log->is_debug &&
            $log->debug( "Included condition '$name' class '$condition_class' ",
                         "ok; now try to instantiate condition..." );
        my $condition = eval { $condition_class->new( $condition_config ) };
        if ( $@ ) {
            configuration_error "Cannot create condition '$name': $@";
        }
        $self->{_conditions}{ $name } = $condition;
        $log->is_debug &&
            $log->debug( "Instantiated condition '$name' ok" );
    }
}

sub get_condition {
    my ( $self, $name ) = @_;
    unless ( $self->{_conditions}{ $name } ) {
        workflow_error "No condition with name '$name' available";
    }
    return $self->{_conditions}{ $name };
}


########################################
# VALIDATORS

sub _add_validator_config {
    my ( $self, @all_validator_config ) = @_;
    return unless ( @all_validator_config );
    $log ||= get_logger();

    foreach my $validator_config ( @all_validator_config ) {
        next unless ( ref $validator_config eq 'HASH' );
        my $name = $validator_config->{name};
        $log->is_debug &&
            $log->debug( "Adding configuration for validator '$name'" );
        $self->{_validator_config}{ $name } = $validator_config;
        my $validator_class = $validator_config->{class};
        unless ( $validator_class ) {
            configuration_error "Validator '$name' must be associated with ",
                                "a class using the 'class' attribute."
        }
        $log->is_debug &&
            $log->debug( "Trying to include validator class '$validator_class'" );
        eval "require $validator_class";
        if ( $@ ) {
            workflow_error "Cannot include validator class '$validator_class': $@";
        }
        $log->is_debug &&
            $log->debug( "Included validator '$name' class '$validator_class' ",
                         " ok; now try to instantiate validator..." );
        my $validator = eval { $validator_class->new( $validator_config ) };
        if ( $@ ) {
            workflow_error "Cannot create validator '$name': $@";
        }
        $self->{_validators}{ $name } = $validator;
        $log->is_debug &&
            $log->debug( "Instantiated validator '$name' ok" );
    }
}

sub get_validator {
    my ( $self, $name ) = @_;
    unless ( $self->{_validators}{ $name } ) {
        workflow_error "No validator with name '$name' available";
    }
    return $self->{_validators}{ $name };
}

1;

__END__

=head1 NAME

Workflow::Factory - Generates new workflow and supporting objects

=head1 SYNOPSIS

 # Import the singleton for easy access
 use Workflow::Factory qw( FACTORY );
 
 # Add XML configurations to the factory
 FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                                action    => [ 'myactions.xml', 'otheractions.xml' ],
                                validator => [ 'validator.xml', 'myvalidators.xml' ],
                                condition => 'condition.xml',
                                persister => 'persister.xml' );
 
 # Create a new workflow of type 'MyWorkflow'
 my $wf = FACTORY->create_workflow( 'MyWorkflow' );
 
 # Fetch an existing workflow with ID '25'
 my $wf = FACTORY->fetch_workflow( 'MyWorkflow', 25 );

=head1 DESCRIPTION

=head2 Public

The Workflow Factory is your primary interface to the workflow
system. You give it the configuration files and/or data structures for
the L<Workflow>, L<Workflow::Action>, L<Workflow::Condition>,
L<Workflow::Persister>, and L<Workflow::Validator> objects and then
you ask it for new and existing L<Workflow> objects.

=head2 Internal

Developers using the workflow system should be familiar with how the
factory processes configurations and how it makes the various
components of the system are instantiated and stored in the factory.

=head1 METHODS

=head2 Public Methods

B<instance()>

The factory is a singleton, this is how you get access to the
instance. You can also just import the 'FACTORY' constant as in the
L<SYNOPSIS>.

B<create_workflow( $workflow_type )>

Create a new workflow of type C<$workflow_type>. This will create a
new record in whatever persistence mechanism you have associated with
C<$workflow_type> and set the workflow to its initial state.

Any observers you've associated with this workflow type will be
attached to the returned workflow object.

This fires a 'create' event from the just-created workflow object. See
C<WORKFLOWS ARE OBSERVABLE> in L<Workflow> for more.

Returns: newly created workflow object.

B<fetch_workflow( $workflow_type, $workflow_id )>

Retrieve a workflow object of type C<$workflow_type> and ID
C<$workflow_id>. (The C<$workflow_type> is necessary so we can fetch
the workflow using the correct persister.) If a workflow with ID
C<$workflow_id> is not found C<undef> is returned.

Any observers you've associated with this workflow type will be
attached to the returned workflow object.

This fires a 'fetch' event from the retrieved workflow object. See
C<WORKFLOWS ARE OBSERVABLE> in L<Workflow> for more.

Throws exception if no workflow type C<$workflow_type> available.

Returns: L<Workflow> object

B<add_config_from_file( %config_declarations )>

Pass in filenames for the various components you wish to initialize
using the keys 'action', 'condition', 'persister', 'validator' and
'workflow'. The value for each can be a single filename or an arrayref
of filenames.

The system is familiar with the 'perl' and 'xml' configuration formats
-- see the 'doc/configuration.txt' for what we expect as the format
and will autodetect the types based on the file extension of each
file. Just give your file the right extension and it will be read in
properly.

You may also use your own custom configuration file format -- see
C<SUBCLASSING> in L<Workflow::Config> for what you need to do.

You can also read it in yourself and add the resulting hash reference
directly to the factory using C<add_config()>. However, you need to
ensure the configurations are added in the proper order -- when you
add an 'action' configuration and reference 'validator' objects, those
objects should already be read in. A good order is: 'validator',
'condition', 'action', 'workflow'. Then just pass the resulting hash
references to C<add_config()> using the right type and the behavior
should be exactly the same.

Returns: nothing; if we run into a problem parsing one of the files or
creating the objects it requires we throw a L<Workflow::Exception>.

B<add_config( %config_hashrefs )>

Similar to C<add_config_from_file()> -- the keys may be 'action',
'condition', 'persister', 'validator' and/or 'workflow'. But the
values are the actual configuration hashrefs instead of the files
holding the configurations.

You normally will only need to call this if you are programmatically
creating configurations (e.g., hot-deploying a validator class
specified by a user) or using a custom configuration format and for
some reason do not want to use the built-in mechanism in
L<Workflow::Config> to read it for you.

Returns: nothing; if we encounter an error trying to create the
objects referenced in a configuration we throw a
L<Workflow::Exception>.

=head2 Internal Methods

B<save_workflow( $workflow )>

Stores the state and current datetime of the C<$workflow> object. This
is normally called only from the L<Workflow> C<execute_action()>
method.

Returns: C<$workflow>

B<get_workflow_history( $workflow )>

Retrieves all L<Workflow::History> objects related to C<$workflow>.

B<NOTE>: Normal users get the history objects from the L<Workflow>
object itself. Under the covers it calls this.

Returns: list of L<Workflow::History> objects

B<get_action( $workflow, $action_name )>

Retrieves the action C<$action_name> from workflow C<$workflow>. Note
that this does not do any checking as to whether the action is proper
given the state of C<$workflow> or anything like that. It is mostly an
internal method for L<Workflow> (which B<does> do checking as to the
propriety of the action) to instantiate new actions.

Throws exception if no action with name C<$action_name> available.

Returns: L<Workflow::Action> object

B<get_persister( $persister_name )>

Retrieves the persister with name C<$persister_name>.

Throws exception if no persister with name C<$persister_name>
available.

B<get_condition( $condition_name )>

Retrieves the condition with name C<$condition_name>.

Throws exception if no condition with name C<$condition_name>
available.

B<get_validator( $validator_name )>

Retrieves the validator with name C<$validator_name>.

Throws exception if no validator with name C<$validator_name>
available.

=head2 Internal Configuration Methods

B<_add_workflow_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory. Also
cycles through the workflow states and creates a L<Workflow::State>
object for each. These states are passed to the workflow when it is
instantiated.

We also require any necessary observer classes and throw an exception
if we cannot. If successful the observers are kept around and attached
to a workflow in L<create_workflow()> and L<fetch_workflow()>.

Returns: nothing

B<_add_action_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
action.

Throws an exception if there is no 'class' associated with an action
or if we cannot 'require' that class.

Returns: nothing

B<_add_persister_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
persister.

Throws an exception if there is no 'class' associated with a
persister, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

B<_add_condition_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
condition.

Throws an exception if there is no 'class' associated with a
condition, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

B<_add_validator_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
validator.

Throws an exception if there is no 'class' associated with a
validator, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

=head1 SUBCLASSING

=head2 Implementation and Usage

You can subclass the factory to implement your own methods and still
use the useful facade of the C<FACTORY> constant. For instance, the
implementation is typical Perl subclassing:

 package My::Cool::Factory;
 
 use strict;
 use base qw( Workflow::Factory );
 
 sub some_cool_method {
     my ( $self ) = @_;
     ...
 }

To use your factory you can just do the typical import:

 #!/usr/bin/perl
 
 use strict;
 use My::Cool::Factory qw( FACTORY );

Or you can call C<instance()> directly:

 #!/usr/bin/perl
 
 use strict;
 use My::Cool::Factory;
 
 my $factory = My::Cool::Factory->instance();

=head1 SEE ALSO

L<Workflow>

L<Workflow::Action>

L<Workflow::Condition>

L<Workflow::Config>

L<Workflow::Persister>

L<Workflow::Validator>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
