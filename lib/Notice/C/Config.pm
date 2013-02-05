package Notice::C::Config;

use warnings;
use strict;
use base 'Notice';
use Data::Dumper;

# NTS pull this from the menu and modules table
my %submenu = ( 
   '1.0' => [
        '1' => { peer => 1, name=> 'Modules', rm => 'modules', class=> 'navigation'},
        '2' => { peer => 1, name=> 'Security', rm => 'security', class=> 'navigation'},
        '3' => { peer => 0, name=> 'Greeting', rm => 'greet', class=> 'navigation'},
        '4' => { peer => 0, name=> 'CSS', rm => 'css', class=> 'navigation'},
        '5' => { peer => 0, name=> 'Logo', rm => 'logo', class=> 'navigation'},
    ],
);


=head1 NAME

Notice::C::Config - Template controller subclass for Notice

=head1 ABSTRACT

This is where Notice is 0onfigured from. Only those in the Notice_Admin group
should have access here. The user equivelent is "Your Details"

=head1 DESCRIPTION

This lets you update configurations, (e.g. the welcome message)
and modules for this installation of Notice

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    $self->tt_params({ submenu => \%submenu });
}

=head2 RUN MODES

=head3 main

  * Let the use know which subsections of Notice::Email they have access to 

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);

    my ($ac_id,@domains);
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }
    if($ac_id){
        # NTS need to join the group table so that we only list domains that are not in the
        # "no email" domains group
        @domains = $self->resultset('Domain')->search({
            do_acid=>{'=',"$ac_id"}
             },{
        });
    }
    #if($domains[0]->{_column_data}{do_name}){
    if($domains[1]->{_column_data}{do_name}){
        $opt{default_domain} = '/' . $domains[1]->{_column_data}{do_name};
    }

    $message = 'Welcome to the Configuration section<br />';
    $message .=qq |In this section you can: <br/>
                 add,view,edit the details of this copy of Notice, (and its associated network.)<br/>
|;

    $message .= _ajax()
      . $q->div({-id=>'box1'},'This is div1<br /><br />')
      . $q->div({-id=>'box2'},'Another div, div2')
      . $q->button(-id=>'b1', -value=>'Alter div1')
      . $q->button(-id=>'b2', -value=>'Alter div2');

    
    $self->tt_params({
    action  => "$surl/aliases",
    domains => \@domains,
	message => $message,
    body    => $body
		  });
    return $self->tt_process();
}


=head3 css

    set the CSS for this account

=cut

sub css: Runmode {
    my ($self) = @_;
    my ($css,$message,$error,$page);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);
    my ($ac_id);
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }

    if( $self->in_group('HR',$self->param('pe_id')) || $self->param('pe_id') == 1){

        $self->tt_params({ is_admin => 1 });

        my $acc_css = '';
        if(defined $self->cfg("www_path")){
            my $css_path = $self->cfg("www_path") . "/css";
            if(-f "$css_path/${ac_id}.css"){ 
                $acc_css = "${ac_id}.css"; 
                open(CSS, "<$css_path/${ac_id}.css" );
                while(my $line = <CSS>){
                    $css .= $line;
                }
                close(CSS);
            }else{ $css = "/* css for Account: $ac_id */"; }
            $self->tt_params({ name => "${ac_id}.css" });
        }

        my $code;
        my $old_css_name;
        my $css_name;
        if( $q->param('update') && (
                    $q->param('update') eq "Add" ||
                    $q->param('update') eq "Save" ||
                    $q->param('update') eq "Update"
                    )
        ){
            #use DateTime qw /now/;
            #my $now = DateTime->now();         # these three lines work but why bother?
            $code = $q->param('code');
            $old_css_name = $q->param('id');
            $css_name = $q->param('name');

            if($css && $code ne $css){
                # NTS you are here writing this back to 
                if(length($css) < length($code)){
                    $message = "Increaed CSS by " . ( length($code) - length($css) ) . ' characters';
                }else{
                    $message = "CSS reduced by " . ( length($css) - length($code) ) . ' bytes';
                }
                if(defined $self->cfg("www_path")){
                    my $css_path = $self->cfg("www_path") . "/css";
                    unless(-d "$css_path"){
                        `mkdir -p "$css_path"`;
                    }
                    if(-w "$css_path/${ac_id}.css"){
                        $acc_css = "${ac_id}.css";
                        open(CSS, ">$css_path/${ac_id}.css" ) or $message = 'Could not write CSS to file';
                        print CSS $code;
                        close(CSS);
                        $css = $code;
                    }else{
                        $self->tt_params({ error => 'CSS path does not exist'});
                    }
                }

            }else{
                warn "no css or code eq css";
            }

        }

        if($acc_css){ 
            $page .= "this account has a default layout called " . $acc_css;
        }else{
            $page .= "this account FALLS back to the default css of main.css";
            $acc_css = 'main.css';
        }
            
        #if($self->param('css')){
        #    $page .= " but THIS user has a personal override of " . $self->param('css');
        #}else{
        #    $page .= ' - you can edit the account\'s CSS here';
        #}

        # we don't check per-page CSS

        $self->tt_params({
        action  => "$surl/css",
        message => $message,
        msg => $page,
        editor1 => $css,
              });
        #return $self->tt_process('default.tmpl');
        return $self->tt_process();
    }else{
       return $self->tt_process('default.tmpl', {error => 'You have to be in the HR group to edit the account CSS' });
       warn "You " . $self->param('pe_id') . " are not in the HR group";
    }
}


=head3 logo
   
    set the logo at the top
   
=cut
   
sub logo: Runmode {
    my ($self) = @_;
    my ($welcome,$message);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);
    my ($ac_id);
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }
    $message = 'Here you will be able to upload a small Logo for this account';
   
    if( $self->in_group('HR',$self->param('pe_id')) || $self->param('pe_id') == 1){
        $self->tt_params({ is_admin => 1 });
   
        $self->tt_params({
        action  => "$surl/aliases",
        page => $message,
              });
        return $self->tt_process('default.tmpl');
    }
}


=head3 greet

  * The message that users get on the front page AFTER logging in
  - if they do not have a default homepage

=cut

sub greet: Runmode {
    my ($self) = @_;
    my ($welcome,$message);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);
    my ($ac_id);
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }

    if( $self->in_group('HR',$self->param('pe_id')) || $self->param('pe_id') == 1){ 
        $self->tt_params({ is_admin => 1 }); 

        my $cf_id = 12; # this should be pulled from Conf!

        if($q->param('update') || $q->param('add') ){
            my $wel_rc = $self->resultset('ConfData')->search({
                                      -and => [
                                                 cfd_key => 'welcome',
                                                 cfd_acid => "$ac_id"
                                                ]})->first;
            my $msg_rc = $self->resultset('ConfData')->search({
                                      -and => [
                                                 cfd_key => 'message',
                                                 cfd_acid => "$ac_id"
                                                ]})->first;
            #if($q->param('update')){
            #    warn "we are doing an " . $q->param('update') . ' for acc: ' . $ac_id;
            #}elsif( $q->param('add') ){
            #    warn "we are doing an " . $q->param('add') . ' for account: ' . $ac_id;
            #    warn " Welcome: " . $q->param('welcome') . ' with a message of length ' .  length($q->param('message'));
            #}
            # NOTE we should only update if it has changed
            if($wel_rc){
                $wel_rc->update({ cfd_value => $q->param('welcome') })->update;
                $message .= " Welcome updated ";
            }else{
                $self->resultset('ConfData')->create({ cfd_cfid => $cf_id, cfd_acid => $ac_id, cfd_key => 'welcome', cfd_value => $q->param('welcome') })->update;
                $message .= " Welcome created ";
            }
            if($msg_rc){
                $msg_rc->update({ cfd_value => $q->param('message') })->update;
                $message .= " message updated ";
            }else{
                $self->resultset('ConfData')->create({ cfd_cfid => $cf_id, cfd_acid => $ac_id, cfd_key => 'message', cfd_value => $q->param('message') })->update;
                $message .= " message created ";
            }
            $self->tt_params({ message => $message });
        }
    }

    if($ac_id){
        # NTS need to join the group table so that we only list domains that are not in the
        # "no email" domains group
        my $conf_rc = $self->resultset('ConfData')->search({
            -and => [
             cf_name => 'greeting',
             cfd_acid => "$ac_id"
            ]
             },{
            join => ['config']
        });
       my $ac = $self->resultset('Account')->search({ ac_id => "$ac_id" })->first;

       if($ac && ( $ac->ac_name || $ac->ac_id )){
        if($ac->ac_name){
           $self->tt_params({ ac_name => $ac->ac_name });
        }
        $self->tt_params({ ac_id => $ac->ac_id });
       } 
        
       if($conf_rc){

            while(my $cfd = $conf_rc->next){
                if($cfd->cfd_key eq 'welcome'){
                    $welcome = $cfd->cfd_value;
                }elsif($cfd->cfd_key eq 'message'){
                    $message = $cfd->cfd_value;
                }
            }

            $self->tt_params({
                main_welcome => $welcome,
                main_message => $message
               });
       }
       # if we have an update then we should do that here
    }
    return $self->tt_process();
}

=head3 ajax_alter_div1

runmodes called via ajax
- we are able to prevent users from accessing these directly

=cut

sub ajax_alter_div1 : Runmode {
  my $self = shift;
  if($self->param('id')){
    # foreach my $sp ( $self->param ){ warn "$sp = " . $self->param($sp); } #debug
    return $self->redirect($self->query->url . '/' . $self->param('mod'));
  }else{
    scalar localtime() . $self->query->p('Ajax example, (Look Ma, no page reload!)');
  }
    
}

=head3 ajax_alter_div2

How specific do these have to be?
It would be nice to abstract them;
sub ajax_verb_id : Runmode {
}

=cut

sub ajax_alter_div2 : Runmode {
  my $self = shift;
  reverse $self->query->param('some_text');
}

=head3 _ajax

We are going to generalise this where possible so that every module 
 can have access to ajax for any function that will improve the user experience.

=cut

sub _ajax {
   my $rm = shift;
   if($rm){ warn $rm; }
  return '<style type="text/css">
      body { background-color: #eee }
      #box1, #box2 { border: 1px solid gray; width: 200px; height: 80px; padding: 4px; margin: 10px; }
      #box2, #b2   { border: 1px solid blue; }
  </style>
  <script type="text/javascript">
    $(function(){
      $("#b1").click(function() {
          $("#box1").load(
              "config",
              { "rm": "ajax_alter_div1" }
              )
      });
      $("#b2").click(function() {
          $("#box2").load(
              "config",
              { "rm": "ajax_alter_div2", some_text: $("#box2").text() }
              )
      });
    });
    </script>';
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

Copyright (C) 2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut


