package Notice::Security;
use strict;
use warnings;
our %opt; # nice to have them
use lib 'lib';
use Notice::DB;
our %__CONFIG;
#use UNIVERSAL::require;
use Carp;


our $VERSION = 0.01;

=head1 NAME

Notice::Security - watching the watchers

=head1 SYNOPSIS

    This records the actions of Notice users and inforces any ACL that are set in the database

=head1 DESCRIPTION

We don't want users slurping the database or letting leaks become floods.
This module records the users action, (how many times they have logged in, how many accounts they have viewed today...)
and can enforce any policy that is defined for Notice,their account, or even their user.

This is just a rough sketch at this time.

=head1 METHODS

=head2 new

create a new copy of this

=cut

sub new {
    my $class  = shift;
    my $name   = shift;
    my $cgiapp = shift;
    my $self   = {};

    bless $self, $class;
    $self->{name}   = $name;
    $self->{cgiapp} = $cgiapp;
    Scalar::Util::weaken( $self->{cgiapp} )
        if ref $self->{cgiapp};    # weaken circular reference

    return $self;
}


=head2 import

check that this is being imported by a CGI::Application

=cut

sub import {
    my $pkg     = shift;
    my $callpkg = caller;
    if ( !UNIVERSAL::isa( $callpkg, 'CGI::Application' ) && !UNIVERSAL::isa( $callpkg, 'Notice') ) {
        warn
            "Calling package is not Part of Notice:: module!  If you are using \@ISA instead of 'use base', make sure it is in a BEGIN { } block, and make sure these statements appear before the plugin is loaded";
    }
    else {
        $callpkg->add_callback( prerun => \&prerun_callback );
    }
}


=head2 username

This method will return the name of the currently logged in user.  It uses
three different methods to figure out the username:

=over 4

=item GET_USERNAME option

Use the subroutine provided by the GET_USERNAME option to figure out the
current username

=item CGI::Application::Plugin::Authentication

See if the L<CGI::Application::Plugin::Authentication> plugin is being used,
and retrieve the username through this plugin

=item REMOTE_USER

See if the REMOTE_USER environment variable is set and use that value

=back

=cut

sub username {
    my $self   = shift;
    warn "username:" if $opt{D}>=1;

    my $config = $self->_config;
    warn "un_a";

    if ( $config->{GET_USERNAME} ) {
        return $config->{GET_USERNAME}->($self);
    }
    elsif ( $self->cgiapp->can('authen') ) {
        return $self->cgiapp->authen->username;
    }
    else {
        return $ENV{REMOTE_USER};
    }
    warn "un_z";
}

=head2 cgiapp

This will return the underlying CGI::Application object.

=cut

sub cgiapp {
    return $_[0]->{cgiapp};
}

sub _config {
    my $self = shift;
    my $name = $self->{name};
    my $config;
    if ( ref $self->cgiapp ) {
        $config = $self->{__CAP_AUTHORIZATION_CONFIG} ||= $__CONFIG{$name}
            || {};
    }
    else {
        $__CONFIG{$name} ||= {};
        $config = $__CONFIG{$name};
    }
    return $config;
}

=head2 SUBCLASSED METHODS

=head3 config

we will need access to the database and to know which user we are dealing with, (and what they are doing.)

(thank you CGI/Application/Plugin/Authorization.pm )

=cut

sub config {
    my $self  = shift;
    my $class = ref $self;

    die
        "Calling config after the Authorization object has already been created"
        if $self->{loaded};
    my $config = $self->_config;

    if (@_) {
        my $props;
        if ( ref( $_[0] ) eq 'HASH' ) {
            my $rthash = %{ $_[0] };
            $props = CGI::Application->_cap_hash( $_[0] );
        }
        else {
            $props = CGI::Application->_cap_hash( {@_} );
        }

        # Check for DRIVER
        if ( defined $props->{DRIVER} ) {
            croak
                "authz config error:  parameter DRIVER is not a string or arrayref"
                if ref $props->{DRIVER}
                && Scalar::Util::reftype( $props->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = delete $props->{DRIVER};
            # We will accept a string, or an arrayref of options, but what we
            # really want is an array of arrayrefs of options, so that we can
            # support multiple drivers each with their own custom options
            no warnings qw(uninitialized);
            $config->{DRIVER} = [ $config->{DRIVER} ]
                if Scalar::Util::reftype( $config->{DRIVER} ) ne 'ARRAY';
            $config->{DRIVER} = [ $config->{DRIVER} ]
                if Scalar::Util::reftype( $config->{DRIVER}->[0] ) ne 'ARRAY';
        }

        # Check for GET_USERNAME
        if ( defined $props->{GET_USERNAME} ) {
            croak
                "authz config error:  parameter GET_USERNAME is not a CODE reference"
                if ref $props->{GET_USERNAME} ne 'CODE';
            $config->{GET_USERNAME} = delete $props->{GET_USERNAME};
        }

    }
}


=head3 prerun_callback

Before a user's runmode is even called we can check to see if they should.
"Just becuase you can, does not mean you should" just because, "Should you?"

=cut

sub prerun_callback {
  warn "You are in Notice::Security::prerun_callback" if $opt{D}>=1;
  my $self = shift;
  my $module = $self->{__PARAMS}->{'mod'};
  my $runmode = $self->get_current_runmode;
  my $username = $self->{__PARAMS}->{'username'};
  my $action = $self->{__PARAMS}->{'id'};
  warn $username . " is using " . $module . "::" . $runmode . " doing " . $action . "\n" if $opt{D}>=1;

  # get config from database

  # check action
  
  # add entry to database

  # take action

}

=head3 postrun_callback

If we need to, we can take action after the runmode has been processed. 

=cut

sub postrun_callback {
  my $self = shift;
  my $runmode = $self->get_current_runmode;
  # warn "and now we are in Notice::Security::postrun_callback";

  # get config from database

  # check action

  # add entry to database

  # take action

}

1;
__END__

=head1 BUGS AND LIMITATIONS

Probably, and certainly better ways to do the same thing

Please report any bugs or feature requests to
C<alexx@cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=notice>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Notice

You could also look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Notice

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Notice

    CPAN Ratings
        http://cpanratings.perl.org/d/Notice

    Search CPAN
        http://search.cpan.org/dist/Notice/


=head1 SEE ALSO

L<CGI::Application>, 
L<CGI::Application::Plugin::DBIC::Schema>, 
L<DBIx::Class>, 
L<CGI::Application::Structured>, 
L<CGI::Application::Structured::Tools>

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2001-2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut

