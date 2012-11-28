package Notice::C::Users;

use warnings;
use strict;
use lib 'lib'; #DEBUG
use base 'Notice';
use Data::Dumper;

# NTS pull this from the menu and modules table
my %submenu = ( 
   '1.4.2' => [
   #     '1' => { peer => 1, name=> 'Preferences', rm => 'prefs', class=> 'navigation'},
        '2' => { name=> 'tree', rm => 'tree', class=> 'navigation'},
   #     '3' => { name=> 'Menu', rm => 'menu', class=> 'navigation'},
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
        my $ac_tree = $self->param('ac_tree');
        my %child;
        if( $self->param('pe_level') && $self->param('pe_level') >= 100 
            || $self->param('inc_child') || $self->session->param('inc_child')
        ){
            # We don't want to clutter things with child accounts unless the user wants that
            %child = ( 'accounts.ac_tree' => {'like' => "$ac_tree\%" });
        }
        my $ef_acid = $self->param('ef_acid');
        my @people = $self->resultset('People')->search({
            -or => [
                #pe_acid => $ac_id,
                pe_acid => $ef_acid,
               \%child
            #{ 'accounts.ac_tree' => {'like' => "$ac_tree\%" } }
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

    
    $message = 'The people in this account<br />';
    $body .=qq |In this section you can: <br />add,view,edit the people in this account<br />|;
    
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

=head3 tree

  * Gives us a list of everyone in tree format

=cut

sub tree: Runmode {
    my ($self) = @_;
    my ($message,$body,%opt,$who_rs,%child);
    my $ef_acid = $self->param('ef_acid');
    my $ac_tree = $self->param('ac_tree');
    if( $self->param('pe_level') && $self->param('pe_level') >= 100
        && ! $self->param('no_child')
    ){ 
        # We want to clutter things with child accounts
        %child = ( 'accounts.ac_tree' => {'like' => "$ac_tree\%" });
    }

    my @people = $self->resultset('People')->search({
            -or => [
                #pe_acid => $ac_id,
                pe_acid => $ef_acid,
               \%child
            #{ 'accounts.ac_tree' => {'like' => "$ac_tree\%" } }
            ]
            },{
            join => ['accounts'],
            '+columns' => [ 'accounts.ac_name','accounts.ac_tree']
           });

    $self->tt_params({
    people  => \@people,
    #p       => $ud_rs, #person doing the looking
    #d       => $who_rs, #person being looked at (usually the same)
    submenu => \%submenu,
    #message => $message,
    #page    => $body
          });
    return $self->tt_process();
}

=head3 _user_details

  * Gives us $hash{pe_id} and we will populate it with data

=cut

sub _user_details: Runmode {
    my ($self,$ud) = @_;
    #my ($self) = shift;
    #my $ud = shift;
    eval {
        unless(defined $ud->{pe_id}){
            return 0;
        }
    };
    if($@){ 
        warn "$@ $?"; return 0; 
    }
    my $pe_id = $ud->{pe_id};
    my $user_details = $self->resultset('People')->search({ pe_id => "$pe_id" })->first;
    %{ $ud } = %{ $user_details->{_column_data} };
    #my %_cd = %{ $user_details->{_column_data} };

=pod 

    #foreach my $row (keys %{ $user_details->{_column_data} }){
    foreach my $row (keys %_cd ){
        if(defined $_cd{$row}){
            $ud->{$row} = $_cd{$row}
        }
    }

=cut

    #warn Dumper(\$user_details);
}

=head3 _set_passphrase

    This is used by Notice::C::ForgotPassword to update the people.pe_passwd field
    If there is an error, we return it and if there is no error we return 0   

    It expects either a pe_id OR a pe_loggedin 
    AND a new passphrase

=cut

sub _set_passphrase {
    my ($self,$pe_id,$pe_password,$pe_loggedin) = @_;
    my %create_user;
    eval {
        use Crypt::CBC;
        use MIME::Base64;

        my $cipher = Crypt::CBC->new({
            key         => $self->cfg("key"),
            iv          => $self->cfg("iv"), # 128 bits / 16 char
            cipher      => "Crypt::Rijndael",
            literal_key => 1,
            header      => "none",
            keysize     => 32 # 256/8
        });

        my $encrypted = $cipher->encrypt($pe_password);
        # base64 encode so we can store in db
        $encrypted = encode_base64($encrypted);
        # remove trailing newline inserted by encode_base64
        chomp($encrypted);
        $create_user{"pe_password"} = $encrypted;
    };
    if($@){ 
        use Digest::MD5 qw(md5_hex);
        $create_user{"pe_password"} = md5_hex($pe_password); 
    }
    $create_user{"pe_passwd"} = md5_hex($pe_password);
    if($pe_loggedin){
        $create_user{"pe_loggedin"} = \'NOW()';
        $create_user{"pe_confirmed"} = \'NOW()';
    }
    my $rc = $self->resultset('People')->search({ 
                        -or => [
                            'pe_id' => $pe_id,
                            'pe_loggedin' => $pe_loggedin
                        ]
                    })->first;
    if($rc){
        my $count = $rc->pe_loggedin;
        $count=~s/.*_//g;
        $count++;
        $create_user{"pe_loggedin"} = $count;
        $rc->update( \%create_user );
        #if($rc->is_changed()){
            return 0;
        #}else{
        #    return 'Sorry - failed to update your passphrase' . $rc->error ;
        #}
    }else{
        return 'failed to find user';
    }
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


