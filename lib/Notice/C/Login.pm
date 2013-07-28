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

=head3 main

  * This runmode manages login attempts

=cut

sub main: StartRunmode {
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
    #return $self->my_login_form;
    return $self->login;
  }
}


sub form: Runmode {
  my $self   = shift;
  my $url = $self->query->url;

  my ($PATH_INFO,$info,$runmode);
  if($ENV{'PATH_INFO'}){
    $PATH_INFO = $ENV{'PATH_INFO'} || undef;
    (undef, $info, $runmode) = split(/\//, $PATH_INFO);
  }
  my $dest= $self->query->param('destination') || 'main';
  if ($info){   
    $dest = $info;
    if($runmode){
        $dest .= "/$runmode";
        $self->tt_params({ authen_login => $runmode });
    }
  }
    # NTS add in the ?blah=blah so that we don't lose the GET data
  $self->tt_params({ dest => $dest });
 
  my $user = $self->authen->username;
  if (1==0 && $user) {
    if($dest){ $url .= '/' . $dest; }
    $url=~s/\/login\/?$//g;
    return $self->redirect("$url");
    exit;
  } else {
    my $authen_username = '';
    if($self->query){
        my $query       = $self->query;
        #my $credentials = $self->authen->credentials;
        $authen_username = $query->param('authen_username');
        unless($authen_username){
            $authen_username = $query->cookie('CAPAUTHTOKEN');
            $self->tt_params({ authen_rememberuser => 'checked="checked"' });
            #warn "got username from cookie " . $authen_username;
        }
    }
    $self->tt_params({ authen_username => $authen_username });
    my $url = $self->query->self_url;
    my $warning = $self->authen->login_attempts;
    if($warning && $warning ne '' && $warning=~m/^\d+$/){
        $warning = '<span class="red error">Invalid username or password (login attempt ' . $warning . ')</span>';
        $self->tt_params({ login_warning => $warning });
    }
    # This should be an option pulled from the DB config table
    unless ($url =~ /^https/) {
      $url =~ s/^http/https/;
      if( defined $ENV{'HTTP_X_REQUESTED_WITH'}){ $self->header_type('none'); return $self->tt_process('login_form.tmpl'); }
      return $self->tt_process('login.tmpl');
    }
    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}){ return $self->tt_process('login_form.tmpl'); }
    return $self->tt_process('login.tmpl');
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

