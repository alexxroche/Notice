package Notice::C::Beekeeping;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

To keep track of hives and hive-records.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/!main/);
}

=head2 RUN MODES

=head3 main

  * This is going to display a to-do list based on entries in
    hive data-cards.

=cut

sub main: StartRunmode {
    my ($self) = @_;
	my $heading =qq 'Welcome to the GB.com Beekeeping Site';
	my $body =qq ' <br />

Here we take the "What _ever_ works" attitude, and for us
that includes a database where anyone can store the important data that they collect about
the bees that they work with.

For example, you can create a list of all of the locations where you keep beehives, (apiary)
and then make a note of each hive/colony that you have in each apiary. Then the fun part:
you can store hive records for each hive and we will graph the data for you so that you can
watch for patterns.<br />
<br />
So to start off with you should <a class="black" href="beekeeping/add">enter some locations</a>.<br />
<br />
<br />If this is your first time you will have to create an account and log in
<br />then you can <a class="black" href="beekeeping/list">list</a> your apiraies
<br />or add a <a class="black" href="beekeeping/add">new record entry</a> for an existing <a class="black" href="beekeeping/hive">hive</a>
        
    ';
    unless($self->authen->username){ $self->tt_params({show_login=>1}); }
    $self->tt_params({
    no_home => 1,
	heading => $heading,
	body => $body,
	title   => 'Beekeeping'
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

=head3 add

add the apiaries/hives

=cut

sub add: Runmode{
    my $self = shift;
    $self->tt_params({ message => 'Add a hive, hive-record or apiry here'});
    return $self->tt_process('Notice/C/Beekeeping/main.tmpl');
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

