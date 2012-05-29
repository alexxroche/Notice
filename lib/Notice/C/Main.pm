package Notice::C::Main;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This is like the index.html once they have logged in

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/^(?!main)/);
    # debug message
    if($self->param('i18n') && $self->param('debug')){ 
        $self->tt_params({warning => '<span class="small lang i18n">Lang:' . $self->param('i18n') . '</span>'}); 
    }
}

=head2 RUN MODES

=head3 main

  * Display the welcome message for the account that they are in
  * Display the side menu and the search menu at the top,
    (if that is enabled for their account and user.)

=cut

sub main: StartRunmode {
    my ($self) = @_;
	my $message = '';
    if($self->param('message')){ $message = $self->param('message'); }
    my $no_wrapper = 1;
    my $q = $self->query();
    if($self->authen->is_authenticated){
        $no_wrapper = 0;
    }else{
        #my $dest = $self->query->url;
        #return $self->redirect("$dest/login");
        return $self->forward('login');
        exit;
        $message = 'Welcome - you probably want to login <a href="' . $self->query->url . '/main/login">here</a>';
         $self->tt_params({
            no_wrapper => $no_wrapper,
            message => $message,
        });
        $self->plt;
        return $self->tt_process();
    }
    if($q->param('debug')){
        use Data::Dumper;
        my $dump .= Dumper(\%{ $q });
        $dump=~s/\n/<br \/>\n/g;
        $message .= $dump;
    }
    my $ef_acid = '0';
    if($self->param('ef_acid')){ 
        $ef_acid = $self->param('ef_acid');
    }elsif($self->session->param('ef_acid')){
        $ef_acid = $self->session->param('ef_acid');
    }

    my $g = $self->resultset('ConfData')->search({
        #'cfd_acid' => { '=', "$ef_acid"}, 
        'ac_id' => { '=', "$ef_acid"}, 
        'cf_name' => { '=', "greeting"}, 
        -or => [
            'cfd_key' => { '=', "welcome"}, 
            'cfd_key' => { '=', "message"}, 
         ],
       },{
        join     => ['config','ac_parent'],
        columns => ['cfd_key','cfd_value'],
    });
    my ($greeting,$welcome);
    while(my $v = $g->next){
        if($v->cfd_key eq 'welcome'){ 
            $greeting = "<blockquote class=\"header\">" .$v->cfd_value . "</blockquote>"; 
        }else{ $welcome = $v->cfd_value; }
    }
    if($welcome){ $welcome =~s/([^<br\s?\/?>])\s*\n/$1<br \/><br \/>\n/g; }

    #if($self->param('i18n')){ $message .= '<span class="small">Lang:' . $self->param('i18n') . '</span>'; }

    $self->tt_params({
    greeting => $greeting,
    welcome => $welcome,
    no_wrapper => $no_wrapper,
	message => $message,
		  });
    $self->plt;
    return $self->tt_process();
    
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

