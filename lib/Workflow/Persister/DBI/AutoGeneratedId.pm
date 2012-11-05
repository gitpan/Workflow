package Workflow::Persister::DBI::AutoGeneratedId;

# $Id: AutoGeneratedId.pm 454 2009-01-12 10:04:02Z jonasbn $

use warnings;
use strict;
use base qw( Class::Accessor );
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error );

$Workflow::Persister::DBI::AutoGeneratedId::VERSION = '1.06';

my @FIELDS = qw( from_handle handle_property func_property );
__PACKAGE__->mk_accessors(@FIELDS);

sub new {
    my ( $class, $params ) = @_;
    my $log = get_logger();

    my $self = bless {}, $class;
    for (@FIELDS) {
        $self->$_( $params->{$_} ) if ( $params->{$_} );
    }
    if ( my $handle_type = $self->from_handle ) {
        unless ( $handle_type =~ /^(database|statement)$/ ) {
            configuration_error "Parameter 'from_handle' must be 'database' ",
                "or 'statement' (Given: '$handle_type')";
        }
        unless ( $self->handle_property ) {
            configuration_error "If you specify 'from_handle' you must ",
                "specify a value for 'handle_property'";
        }
        $log->is_debug
            && $log->debug( "Using '", $self->handle_property, "' from ", "'",
            $self->from_handle, "' for ID generator" );
    } elsif ( !$self->func_property ) {
        configuration_error "If you do not specify a value in 'from_handle' ",
            "you must specify a value for 'func_property'";
    } else {
        $log->is_debug
            && $log->debug( "Using database func() property '",
            $self->func_property, "' for ID generator" );
    }
    return $self;
}

sub pre_fetch_id {return}

sub post_fetch_id {
    my ( $self, $dbh, $sth ) = @_;
    my $from_handle = $self->from_handle;
    if ( $from_handle eq 'database' ) {
        return $dbh->{ $self->handle_property };
    } elsif ( $from_handle eq 'statement' ) {
        return $sth->{ $self->handle_property };
    } elsif ( my $func_property = $self->func_property ) {
        return $dbh->func($func_property);
    }
}

1;

__END__

=head1 NAME

Workflow::Persister::DBI::AutoGeneratedId - Pull IDs from databases that autogenerate them

=head1 VERSION

This documentation describes version 1.06 of this package

=head1 SYNOPSIS

 <persister name="MyPersister"
            dsn="DBI:mysql:database=foo"
            ...

=head1 DESCRIPTION

Be able to pull an ID from a database or statement handle, or call a
DBI function to get the value.

=head2 Properties

B<from_handle>

If you want to pull the value from a handle specify either 'database'
or 'statement' to specify what handle to pull it from. You must also
specify a value for 'handle_property'. For example, if you are using
MySQL this would be 'database'.

B<handle_property>

Property to pull from handle specified in 'from_handle'. For example,
if you are using MySQL this would be 'mysql_insertid'.

B<func_property>

Property to pass to the DBI 'func()' call to return the ID value. For
example, if you are using SQLite this would be 'last_insert_rowid'.

=head2 METHODS

=head3 new ( \%params )

This method instantiates a class for retrieval of auto-generated ids from a
L<DBI> based persistance entity.

It takes a hashref containing keys matching the properties outlines in the
section above or throws L<Workflow::Exception>s if these are not defined.

Returns instantiated object upon success.

=head3 pre_fetch_id

This is a I<dummy> method, use L</post_fetch_id>

=head3 post_fetch_id

Returns a unique sequence id from a database.

Takes a two parameters, a L<DBI> database handle and a statement handle

Returns a single value, a integer representing a sequence id from the provided
database handle, based on the statement handle.

=head1 COPYRIGHT

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
