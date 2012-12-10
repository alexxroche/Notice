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
    ],
);


=head1 NAME

Notice::C::Config - Template controller subclass for Notice

=head1 ABSTRACT

This is where Notice is configured from. Only those in the Notice_Admin group
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
    submenu => \%submenu,
	message => $message,
    body    => $body
		  });
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
    scalar localtime . $self->query->p('Ajax example, (Look Ma, no page reload!)');
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


