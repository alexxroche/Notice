package Notice::C::Vcard;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';

=head1 NAME

Notice::C::vcard

=head1 ABSTRACT

This redirects to Contacts

=head1 DESCRIPTION

In Notice the URI should be meaningful, obvious and helpful
So that is why this exists.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/^(?!main)/);
}

=head2 RUN MODES

=head3 main

  * Display the welcome message for the account that they are in
  * Display the side menu and the search menu at the top,
    (if that is enabled for their account and user.)

=cut

sub main: StartRunmode {
    #my ($self) = @_;
    my $self = shift;
    my $url = $self->query->url;
    $url .= '/Contacts';
    warn "vCard url: $url";
    #my $q = $self->query();
    my $surl = ($self->query->self_url);
    $surl =~s/(\?.*)$//; #strip any GET values
    my $args = $1;
    if(defined $args){ $url .= "/$args";
        warn "vCard surl: $surl $args";
    }
    return $self->redirect($url);
    #return $self->redirect("$surl/Contacts/$args");
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
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

