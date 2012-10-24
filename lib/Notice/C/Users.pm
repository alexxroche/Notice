package Notice::C::Users;

use warnings;
use strict;
use lib 'lib'; #DEBUG
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

Notice::C::Users - Template controller subclass for Notice

=head1 ABSTRACT

This is where we see the people that actually have access to Notice
We can add users and can view/change their details, if we have permission.

=head1 DESCRIPTION

This lets you see the people in your account, and those in child accounts.

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
    my ($message,$body,%opt,$who_rs);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);
    our $pe_id;
    our $ud_rs;
    if($self->param('ef_peid')){ $pe_id = $self->param('ef_peid'); }
    elsif($self->param('pe_id')){ $pe_id = $self->param('pe_id'); }

    if($q->param('Edit')){
        $self->tt_params({ edit => 'Edit' });
    }
    # NOTE we have to let them update their details here


    if($pe_id && $pe_id=~m/^\d+$/){
        $ud_rs = $self->resultset('People')->search({pe_id => $pe_id})->first;
    }else{
        our $username;
        $username = $self->authen->username;
        $ud_rs = $self->resultset('People')->search({pe_email => $username})->first;
    }
    if($self->param('id') && $self->param('id')=~m/^\d+$/){
        our $who_id = $self->param('id');
        $who_rs = $self->resultset('People')->search({pe_id => $who_id})->first;
    }else{
        $who_rs = $ud_rs;
    }
    our $ac_id;
    eval {
          $ac_id = $who_rs->pe_acid;
    };
        my $ef_acid = $self->param('ef_acid');
        my $ac_tree = $self->param('ac_tree');
        my @people = $self->resultset('People')->search({
            -or => [
                pe_acid => $ac_id,
                pe_acid => $ef_acid,
                'accounts.ac_tree' => {'like' => "$ac_tree\%" }
            ]
            },{
            join => ['accounts'],
            '+columns' => [ 'accounts.ac_name','accounts.ac_tree'] 
           });
        $self->tt_params({ people => \@people });

    my @ranks = $self->resultset('Rank')->search({'ra_boatn' => 'before'},{ 'columns'   => ['ra_id','ra_name'] });
    my @accounts = $self->resultset('Account')->search({
        -or => [
        'ac_id' => $ac_id,
        'ac_useradd' => { '>', '40' }, 
        ],
        },{ 'columns'   => ['ac_id','ac_name'], order_by => {-asc =>['ac_id+0','ac_id']}
    });
    my @countries = $self->resultset('Country')->search({'curid' => { '!=', undef },},{'columns'   => ['iso']});
    $self->tt_params({
        ranks   => \@ranks,
        accounts=> \@accounts,
        countries=> \@countries,
    });

    
    $message = 'Welcome to the Your Details section<br />';
    $body .=qq |In this section you can: <br />add,view,edit your details in this copy of Notice, (and its associated network.)<br />|;
    
    $self->tt_params({
    action  => "$surl",
    p       => $ud_rs, #person doing the looking
    d       => $who_rs, #person being looked at (usually the same)
    submenu => \%submenu,
	message => $message,
    page    => $body
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


