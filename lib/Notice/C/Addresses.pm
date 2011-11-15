package Notice::C::Addresses;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This one deals with Addresses, (crazy nameing schema! I know.)

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;

}

=head2 RUN MODES

=head3 index

  * Purpose - display addresses
  * State   - To be written
  * Function- to remove that error and act as a blank Class.

=cut

sub index: StartRunmode {
    my ($c) = @_;
    $c->tt_params({
	message => 'Hello world!',
	title   => 'C::Addresses'
		  });
    return $c->tt_process();
    
}

=head3 _add

Add an address
expects an account ID (ac_id)
returns ad_id on success or NULL on failure

=cut

sub _add: Runmode{
	my $c = shift;
    my $ac_id;
    $ac_id = $c->param('ef_acid');
    if($ac_id!~m/^\d+$/){
        $ac_id = $c->param('pe_acid');
    }
    unless($ac_id=~m/^\d+$/){ $ac_id = $c->param('ac_id'); } # last gasp

    unless($ac_id=~m/^\d+$/){ return "Failed to find an account for this address $ac_id"; }
    # check we don't have this address already in _this_ account
    # NTS not written
    #my($query)="SELECT ad_id from address where ad_adpostcode like '%$values->{ad_postcode}%' $child_accounts order by ad_id";
    my $ad_id;
    my $data;
    $data = $c->param('create_address');
    if($data){
        my $comment = $c->resultset('Address')->find_or_create( $data );
        $comment->update;
        $ad_id = $comment->id;
    }else{
        return "No data found to create address";
    }
    #$ad_id = "Added address ($ad_id) to $ac_id"; #debug
    return $ad_id;
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

