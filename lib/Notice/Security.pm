package Notice::Security;
use strict;
use warnings;
our %opt; # nice to have them
$opt{D}=0;
use lib 'lib';
use Notice::DB;
my %__CONFIG;
#use UNIVERSAL::require;
use Carp;
use Data::Dumper;

our @periods = qw/ S M  H d w m y /; #Second Minute Hour day week month year

our $VERSION = 0.03;

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

=cut

###
### Helper methods
###

sub _cgiapp {
    return $_[0]->{cgiapp};
}

sub _config {
    my $self  = shift;
    my $class = ref $self ? ref $self : $self;
    my $config;
    if ( ref $self ) {
        $config = $self->{__CAP_AUTHENTICATION_CONFIG} ||= $__CONFIG{$class} || {};
    } else {
        $__CONFIG{$class} ||= {};
        $config = $__CONFIG{$class};
    }
    return $config;
}

###
### main methods
###

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


=head2 _enforce_acl

this is the bouncer that thows people out or warns them, (or just reports)

=cut

sub _enforce_acl {
# NOTE this is not finished (all lips and no teeth)
    my $self = shift;
    my $act  = shift;
    my $config = $self->Notice::Security::config;

#  type enum('hard','soft','silent') COMMENT 'soft are only triggered once, (==), hard (>=); maybe?'
#  report      | enum('lock_out','log_off','email_manager','email_user','warn_popup','warn_embeded','none','lockout_and_email_manager')


    if ($act->{report} eq 'warn_popup') {
        unless(defined $act->{'description'}){
            $act->{'description'} = 
                '<script type="text/javascript">alert("All actions are being monitored");</script>';
        }
        unless($act->{'description'}=~m/javascript.*alert/){
            $act->{'description'} = '<script type="text/javascript">alert("' . $act->{'description'} . '");</script>';
        }
        $self->tt_params({ popup => $act->{'description'} });
    }elsif ($act->{report} eq 'lock_out' or $act->{report} eq 'log_off' ) {
          # The message the the user recieves is pulled form the database activity_acl.description that triggered this 
        if ($act->{report} eq 'lock_out'){
            # We lock with:
            # UPDATE people set pe_passwd = CONCAT(pe_passwd, '_LOCKED') WHERE pe_id = $pe_id;
        }else{
            # We just remove their session
            if ($self->authen->username) {
                $self->authen->logout;
                $self->session_delete;
            }
            unless( defined $act->{'description'} && $act->{'description'} ne ''){
                $act->{'description'} = 'You have been nauty!';
            }
            $self->param(message => $act->{'description'});
            return $self->redirect($self->query->url);
        }
        $self->header_add(-location => $config->{LOGIN_URL});
        $self->param('message' =>  $act->{description});
        $self->header_type('redirect');
        $self->prerun_mode('authen_dummy_redirect');
    } else {
        warn "$act->{'username'} did $act->{'action'} $act->{'object'} $act->{'tally'} times in $act->{'period'}";
      #but we did nothing about it
    }
}


=head2 cgiapp

This will return the underlying CGI::Application object.

=cut

sub cgiapp {
    return $_[0]->{cgiapp};
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
    #my $config = $self->_config;
    my $config = _config($self);

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
  warn "You are in Notice::Security::prerun_callback" if $opt{D}>=10;
  my $self = shift;
  my (%sec,$action,$rm,$mod,$crm,$username,$id,$sid,$did,$eid,$fid,$desc);
  my ($message,@sec_stats,@people,@acl);
  my $pe_id='0'; # person that we are sooping on
  my $ac_id='0'; # and their account
  eval {
    if($self->{__PARAMS}->{'pe_id'}){
        $pe_id = $self->{__PARAMS}->{'pe_id'};
    }else{
        $pe_id = $self->param('pe_id');
    }
  };
  if($@){
    warn "We don't know this user's ID" if $opt{D}>=0;
  }
  eval {
    if($self->{__PARAMS}->{'pe_acid'}){
        $ac_id = $self->{__PARAMS}->{'pe_acid'};
    }else{
        $ac_id = $self->param('pe_acid');
    }
  };
  if($@){
    warn "We don't know this user's Account" if $opt{D}>=0;
  }

  eval {
    if($self->authen->username){
        $username .= $self->authen->username;
    }else{
        $username .= $self->{__PARAMS}->{'username'}||'';
    }
  };
  if($@){
    warn "no username" if $opt{D}>=0;
  }
  unless(defined $username){ $username = 'Anon'; } # Un-non
  $mod = $self->{__PARAMS}->{'mod'}||'';    # Notice::C::$module
  $crm = $self->get_current_runmode||'';    # $mod::&function
  $id = $self->{__PARAMS}->{'id'}||'';      # what they are doing ($q)
  $sid = $self->{__PARAMS}->{'sid'}||'';    # with what
  $did = $self->{__PARAMS}->{'did'}||'';    # to whom ?
  $eid = $self->{__PARAMS}->{'eid'}||'';    # not used yet
  $fid = $self->{__PARAMS}->{'fid'}||'';    # also not used yet
  $rm = $self->{__PARAMS}->{'rm'}||'';   # if this == $crm then they are looking

  $action = 'view';
    # NOTE this next section seems to have too much that is specific to particular modules
    # NOTE login and out is understandable, but the rest should be generalised for all modules
  if($rm eq 'mustlogin' && length($id) > length($rm)){
    $action = 'login';
    #$desc = $ENV{REMOTE_IP}; # maybe?
    $desc='';
  }elsif($rm eq 'logout' && $mod eq 'logout'){
    $action = 'logout'; 
    $desc='';
  }elsif($mod eq 'search' || $rm eq 'search'){
    $action = 'search';
    $desc = $id; # we want to strip this down to something useful
  }elsif(length($id) > length($rm) && $id=~m/^$mod/){
    $action = 'view'; #until we extract their actual CRUD
    $desc = $rm;
    # they are [CRUD]ing something in $crm
  }elsif($rm eq $mod || $rm eq $crm){
    #warn $id;
    if($id =~m/^(\d+)/){
        $crm = 'alias dom';
        $action = 'add';
    }elsif($id =~s/${crm}.*[\?;]id=(\d+).*update/$1/i){
        $crm = 'update';
        $action = 'update';
    }elsif($id =~s/${crm}.*[\?;]id=(\d+).*change/$1/i){
        $crm = 'status';
        $action = 'update';
    }else{
        $id =~s/${crm}.*id=(\d+).*/$1/;
    }
    $desc = "$mod $crm $id";
    # they are in viewing $crm of $mod (or should be)
  }elsif($rm eq $id){
    # they are viewing $id
    if($mod=~m/calendar/i){
        $desc = "$mod $id";
    }else{
        $desc = "$mod rm=id";
    }
  }else{
    if($mod=~m/^calendar.*cal=([^;]+);.*add_event=Add/i){
            $action = 'add';
            my $cal = $1;
            $cal=~s/\%2F/\//g;
            $desc = 'cal event add ' . $cal;
    }elsif($mod=~m/^([^?]+)\?.*(add|edit|update)=(\w+)/i){
            $desc = "$1 $crm $2 $id";
    }else{
        warn "mod: $mod crm: $crm id: $id";
        $desc = ucfirst($mod) . ' ' . $crm . ' ' .$id;
    }
  }
    $desc=~s/\?[^\s]+//; #strip out any residual form data

    # foreach my $param (keys %{ $self } ){ $sec{'message'} .= "$param <br/>\n"; }
    # $sec{'message'} .= Dumper( \%{ $self->{__PARAMS} } );
    #if(length($mod) > length($rm)){ warn "mod: $mod rm: $rm"; $mod=~s/^$rm//; }

    #if($username && $username eq 'a@b.com'){ #DEBUG
  #$sec{'comment'} .= $username . " is using " . $runmode . "::" . $function .' and they are '. $mod . " 'ing with  " . $action . "\n";
  $opt{'comment'} .= "username: $username rm: $rm crm: $crm mod: $mod id: $id sid: $sid did: $did eid: $eid fid: $fid";
   # warn the users?
  $sec{'comment'} .= "All actions are being monitored" if $opt{D}>=2;
  #$sec{'comment'} .= $opt{'comment'};
  #$sec{'comment'} .= 'SELECT * from activity_log where action = "' . $action . '" and user = ' . $pe_id . ' and period = "d" and start = CURDATE() and end = CURDATE()+1;';

  #$self->tt_params({ sec => \%sec, observation => 'ALEXX WAS HERE', error => Dumper(\%sec), message => \%sec, warning => Dumper(\%sec)});
  #$self->tt_params({ sec => \%sec, warning => Dumper(\%sec)});
  #warn $sec{'comment'};
    # }

  # get config from database


  # we need to know this users pe_id, but if we already have it then do we have to check it?
  if(defined $username && (! defined $pe_id ||  $pe_id!~m/^\d+$/)){
    @people = $self->resultset('People')->search({
       'pe_email' => { '=', "$username"}},{} )->first;
    unless( defined $ac_id && $ac_id=~m/^\d+$/ ){
        warn "setting ac_id to: " if $opt{D}>=1;
        $ac_id = $people[0]->{'pe_acid'};
    }
  }else{
    # if we don't know who this is then should we log against remote IP
    # or just create an Anon user
  }
  unless( defined $ac_id && $ac_id=~m/^\d+$/ ){
     if($self->param('pe_acid') && $self->param('pe_acid')=~m/^\d+$/){
          $ac_id = $self->param('pe_acid');
     }else{
          # um, this seems rather important - why isn't it in lib/Notice.pm ?
          if(defined $pe_id){ 
            my $find_acid = $self->resultset('People')->search({'pe_id' => "$pe_id"})->first;
            $ac_id = $find_acid->pe_acid;
          }else{
            # This is perfectly possible: e.g. Beekeeping.pm has an unprotected main runmode
            warn "We have neither pe_id nore ac_id " if $opt{D}>=1;
          }
     }
  }

  my %activity;
  my $sec_rs;
  eval {
    if(defined $pe_id){
    $sec_rs = $self->resultset('ActivityLog')->search({
        user => "$pe_id",
        action => "$action",
        description => "$desc",
        -or => [
            -and => [
                period => 'd',
                start => {'=' => \'CURDATE()'},
                end =>   {'<=' => \' CURDATE()+1'},
            ],
            -and => [
                period => 'y',
                start => {'=' => \'concat(date_format(NOW(), "%Y"), "-01-01")'},
                end =>   {'<=' => \'concat(date_format(NOW(), "%Y"), "-12-31")'},

            ],
            # select date_sub(concat(date_format(date_add( curdate(), interval 1 month), '%Y-%m'), '-01'), INTERVAL 1 DAY) ;
            #
            # NTS have to add m,w,H,M,S
        ],
      }
    );
    #@sec_stats = $self->resultset('ActivityLog')->search();
    }
  };
  if($@){
     warn "sec_rs: $@";
  }else{
    my %updated;
    my %tally;
    # actually we are going to search for seven entries (S,M,H,d,w,m,y) and increment them or insert them
    unless(defined $sec_rs){  # If we don't have a pe_id we don't know who to hang this on.
        warn "Who goes there?";
        return;
    }
    while( my $act = $sec_rs->next){
      #warn "looping sec_rs";
        if( $act->period ){
            my $this_alid =  $act->alid;
            my $this_tally =  $act->tally;
            my $this_p =  $act->period;
            $this_tally +=1;
            $updated{"$this_p"} = 1;
            #my %c = (alid => $this_alid, tally => $this_tally); #change to make
            # In raw SQL I would use alid (which is unique) but because of DBIx::Class
            # and the fast that each ( action, period, start ) should also be unique, we don't need to add alid
            my %c = ( tally => $this_tally); #change to make
            # $sec_rs->update( \%c ); #this knobbled the d value with the y value!
            #... but it failed
            $tally{"$this_p"} = $this_tally;
            my $u_rs = $self->resultset('ActivityLog')->search({ alid => "$this_alid"})->update( \%c );
            eval {
                #if($sec_rs->is_changed()){
                if($u_rs->is_changed()){
                   warn "INCREMENTED $this_p for $username";
                }else{
                   warn 'activity increment failed, sorry.';
                }
            };
        }
    }
# NTS alid, user, period, tally, action, start, end, description
    #warn Dumper(\%updated);
    # if any are missing we insert them
    PERIOD_LOOP: foreach my $period (@periods){
        next PERIOD_LOOP if $updated{$period}; 
        my %create_data;
        if ($period eq 'd'){
            %create_data = ( start => \'CURDATE()', end => \'CURDATE()+1');
        }
        elsif ($period eq 'y'){
            %create_data = ( start => \'concat(date_format(NOW(), "%Y"), "-01-01")',
                end => \'concat(date_format(NOW(), "%Y"), "-12-31")');
        }
        $create_data{'period'} = $period;
        $create_data{'user'} = $pe_id;
        $create_data{'action'} = $action;
        $create_data{'description'} = $desc;
        #$create_data{'tally'} = 1; 
        if($create_data{'user'} && $create_data{'user'} ne '' && $create_data{'start'} ){
  # add entry to database
           $tally{"$period"} = 1;
           my $dbh = $self->resultset('ActivityLog')->create( \%create_data );
           $dbh->update;
        }elsif($create_data{'start'} && $opt{D}>=99){
            warn Dumper(\%create_data) . $opt{'comment'};
        }
        # NTS add Hour and month code
        # $act_id = $dbh->id; # if we need it
    } 

    # We _could_ break out as soon as an infraction is found but to keep the reports clean we 
    # do the above accounting first and then take actio
    my $object= $desc; $object=~s/ .*//;
    my $acl_rs = $self->resultset('ActivityAcl')->search({
        action => "$action",
        object => {'like' => "$object"},
        -or => [
                user => "$pe_id", #people can only have one pe_id
                user => "0", # everyone is zero
        ],
        -or => [
                acid => "$ac_id", #people can only have one ac_id
                acid => "0", # everyone is in account zero
        ],
        #-or => [
                # agh! we have to join the groups table with the people table with activity_acl.group
                # this seems rather heavy for each and EVERY request;
                # might have to re-think this
            # PLUS 'group' is a protected word in mySQL sooo a BAD name for a column in a table! 
        #],
        -or => [
            # It should be possible to build these arrays from the %tally hash
            -and => [
                period => 'd',
                tally => "$tally{'d'}",
                type => 'soft',
            ],
            -and => [
                period => 'd',
                tally => {'<=' => "$tally{'d'}"},
                type => {'!=' => 'soft'},
            ],
            -and => [
                period => 'y',
                tally => $tally{'y'},
                type => 'soft',
            ],
            -and => [
                period => 'y',
                tally => {'<=' => "$tally{'y'}"},
                type => {'!=' => 'soft'},
            ],
            # NTS have to add m,w,H,M,S
        ],
      }
    );

    while( my $act = $acl_rs->next){
        #%activity = %{ $act };
        foreach my $col (keys %{ $act->{_column_data} }){
            $activity{"$col"} = $act->{_column_data}->{$col};
        }
        # hmmm we may match against more than one, but really we just want the most applicable
        # don't we?

        # If their actions are forbidden then we can simple alter the runmode here
        # _or
        # take action
        if(1==1 || $activity{is_bad}){ 
            #$activity{report} = 'warn_popup';
            #warn "$username tried bad things";
            _enforce_acl($self,\%activity); 
            #$self->Notice::Security::_enforce_acl(\%activity); 
            #warn "that told them";
        }
    }

  } #else resultset('ActivityLog')->search did not error
 
    # purging things like last years second/minuet/hour entries will be a manual admin task until 
    # we can set limits in the config and then purge them automatically

}



=head3 postrun_callback

If we need to, we can take action after the runmode has been processed. 

though we probably don't want to as all the enforcing happens in prerun
(because: why let them even get to the runmode?)

=cut

sub postrun_callback {
  warn "You are in Notice::Security::postrun_callback" if $opt{D}>=10;
  my $self = shift;
  my $runmode = $self->get_current_runmode;
  my $username = '';
  eval {
    if($self->authen->username){
        $username .= $self->authen->username;
    }
  };
  if($@){
    $username .= $self->{__PARAMS}->{'username'};
  }

  # warn "and now we are in Notice::Security::postrun_callback";
    
  if($self->param('sec') || $self->param('sec_action') || $self->param('sec_error')){
    warn "Looks like " . $self->param('sec');
    my $who = $self->param('sec');
    $who=~s/.* for //;
    unless($who || $username){  $who .= 'whom ever is at'; $username .= $ENV{REMOTE_ADDR}; }
    warn "so we are going to spank $who ($username)";
  }

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
L<CGI::Application::Plugin::Authentication>, 

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2001-2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut

