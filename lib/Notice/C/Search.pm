package Notice::C::Search;

use warnings;
use strict;
use base 'Notice';
my %submenu = (
   '1.1' => [
        '1' => { name=> 'Person', rm => 'ppl', class=> 'navigation'},
        '2' => { name=> 'Place', rm => 'plc', class=> 'navigation'},
        '3' => { name=> 'Thing', rm => 'thng', class=> 'navigation'},
    ],
);



our $VERSION = 0.01;

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This one is huge - it has to be the gatekeeper of information, (keeping the strict hyrachy of Notice) while being as helpful as possible.
It should be as helpful as a speedballing spanial but as discreet as George, (the porter at a gentelmans club.)

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
    $runmode=~s/.*\///;

    my $known_as;
    $known_as = $self->param('known_as');
    $self->tt_params({title => 'Notice CRaAM ' . $runmode ." ". $known_as ." at ". $ENV{REMOTE_ADDR}});
}

=head2 RUN MODES

=head3 index

  * Purpose - display potential sales
  * State   - To be written
  * Function- The index page lists scheduled contacts, i.e. who you should be calling next 
                and who you should be calling upon

  * The other runmodes will display the actual contact details

# N.B. Each time a sales contact is displayed that is logged against that member of staff
# The team-leader config can set a limit on the number of contacts that can be viewed each
# minute, hour, day, week, month, year
# dynamic limits that are calculated for each user each night. These are in place to check
# how many are viewed and that they are not falling behind or data mining.

=cut

sub index: StartRunmode {
    my ($self) = @_;
    $self->tt_params({
	message => 'Welcome to the Search page!',
		  });
    $self->plt;
    return $self->tt_process();
    
}

=head3 people

  we need the obvious to be right

=cut

sub people: Runmode {
  my $self = shift;
    $self->redirect('ppl');
}

=head3 ppl

    Search for people

=cut

sub ppl: Runmode {
    my ($self) = @_;

    # check that we don't already have this contact
        # if we do and it is in this branch then alert
        # if we do and it is not somewhere that this user can view then add it
    #

    $self->tt_params({
    message => "I'm getting on a bit and can't remember that person. Sorry sir.",
          });
    $self->plt;
    return $self->tt_process();
}
    

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
Please fix any bugs, add any features you need and you can report them through GitHub or CPAN.

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

