package Notice::C::Details;

use warnings;
use strict;
use lib 'lib';
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

Notice::C::Details - Template controller subclass for Notice

=head1 ABSTRACT

This is where a user can view/change their details in Notice.

=head1 DESCRIPTION

This lets you update your password and email, menu and even create a css for yourself/your account/each page

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    $self->tt_params({ submenu => \%submenu });
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

    $message = 'Welcome to the Your Details section<br />';
    $body .=qq |In this section you can: <br />
                 add,view,edit your details in this copy of Notice, (and its associated network.)<br />
|;
    
    $self->tt_params({
    action  => "$surl/aliases",
    domains => \@domains,
	message => $message,
    body    => $body
		  });
    return $self->tt_process();
}

=head3 css

View and edit the css for your account/user and even per page (eventually)

=cut


sub css: Runmode {
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;

    $message = 'Here you can update the CSS that you user for this site.<br />';
    $body .=qq |You can create a new css just for you. If you give it a name then others will be able to find and use it. They will even be able to take a copy and change it for their needs. You can even have a css for each page!<br />
        Account admin can set a default css for their account, and Notice_admin can set the default css for the whole site.<br />
|; 


    $self->tt_params({
    message => $message,
    body    => $body
          });
    return $self->tt_process();
}

=head3 menu

View and edit which menu items turn up. The ones that you can chose from a determined by your account;group;pe_level

=cut

sub menu: Runmode {
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;

    $message = 'Here you can set which modules and function show up in your navigation menu, (on the left).<br />';
    $body .=qq |
|; 

    $self->tt_params({
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


