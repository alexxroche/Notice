package Notice::Base;

use strict;
use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::DBH(qw/dbh_config dbh/);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
use CGI::Application::Plugin::TT;
use Digest::MD5 qw(md5_hex);

our $VERSION = 2.10;

=head3 setup

=cut

sub setup {
  my $self = shift;

  $self->mode_param(
    path_info => 1,
    param => 'rm',
  );
}

=head3 cgiapp_init

=cut

sub cgiapp_init {
  my $self = shift;

  my %CFG = $self->cfg;

  $self->tmpl_path(['./templates']);
   my @template_paths = ($self->cfg("tt2_dir") );
   $self->tt_include_path( \@template_paths );
   #$self->tt_include_path('templates');


  # open database connection
  $self->dbh_config(
    $CFG{'DB_DSN'},    # "dbi:mysql:database=webapp",
    $CFG{'DB_USER'},   # "webadmin",
    $CFG{'DB_PASS'},   # ""
  );

  $self->session_config(
    CGI_SESSION_OPTIONS => [
      "driver:mysql;serializer:Storable;id:md5",
      $self->query, {Handle => $self->dbh},
    ],

    DEFAULT_EXPIRY => '+1h',
#    COOKIE_PARAMS => {
#      -name => 'MYCGIAPPSID',
#      -expires => '+24h',
#      -path => '/',
#    },
  );

  # configure authentication parameters
  $self->authen->config(
    DRIVER => [ 'DBI',
      DBH         => $self->dbh,
      TABLE       => 'people',
      CONSTRAINTS => {
	'people.pe_email'      => '__CREDENTIAL_1__',
        'MD5:people.pe_passwd' => '__CREDENTIAL_2__'
      },
    ],

    STORE                => 'Session',
    LOGOUT_RUNMODE       => 'logout',
    LOGIN_RUNMODE        => 'login',
    POST_LOGIN_RUNMODE   => 'okay',
    RENDER_LOGIN         => \&my_login_form,
  );

  # define runmodes (pages) that require successful login:
  $self->authen->protected_runmodes(
    'mustlogin',
     'email',
    'assets',
    'private',
    'private2',

  );

      my $cr = $self->get_current_runmode() ? $self->get_current_runmode() : '';
    if($self->authen->username){ $cr .= $self->authen->username; }
    $self->param(title => 'Notice ' . $cr . ' - AT ' . $ENV{REMOTE_ADDR});
    $self->tt_params(message => 'Hello from Notice.pm');

  $self->tt_config( TEMPLATE_OPTIONS => { WRAPPER => 'Notice::C::wrapper.tmpl' } );

}

=head3 index

obv.

=cut

sub index : StartRunmode {
  my $self = shift;
  my $template = $self->load_tmpl("index.html");
  $template->param({
      NAME  => 'INDEX',
      MYURL => $self->query->url(),
      USER  => $self->authen->username,
  });
  return $template->output;
}


=head3 teardown

=cut

sub teardown {
  my $self = shift;
  $self->dbh->disconnect(); # close database connection
  #$self->session->flush; #flush the session (should be in the FastCGI instance script)
}

=head3 mustlogin

=cut

sub mustlogin : Runmode {
  my $self = shift;
  my $url = $self->query->url;
  return $self->redirect($url);
}

=head3 okay

=cut

sub okay : Runmode {
  my $self = shift;

  my $url = $self->query->url;
#  my $user = $self->authen->username;
  my $dest = $self->query->param('destination') || 'index';

  if ($url =~ /^https/) {
    $url =~ s/^https/http/;
  }

  return $self->redirect("$url/$dest");
}

=head3 login

=cut

sub login : Runmode {
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

=head3 my_login_form

=cut

sub my_login_form {
  my $self = shift;
  my $template = $self->load_tmpl('login_form.html');

  (undef, my $info) = split(/\//, $ENV{'PATH_INFO'});
  my $url = $self->query->url;

  my $destination = $self->query->param('destination');

  unless ($destination) {
    if ($info) {
      $destination = $info;
    } else {
      $destination = "index";
    }
  }

  my $error = $self->authen->login_attempts;

  $template->param(MYURL => $url);
  $template->param(ERROR => $error);
  $template->param(DESTINATION => $destination);
  return $template->output;
}

=head3 logout

=cut

sub logout : Runmode {
  my $self = shift;
  if ($self->authen->username) {
    $self->authen->logout;
    $self->session->delete;
  }
  return $self->redirect($self->query->url);
}

=head3 myerror

=cut

sub myerror : ErrorRunmode {
  my $self = shift;
  my $error = shift;
  my $template = $self->load_tmpl("default.html");
  $template->param(NAME => 'ERROR');
  $template->param(MESSAGE => $error);
  $template->param(MYURL => $self->query->url);
  return $template->output;
}

=head3 AUTOLOAD

=cut

sub AUTOLOAD : Runmode {
  my $self = shift;
  my $rm = shift;
  my $template = $self->load_tmpl("default.html");
  $template->param(NAME => 'AUTOLOAD');
  $template->param(MESSAGE =>
    "<p>Error: could not find run mode \'$rm\'<br>\n");
  $template->param(MYURL => $self->query->url);
  return $template->output;
}


1;
