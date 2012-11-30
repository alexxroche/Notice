package Notice::C::Myerror;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

The error runmode. This is very raw.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    # N.B. don't protect the main runmode!
}

=head2 RUN MODES

=head3 main

  * Purpose - display an error

=cut

sub main: StartRunmode {
    #my ($self) = @_;
    my $self = shift;
    my $error = shift||'';
    my $url = $self->query->self_url;
    my $result = "<h1>error</h1>";
    my $username=$self->authen->username;
    my $who = ' for ' . $username;
    $result .= "<h2>$@</h2>$error";
    $result .= "<br />p.s. URL = $url";
    # probably don't want a template as that might be what is going wrong
    $self->tt_params({no_wrapper => 1, message => $result});
    $self->param('sec' =>  "Notice has a 'myerror' $who");
    warn "Notice has a 'myerror' $who";
    #return $self->tt_process('error.tmpl');
    return $self->tt_process();
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module, but only becuase it is
so simple, and mostly unused, that there are not many places for bugs
to hide.

Please fix any bugs or add any features you need. 
You can report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

