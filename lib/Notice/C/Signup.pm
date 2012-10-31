package Notice::C::Signup;

use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

Provide signup for Notice. This lets 'walk-ups' create
an account and user for themselves. In some installs of
Notice this would not be wanted.

You should also be able to change this so that they can enter
their details, and create a disabled account, that is enabled
when they prove that their signup email address is real.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
}

=head2 RUN MODES

=head3 main

  * To display a signup page and process the form when submitted
  * Expects a form with user data
  * Creates user (with optional address and optional account) on success
  * Returns to the form on failure (but maintains the form data as it was entered)
  * KNOW BUGS - the select options are not maintained on failure

=cut

sub main: StartRunmode {
    my ($self) = @_;
    use Data::Dumper;
    my $q = \%{ $self->query() };  # WORKS
    my $message;
    my $warning;
    my $error;
    my $title = 'Notice CRaAM ' . $self->get_current_runmode() . ' - from ' . $ENV{REMOTE_ADDR};

    if($self->param('id')){ $message = "Signup up action " . $self->param('id') . '[main] ';
        if($self->param('sid')){ $message .= $self->param('sid');}
    }#else{ $message .= ""; }

    unless($self->param('id') || $q->param('id')){
        DEBUG: {
            last DEBUG unless ($q->param('debug') && $q->param('debug')>=2);
            $message .= "QUERY: ";
            $message .= Dumper($q);
            $message=~s/\n/<br \/>\n/g;
            $message .= Dumper($self);
        }
    }
    if($q->param('debug')){ $self->tt_params(no_js => 1); } #remove the javascript checks

    # almost certainly going to need these
    my @ranks = $self->resultset('Rank')->search({'ra_boatn' => { '=', 'before' } },{ 'columns'   => ['ra_id','ra_name'] });
    my @accounts = $self->resultset('Account')->search(
        {'ac_useradd' => { '>', '40' }, },
        { 'columns'   => ['ac_id','ac_name'], order_by => {-asc =>['ac_id+0','ac_id']}
    });
    my @countries = $self->resultset('Country')->search({'curid' => { '!=', undef },},{'columns'   => ['iso']});
    $self->tt_params({
        form => $q,
        ranks   => \@ranks,
        accounts=> \@accounts,
        countries=> \@countries,
        title   => $title
    });

    my $ac_id; $ac_id = $q->param('ac_id');
    #$self->param(message => "Got ac_id of $ac_id<br />\n");
    if($ac_id){ $message .= "Got ac_id of $ac_id<br />\n"; }

     if ( $q->param('Add') && ( 
            # must be a better way to do this wil L18n (obv. we could just skip the second half of this if)
            $q->param('Add') eq "Add" || 
            $q->param('Add') eq 'Ajouter' ) 
        ){

        my %create_user;
        my %create_address;
        my $create_account;
        my $new_account = 1; # we will set this to 0 if conf_data tells us that walk-ups can't create accounts && there is one account
        #my %create_user = ( pw_date => \'NOW()');   #this works
        #my %create_user = ( pw_date => \'md5(PASSWORD)');
        #my %create_user = ( pe_paswd => \'md5(');
        #$create_user{pw_date} .= $q->param('pw_hid') . ')';
        #$create_user{pw_date} =~s/PASSWORD/$q->param('pw_hid')/;
        #$create_user{pe_paswd} .= $q->param('pw_hid') . ')';
        #%create_user = ("pe_password" => \'md5(\'' . $q->param('pw_hid') . '\')'); #fail
        foreach my $ak (keys %{ $q->{'param'} } ){
            
        # might be better to pull this from an array, but there must be a
        # better DBIx::Class way to know which collums we are looking for
          if( $ak=~m/^pw_/ && (
            $ak eq 'pw_raid' ||
            $ak eq 'pw_fname' ||
            $ak eq 'pw_lname' ||
            $ak eq 'pw_email' ||
            $ak eq 'pw_acid' ||
            $ak eq 'pw_hid'
            ) && $q->param($ak) ne ''
           ){
                my $pe_key = $ak;
                $pe_key =~s/^pw_//;
                if( $pe_key =~s/hid/passwd/){
                    use Digest::MD5 qw(md5_hex);
                    #my $pe_password = '';
                    #$pe_password .= $q->param($ak);
                    # $create_user{"pe_password"} = \'md5(\'' . $q->param($ak) . '\')';
                    #%create_user .= ("pe_password" => \'md5(\'' . $q->param($ak) . '\')');
                    #$create_user{"pe_password"} = 'md5(' . $pe_password . ')';
                    #$create_user{"pe_password"} = $pe_password;
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
                         
                        my $encrypted = $cipher->encrypt($q->param($ak));
                        # base64 encode so we can store in db
                        $encrypted = encode_base64($encrypted);
                        # remove trailing newline inserted by encode_base64
                        chomp($encrypted);
                        $create_user{"pe_password"} = $encrypted;
                        # my $enc = SELECT pe_password from people;
                        ## $enc = pack(“H*”,$enc); #convert from hex
                        # $enc = decode_base64($enc); #decode base 64
                        # my $decrypted = $cipher->decrypt($enc);
                    };
                    if($@){ $create_user{"pe_password"} = md5_hex($q->param($ak)); }
                    #$create_user{"pe_$pe_key"} = md5_hex("$q->param($ak)");
                    $create_user{"pe_$pe_key"} = md5_hex($q->param($ak));
                    #$create_user{"pe_$pe_key"} = md5_hex($pe_password); #works
                    #$create_user{"pe_$pe_key"} = md5_hex();
                    #use Digest::MD5 qw(md5_base64);
                    #$create_user{"pe_$pe_key"} = md5_base64($q->param($ak));
                }else{
                    #$create_user{"pe_$pe_key"} = $q->param($ak) . '<br />';
                    $create_user{"pe_$pe_key"} = $q->param($ak);
                }
            }
            elsif($ak =~m/^ac_name$/){
                $create_account = $q->param($ak);
            }
            elsif($ak =~m/^ad_.{3,10}$/ && $q->param($ak) ne ''){
                $create_address{$ak} = $q->param($ak);
            }
        } #end foreach that collects the form data
        $create_user{"pe_confirmed"} = $ENV{REMOTE_ADDR};
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
        my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
        my $year = 1900 + $yearOffset;
        $create_user{"pe_loggedin"} = "$weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year, $hour:$minute:$second";

        # check pw_hid eq pw_hid_conf 
        if($q->param('pw_hid') ne $q->param('pw_c_hid') || !$q->param('pw_c_hid') || $q->param('pw_c_hid') eq ''){
            if(!$q->param('pw_c_hid') || $q->param('pw_c_hid') eq ''){
                $message =qq |Can't use a blank password|; #'
            }else{
                $message =qq |Passwords don't match|; #'
            }
           $self->tt_params({
                message => $message,
                new_account => $new_account,
                warning => "Passwords need checking",
            });
            return $self->tt_process();
        }
        #check we have the required data
        unless($create_user{pe_email} && $create_user{pe_passwd}){
            $self->tt_params({
                message => "Try filling in the form rather than just clicking like an epelectic monkey",
                new_account => $new_account,
                warning => "<br />Some data from you would be nice",
            });
            return $self->tt_process();

        }
        # check that we don't already have this email address in our database
        if(%create_user){
            my $existing_user = $self->resultset('People')->search(
            {pe_email => {'LIKE', $q->param('pw_email')}},
            undef
            )->count;
            if($existing_user >=1){
                $self->tt_params({
                message => "Email address already in use",
                new_account => $new_account,
                warning => "",
            });
                #warning => "Looks like you are trying to use someone else's email address",
            return $self->tt_process();
            }
        }else{
            $self->tt_params({
                message => "Try filling in the form rather than just clicking like an epelectic monkey",
                new_account => $new_account,
                warning => "No data found",
            });
            return $self->tt_process();
        }

        
        #first we create the account (if it does not exist)
        if(!$q->param('pw_acid') || $q->param('pw_acid') eq '' || $q->param('pw_acid') eq '0'){
            $self->param(ac_name => $q->param('ac_name'));
            $self->param(ac_approved => _walk_up_type($self));
            my $new_ac=0;
            my $n2ac=''; #Name to accounts 
            my $names = $q->param('pw_lname').$q->param('pw_fname');
            $n2ac = substr($names,0,1);

            if($self->param('ac_approved') eq 'nbh'){ #explained in _walk_up_type
                #$self->param(n2ac => substr("$self->param('pw_lname')$self->param('pw_fname')",0,1));
                $message .= "<br />Names: " . $q->param('pw_lname') . $q->param('pw_fname') . "<br />";
                #$n2ac = substr("$q->param('pw_lname')$q->param('pw_fname')",0,1);
                $message .= "produces: $n2ac<br />";
                unless($n2ac){ $n2ac = '?';}
                $n2ac = $q->param('pw_acid') . '.' . $n2ac . '.' . $q->param('pw_lname');
                unless($self->param('pe_lname')){ $n2ac .= '?';} #lazy nameless or secretive
                $self->param(n2ac => $n2ac);
                use Notice::C::Account;
                # create the account
                $new_ac = Notice::C::Account::_name_to_child($self);
                $self->param(ac_id => $new_ac);
            }elsif($self->param('ac_approved') eq 'fixed-next'){ #explained in _walk_up_type
                #$self->param(ac_parent => '3');
                $self->param(ac_name => "$n2ac") unless $self->param('ac_name');
                $self->param(ac_notes => "$names");
                use Notice::C::Account;
                my $ac_tree;
                ($new_ac,$ac_tree) = Notice::C::Account::_new_child($self);
                if($ac_tree!~m/^\d+(\.\d+)*$/){ #then we have failed to find a valid account
                        $warning =qq |<br />Account NOT created and hence we could not add you as a user. <br />
                        If you feel that this is a mistake/error or not what you want then please contact us.|;
                        $message = "Sorry, we were unable to find a valid account ($ac_tree.)(o)" . $self->param('message');
                    $self->tt_params({
                        error => "Failed to find a valid account ($ac_tree)()",
                        message => $message,
                        warning => $warning
                    });
                    return $self->tt_process();
                }
                $self->param(ac_id => $new_ac);
            }else{
                $self->tt_params({
                    error => "Failed to find a valid account to add you to.",
                    message => "Sorry, we are not creating new accounts at this time",
                    warning => $warning
                });
                return $self->tt_process();
            }
            $self->param(ef_acid => $ac_id);
            $create_user{pe_acid} = $self->param('ac_id');
        }

        #now we have an account we create the address (if supplied)
        $self->param('ad_adcountry' => $create_address{ad_adcountry});
        $self->param('ad_type' => $create_address{ad_type});
        delete($create_address{ad_adcountry});
        delete($create_address{ad_type});
        # One day the Address will be just one textarea and we will split it up for them
        if(%create_address){
            #if($q->param('ac_adname')=~m/^\d+$/){
            # for some reason we have a seperate column for property names and property numbers...
            if($create_address{ad_adname}=~m/^\d+$/){
                #$create_address{ad_adnumber} = $q->param('ac_adname');
                $create_address{ad_adnumber} = $create_address{ad_adname};
                delete($create_address{ad_adname});
            }
            $create_address{ad_acid} = $self->param('ac_id');
            $self->param('create_address' => \%create_address);
            use Notice::C::Addresses;
            my $ad_added = Notice::C::Addresses::_add($self);
            if($ad_added!~m/^\d+$/){
                $message .= $ad_added;
                $self->tt_params({
                    error => $error,
                    message => $message,
                    warning => $warning
                });
                return $self->tt_process();
            }
        }

        # now we create the user

        #$warning = Dumper(\%create_user);
        my $pe_id;
        if(%create_user){
            my $existing_user = $self->resultset('People')->search(
            {pe_email => {'LIKE', $q->param('pw_email')}},
            undef
            );
            my $comment = $self->resultset('People')->create( \%create_user );
                $comment->update;
            $pe_id = $comment->id;
            # and they will need some menu items

            my $ef_acid = $create_user{'pe_acid'};

            my $m_rs = $self->resultset('ConfData')->search({
                'ac_id' => "$ef_acid",
                'cf_name' => "menu",
                -or => [
                    'cfd_key' => "default_menu",
                    'cfd_key' => "default_walkup_menu",
                 ],
               },{
                join     => ['config','ac_parent'],
                columns => ['cfd_key','cfd_value'],
            });
            my $menu_done=0;
            while(my $v = $m_rs->next){
                if($v->cfd_key eq 'default_menu'){
                    my @menu_items = split(',', $v->cfd_value);
                    foreach my $ak (@menu_items){
                        if($pe_id && $pe_id=~m/^\d+$/ && $ak=~m/^\d+(\.\d+)*$/){
                            my $rs = $self->resultset('Menu')->update_or_create({ pe_id => "$pe_id", menu => "$ak", hidden => '0' });
                            $menu_done .= $rs->id;
                        }
                    }
                }
            }
            unless($menu_done){

                # either the defaults for that account or the global defaults
                my %menu = (
                'pe_id' => $pe_id,
                'menu' => '3', #3 is domains
                );

                my $menu = $self->resultset('Menu')->create( \%menu );
                    $menu->update;
            }
        }
        $warning .= "UserID: $pe_id<br />\n" unless $pe_id=~m/^\d+$/;
        # we have to know if this account wants to send out confirmation emails
        # and if the use has to confirm before they can log in.

    # NTS you are HERE
    my $verification_sent = 0;

    # create signup email and send it out (if this account requires confirmation of some kind)
        my $body;
        if($verification_sent){
            $body =qq |A confirmation email has been sent to your address. Use the link in the email to get to the 
<a href="/cgi-bin/index.cgi/main/login">log in page</a>|;  #works
        }else{
            $body =qq |Signup complete. You may <a href="/cgi-bin/index.cgi/main/login">log in here</a>|;
        }
#<a href="login/">log in page</a>|;   #works for /cgi-bin/index.cgi/signup but NOT for /cgi-bin/index.cgi/signup/
#<a href="cgi-bin/index.cgi/login/">log in page</a>|;   #fail


        $self->tt_params({
    message => $message,
    new_account => $new_account,
    warning => $warning,
    body => $body,
    no_page => 1
          });
    return $self->tt_process();


    } # end of Add

    $self->tt_params({
       # ac_selected => 'Default',  # this works
        new_account => 1,           # let them add new accounts
        message => $message,
        warning => $warning,
	});
    return $self->tt_process();
    
}

=head3 verify

this runmode is used to verify a new users email address or a new email address

this is stored in people.pe_confirmed in the form

YYYYMMDDHHMMSS_remoteIP_ZERO_$validation-string_$optional-validation-count
e.g. (IPv4)
20090813164202_93.97.171.186_ZERO_02b4d99c82b4ea2849814cfc15c081fb_2
or (IPv6)
20090813164202_2001:9470:1f08:3370:1234:4567:8765:3452_ZERO_02b4d99c82b4ea2849814cfc15c081fb_2

where 
    YYYYMMDDHHMMSS is the date of the last validation request
    remoteIP is that of the requester or user
    ZERO is a backwardly compatable delimiter that may be used in future expantion
    validation string is just that
    count is how many times they (or we) have generated a valiadtion request

=over

=item B<known limitations>

The optional validation count can not be more than 9,999,999 (with pe_configed varchar(100) );

=back

Once verified this is set to $datetime-of-validation $ip_validation_came_from $origial $validation-request-date
e.g.
2008-07-29 20:56:51 10.2.2.50 20080729205645

=cut

sub verify: Runmode {
    my ($self) = @_;
    use Data::Dumper;
    my $q = \%{ $self->query() };  # WORKS
    my $message;
    my $warning;
    my $title = 'Notice CRaAM ' . $self->get_current_runmode() . ' - from ' . $ENV{REMOTE_ADDR};
    my $code='';
    if($self->param('id')){ 
        $code = substr($self->param('id'), 0, 32);
        $code =~s/[^a-f0-9]//g;
        $message = "Verification code: <blockquote>" . $self->param('id') . "</blockquote>";
        if($self->param('sid') || $self->param('id') ne $code){ 
            $warning = "Dodgy looking validation code... but I can work with it.";
        }
    }
    $self->tt_params({
        message => $message,
        code => $code,
        warning => $warning,
        title => $title
    });
    return $self->tt_process();
}

=head3 _walk_up_type

this looks to see what (and if) the type of walk up new account should be

=over 10

=item B<next accounts>

we can either just find the next account
returns next

=item B<fixed walk-up>

or we might have a walk-up account defined (can be combined with next)
returns fixed
or fixed-next to create the next child of the fixed account

=item B<account from name>

create the account based on the name supplied
returns name

=item B<nbh>

like account from name but with a heirachy
then we might have ac_from_name set, then we create the account based on 
the pe_lname.pe_fname in a heirachy "nbh" or nameBasedHeirachy

This may be combined with next account and fixed walk-up
returns nbh for nbh+next (default)
or nbh-fixed[-ac_id] for nbh + fixed
or nbh-name for nbh 

=back

=cut

sub _walk_up_type{
    my ($self) = @_;
    my $type = '';
    #NTS move this into a http://search.cpan.org/~frew/DBIx-Class-0.08192/lib/DBIx/Class/Manual/Cookbook.pod#Arbitrary_SQL_through_a_custom_ResultSource
    my $query =qq |SELECT cfd_value FROM conf_data,config 
            WHERE config.cf_id=conf_data.cfd_cfid and cf_name='walk-up' and cf_moid = '1.4.1' and cfd_key='type';|;
    #$type = $cd_rs->search(\[ 'cdid = ? AND (artist = ? OR artist = ?)', [ 'cdid', 2 ], [ 'artist', 1 ], [ 'artist', 2 ] ]);
   # $type = $self->resultset('ConfData')->search(\[ 'cf_name = ? ', 'cf_moid = ?', 'cfd_key = ?', [ 'cf_name', 'walk-up' ], [ 'cf_moid', '1.4.1' ], [ 'cfd_key', 'type' ] ],
    #       { 
    #          'columns'   => ['cfd_value'],
    #          join => 'config'
    #        });
    #$self->param(error => 'Got here' funky => 'Brown' });
    #$type = 'nbh';
    $type = 'fixed-next';
    $self->param(error => 'Got here');

    return $type;
}


=head3 _list_accounts

create a list of accounts sorted by heirachy
This isn't used yet, but with the strange account ID system (that stores the heiracy in its value)
we will probably need this later. Also see notice.alexx.net 0.01 Notice::DB::account:show_accounts

=cut

sub _list_accounts {
    #my $query =qq |SELECT me.ac_id, me.ac_name FROM account me ORDER BY LENGTH(LEFT(ac_id,2)+0),LEFT(ac_id,3),LEFT(ac_id,5),LEFT(ac_id,7),LEFT(ac_id,9);|;
    my $query =qq |SELECT me.ac_id, me.ac_name FROM account me ORDER BY round(ac_id),ac_id;|;
    #SELECT me.ac_id, ac_id +0, CAST(ac_id AS unsigned), ac_id + 0.00, mid(ac_id, 1, LENGTH(ac_id) -0) as mid, 
    #   CAST(mid(ac_id, 1, LENGTH(ac_id) -0) AS unsigned) as cast 
    #       FROM account me 
    #  ORDER BY LENGTH(LEFT(ac_id,2) +0), LEFT(ac_id, 3),LEFT(ac_id, 5), LEFT(ac_id, 7), LEFT(ac_id, 9);

}


1;

__END__

=head1 BUGS AND LIMITATIONS

There are known problems with this module, but for the most part it works.
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

