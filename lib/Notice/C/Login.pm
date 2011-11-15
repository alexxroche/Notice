package Notice::C::Login;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This lets registerd users and admin Log into Notice.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;

}

=head2 RUN MODES

=head3 index

  * This runmode manages login attempts

=cut

sub index: StartRunmode {
  my $self   = shift;
  my $url = $self->query->url;

  my $user = $self->authen->username;
  if ($user) {
    my $message = "User $user is already logged in!";
    my $template = $self->load_tmpl('default.html');
    $template->param(MESSAGE => $message);
    $template->param(MYURL => $url);
    return $template->output;
  } else {
    my $url = $self->query->self_url;
    unless ($url =~ /^https/) {
      $url =~ s/^http/https/;
      return $self->redirect($url);
    }
    return $self->my_login_form;
  }
}


# Private methods go here. Start their names with an _ so they are skipped
# by Pod::Coverage.

#
#sub _non_runmode_util_subroutine{
#	# no self = shift needed.
#	...
#}
#
#sub _non_runmode_util_method{
#	my $self = shift;
#	...
#}
#

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

