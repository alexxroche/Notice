package Notice::C::Domains;

use warnings;
use strict;
use base 'Notice';

use Data::Dumper;
my %warning;

=head1 NAME

Notice::C::Domains - Template controller subclass for Notice

=head1 ABSTRACT

List domain names and subzones.

=head1 DESCRIPTION

This is here to manage domain names.

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
    $self->tt_params({title => 'Notice CRaAM ' . $runmode ." - $known_as at ". $ENV{REMOTE_ADDR}});
    $self->param(runmode => $runmode);
    $self->tt_params(runmode => $runmode);

       %warning = ( 
            1 => 'Domain too short', 
            2 => 'Domain already registered, (you could add it to your "desired" domains)',
            3 => 'Domain already present in this account',
    );

}

=head2 RUN MODES

=head3 main

  * List domain names in your account.

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $username= $self->authen->username;
    my $message;
    my %menu;
    my @menu_order;
    my $q = $self->query;

    if($self->param('warning') && $self->param('warning')=~m/^\d+$/){ 
        warn $self->param('warning');
        $self->tt_params({ warning => $warning{$self->param('warning')} });
        #$self->tt_params({ warning => $self->param('warning')});  #no we don't want XSS
    }elsif($q->param('warning')){
        if($warning{$q->param('warning')}){
            $self->tt_params({ warning => $warning{$q->param('warning')} });
        }else{
            $self->tt_params({ warning => 'That did not work' });
        }
    }
    # pull from config
    my $explain = 'Only enabled and migrating domains are "live" in the DNS system';
    $explain = '' if $self->param('ef_acid') ne '1';

    if($self->session('tmessage') ne ''){
        $message .= $self->session('tmessage');
        $self->session(tmessage => '');
    }

    if($self->param('message')){ 
        $message .= $self->param('message'); 
    }else{ 
    
        $message .= "Menu: ";
       # foreach my $key ( $self->param() ){
       #     $message .=qq |$key = $self->param("$key") <br />\n |;
       # }
        $message .= Dumper( $self->param('menu') );
        $message .= "/MENU";
        
    $message = ''; #don't need this debug info
    }
    if($self->param('menu_order')){
        #@menu_order = @{ $self->param('menu')->{'order'} };
        @menu_order = @{ $self->param('menu_order') };
        #delete($self->param('menu')->{'order'});
        #%menu = %{ $self->param('menu') };
        #foreach my $mi (keys %menu ){
        foreach my $mi (keys %{ $self->param('menu')} ){
            if($self->param('menu')->{"$mi"}->{'hidden'}){
                $menu{$mi} = $self->param('menu')->{"$mi"}->{'hidden'};
                #warn qq |$mi = $menu{"$mi"}|;
                #$message .= "MI: $mi = $menu{$mi}<br />";
            }
        }
    }else{
        #push @menu_order, "We have no bananas today";
        $menu_order[0] = Dumper($self->param('menu')) ;
        #$message .= $menu_order[0];
    }
	my $ac_id;
	my @domains;
	if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
	elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }
	if($ac_id){
		@domains = $self->resultset('Domain')->search({
			do_acid=>{'=',"$ac_id"}
		     },{
		});
	$message .= @domains . " domains found in this account";

	} else {
		$message = Dumper(@domains);
		$message .= "no account id";
	}
    $self->tt_params({
    explanation => $explain,
    menu_order => \@menu_order,
    menu => \%menu,
    domain_list => \@domains,
    message => $message,
		  });
    return $self->tt_process();
    #return $self->tt_process('Notice/C/Domains/index.tmpl');
    
}

=head3 edit

 Edit the zone file for a domain

=cut

sub edit: Runmode{
    my ($self) = @_;
    my (%opt);
    
    my $dest = $self->query->url;
    my $message;
    unless($dest=~m/domains/){ $dest .= '/domains'; }
    my $q = $self->query;
    my $type; #of domain 
    #my $q = $self->query(); #DOES NOT WORK with  my $self = shift; 
    if( $q->param('id') || $q->param('domain') || $q->param('name') ){
        my %find_domain = ();

        if( $q->param('id') ){
            $find_domain{'do_id'}=$q->param('id');
        }elsif( $q->param('domain') ){
            $find_domain{'do_name'}=$q->param('domain');
        }elsif( $q->param('name') ){
            $find_domain{'do_name'}=$q->param('name');
        }

        # have to limit this search to domains in their account
        my $ef_acid;
        if($self->param('ef_acid')){
            $ef_acid = $self->param('ef_acid');
        }

        my $acrs = $self->resultset('Account')->search({
                        'ac_id' => { '=', "$ef_acid"},
                    },{});
        while( my $ac = $acrs->next){
            my $ac_tree = $ac->ac_tree;
            $self->param(ac_tree => $ac_tree);
            $self->session->param(ac_tree => $ac_tree);
        }

        if($q->param('Change')){
            if($q->param('do_acid') == $ef_acid){
                $opt{nts} .= "You are tryin' to change the status of ";
                my %change_domain;
                $change_domain{do_status} = $q->param('do_status');
                $change_domain{do_acid} = $ef_acid;
                $opt{nts} .= $q->param('name');
                $opt{nts} .= ' to a status of ' . $change_domain{do_status};
                my %check_domain;
                $check_domain{do_id} = $q->param('id');
                my $domain = $self->resultset('Domain')->search( \%check_domain )->first;
                if($domain->do_status eq $change_domain{do_status}){
                        $opt{nts} .=qq ' <span class="error">BUT</span> it already is set to that... so no change neeed';
                }else{
                    # Here we create an invoice IF they are going from $anything => enabled
                    # NTS create a forward where they can confirm that they want to enable to domain.
                    $domain->update( \%change_domain );
                    if($domain->is_changed()){
                           $opt{nts} = 'Update did not happen, sorry.';
                    }else{
                           $opt{nts} = 'Domain status updated';
                    }
                }
                $self->tt_params({nts => $opt{nts}});

            }else{
                $self->tt_params({nts => 'That seems to be in some other account'});
            }
        }

        if(%find_domain && $ef_acid){
            my $acrs = $self->resultset('Account')->search({
                        'ac_id' => { '=', "$ef_acid"},
                    },{
                        colums => ['ac_tree'],
                    });
            while( my $ac = $acrs->next){
                my $ac_tree = $ac->ac_tree;
                my $ses_actree = $self->session->param('ac_tree');
                my $par_actree = $self->param('ac_tree');
                unless($ses_actree eq $ac_tree || $par_actree eq $ac_tree){
                        $self->param(ac_tree => $ac_tree);
                        $self->session->param(ac_tree => $ac_tree);
                }
            }
            #$find_domain{do_acid} = $q->param('ef_acid');
            $find_domain{do_acid} = $ef_acid;
        }else{
            $message .= "Domain not found in this account";
            if($ef_acid && $ef_acid=~m/^\d+$/){ $message .= "($ef_acid)"; }
            $message .= Dumper( $q->param ) if $self->param('debug')>=12;
            #$self->tt_params({message => "Domain not found in this account ($ef_acid)"});
            $self->tt_params({message => $message});
            return $self->tt_process();
        }
        #my $frs = $self->resultset('Domain')->search( \%find_domain );
        my $rows = $self->resultset('Domain')->search( \%find_domain )->count;

        unless($rows==1){
            $self->param(no_display => 1);
            $self->tt_params({domain => $find_domain{'do_name'}});
            $self->tt_params({no_display=> '1'});
            return $self->tt_process();
            exit;
        }
        my $domain_details = $self->resultset('Domain')->search( \%find_domain )->first;
        #my $domain_details = $self->resultset('Domain')->search( \%find_domain )->single;

        #while( my $f = $frs->next){
        #    if( $f->do_acid eq $q->param('do_acid')){
        #        $dest=~s/\/add$//;
        #    }
        #}
        my $zone; # may just contain a DS key 
        use Notice::C::Account;        
        my $account_tree = '1';
        if($self->param('ac_tree')){
            $account_tree = $self->param('ac_tree');
        }elsif($self->session->param('ac_tree')){
            $account_tree = $self->session->param('ac_tree');
        }
        my $account_path;
        $account_path = $account_tree;
        $account_path = Notice::C::Account::_to_path($account_tree);
        if($account_path eq ''){ $account_path = '1';}
        unless($account_path=~m/^\d+/){ $account_path = '1/' . $account_tree; } #we need /some/ directory to sort this into
        my $zone_file; #actuall filename
            my $domain_name;
            if($domain_details->do_name){
               $domain_name = $domain_details->do_name;
            }
        #warn "Domain: $domain_name (rows: $rows)";
        #$account_path .= "master/" . substr($q->param('domain'),0,1);
        $account_path .= "master/" . substr($domain_name,0,1);
           $zone_file = $account_path . '/'; #actuall filename
        if($domain_name){
            my $type_test = $domain_name;
            $zone_file .= $type_test;
            if($type_test=~m/\.customers.example.com$/){ #NOTE evil hard-coded, use groups or prior knowledge
               $type = 'subzone';
            }
        }
        my $warning = ":";

            unless($domain_name){    
                #$zone_file  .= $domain_name;
                #we have not found this domain in this account
                $self->param(no_display => 1);
                $self->tt_params({domain => $domain_details->{do_name}});
                $self->tt_params({no_display=> '1'});
	            return $self->tt_process();
                exit;
                #$zone_file .= $q->param('domain'); #dangerous! (NTS fix this)
            }
        $warning .= "Zone file path: $zone_file";
            $self->tt_params({warning => $warning}) if $q->param('debug');
        if($q->param('zone')){
            # we have a zonefile or data for this subzone
            unless(-d "$account_path"){ 
                #create the path
                use Cwd;
                use File::Path;
                my $currWorkDir;
                   $currWorkDir = &Cwd::cwd();
                my $fullPath;
                   $fullPath = $currWorkDir .'/'. $account_path;
                &File::Path::mkpath($fullPath);
            }
            my $zone_data;
               $zone_data = $q->param('zone');
               #clean up the data
            # NTS you are here
            # If this is a domain that has parent zone in another account
            # and that account has set this domain to be "public chargeable subzones"
            # (which we should know from this domains do_grid)
            # we clean up any entry to be just NS and DS and comments
            # SO we expect: "ns0.ex.mple.(\n)? ns1.example.com(\n)? ns2.example.net."
            # and we want: "@   28800   IN NS ns0.ex.mple.\n@   28800 IN    NS  ns1.example.com.\n
            # we also let them have
            # dskey.example. KEY  256 3 1 (
            #   AQPwHb4UL1U9RHaU8qP+Ts5bVOU1s7fYbj2b3CCbzNdj4+/ECd18yKiyUQqKqQFWW5T3iVc8SJOKnueJHt/Jb/wt
            #      ) ; key id = 28668
            # DS   28668 1  1  49FD46E6C4B45C55D4AC69CBD3CD34AC1AFE51DE
            #
            # and if they do we will have to add 
            # NXT      subzone.example. NS SOA KEY SIG NXT
            # subzone  DS      tag=12345 alg=3 digest_type=1 <foofoo>
            # (http://tools.ietf.org/html/rfc3658)

            # if the parent account wants a sub-domain they just create a subzone and change the do_grid
            # (or just hard-code it into the main zone)

            my $is_subzone=0;
            #do lookup
            #NTS not written

            #dirtuy hack because the above section is not written yet
            if(1==1){
                    $is_subzone=1;
            }
            
 
            open(NEWZONE, ">", "$zone_file$$");
            #print NEWZONE $q->param('zone');
            print NEWZONE $zone_data;
            close(NEWZONE);
            use File::Find;
            # if this IS a zonefile then we check that it is valid
            # checkzone
            rename("$zone_file$$","$zone_file");            
        }
        if(-f "$zone_file"){
            open(ZONE, "<", "$zone_file");
            while(<ZONE>){ $zone .= $_; }
            close(ZONE);
        }else{
            $zone = '@        28800     IN      NS      ns1.example.com.
@        28800     IN      NS      ns0.example.com.' if $q->param('debug');
            if ($q->param('debug')){
                $zone .= ";Domain_name = $domain_name; name= " .$domain_details->do_name;
            }
        }

        $type = 'subzone';
  	$self->tt_params({d=> $domain_details,zone=> $zone});	
     }else{
        my $guess = "ID:" . $q->param('id') . " Name:" . $q->param('domain') . "," . $q->param('name');
        $self->tt_params({message=> "Which domain are you looking for? ($guess)"});
     }
     $self->tt_params({type=> $type});
	 return $self->tt_process();
}

=head3 add

 Add a domain

=cut

sub add: Runmode{
    my $self = shift;
    my $message = '';
    my %opt;
    my $dest = $self->query->url;
    unless($dest=~m/domains/){ $dest .= '/domains'; }
    my $q = $self->query();
    my $domain = Dumper($q);
   if( $q->param('Add') ){
        my %create_domain = ( do_added => \'NOW()');    
        my %find_domain = ();    
        foreach my $ak (keys %{ $q->{'param'} } ){
            if($ak=~m/^do_/){
                $message .= "$ak = $q->param($ak) <br />\n";
                $create_domain{$ak} = lc($q->param($ak));
                if( $ak eq 'do_name'){
                    $find_domain{$ak} = lc($q->param($ak));
                }
            }
        }

        #find their pe_level (later we can search for group membership)
        if($self->param('pe_id')=~m/^\d+$/){
            $opt{'pe_id'} = $self->param('pe_id');
        }elsif($self->session->param('pe_id')=~m/^\d+$/){
            $opt{'pe_id'} =$self->session->param('pe_id');
        }

        my $pe_level;
        if($opt{pe_id}=~m/^\d+$/){
             my $user_details = $self->resultset('People')->search(
                {pe_id => {'=', $opt{pe_id}}},{}
                );
            if($user_details && $opt{pe_id}=~m/^\d+$/){
                while( my $ud = $user_details->next){
                    if($ud->pe_level){
                        $pe_level = $ud->pe_level;
                    }
                }
            }
        }


    # we need to look up domain restrictions (are they allowed to have two letter domain names in .co.uk ?)

    # we have to check that this "domain" does not exist as a hostname or hard-coded subdomain in the parent
    # so first we have to find parent ac_tree and then grep for this host in there


    # NTS dirty hack
    if( $find_domain{'do_name'}=~m/^.*\,.*$/ ){
        my $msg .= "Try without the comma";
        $self->tt_params({ warning => $msg});
        return $self->forward('main');
    }

    if( $find_domain{'do_name'}=~m/^\w{1,3}\.\w{2,3}$/ ){
        my $msg .= "That looks a little short";
        $self->tt_params({ warning => $msg});
        return $self->forward('main');
    }
    if( $find_domain{'do_name'}=~m/(.*\.)+.*\.gb\.com$/ ){
         my $msg .= "No sub-domains: if you want a sub-domain register the domain, and add your name servers";
        $self->tt_params({ warning => $msg});
        return $self->forward('main');
    }

    unless($pe_level>=100){
    if( $find_domain{'do_name'}=~m/^...\.gb\.com$/ || #i.e. three char 
        $find_domain{'do_name'}=~m/^..\.gb\.com$/  || #i.e. two char
        $find_domain{'do_name'}=~m/^.\.gb\.com$/    #i.e. one char
        ){    #i.e. one char
        my $min_length = 11;
        $min_length -= length($find_domain{'do_name'});
        my $warning .= "Domain too short";
        if($min_length){ $warning .= " (needs $min_length more)"; }
        $dest .= '?warning=1';
        $self->param(warning => $warning);
        $self->tt_params({
            warning => $warning{1},
        });
         #return $self->redirect("$dest");
         return $self->forward('main');
    }
    }
    # check that this IS a valid domain
    if(  $find_domain{'do_name'}=~m/\@/ ){
        #$self->tt_params(warning => 'This section is for DOMAIN NAMES dear, emails is another department');
        $self->tt_params(warning => 'Not a DOMAIN NAME');
        return $self->forward('main');
      }

    if(
        $find_domain{'do_name'}!~m/[a-z0-9][a-z0-9_\.-]{0,}[a-z0-9][\.][a-z0-9]{2,14}$/ ||
        $find_domain{'do_name'}=~m/\.\./ ||
        $find_domain{'do_name'}=~m/\W\W/
      ){
        $self->tt_params(warning => 'Not a valid Domain Name');
        return $self->forward('main');
      }


        # If the user is adding a domain with do_status
        # of [ registering, enabled ]
        # and we find the same domain with do_status[ regerstring,enabled,disabled ]

        # or they are trying to add a domain to an account that already has it
        
        my $frs = $self->resultset('Domain')->search( \%find_domain );
        
        while( my $f = $frs->next){
            if( $f->do_acid eq $q->param('do_acid')){
                $dest=~s/\/add$//;
                $self->tt_params({ warning => $warning{3} });
                $dest.= '?warning=3';
                return $self->forward('main');
                #return $self->redirect("$dest");
            }
            if( $f->do_status eq 'enabled' ||
                $f->do_status eq 'registering'
            ){
             my $warning =qq |Domain already registered, (you could add it to your "desired" domains)|;
             $self->tt_params({ warning => $warning });
             #$self->tt_params({ warning => 2 });
             $dest=~s/\/add$//;
             $dest.= '?warning=2';
             return $self->forward('main');
             #return $self->redirect("$dest");
             #return $self->tt_process('Notice/C/Domains/main.tmpl');
            }
        }


        my $rs = $self->resultset('Domain')->create( \%create_domain );
        $rs->update;
        my $do_id = $rs->id;
        if($do_id=~m/^\d+$/){
            $message .= 'added ' . $q->param('do_name') . " ($do_id)";
        }else{
            $message .= 'Domain not added';
        }
        $self->tt_params({
            message => $message,
        });
    }
    #could do a redirect, but this works fine for now
    # return $self->tt_process('Notice/C/Domains/main.tmpl');
    # except this way we end up without the domain list (possibly a "feature" ? )
     #return $self->redirect("$dest");
     return $self->forward('main');
}


=head3 search

search for an existing domain

=cut

sub search: Runmode{
    my ($self) = @_;
    my (%opt);

    my $dest = $self->query->url;
    my ($message);
    unless($dest=~m/domains/){ $dest .= '/domains'; }
    my $q = $self->query;
    my $type; #of domain
    my @domains;
    if( $q->param('id') || $q->param('domain') || $q->param('name') ){
        my %find_domain = ();

        if( $q->param('id') ){
            $find_domain{'do_acid'}=$q->param('id');
        }elsif( $q->param('domain') ){
            $find_domain{'do_name'}=$q->param('domain');
        }elsif( $q->param('name') ){
            $find_domain{'do_name'}=$q->param('name');
        }
        #find their pe_level (later we can search for group membership)
        if($self->param('pe_id')=~m/^\d+$/){
            $opt{'pe_id'} = $self->param('pe_id');
        }elsif($self->session->param('pe_id')=~m/^\d+$/){
            $opt{'pe_id'} =$self->session->param('pe_id');
        }

        #$message .= "Your ID: ".$opt{pe_id};

        my $pe_level;
        if($opt{pe_id}=~m/^\d+$/){
             my $user_details = $self->resultset('People')->search(
                {pe_id => {'=', $opt{pe_id}}},{}
                );
            if($user_details && $opt{pe_id}=~m/^\d+$/){
                while( my $ud = $user_details->next){
                    if($ud->pe_level){
                        $pe_level = $ud->pe_level;
                    }
                }
            }
        }
            
        unless($pe_level >=100){
            $find_domain{'do_acid'} = $self->param('ef_acid');
            unless($find_domain{'do_acid'}=~m/^\d+$/){ $find_domain{'do_acid'} = 'FAIL'; }
        };
        
        $message .= 'Searching for ' . $find_domain{'do_name'};
        #@domains = $self->resultset('Domain')->search( \%find_domain );
        my $frs = $self->resultset('Domain')->search( \%find_domain );
        my $rows = $self->resultset('Domain')->search( \%find_domain )->count;

        if($rows>=1){
            $message .= "<br />Found: $rows matching domains";
            $opt{body} .=qq |<table><tr>
                <th>Status</th>
                <th>Date Domain added, (ID)</th>
                <th>Account Name (ID) [Tree]</th>
                <th>Email Contact</th>
            </tr>|;
            $opt{stripe} = 'odd';
            while( my $f = $frs->next){
                if( $f->do_acid eq $self->param('ef_acid') || $pe_level >=100){
                    my $ac_id = $f->do_acid;
                    if($ac_id=~m/^\d+$/){
                        my $acrs  = $self->resultset('Account')->search({'ac_id' => {'=' => $ac_id} }, undef)->first;
                        $opt{$f->do_id}{ac_name} = $acrs->ac_name=~m/.+/ ? $acrs->ac_name : '&lt;"Blank"&gt;';
                        $opt{$f->do_id}{ac_tree} = $acrs->ac_tree=~m/.+/ ? $acrs->ac_tree : '&lt;"Blank"&gt;';
                        my $pers  = $self->resultset('People')->search({'pe_acid' => {'=' => $ac_id} }, undef)->first;
                        $opt{$f->do_id}{pe_email} = $pers->pe_email=~m/.+/ ? $pers->pe_email : '&lt;"Blank"&gt;';
                        $opt{$f->do_id}{pe_fname} = $pers->pe_fname=~m/.+/ ? $pers->pe_fname : '&lt;"?';
                        $opt{$f->do_id}{pe_lname} = $pers->pe_lname=~m/.+/ ? $pers->pe_lname : ' ??"&gt;';
                    }
                    #my $acrs = $self->resultset('Account')-search({ 'ac_id' => {'=', $f->do_acid}, },{ })->first;
                $opt{body} .='<tr class="' . $opt{stripe} .'">';
                $opt{body} .='<td>'. $f->do_status . '</td>';
                $opt{body} .='<td>'. $f->do_added . '('. $f->do_id .')</td>';
                $opt{body} .='<td><a href="search/'. $ac_id . '">'.  
                    $opt{$f->do_id}{ac_name} .'</a>      <span class="right">('. 
                    $f->do_acid . ') ['. $opt{$f->do_id}{ac_tree} . ' ]</span></td>';
                $opt{body} .='<td> '. 
                $opt{$f->do_id}{pe_fname} . ' '.
                $opt{$f->do_id}{pe_lname} . ' '.
                $opt{$f->do_id}{pe_email} . '</td>';
                $opt{body} .='</tr>';
                }
                if($opt{stripe} eq 'odd'){ $opt{stripe} = 'even';}else{ $opt{stripe} = 'odd'; }
            }
            $opt{body} .=qq |</table>|;
        }else{
            $message .= ", but not found in this account.";
        }
    }
    if(@domains){ $self->tt_params({domains => \@domains}); }
    $self->tt_params({message => $message});
    if($opt{body}){ $self->tt_params({results_table => $opt{body}}); }
    return $self->tt_process();
}

=head3 delete

 Add a domain

=cut

sub delete: Runmode{
    my ($self) = @_;
    my (%opt);

    my $dest = $self->query->url;
    my $message;
    unless($dest=~m/domains/){ $dest .= '/domains'; }
    my $q = $self->query;
    my $type; #of domain
    if( $q->param('id') || $q->param('domain') || $q->param('name') ){
        my %find_domain = ();

        if( $q->param('id') ){
            $find_domain{'do_id'}=$q->param('id');
        }elsif( $q->param('domain') ){
            $find_domain{'do_name'}=$q->param('domain');
        }elsif( $q->param('name') ){
            $find_domain{'do_name'}=$q->param('name');
        }

        # have to limit this search to domains in their account
        my $ef_acid;
        if($self->param('ef_acid')){
            $ef_acid = $self->param('ef_acid');
        }
      $opt{do_name} = $find_domain{do_name};
      if($opt{do_name}){
        $message .= $opt{do_name};
      }elsif($q->param('name') ne ''){
        $message .= $q->param('name') . " (" . $q->param('id') . ")";
      }else{
        $message .=  '|domain| ';
      }
     my $del = $self->resultset('Domain')->search({ 
            do_id => {'=', $find_domain{'do_id'} },
        },{
            columns => ['do_id','do_acid'],
        })->first;
     if($del && $del->do_acid && ( $del->do_acid eq $ef_acid )){
        $del->delete();
        $self->param(message => $message);
        $self->session->param(tmessage => $message);
        $self->tt_params({message => $message});
        my($surl,$qurl) = ($self->query->url,$self->query->self_url);
        warn "surl = $surl";
        warn "qurl = $qurl";
        return $self->redirect("$surl/domains/");
      }else{
           $self->tt_params({message => 'That seems to be in another account'});
           return $self->tt_process('Notice/C/Domains/main.tmpl');
      }
    }else{
       $message .= 'deleted (when we write that)';
        $message .= '('. $q->param('id') .'||'. $q->param('domain') .'||'. $q->param('name') .')';
        foreach my $ak (keys %{ $q->{'param'} } ){
                my $key = $ak;
                my $value = $q->param($ak);
                #$message .= " " .$ak ."=". $q->param($ak) ."<br />\n";
                $message .= "$key = $value<br />\n";
        }
       $self->tt_params({message => $message});
       return $self->tt_process('Notice/C/Domains/main.tmpl');
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


