package Notice::C::Beekeeping;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';

my %submenu = (
   53 => [
        '1' => { name=> 'New Apiary', rm => 'add_apiary', class=> 'navigation'},
        '2' => { name=> 'Add Hive', rm => 'add_hive', class=> 'navigation'},
        '3' => { name=> 'List Bees', rm => 'list_bees', class=> 'navigation'},
        '70' => { name=> 'Nantional News', rm => 'national_news', class=> 'navigation'},
        '99' => { name=> 'Front Page', rm => 'walk_in', class=> 'navigation'},
    ],
);


=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

This creates a Beekeeping corner in Notice

=head1 DESCRIPTION

To keep track of hives and hive-records. Lets people slide in through a side-door, (rather than the main sign-up).

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/!main|!swarm/);
    $self->tt_params({ submenu => \%submenu });
}

=head2 RUN MODES

=head3 main

  * This is going to display a to-do list based on entries in
    hive data-cards.

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $username = '';
    if($self->authen->username){ 
        $username = $self->authen->username;
        $self->tt_params({ username => $username});
    }else{
        $self->tt_params({
	        title   => 'BKBK - BeeKeeping BookKeeping',
            show_login=>1, 
            no_home => 1,
            dest=>'beekeeping',
        }); 
    }
    $self->tt_params({
		  });
    return $self->tt_process();
    
}

=head3 list

list the apiaries

=cut

sub list: Runmode{
	my $self = shift;
	$self->tt_params({ message => 'You have not added an Apiary yet'});
 	return $self->tt_process('Notice/C/Beekeeping/main.tmpl');
}

=head3 walk_in

show what the public can see

=cut

sub walk_in: Runmode{
    my $self = shift;
    $self->tt_params({ hide_login=>1});
    return $self->tt_process();
}

=head3 local_news

show the news for your region/area

=cut

sub local_news: Runmode{
    my $self = shift;
    return $self->tt_process();
}


=head3 national_news

show the news for a nation

=cut

sub national_news: Runmode{
    my $self = shift;
    return $self->tt_process('Notice/C/Beekeeping/national_news.tmpl');
}

=head3 add

add the apiaries/hives

=cut

sub add: Runmode{
    my $self = shift;
    $self->tt_params({ message => 'Add a hive, hive-record or apiry here'});
    return $self->tt_process('Notice/C/Beekeeping/main.tmpl');
}

=head3 swarm

How to identify the type of swarm (including zergling)
and a list of your local bee keeper

=cut

sub swarm: Runmode{
    my $self = shift;
    $self->tt_params({ message => 'Sounds like fun, but is it a honey bee swarm?'});
    return $self->tt_process();
}


=head3 hive

hive(s)

=cut

sub hive: Runmode{
    my $self = shift;
    $self->tt_params({ message => 'You have no hives'});
    return $self->tt_process('Notice/C/Beekeeping/main.tmpl');
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
Please fix any bugs or add any features you need. You can report them through GitHub.

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

