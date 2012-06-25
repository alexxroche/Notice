package Notice;
use strict;
use warnings;
use base 'CGI::Application';
our %opt; # nice to have them
$opt{D}=0;
use lib 'lib';

our $VERSION = 3.10;

use Notice::DB;
our $page_load_time = time;
BEGIN {
    eval { 
        use Time::HiRes qw( time );
        $page_load_time = time;
    };
    if($@){
        $page_load_time = time;
    }
}

#use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::DBH(qw/dbh_config dbh/);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::DBIC::Schema qw/dbic_config schema resultset/;
#use CGI::Application::Plugin::DebugScreen;
use Digest::MD5 qw(md5_hex);
#use DBIx::Class::Exception;
#$ENV{DBIC_TRACE} = 10;

use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::TT;
use Data::Dumper;

my %CFG;
# This is fun: we should have this in global scope, b ut %CFG isn't populated yet...
#__PACKAGE__->tt_config( TEMPLATE_OPTIONS => $CFG{TEMPLATE_OPTIONS} );

=head1 NAME

Notice - A MVC (DBIC,TT,CAS) CGI::Application Customer Resource and Account Manager inspired by C:A:Structured

=head1 SYNOPSIS

    A controller module for Notice.
    
    Imports DBIx::Class schema here for all subclasses generated by script/create_controller.pl

=head1 DESCRIPTION

A base class for Controllers in this app. Subclasses are found
in the Notice::C:: (keeping the C in MVC seperated from, e.g. Notice::DB.)

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Setting up to catch exceptions, except it does not catch

=cut

sub setup {
  my $self = shift;
  $self->error_mode('myerror');
  $self->run_modes( "AUTOLOAD" => \&catch_my_exception);
}


=head3 cgiapp_init

Initializes the Controller base class for app, configures DBIx::Class plugin,
sets an error mode and configures the TT template directory.

=cut

sub cgiapp_init {
  my $self = shift;
  # use 5.12; use utf8; # harshly non-backwardly compatible
  # http://cgi-app.org/index.cgi?page_name=Utf8Example
  $self->query->charset('UTF-8'); 
  if(-f 'config/config.pl'){
    use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
    #$self->cfg_file('config/config.pl'); #only needed if ommited from Notice::Dispatch
    %CFG = $self->cfg;
  }elsif(-f '../config/config.pl'){
    use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
    %CFG = $self->cfg;
  }elsif(-f '../../config/config.pl'){
    use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
    %CFG = $self->cfg;
  }else{
    warn('Default config');
        
    $CFG{db_schema} = 'Notice::DB';
    $CFG{db_dsn} = "dbi:mysql:database=notice";
    $CFG{db_user} = "notice_adminuser";
    $CFG{db_pw} = "12345678-abcd-1234-a693-00188bba79ac";
    $CFG{tt2_dir} = "templates";
  }

#http://template-toolkit.org/docs/manual/Config.html#section_TAG_STYLE
  if(defined $CFG{TEMPLATE_OPTIONS} && keys %{ $CFG{TEMPLATE_OPTIONS} }){
    $self->tt_config( TEMPLATE_OPTIONS => $CFG{TEMPLATE_OPTIONS} );
  }
  #my @template_paths = ($self->cfg("tt2_dir") );
  my @template_paths = ($CFG{'tt2_dir'});
  $self->tt_include_path( \@template_paths, './templates' );
  $self->tmpl_path(\@template_paths);

  #let CGI::Application::Plugin::DBIC::Schema know where and what the database is
  $self->dbic_config(
        {
            schema       => $CFG{'db_schema'},
            connect_info => [
                $CFG{'db_dsn'},
                $CFG{'db_user'},
                $CFG{'db_pw'}
                ]    # use same args as DBI connect
        }
  );


  # open database connection using CGI::Application::Plugin::DBH
  # this is used by session_config to get a handel on the DB.
  # It would be nice if we could just pull a handel from DBIx::Class

  $self->dbh_config(
    $CFG{'db_dsn'},    # "dbi:mysql:database=webapp",
    $CFG{'db_user'},   # "webadmin",
    $CFG{'db_pw'},   # ""
  );
   #unless($CFG{'session_expiry'}){ $CFG{'session_expiry'} = '+1h'; }
   unless($CFG{'session_expiry'}){ 
     if($CFG{'session_timeout'}){ 
        $CFG{'session_expiry'} = $CFG{'session_timeout'};
     }else{
        $CFG{'session_expiry'} = '+1w'; 
     }
   }

  $self->session_config(
    CGI_SESSION_OPTIONS => [
      "driver:mysql;serializer:Storable;id:md5",
      $self->query, {Handle => $self->dbh},
    ],

   DEFAULT_EXPIRY => $CFG{'session_expiry'},
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
  $self->authen->protected_runmodes('mustlogin');

    my $known_as = '';
    my $username = '';
    if($self->query){
        my ($self_url) =  ($self->query->self_url);
        unless($self_url=~s/.*\/index.cgi\/([^\/]*)\/?\?.*/$1/){ $self_url = 'main'; } #runmode
        eval{
         if( $self->authen->is_authenticated){ 
            $username = $self->authen->username; 
            $self->param(username => $username);
            if($self->session->param('ef_acid')){ 
                my $ef_acid = $self->session->param('ef_acid');
                $self->param(ef_acid => $ef_acid);
            }
            if($self->session->param('ac_tree')){ 
                my $ac_tree = $self->session->param('ac_tree');
                $self->param(ac_tree => $ac_tree);
            }
            
            if($self->session->param('known_as')){
                $known_as = $self->session->param('known_as');
                $self->param(known_as => $known_as); 
            }
            if($self->session->param('menu')){
                my $menu = $self->session->param('menu');
                $self->param(menu => $menu);
            }
            if($self->session->param('menu_order')){
                my @menu_order = $self->session->param('menu_order');
                $self->param(menu_order => @menu_order);
            }
            if($self->session->param('pe_id')){
                my $pe_id = $self->session->param('pe_id');
                $self->param(pe_id => $pe_id);
            }
            
            # we /should/ have populated our params from the session... but lets check

            if($username && !$self->session->param('menu')){
                my $user_data = $self->resultset('People')->search({
                    'pe_email' => { '=', "$username"},
                   },{
                    columns => ['pe_id','pe_acid','pe_fname','pe_lname','pe_menu']
                });
                my ($pe_id,$ef_acid,$ac_tree,$pe_menu);
                while( my $ud = $user_data->next){
                    $pe_id = $ud->pe_id; #later, for the admin we will have to have effective_peid as we do with ef_acid
                    $ef_acid = $ud->pe_acid;
                    $pe_menu = $ud->pe_menu;
                    $self->session->param(menu => $pe_menu);
                    $self->param(ef_acid => $ef_acid); # this can be changed by some users
                    $self->param(pe_acid => $ef_acid); # this is _ALWAYS_ thier real ac_id
                    $known_as = $ud->pe_fname . ' ' . $ud->pe_lname;
                    $self->param(known_as => $username);
                    $self->param(pe_id => $pe_id);
                    if($ef_acid=~m/^\d+$/){
                        $self->session->param(ef_acid => $ef_acid);
                    }else{
                        $self->session->param(ef_acid => 'Account not found');
                    }
                    $self->session->param(known_as => $known_as);
                }
                
                if($pe_id=~m/^\d+$/){
                    my $acrs = $self->resultset('Account')->search({
                        'ac_id' => { '=', "$ef_acid"},
                    },{});
                    while( my $ac = $acrs->next){
                        my $ac_tree = $ac->ac_tree;
                        $self->param(ac_tree => $ac_tree);
                        $self->session->param(ac_tree => $ac_tree);
                    }
                    $self->session->param(pe_id => $pe_id);

                 my $is_an_admin = 1;
                 my $module_cats;
                 $module_cats .= qq/ 'modules.mo_catagorie' => { '=', 'service'}, /;

                    if($is_an_admin){
                       $module_cats .= qq/ 'modules.mo_catagorie' => { '=', 'sysadmin'}, # we don't want function /;
                       $module_cats .= qq/ 'modules.mo_catagorie' => { '=', 'base'}, # we don't want function /;
                    }

                    my $menu_class = 'navigation'; #change the css not the class!
                    #my $menu_rs = $self->resultset('Menu')->search({
                    my @menu_rs = $self->resultset('Menu')->search({
                        'pe_id' => { '=', $self->param('pe_id')},
                        -or => [ 
                                'modules.mo_catagorie' => { '=', 'base'},
                                'modules.mo_catagorie' => { '=', 'details'},
                                'modules.mo_catagorie' => { '=', 'service'},
                                'modules.mo_catagorie' => { '=', 'sysadmin'},
                        ],
                        'hidden' => { '<=', '0'}, #catagorie ?? IT IS Category !
                        },{
                        columns => ['menu','hidden',{ name => 'modules.mo_name AS name'},{ rm => 'modules.mo_runmode AS rm'} ],
                        join => 'modules',
                        order_by => {-asc =>['pref','mo_default_hierarchy','menu+0']}
                        });
                    my %menu; # this will be a list of this users menu items
                    my @menu_order; #and this will be the order that they want them displayed in

                    #warn Dumper($menu_rs);
                    # GOT HERE! NTS

                    #my $menu_cols = $menu_rs->all;
                    # NOTE we may have to sort these 
                    my $menu_cols = keys %{ $menu_rs[0]->{_column_data} };
                    my $menu_rows = @menu_rs;
                    #warn "Cols: $menu_cols, Rows: $menu_rows";

                    # NOTE we can add global default menu items here
                    push @menu_order, '1.2';
                    $menu{'1.2'} = {hidden => '', rm => 'details', name => 'Your Details', class => "$menu_class"};

                    # NOTE I _know_ that there is a better way to do this.. but my dbic-fu fails here
                    for(my $i=0;$i<=$menu_rows;$i++){
                        my $menu     = $menu_rs[$i]->{_column_data}{menu};
                        my $hidden   = $menu_rs[$i]->{_column_data}{hidden} || '';
                        my $rm       = $menu_rs[$i]->{_column_data}{rm};
                        my $menu_name= $menu_rs[$i]->{_column_data}{name};
                        if($menu_name && $rm){
                          push @menu_order, $menu;
                          $menu{$menu} = {hidden => "$hidden", rm => "$rm", name => "$menu_name", class => "$menu_class"};
                        }
                    }

                    push @menu_order, '1.0';
                    $menu{'1.0'} = {hidden=>'',rm=>'config',name=>'Configuration', class => "$menu_class"};

=pod

                    # This all worked when I still had %modules hard-coded. 
                    # First I tried to populate that hash from the database, before I realised
                    # that I should join the modules table, (maybe I should not, but I have not found that yet.)

                    while( my $m = $menu_rs->next){
                        #my $menu_name = $modules{$m->menu()}{'name'};
                        my $menu_name = $m->name;
                        my $rm = $m->rm;
                        #my $rm = $modules{$m->menu()}{'rm'};
                         my $message = keys %{ $m };
                        $message .= $self->param('message');
                        $self->param(message => $message);
                        push @menu_order, $m->menu;
                        my $hidden = $m->hidden;
                        $menu{$m->menu} = {hidden => "$hidden", rm => "$rm", name => "$menu_name", class => "$menu_class"};
                        warn qq |hidden => $hidden, rm => $rm, name => $menu_name, class => "$menu_class"|;
                    }
=cut

                    my $menu_dump = Dumper(\%menu);
                    $self->param(menu => \%menu);
                    $self->param(menu_order => \@menu_order);
                    $self->session->param(menu => \%menu);
                    $self->session->param(menu_order => \@menu_order);
                    $self->tt_params({menu_order => \@menu_order});
                    $self->tt_params({menu => \%menu});
                }else{
                    warn "$self->param('pe_id') is undef so we can't search for menu items";
                }
            }
                # NTS not sure the Runmodes /need/ to know the menu options - we should probably just 
                # pass that directly into $self->tt_params(menu => \%menu);
          }
        };
        #my $runmode = $self_url;
        my $runmode = '';
        $runmode = ($self->query->self_url);
        if($self->param('rm')){
            $runmode = $self->param('rm');
        }
        # NOTE this still needs some tweeking
        $runmode =~s/\/?$//;
        if($self->param('id')){
            my $id = $self->param('id');
            if($self->param('did')){
                my $did = $self->param('did');
                $runmode =~s/\/$did[^\/]*//;
            }
            if($self->param('extra1')){
                my $extra = $self->param('extra1');
                $runmode =~s/\/$extra[^\/]*//;
            }
            if($self->param('sid')){
                my $sid = $self->param('sid');
                $runmode =~s/\/$sid[^\/]*(\/.*)?//;
            }
            if($id){
                $runmode =~s/\/$id\/.*//;
            }else{
                $runmode =~s/\/$id[^\/]*$//;
            }
        }
        $runmode=~s/.*\///;
        $runmode=~s/\?.*//;

        if($self->param('rm')){ $runmode = $self->param('rm'); }else{ $self->param('rm' => $runmode); }
        my($module,$id) = ($self->query->self_url=~m/index.cgi\/([^\/]*)\/?([^\/]*)/);
        unless($self->param('id')){ $self->param('id' => $id ); }
        unless($self->param('mod')){ $self->param('mod' => $module ); }
        if(!$self->param('i18n')){
            # The default language comes from the URI first and then 
            # the users config and if both are missing we pull it from the browser    
            #my $http_headers = \%{ $self->query() };

            # NTS check session
            # else
            # NTS pull from database
            # else
            # we try to extract the language from the browser

            # my @lang_list = split(/;/, $ENV{HTTP_ACCEPT_LANGUAGE}); 
            # my @lang_region = split(/,/, $lang_list[0]); 
            # $self->param('i18n' => $lang_region[@lang_region - 1]);
            #my @lang_list = split(/;/, $self->param('ALL_HTTP'));
            #warn $self->param('ALL_HTTP');
            if($ENV{HTTP_ACCEPT_LANGUAGE}=~m/^([^,]+)/){
                my $HTTP_ACCEPT_LANGUAGE = $1;
                $HTTP_ACCEPT_LANGUAGE =~s/-/_/;
                $self->param('i18n' => $HTTP_ACCEPT_LANGUAGE);
                #warn "HTTP_ACCEPT_LANGUAGE = " .$self->param('i18n');
            }elsif($ENV{LANGUAGE}=~m/^([^,:]+)/){
                $self->param('i18n' => $1);
                #warn "LANGUAGE = " .$self->param('i18n');
            }elsif($ENV{LANG}=~m/^([^\.]+)/){
                $self->param('i18n' => $1);
                #warn "LANG= " . $self->param('i18n');
            }elsif($ENV{GDM_LANG}=~m/^([^\.]+)/){
                $self->param('i18n' => $1);
                #warn "GDM_LANG= " .$self->param('i18n');
            }elsif($CFG{'default_lang'}){ 
                $self->param('i18n' => $CFG{'default_lang'}); 
                #warn "default_lang = " .$self->param('i18n');
            }
            #    HTTP_USER_AGENT
            #    GDM_KEYBOARD_LAYOUT = gb
        }
          # $self->param('i18n' => 'fr-fr'); #debug
          #  foreach my $env (keys %ENV){ my $line = "$env = $ENV{$env}"; if($line=~m/lang/i){ warn $line; }} 
        $self->tt_params({caller  => $self->param('caller')});
        $self->tt_params({REMOTE_ADDR  => $ENV{REMOTE_ADDR}});
        $self->tt_params({title => 'Notice CRaAM  ' . $runmode ." - $known_as AT ". $ENV{REMOTE_ADDR}});
    }else{
        $self->tt_params({title => 'Notice CRaAM -' . $known_as . ' ON '. $ENV{REMOTE_ADDR}});
    }
    # Maybe this was not called using cgi-bin/index.cgi  (e.g. server.pl)
    if($self->param('plt') && $self->param('caller')){
        $self->param('page_load_time' => $self->param('plt') );
    }else{
        eval {
            use Time::HiRes qw( time );
            $page_load_time = time;
        };
        if($@){
            $page_load_time = time;
        }
        $self->param('page_load_time' => $page_load_time);
    }
}

=head3 cgiapp_prerun

This lets us hook in the security module, (if it is installed)

=cut

sub cgiapp_prerun {
    my $self = shift;
    eval {
        require Notice::Security;
        Notice::Security->new();
        #Notice::Security->import();
        my $breach = $self->Notice::Security::prerun_callback();
        if($breach){ 
            if(ref($breach) eq 'HASH' || UNIVERSAL::isa($breach, 'HASH')){ 
                warn Dumper($breach); 
            }else{ warn $breach; } 
            return; 
        }
    };
    if($@){
        warn "NotiSec:" . $@;
        #$self->tt_params({ warning => 'naughty naught got caughty'});
        $self->tt_params({ warning => 'Security breach'});
    }else{
        warn "back from sec" if $opt{D}>=10;
    }

    # This is where we dynamically set the css
    my %user_details;
    my $pe_id = $self->param('pe_id');
    # still looking for a reliable way to collect the runmode
    my $page = ($self->query->self_url);
    # This has to be a little complicated to cove:
    # with i18n in the URI
    # without i18n in the URI
    # we /may/ want to add complication so that email/edit_alias/ and email/aliases/ have the option of seperate CSS
    if($page=~m/.*\/index.cgi\/[\w{2}][_\w{2}]?\/([^\/]*)\/?\??.*/){ 
        $page=~s/.*\/index.cgi\/[\w{2}][_\w{2}]?\/([^\/]*)\/?\??.*/$1/; # we have a languge set
    }elsif($page=~m/.*\/index.cgi\/([^\/|\?]*)\/?\??.*$/){
        $page=~s/.*\/index.cgi\/([^\/|\?]*)\/?\??.*$/$1/;
    }else{ $page = 'main'; }
    my $acid = $self->param('ef_acid');
    # this is fun. We, and by we I mean this script, can live in /usr/lib/cgi-bin
    # and we are looking for ~www/css or where ever the static files are.
    # we /could/ look up https://$ENV{hostname}/css but I think that I want 
    #  if( -f "$css_path/file.css")
    my $css_location_modifier='./';
    if(defined $CFG{www_path}){
        my $css_path = $CFG{www_path} . "/css";
        my $user_css = 'main.css';
        # NOTE !important: (not always ) ef_acid == ac_id and for CSS we should use the ef_acid
        # unless $self->param('acid_css') is set to over-ride this
        {
           no warnings; # about "Use of uninitialized value" WHO CARES!
           if(-f "$css_path/${page}_${pe_id}_${acid}.css"){ $user_css = $page.'_'.${pe_id}.'_'.${acid}.'.css';}
        elsif(-f "$css_path/${pe_id}_${acid}.css"){ $user_css = ${pe_id}.'_'.${acid}.'.css';}
        elsif(-f "$css_path/css/${acid}.css"){ $user_css = "${acid}.css";}
        elsif(-f "$css_path/${page}_${pe_id}_${acid}.css"){$user_css = $page.'_'.${pe_id}.'_'.${acid}.'.css';}
        elsif(-f "$css_path/${pe_id}_${acid}.css"){ $user_css = ${pe_id}.'_'.${acid}.'.css';}
        elsif(-f "$css_path/${acid}.css"){ $user_css = "${acid}.css";}
        }

        $self->param('css' => $user_css);
        $self->tt_params({'css' => $user_css});
    }
}

=head3 cgiapp_postrun

This lets us hook in the security module, (if it is installed)

=cut

sub cgiapp_postrun {
    my $self = shift;
    eval {

        # any module can set $self->param('sec') to report back here
        # any module can set $self->param('sec_action') to report an action
        # any module can set $self->param('sec_action') to report an action

        #require Notice::Security;
        #Notice::Security->import();
        $self->Notice::Security::postrun_callback();
    };
}

=head3 tt_pre_process

Globally tinkering with the templates just before they are processed

=cut

sub tt_pre_process {
  my $self = shift;
     $self->plt;
}

=head3 tt_post_process

Globally tinkering with the templates after they have been parsed and populated

=cut


sub tt_post_process {
  my $self    = shift;
  my $htmlref = shift;
  if( $self->param('debug') || $self->query->self_url=~m/debug=dirty/){
    # crazy! add a class to each bare html tag
    while($$htmlref =~m/(.*<body.*<\w+)(>.*<\/body>.*)/si){
        $$htmlref = $1 . ' class="red"' . $2;
        #$$htmlref =~s/(<body.*<\w+)(>.*<\/body>)/$1 class="red" $2/sig;
    }
    $$htmlref =~s/Alexx Roche/Alexx Roche <br\/>NOT Cleaned by HTML::Clean/;
  }else{
    require HTML::Clean;
    my $h = HTML::Clean->new($htmlref);
    if($$htmlref=~m/<pre/){
        $h->strip({whitespace => 0});
    }else{
        $h->level(9); #y,no11?
        $h->strip;
    }
    $$htmlref = ${$h->data};
    #my $newref=$h->data;$$htmlref=$$newref;
  }
  # This is just one of the many ways that i18n/i10n can be achieved
  eval {
    use Template::Multilingual;
    my $template = Template::Multilingual->new();
    $template->language($self->param('i18n'));
    my $i18n;
    $template->process(\$$htmlref,'',\$i18n);
    $$htmlref = $i18n;
  };
  if($@){ warn $@; }
  return;
}

=head3 plt

find out when this page finished loading

=cut

sub plt {
    my $self = shift;
    my $page_loaded = 0;
    eval {
        use Time::HiRes qw ( time );
        $page_loaded = time;
    };
    if($@){
        $page_loaded = time;
    }
    $self->tt_params({page_load_time => sprintf("Took %.3f ms", (($page_loaded - $self->param('page_load_time'))*1000))});
    return sprintf("%.3f", (($page_loaded - $self->param('page_load_time'))*1000));
}

=head3 catch_my_exception

 this is meant to catch errors, but so far it does not seem to work
 (probably overridden by one of the plugins)

=cut

sub catch_my_exception {
    my $self = shift;
    my $intended_runmode = shift;
    my $output = "Looking for '$intended_runmode', but found 'AUTOLOAD' instead";
    return $output;
}


=head3 teardown

database handel disconnection

=cut


sub teardown {
  my $self = shift;
  $self->dbh->disconnect(); # close database connection
}

=head3 mustlogin

yes! they must

=cut

sub mustlogin : Runmode {
  my $self = shift;
  my $url = $self->query->url;
  #$url=~s/(mustlogin\/){2,}/mustlogin\//g;
  return $self->redirect($url);
}

=head3 okay

if it is, then it is

=cut

sub okay : Runmode {
  my $self = shift;
  my $url = $self->query->url;
  my $dest = $self->query->param('destination') || 'main';

  if ($self->param('noTLS') && $url =~m/^https/) {
    $url =~ s/^https/http/; #this is the opposite of what we /should/ be doing
  }
  return $self->redirect("$url/$dest");
}

=head3 login

if you can - we should move this into Notice::C::Login

=cut

sub login : Runmode {
  my $self   = shift;
  my $url = $self->query->url;

  my $user = $self->authen->username;
  if ($user) {
    my $dest = $self->query->param('destination') || 'main';
    $url=~s/\/login$//;
    return $self->redirect("$url/$dest");
    exit;
  } else {
    my $url = $self->query->self_url;
    # This should be an option pulled from the DB config table
    unless ($url =~ /^https/) {
      $url =~ s/^http/https/;
      return $self->my_login_form
    }
    return $self->my_login_form;
  }
}

=head3 my_login_form

going to move this to Notice::C::Login.pm as soon as I can
(Or just drop it as I don't think we use it anymore,
but it shows that we are not locked into TT.)

=cut

sub my_login_form {
  my $self = shift;
  my $template = $self->load_tmpl('login_form.html');

  my $PATH_INFO = '';
  if($ENV{'PATH_INFO'}){ $PATH_INFO = $ENV{'PATH_INFO'} || undef; }
  (undef, my $info) = split(/\//, $PATH_INFO);
  my $url = $self->query->url;

  my $destination = $self->query->param('destination');

  unless ($destination) {
    if ($info) {
      $destination = $info;
    } else {
      $destination = "main";
    }
  }

  my $message = 'Would you be so kind as to login using your details. Thank you';
  my $error = $self->authen->login_attempts;
  if($url!~m/cgi-bin\/index.cgi/){
        $url=~s/cgi-bin/cgi-bin\/index.cgi/;
  }
  if($url!~m/mustlogin/){
    $url .= '/mustlogin';
    $message = 'Please login';
  }elsif($url=~m/mustlogin\/mustlogin/){
    $message = 'Try again... or click <a href="/cgi-bin/index.cgi/lost">here</a> to recover your password';
    $url=~s/mustlogin\/mustlogin/mustlogin/g;
  }

  $template->param(MESSAGE => $message);
  $template->param(MYURL => $url);
  $template->param(ERROR => $error);
  $template->param(DESTINATION => $destination);
  return $template->output;
}

=head3 logout

and don't let the door hit you on the way out

=cut

sub logout : Runmode {
  my $self = shift;
  if ($self->authen->username) {
    $self->authen->logout;
    $self->session_delete;
  }
  $self->param(message => 'You are no longer logged in');
  return $self->redirect($self->query->url);
}

=head3 their_error

This catches 500 errors but not 404 or 400

=cut

sub their_error : ErrorRunmode {
  my $self = shift;
  my $error = shift;
  my $url = $self->query->self_url;
     my $result = '<h1 class="red error">error</h1>';
    $result .= "<h2>$@<!--$error-->";
    $result .= "<br/> URL = $url</h2><br/>";
    # probably don't want a template as that might be what is going wrong
  $self->tt_params({no_wrapper => 1});
  $self->tt_params({message => $result});
    #my $plt = $self->param('page_load_time');
    my $plt = $self->plt;
    warn "Notice has a 'their_error' Notice.pm 613" if ($self->param('debug') || $url=~m/debug=\d+/);
    # we seem to get here, but then we don't get our page
    # NOTE this isn't working - fix it!
    #return $self->tt_process('error500.tmpl');
    # agh! this is painful! 
    return qq |<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<title>Notice - 500 error</title>
<link rel="stylesheet" href="/css/main.css" />
<meta name="description" content="Notice CRaAM" />
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="keywords" content="extended, customer, resource, management, system, for, internet, companies" />
<link rel="stylesheet" type="text/css" media="screen" href="/css/asset.css" />
<script type="text/javascript" src="/js/jquery.js"></script>
</head>
<body>
<div id="head_padding">&nbsp; <!-- add css to do this --></div>
<div id="content">
  <table id="body"><tr><td>
    <div id="heading">
        <span class="message">We have no Bananas today!</span>
    </div>
  </td></tr>
  <tr><td>
    <div id="bodyblock">
        Nope, can't find any. Maybe you should <a class="red" href="#" onclick="history.back()">go back</a>
    </div>
  </td></tr>
  </table>
</div>
<div id="sysops">If you are interested, or would like to report this error:
$result
<h1 class="error red">end of Error</h1>
</div>
<div id="footer">Copyright (c) 2007-2012 Alexx Roche<span class=pageLoadTime>(Took $plt ms)</span></div>
</body>
</html>|;
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

