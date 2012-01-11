package Notice::C::Okay;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This is another superfluous part of the login system.
It should be pruned out.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

TODO: Change Notice.pm so that this is not needed.

=cut

sub setup {
    my ($self) = @_;
}

=head2 RUN MODES

=head3 index

This lets us give a "well done, you mangaged to not forget your password" page

=cut

sub index: StartRunmode {
    my ($c) = @_;
    $c->tt_params({
	message => 'Hello world!',
	title   => 'C::Okay'
		  });
    return $c->tt_process();
    
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
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut


