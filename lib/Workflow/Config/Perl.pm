package Workflow::Config::Perl;

# $Id: Perl.pm,v 1.1 2004/09/13 02:03:09 cwinters Exp $

use strict;
use base qw( Workflow::Config );

$Workflow::Config::Perl::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

my ( $log );

sub parse {
    my ( $self, $type, @items ) = @_;
    $log ||= get_logger();

    $self->_check_config_type( $type );
    my @config_items = _expand_refs( @items );
    return () unless ( scalar @config_items );

    my @config = ();
    foreach my $item ( @config_items ) {
        my ( $file_name );
        if ( ref $item ) {
            $method = '_translate_perl';
            $file_name = '[scalar ref]';
        }

        # $item is a filename...
        else {
            $method = '_translate_perl_file';
            $file_name = $item;
        }
        $log->is_info &&
            $log->info( "Will parse '$type' Perl config file '$file_name'" );
        my $this_config = $class->$method( $type, $item );
        $log->is_info &&
            $log->info( "Parsed Perl '$file_name' ok" );
        if ( ref $this_config->{ $type } eq 'ARRAY' ) {
            $log->debug( "Adding multiple configurations for '$type'" );
            push @config, @{ $this_config->{ $type } };
        }
        else {
            $log->debug( "Adding single configuration for '$type'" );
            push @config, $this_config;
        }
    }
    return @config;
}

sub _translate_perl_file {
    my ( $class, $type, $file ) = @_;
    my $log = get_logger();

    local $/ = undef;
    open( CONF, '<', $file )
        || configuration_error "Cannot read file '$file': $!";
    my $config = <CONF>;
    close( CONF );
    my $data = $class->_translate_perl( $type, $config, $file );
    $log->is_debug &&
        $log->debug( "Translated '$type' '$file' into: ", Dumper( $data ) );
    return $data;
}

sub _translate_perl {
    my ( $class, $type, $config, $file ) = @_;
    my $log = get_logger();

    no strict 'vars';
    my $data = eval $config;
    if ( $@ ) {
        configuration_error "Cannot evaluate perl data structure ",
                            "in '$file': $@";
    }
    return $data;
}



1;

__END__

=head1 NAME

Workflow::Config::Perl - Parse workflow configurations as Perl data structures

=head1 SYNOPSIS

 # either of these is acceptable
 my $parser = Workflow::Config->new( 'perl' );
 my $parser = Workflow::Config->new( 'pl' );
 
 my $conf = $parser->parse( 'condition',
                            'my_conditions.pl', 'your_conditions.perl' );

=head1 DESCRIPTION

Implementation of configuration parser for serialized Perl data
structures from files/data. See L<Workflow::Config> for C<parse()>
description.

=head1 SEE ALSO

L<Workflow::Config>

=head1 COPYRIGHT

Copyright (c) 2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
