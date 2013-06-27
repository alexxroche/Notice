package Notice::C::Email;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';
use Data::Dumper;

# NTS pull this from the menu and modules table
my %submenu = ( 
   '3.1' => [
        '1' => { name=> 'Forwardings', rm => 'aliases', class=> 'navigation'},
        '2' => { name=> 'IMAP4/POP3', rm => 'imap', class=> 'navigation'},
    ],
);


=head1 NAME

Notice::C::Email - Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

An overview of functionality of email managed by this system.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    $self->tt_params({ submenu => \%submenu });
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

    $message = 'Welcome to the Email section ';
    if($self->param('i18n') && $self->param('i18n') eq 'fr'){
        $message = 'Bienvenue à le email section'; #pull this from fr.po
    }
    $message .=qq |<br />In this section you can: <br/>
                 add,view,edit the details of the electronic messaging containers.<br/>
        If you were a sytem administrator you could control other aspects of the electronic communications system.<br/>
        (If you have the webmail module installed you will be able to grant or revoke access here)|;
    
    if($surl){
        unless($opt{default_domain}){ $opt{default_domain} = ''; }
    $message .=qq |<br /> Forwardings (Aliases) can be viewed <a href="$surl/aliases$opt{default_domain}">here</a>
                <br /> and IMAP4/POP3 accounts can be viewed <a href="$surl/imap">here</a>|;
    }

    $self->tt_params({
    action  => "$surl/aliases",
    domains => \@domains,
	message => $message,
    body    => $body
		  });
    return $self->tt_process();
}


=head3 aliases

These are the forwardings

=cut


sub aliases: Runmode{
    # NTS you need a domain list so that they can select
    # NTS need to an add_alias table
    my ($self) = @_;
    my ($message,$body,%opt);
    
    my $surl;
       $surl = ($self->query->self_url);
    $opt{ef_acid} = $self->param('ef_acid');
    my $q = $self->query;
    if($self->param('id')){
        $opt{do_name} = $self->param('id');
    }elsif($q->param('id')){ 
        $opt{do_name} = $q->param('id');
    }

    if($self->param('sid')){
        $opt{offset} = $self->param('sid');
    }elsif($q->param('sid')){ 
        $opt{offset} = $q->param('sid');
    }

    my ($ac_id,@domains);
    my $error = 'Please select a domain';
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }

    # maybe they are added an alias
    if($q->param('userid') && $q->param('doid')) {
        $opt{ea_userid} = $q->param('userid');
        $opt{ea_doid} = $q->param('doid');

        my %create_data;
        foreach my $ak (keys %{ $q->{'param'} } ){
            if(
            $ak eq 'userid' ||
            $ak eq 'doid'
            ){
                $create_data{"ea_$ak"} = $q->param($ak);
            }elsif($ak eq 'to'){
            #warn "$ak = " . $q->param($ak);
                my $to = $q->param($ak); 
                $to=~s/[^a-z]\s*$//;
                $to=~s/\s+/ /g;
                $to=~s/\s*$//;
                chomp($to);
                if($to=~m/[,;\s]/ && $to!~m/^|/){ #we have more than one
                    my @addresses = split(qr/[,;\s*]/, $to);
                    # we could do a foreach but for now
                    $opt{error} .= "Just one destination address for now";
                    $self->tt_params({ error => $opt{error} });
                    return $self->tt_process();
                }elsif($to=~m/^\|/){ #we have a pipe
                    $create_data{'ea_touser'} = $to;
                }else{
                    #my ($ea_touser,$ea_at) = split /\@/, $q->param($ak); 
                    my ($ea_touser,$ea_at) = split /\@/, $to;
                    $create_data{'ea_touser'} = $ea_touser;
                    $create_data{'ea_at'} = $ea_at;
                 my @this_domain = $self->resultset('Domain')->search({
                    do_acid=>{'=',"$ac_id"},
                    do_name =>{'=',"$create_data{'ea_at'}"}
                    },{
                    });
                 my $this_doid;
                    $this_doid = $this_domain[0]->{_column_data}{do_id};
                    #check that they are not trying to create a loop
                     if($create_data{'doid'} && int($this_doid) == int($create_data{'doid'})){
                        $self->tt_params({ error => 'I think we will skip the email loop today'});
                        return $self->tt_process();
                     }else{
                        $opt{'from_domain'} = $this_domain[0]->{_column_data}{do_name};
                     }
                }
            }
        }
        #warn Dumper(\%create_data);
        my $obj = $self->resultset('Aliase')->find_or_new( \%create_data );
        if ($obj->in_storage) {
            if($self->param('load_edit')){
                $self->tt_params({message => 'Alias already exists'});
                $self->tt_params({warning => 'Alias already exists'});
                #return $self->redirect("$dest");
                return $self->forward('edit_alias');
            }else{
                $message = 'Alias already exists';
            }
        }else{
            #warn "inserting $opt{ea_userid}";
            $obj->insert;
            #$opt{ea_id} = $obj->id;
            if($self->param('load_edit')){
                $self->tt_params({message => 'Alias created'});
                #return $self->redirect("$dest");
                return $self->forward('edit_alias');
            }else{
                $message .= "Alias Added for $opt{ea_userid}";
                if($opt{from_domain}){
                        $message .= "\@$opt{from_domain}";
                }
                #$self->tt_params({message => $message});
            }
        }
    } #/ if new alias data
    #maybe they are deleting an aliase
    elsif($q->param('id') && $q->param('Delete')) {
        my %data;
        foreach my $ak (keys %{ $q->{'param'} } ){
            #warn  "$ak = " . $q->param($ak);
            if($ak eq 'id'){
                $data{ea_id} = $q->param($ak);
            }
        }
        if(%data){
            # we should have alias_hist and store this old aliase there for roll back
            my $rs = $self->resultset('Aliase')->search( \%data )->delete;
            if($rs){ $message = 'That Aliase is no more'; }
            else{ $message = 'I tried to delete that for you but...' . $? ; }
        }else{
            $message = "do what now?";
        }
    }
    if($ac_id){
        # NTS need to join the group table so that we only list domains that are not in the
        # "no email" domains group
        @domains = $self->resultset('Domain')->search({
            do_acid=>{'=',"$ac_id"}
             },{
        });
        # NOTE this is a dirty hack to give the user something to click on
        if(defined $domains[0]->do_id && $domains[0]->do_id){
                my $this_name = $domains[0]->do_name;
                $error .= '<br /><a href="' . $surl .'/' . $this_name . '" class="blue">' . $this_name . '</a><br />';
        }
    }

    unless($opt{do_name} && $opt{do_name} ne ''){
        $self->tt_params({ error => $error });
        return $self->tt_process();
    }

    # AliasData table lets us colour the Edit Details button class when we have data
    my @alias = $self->resultset('Aliase')->search({ 
        'do_acid' => { '=', "$opt{ef_acid}"},
        'do_name' => { '=', "$opt{do_name}"}
        },{
        join => ['domains', 'aliasdetails'],
        #+columns => [{ do_name => 'domains.do_name AS do_name'} ],
        #select => [ 'ea_userid', 'ea_doid', 'ea_touser', 'ea_at' ],
        #the above two lines work but this line is shorter
        columns => [ 'domains.do_name', 'ea_id', 'ea_userid', 'ea_doid', 'ea_touser', 'ea_at', 'ea_suspended','aliasdetails.ead_date' ],
        });

    $self->tt_params({
    do_name => $opt{do_name},
    message => $message,
    domains => \@domains,
    body    => $body,
    alias   => \@alias,
          });
    return $self->tt_process();

}

=head3 edit_alias

this lets you update the aliases additional data

=cut

sub edit_alias: Runmode{
    my ($self) = @_;
    my ($message,$body,%opt,%ref);

    #my $q = $self->query;
    my $q = \%{ $self->query() };
    if($q->param('id')){
        $opt{ea_id} = $q->param('id');
    }elsif($self->param('id')){
        $opt{ea_from} = $self->param('id');
    }


    # lets see if we are adding or changing the alias_details

    if($self->param('password_size')){
            $self->tt_params({ password_size => $self->param('password_size')});
    }
    my %find_alias;
    if($opt{ed_id} && $opt{ea_id}=~m/^\d+$/){
        $find_alias{ea_id} = $opt{ea_id};
    }elsif($opt{ea_from}=~m/^\d+$/){
        $find_alias{ea_id} = $opt{ea_from};
    }elsif($opt{ea_from}=~m/.+\@.+/){
        ($find_alias{ea_userid},$find_alias{do_name}) = split(/\@/, $opt{ea_from});
    }else{
        ($find_alias{ea_userid},$find_alias{do_id}) = split(/\@/, $opt{ea_from});
        unless($find_alias{do_id} && $find_alias{do_id}=~m/^\d+$/){
            $find_alias{do_id} = $self->param('sid') ? $self->param('sid') : $q->param('sid');
        }
    }

    # we might have cgi-bin/index.cgi/email/edit_alias/user@example.com
    # OR
    # we might have cgi-bin/index.cgi/email/edit_alias/$ea_id
    # OR
    # we might have cgi-bin/index.cgi/email/edit_alias/user/$do_id

    my @ref = $self->resultset('Aliase')->search({
        #'ea_id' => { '=', "$opt{ea_id}"}
        %find_alias
        },{
        join => ['domains', 'aliasdetails'],
        columns => [ 'domains.do_name', 'ea_id', 'ea_userid', 'ea_doid', 'ea_touser', 'ea_at', 'ea_suspended', 'aliasdetails.ead_website', 'aliasdetails.ead_password', 'aliasdetails.ead_notes' ],
        });

    # If we don't have any data then this is an error
    unless(defined $ref[0]->ea_touser){
        $self->tt_params({error => 'Unknown Email Alias'});
        return $self->tt_process('site_wrapper.tmpl');
    }        

    # NTS you are here => lets see if they are chaning the forwarding
    %find_alias = ();
    if(defined $ref[0]->ea_id){
        $find_alias{ea_id} = $ref[0]->ea_id;
    }
    my %update_alias;
    my %update_details;
    my %find_details;

    if($q->param('save')){
        foreach my $ak (keys %{ $q->{'param'} } ){
            if($ak eq 'status'){
                my $status = $q->param($ak) eq 'enabled' ? 0 : 1 ;
                unless(defined $ref[0]->ea_suspended && $ref[0]->ea_suspended eq $status){
                    $update_alias{ea_suspended} = $status;
                    $update_alias{ea_id} = $q->param('editAlias');
                }
            }elsif($ak eq 'destination'){
                my($ea_touser,$ea_at) = split('@', $q->param($ak));
                unless(defined $ref[0]->ea_touser && $ref[0]->ea_touser eq $ea_touser &&
                       defined $ref[0]->ea_at && $ref[0]->ea_at eq $ea_at
                ){
                    $update_alias{'ea_at'} = $ea_at;
                    $update_alias{'ea_touser'} = $ea_touser;
                }
            }elsif($ak eq 'website' || $ak eq 'notes'){
                    if(defined $ref[0]->aliasdetails){ 
                            #warn $ref[0]->aliasdetails->ead_website;   #WORKS
                            # NOTE how to do dynamic method references
                            #warn $ref[0]->aliasdetails->${\"ead_$ak"}; #ALSO WORKS
                            #warn $ref[0]->aliasdetails->{_column_data}{"ead_$ak"}; #ALSO WORKS, but is ugly and wrong
                    }
                unless(defined $ref[0]->aliasdetails && $ref[0]->aliasdetails->${\"ead_$ak"} eq $q->param($ak)){
                    $update_details{"ead_$ak"} = $q->param($ak);
                    $find_details{ead_userid} = $q->param('from');
                    $find_details{ead_doid} = $q->param('domain');
                }
            # we should change this to passphrase
            }elsif($ak eq 'passwd'){
                unless(defined $ref[0]->aliasdetails && 
                       $ref[0]->aliasdetails->${\"ead_password"} eq $q->param($ak)){
                    $update_details{'ead_password'} = $q->param($ak);
                    $find_details{ead_userid} = $q->param('from');
                    $find_details{ead_doid} = $q->param('domain');
                }
            }else{
               # warn "$ak = " . $q->param($ak);
            }
        }

        my $done=0;
        if(%update_alias){
            my $rc = $self->resultset('Aliase')->search(\%find_alias);
            $done += $rc->update( \%update_alias );
            #warn "updating" . Dumper(\%update_alias);
        }
        if(%update_details){
            warn "finding" . Dumper(\%find_details);
            warn "updating" . Dumper(\%update_details);
            my $rc = $self->resultset('AliasDetail')->search(\%find_details);
                #$update_details{"ead_date"} = \'NOW()'; # is this more useful as created or updated?
                #$done += $rc->update_or_create( \%update_details );
            if($rc->count){
                $done += $rc->update( \%update_details );
            }else{
                $update_details{"ead_date"} = \'NOW()';
                $done += $rc->create( \%update_details );
            }
        }
        if($done){
                @ref = $self->resultset('Aliase')->search({ %find_alias },{
                    join => ['domains', 'aliasdetails'],
                    columns => [ 'domains.do_name', 'ea_id', 'ea_userid', 'ea_doid', 'ea_touser', 'ea_at', 'ea_suspended', 'aliasdetails.ead_website', 'aliasdetails.ead_password', 'aliasdetails.ead_notes' ],
                });
        }
        # we need to be able to delete the AliasDetail row if we get no data

    }


    $self->tt_params({
    ref     => \@ref,
    silent_password => 1, # turn off the javascript alert
    message => $message,
    body    => $body,
          });
    return $self->tt_process();

}

=head3 imap

this lists the imap/pop accounts on the system

=cut

sub imap: Runmode{
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;
    if($self->param('id')){
        $opt{do_name} = $self->param('id');
    }elsif($q->param('id')){
        $opt{do_name} = $q->param('id');
    }
    my $pe_level = 1;
    if($self->param('pe_level') && $self->param('pe_level')=~m/^\d+$/){
            $pe_level = $self->param('pe_level');
    }elsif($self->session->param('pe_level') && $self->session->param('pe_level')=~m/^\d+$/){
            $pe_level = $self->session->param('pe_level');
    }

    $self->tt_params({ pe_level => $pe_level });
    my %limits = ( join => ['domains'] );

    if($self->in_group('HR',$self->param('pe_id'))){
        $self->tt_params({ pe_level => $pe_level + 10 });

        if($q->param('Delete')){

           if($q->param('doid') && $q->param('doid')=~m/^\d+$/ &&
              $q->param('userid') && $q->param('userid')=~m/.+$/){
                # lets check that it exists
                #$self->tt_params({ body => 'Deleting ' . $q->param('userid') . ' of domain ID ' . $q->param('doid') });
                my %find =  ( -and => [ im_userid => $q->param('userid'), im_doid => $q->param('doid') ]);
                my $del = $self->resultset('Imap')->search(\%find ,{ columns => ['im_userid','im_doid'], })->first;
                if($del && $del->im_doid && ( $del->im_doid eq $q->param('doid') && $del->im_userid && ( $del->im_userid eq $q->param('userid') ) )){
                    # create imaphistory entry (so that we can undo the delete) NOTE NTS
                    $body = 'Deleted ' . $q->param('userid') . ' of ' . $del->im_home;
                    $del->delete;
                }else{
                    $body = '<span class="error">Could not find' . $q->param('userid');
                }
            }
        }elsif($q->param('Add')){
# NOTE this has not been written yet
            my %create_data;
            foreach my $ak (keys %{ $q->{'param'} } ){
                if(
                $ak eq 'userid' ||
                $ak eq 'doid'
                ){ 
                    $create_data{"im_$ak"} = $q->param($ak);
                }
            }
        }

        my $rows_per_page =
        defined $q->param('rpp') && $q->param('rpp')=~m/^\d{1,3}$/ && $q->param('rpp') <= 100
          ? $q->param('rpp')
           : 30;

        my $page = defined $q->param('page') && $q->param('page')=~m/^\d+$/ ? $q->param('page') : 1;

        my %search =();
        if( defined $q->param('email') && $q->param('email')=~m/^(.+)\@(.+)$/){
           %search =  ( -and => [ im_userid => $1, do_name => $2 ]);
        }

        # There must be a way to do these two searches with only one hit to the DB
        my $total_rows = $self->resultset('Imap')->search(\%search, \%limits )->count;
            # Lets bypass pagination if the results are few
        if($total_rows <= $rows_per_page){ $page = 1; }
        if($page >= int( $rows_per_page * $total_rows ) ){ $page = int( $total_rows / $rows_per_page ); }
        $limits{page} = $page;
        $limits{rows} = $rows_per_page;
        $message .= $total_rows . " containers found ";

        if($total_rows > $rows_per_page || defined $q->param('debug')){
            my $pagination = $self->_page($page,$rows_per_page,$total_rows);
            $self->tt_params({ pagination => $pagination });
        }

        my @rs = $self->resultset('Imap')->search( \%search, \%limits );
        $self->tt_params({ imap => \@rs });

        if($total_rows > $rows_per_page || defined $q->param('debug')){
            my $pagination = $self->_page($page,$rows_per_page,$total_rows);
            $self->tt_params({ pagination => $pagination });
        }


    }else{
        $message =qq |You have no IMAP4 or POP3 accounts|;
        if($opt{do_name}){ $message .=qq | under the domain $opt{do_name}|; }
        $opt{error} = ' ';
    $self->tt_params({ error => $opt{error} });
    }

    $self->tt_params({
    message => $message,
    body    => $body,
          });
    return $self->tt_process();
}

=head3 _send

    This expects to be called either with an array of data,
    OR a hash of data
    OR a string of data

    If the string then we try to split it back up into from, to, body
    If the hash then we expect each data type to have the right key, but
        if not we again try to split it.

    The most usual way to call it is $self->_send($from,$to,$subject,$body);
        but $self->_send($message); will also work.

   If the system has the right modules installed, then we will use them to
    form the message and send it.
   else we will fall back on `sendmail` or `exim` or `postfix`

    Only after trying all of those will we return an error.

=cut

sub _send: Runmode{
    my ($self,$from,$to,$subject,$body,$attach,$sign,$encrypt) = @_;
    my $mailprog='sendmail'; #actually it is exim here through the joys of symlinks

eval {
    use MIME::Entity;
    use MIME::Head;
    use MIME::Body;
    my $email;
    if($from->{body}){ 
        $to = $from->{to};
        $subject = $from->{subject};
        $body = $from->{body};
        $from = $from->{from};
        $sign = $from->{sign}; #PGP key to use (default $from)
        $encrypt = $from->{encrypt}; #PGP key to use (default $to)
        return(-1) unless $body;
        return(-2) unless $from;
        return(-3) unless $to;
    }elsif((! $body || ref($body) eq 'ARRAY') && ref($from) eq 'SCALAR'){
        if( ! $subject){
            my $sender='';
            HEAD: foreach my $line (split("\n", $from)){
                if( ! $subject && $line=~m/^\s*Subject\s?:\s*(.+)$/){ $subject = $1; next HEAD; }
                elsif( ! $to   && $line=~m/^\s*To\s?:\s*(.+)$/){ $to = $1; next HEAD; }
                elsif(!$sender && $line=~m/^\s*From\s?:\s*(.+)$/){ $sender = $1; next HEAD;}
                #last HEAD if $line=~m/^\s*$/;
                $body .= $line;
            }
            if($sender){ 
                if(!$body){
                    $body = $from; 
                }
                $from = $sender; 
            }
        }
        $email = MIME::Entity->build(From    => $from,
                                      To      => $to,
                                      Subject => $subject,
                                      Data    => $body);
   }

   if ($attach) {
        if(ref($attach) eq 'HASH'){
            foreach my $att (keys %{ $attach }){
                $email->attach(Path     => $attach->{$att}{file},
                    Type     => $attach->{$att}{type});
            }
        }
   }


    ($email)=MIME::Entity->build(Type=>'multipart/mixed',
                               'X-Mailer'=>undef,
                               From=>$from,
                               To=>$to,
                               Subject=>$subject,
                );
    if($from->{x_headers}){
        XFE: foreach my $x_header (@{$from->{x_headers}}){
            #$email->add($x_header);
            my($xhlh,$xhrh) = split(/=>/, $x_header);
            next XFE unless $xhrh;
            next XFE unless $xhlh=~m/^(Sender|X-.+)/;
            $email->add($xhlh=>$xhrh);
        }
    }

    $email->attach(Data=>"$body",
               Type=>'text/plain',
               Encoding=>'quoted-printable');

    # Send e-mail
    open(MAIL,"|$mailprog -t") or warn "Can't open $mailprog";
    my $return = $email->print(\*MAIL);
    close(MAIL);
    return($return);
 };
 if($@){
        #maybe  MIME::Entity is not installed
    my $message='';
    if($subject){
        $message = "From: $from\nTo: $to\nSubject: $subject\n\n$body";
    }else{
        $message = $from;
    }
    open(MAIL,"|$mailprog -t") or warn "Can't open $mailprog";
    my $return = print MAIL $message;
    close(MAIL);
    return($return);
    #`echo $message|$mailprog -t`;
 }

}

=head3 _sender

a new way to send email
    the same as &_send but uses newer perl modules
    and can send HTML email (yuck).

=cut

sub _sender {
    my ($self,$from,$to,$subject,$body,$attach,$sign,$encrypt) = @_;
    my $mailprog='sendmail'; #actually it is exim here through the joys of symlinks

    if( ref($to) eq 'ARRAY'){ $to = join(",", @{ $to }); }

 eval {
    use Email::Sender::Simple qw(sendmail);
    my $email;
    my $looks_like_html = 0; #set to >0 to force evil HTML email 
                             # and set to 0 to guess
                             # and set to -1 to force sensible text/plain email.
    if( ( ref($from) eq 'HASH' || ref($from) eq 'REF' ) && defined $from->{body}){
        $to = $from->{to};
        $subject = $from->{subject};
        $body = $from->{body};
        $from = $from->{from};
        $sign = $from->{sign}; #PGP key to use (default $from)
        $encrypt = $from->{encrypt}; #PGP key to use (default $to)
        return(-1) unless $body;
        return(-2) unless $from;
        return(-3) unless $to;
    }elsif((! $body || ref($body) eq 'ARRAY') && ref($from) eq 'SCALAR'){
        if( ! $subject){
            my $sender='';
            HEAD: foreach my $line (split("\n", $from)){
                if( ! $subject && $line=~m/^\s*Subject\s?:\s*(.+)$/){ $subject = $1; next HEAD; }
                elsif( ! $to   && $line=~m/^\s*To\s?:\s*(.+)$/){ $to = $1; next HEAD; }
                elsif(!$sender && $line=~m/^\s*From\s?:\s*(.+)$/){ $sender = $1; next HEAD;}
                #last HEAD if $line=~m/^\s*$/;
                $body .= $line;
            }
            if($sender){
                if(!$body){
                    $body = $from;
                }
                $from = $sender;
            }
        }
       # $email = MIME::Entity->build(From    => $from,
       #                               To      => $to,
       #                               Subject => $subject,
       #                               Data    => $body);
    }
    if($body=~m/[\<|\&lt;]/){
        $looks_like_html += 1;
    }

    if($looks_like_html && $looks_like_html>=1){
        use Email::MIME::CreateHTML;
        #use HTML::Strip;
        #my $hs = HTML::Strip->new();
        #my $plain_text = $hs->parse( $body );
        #$hs->eof;
        use HTML::FormatText;
        my $plain_text = HTML::FormatText->format_string(
        $body,
        leftmargin => 0, 
        rightmargin => 72
        #rightmargin => 76 # http://tools.ietf.org/html/rfc2045#section-6.8 suggests 76 would be good
        );
        # http://search.cpan.org/~bbc/Email-MIME-CreateHTML-1.030/lib/Email/MIME/CreateHTML.pm#COOKBOOK
        # If you want your images to remain as links (rather than be embedded in the email) disable the embed option
        # $email = Email::MIME->create_html(header => [ blah ], body=>$body, embed => 0);
        $email = Email::MIME->create_html(
                header => [
                        From => $from,
                        To => $to,
                        Subject => $subject,
                ],
                body => $body,
                text_body => $plain_text
        );
    }else{
      use Email::Simple;
      use Email::Simple::Creator;
      $email = Email::Simple->create(
        header => [
          To      => $to,
          From    => $from,
          Subject => $subject
        ],
        body => $body
      );
    }

    if ($attach) {
        # NOTE this functionality has not been checked
        use Email::MIME qw(parts_add);
        use IO::All;
        my @parts = $email->parts; #collect the existing message
        if(ref($attach) eq 'HASH'){
            foreach my $att (keys %{ $attach }){
                my $filename = Email::MIME->invent_filename($attach->{$att}{type}), # "report.pdf",
                my $file_type = $attach->{$att}{file};
                my $doc_name = $attach->{$att}{file};
                $doc_name =~s{^.*/}{};
                unless($file_type=~s/\.(\w{3,4})$/$1/){ $file_type = 'text/plain'; }
                my $content_type = $attach->{$att}{type} || $file_type;
                if($file_type=~m/([txt|rtf|html])/i){
                    $content_type = 'plain/' . lc($1);
                }
                elsif($file_type=~m/([pdf|json|html])/i){
                    $content_type = 'application/' . lc($1);
                }
                elsif($file_type=~m/([exe|com])/i){
                    $content_type = 'application/octet-stream';
                }# add your type of MIME (Multipurpose Internet Mail Extensions) here 
    # detects the MIME type from a file
        use File::Type qw(mine_type);
        my $ft = File::Type->new();
        $content_type = $ft->mime_type($attach->{$att}{file});
    # NOTE find a perl module that detects the correct encoding for that file
    # NOTE stop doing this all by hand!
                my @new_part = (
                    Email::MIME->create(
                      attributes => {
                          filename     => $filename, # "report.pdf",
                          content_type => $content_type, # $attach->{$att}{type}, # "application/pdf","text/plain"
                          encoding     => "quoted-printable",
                          name         => $doc_name, #"2004-financials.pdf",
                      },
                      body => io( $attach->{$att}{file} )->all,
                    ),
                  );
                $email->parts_add( \@new_part );
            }
        }
        #$email->parts_set( \@parts );
    }

    if( ( ref($from) eq 'HASH' || ref($from) eq 'REF' ) && defined $from->{x_headers}){
        XFE: foreach my $x_header (@{$from->{x_headers}}){
            my($xhlh,$xhrh) = split(/=>/, $x_header);
            next XFE unless $xhrh;
            next XFE unless $xhlh=~m/^(Sender|X-.+)/;
            $email->header_str_set( $xhlh=>$xhrh ); #Email::MIME
        }
    }

    use Try::Tiny;
    try {
      sendmail($email);
    } catch {
      warn "Falling back to pipe as sending failed: $_";
    };
 };
 if($@){
    warn $@;
        #maybe  Email::Sender::Simple is not installed
    my $message='';
    if($subject){
        $message = "From: $from\nTo: $to\nSubject: $subject\n\n$body";
    }else{
        $message = $from;
    }
    open(MAIL,"|$mailprog -t") or warn "Can't open $mailprog";
    my $return = print MAIL $message;
    close(MAIL);
    return($return);
    #`echo $message|$mailprog -t`;
 }

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


