package Notice::C::Prefs;

use warnings;
use strict;
use base 'Notice';
use Data::Dumper;

# NTS pull this from the menu and modules table
my %submenu = ( 
   '1.2' => [
        '1' => { peer => 1, name=> 'Preferences', rm => 'prefs', class=> 'navigation'},
        '2' => { name=> 'CSS', rm => 'css', class=> 'navigation'},
        '3' => { name=> 'Menu', rm => 'menu', class=> 'navigation'},
    ],
);


=head1 NAME

Notice::C::Prefs - Template controller subclass for Notice

=head1 ABSTRACT

This is where a user can view/change their preferences. Vanilla or more interesting?

=head1 DESCRIPTION

This lets you update your prefs, (this is probably going to be things like search-bias and defaults for data entry.)

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    my $runmode;
    $runmode = ($self->query->self_url);
    $runmode =~s/\/$//;
    if($self->param('rm')){ 
        $runmode = $self->param('rm'); 
    }
    $runmode =~s/^.*\/(.+\/.+)$/$1/;
    if($self->param('id')){
        my $id = $self->param('id');
        if($self->param('extra1')){
            my $extra = $self->param('extra1');
            $runmode =~s/\/$extra[^\/]*//;
        }
        if($self->param('sid')){
            my $sid = $self->param('sid');
            $runmode =~s/\/$sid[^\/]*//;
        }
        $runmode =~s/\/$id[^\/]*$//;
    }
    if($runmode=~m/\/.*[=].*/){
        $runmode=~s/\/.*//;
    }else{
        $runmode=~s/.*\///;
    }
    $runmode=~s/.*\///;

    my $known_as;
    $known_as = $self->param('known_as')||'';
    # BUG https://localhost/cgi-bin/index.cgi/email/edit_alias/blah/1/ has a $runmode of '1'
    #     https://localhost/cgi-bin/index.cgi/email/edit_alias/564 is fine
    # BUG https://localhost/cgi-bin/index.cgi/email/edit_alias/ibm_developer@alexx.net rm is the email address
    $self->tt_params({title => 'Notice CRaAM ' . $runmode ." - $known_as at ". $ENV{REMOTE_ADDR}});
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

    $message = 'Welcome to the Your Preferences section<br />';
    $body .=qq |In this section you can: <br />
                 add,view,edit your details in this copy of Notice, (and its associated network.)<br />
|;
    
    $self->tt_params({
    action  => "$surl/aliases",
    domains => \@domains,
    submenu => \%submenu,
	message => $message,
    body    => $body
		  });
    return $self->tt_process();
}


1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
(Other than it has not been writen yet.)
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


