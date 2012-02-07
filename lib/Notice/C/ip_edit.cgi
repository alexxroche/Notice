#!/usr/bin/perl
use DBI;
use strict;
no strict "refs";
use Notice::Common;
use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI});
use Notice::HTML qw( html_header html_footer sidemenu );
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = 'ip_edit.cgi' . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
my($DEBUG,$error,$col_order,$where);
$DEBUG=0;
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
my(%ippool,$answer,$update,$delete,%error);
my $action_name = 'Update';

 if($DEBUG == 1){
        foreach my $que (keys %form)
        {
                print "$que = $form{$que} <br />";
        }
        print "<br />";
  }

#NTS - this script will no longer be needed when ipblock.cgi gets its AJAX to let us edit an entry inline
#NTS - this script will no longer be needed when ip_search.cgi gets its AJAX to let us edit an entry inline

$error{1}='Duplicate IP address found - you may update the entry here';

# get the ip range from the database (this has a race condition, but we can fix that later)
if($user_details{pe_level} > 5)
{

	foreach my $values (keys %form){
	# NTS need to protect $where from XSS
		if($form{$values} eq 'Edit'){ $where = $values; }
		if($form{$values} eq 'Update'){ $update = $values; }
		if($form{$values} eq 'Delete'){ $where = $values; $delete=1;}
		if($form{$values} eq 'Edit IP'){ $form{ip_ref} = $values; }
		print "$values = $form{$values}<br/>\n" if $DEBUG>=2;
		if($form{error}=~m/^(\d+).*/){ $error = $error{$1}; }
	}
	if($delete){ $action_name = 'Delete'; }
	if($error){ print $error; }


    if($form{ipp_name}){
	use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html update_ipp list_assigned_to);
	my($notice)= new Notice::DB::ip;
	my %values;
#NTS check we are talking to a person with the right privs
#$notice->check_position('$ENV{REMOTE_USER}','Director','Admin','Sysops');
	$values{auth} = 1;
#check we have what we need
	$form{ipp_name} .= '/' . $form{ipp_slash} if ($form{ipp_slash} && $form{ipp_name}!~m|/|);
	$form{ipp_name}=~s/\s//g;
	# we should either have 'ipp_name','ipp_VLAN','ipp_RIR','ipp_assigned_to','ipp_notes'
	# ipp_name should be a valid IPv[4|6]/$valid_slash
	# ipp_VLAN should be a number from 1 to 1005
	# ipp_RIR should be valid in our ippool table
	# ipp_assigned_to should be an AS or company/account
	# ipp_notes should explain the general use within the company in ipp_assigned_to
	#<DEBUG>
	if($DEBUG == 1){
	foreach my $que (keys %form)
	{
		print "$que = $form{$que} <br />";
	}
	print "<br />";
	if( ( 	$form{ipp_name}!~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ &&
		$form{ipp_name}!~m/^([0-9A-F]{1,4}::?){1,7}[0-9A-F]{1,4}\/(\d{1,2}|1(0-1)\d|12[0-8])$/i )
	){ $error .= "ipp_name |$form{ipp_name}| not match <br />"; }
	if($form{ipp_VLAN}!~m/^\d{1,4}$/){ $error .= "VLAN not match <br />"; }
	if($form{ipp_RIR}!~m/^\w+$/){ $error .= "RIR not match <br />"; }
	if($form{ipp_assigned_to}!~m/\w/){ $error .= "assin not match <br />"; } 
	}
	# </DEBUG>
	if( ( 	$form{ipp_name}=~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ ||
		$form{ipp_name}=~m/^([0-9A-F]{1,4}::?){1,7}[0-9A-F]{1,4}\/(\d{1,2}|1(0-1)\d|12[0-8])$/i ) &&
	$form{ipp_VLAN}=~m/^\d{1,4}$/ &&
	$form{ipp_RIR}=~m/.+/ &&
	$form{ipp_assigned_to}=~m/\w/ 
	){
		#warn( " OOOOOOH HERE!!! ");
		$values{ipp_ref}	= $form{ipp_ref};
		$values{ipp_name}	= $form{ipp_name};
		$values{ipp_VLAN}	= $form{ipp_VLAN};
		$values{ipp_network}	= $form{ipp_network};
		$values{ipp_RIR}	= $form{ipp_RIR};
		$values{ipp_assigned_to}= $form{ipp_assigned_to};
		$values{ipp_notes}	= $form{ipp_notes};
		$values{ipp_notes}	=~s/'/\\'/g;
		$values{data_checked}	= 1;
		if($delete){ $values{action} = 'delete'; }
		print "Passed the REG <br />" if $DEBUG == 1; #DEBUG
	}
	# OR One string ipp_name which will have all of the above in one string that we have to split
	elsif($form{ipp_name}) #should match six ','
	{
		$form{ipp_name}=~s/^\s*//;
		chomp($form{ipp_name});
		$form{ipp_name}=~s/\s+/ /g;
		my($name,$vlan,$network,$rir,$assigned_to,$notes) = split(/ /, $form{ipp_name}, 6);
		$values{ipp_name}       = $name;
                $values{ipp_VLAN}       = $vlan;
		$values{ipp_network}	= $network;
                $values{ipp_RIR}        = $rir;
                $values{ipp_assigned_to}= $assigned_to;
                $values{ipp_notes}      = $notes;
		$values{ipp_ref}        = "$name;$network";
                $values{ipp_notes}      =~s/'/\\'/g;
		$values{data_checked} = 1;
		#warn( " OOOOOOH THERE!!!  $name;$network");
	}
	else
	{
		$error .= "<br />Invalid Block Data";
	}
	print "<br /> $error <br />" if $DEBUG ==1;

	if($values{auth} == 1 && $values{data_checked} == 1)
	{
		#<DEBUG>
		if($DEBUG == 1){
		foreach my $key (keys %values)
		{
			print "$key = $values{$key} <br />";
		}
		}
		#</DEBUG>
		$values{pe_id} = $user_details{pe_id};
		$notice->update_ipp(\%values);
	}
	if($values{return})
	{
		print "$values{return} ";
	}
    } # end of ipp_update block #end of if

    if($form{ip}){  # this is an update for an IP address
	use Notice::DB::ip qw( update_ip );
        my($notice_ipu)= new Notice::DB::ip;
        my %values;
	$values{pe_id} = $user_details{pe_id}; # lets get some accountability in here!
#NTS check we are talking to a person with the right privs
#$notice->check_position('$ENV{REMOTE_USER}','Director','Admin','Sysops','GROUP::ip_admin');
        $values{auth} = 1;
#check we have what we need
	my $ip_ref = $form{ip_ref}; # NTS as this is the anchor or uniqueness we should be VERY strict about it
	#my($cidr_ip,$network)= split('\;', $form{ip});
	#my($ip,$slash)= split('\/', $cidr_ip);
	my $ip = $form{ip};
	my $slash = $form{ip_slash};
	my $network = $form{ip_network};
        if($DEBUG == 1){
		print "WE ARE INSIDE FOR THE IP UPDATE SECTIONN\n<br/>";
        	foreach my $que (keys %form)
        	{
        	        print "$que = $form{$que} <br />";
        	}
        	print "<br/>";
		#NTS this might not need as much evaluation if we use a pull down menu,
		#but remembe the modules may be fed by an API rather than this code
		#so they have to check that we are not being fed a IPv4/7 or IPv6/129
        	if( (   $ip!~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ &&
        	        $ip!~m/^([0-9A-F]{0,4}::?){1,7}[0-9A-F]{1,4}$/i )
        	){ $error .= "ip_name |$ip| not match <br />"; }
        	if($slash!~m/^\d{1,3}$/){ $error .= "slash seems off <br />"; }
		if($ip_ref!~m#^(\d{1,3}\.){3}\d{1,3}/(\d|1\d|2\d|30|31|32):\d{1,}(\.\d{1,})*$#){ $error .= "REF: $ip_ref<br/>"; }
        	if($network!~m/^\d{1,}(\.\d{1,})*$/){ $error .= "Network $network << what?<br/>"; }
        	if($form{ip_type}!~m/.+/){ $error .= "TYPE needs to be one or the other <br />"; }
        	if("$form{ip}" ne "$update"){ $error .= "Not a valid submision <br />"; }
        }
        # </DEBUG>
	#NTS the IPv6 RegExp needs work
        if( (   $ip=~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ ||
                $ip=~m/^([0-9A-F]{0,4}::?){1,7}[0-9A-F]{1,4}$/i ) &&
        $form{ip_network}=~m/^\d{1,}(\.\d{1,})*$/ &&
        ( $ip_ref=~m#^(\d{1,3}\.){3}\d{1,3}/(\d|1\d|2\d|30|31|32):\d{1,}(\.\d{1,})*$# ||
	 $ip_ref=~m#([0-9A-F]{0,4}::?){1,7}[0-9A-F]{1,4}/(\d?\d|1[0-1]\d|12[0-8]):\d{1,}(\.\d{1,})*$# ) && 
        $slash=~m/^\d{1,3}$/ &&
        $form{ip_type}=~m/.+/ &&  #without a type an IP address is meaningless!
	"$form{ip}" eq "$update" #yes I am paranoid, yes I know this can be bypassed
        ){
                $values{where}       = $form{where};
                $values{ip}          = $ip;
                $values{ip_slash}    = $slash;
                $values{ip_type}     = $form{ip_type};
                $values{ip_usedfor}  = $form{ip_usedfor};
                $values{ip_usedfor}  =~s/'/\\'/g;
                $values{ip_stockref} = $form{ip_stockref};
                $values{ip_ref} = $form{ip_ref};
                $values{ip_network}  = $form{ip_network};
                $values{ip_network}  =~s/'/\\'/g;
                $values{ip_notes}    = $form{ip_notes};
                $values{ip_notes}    =~s/'/\\'/g;
                $values{data_checked}= 1;
                print "Passed the REG <br />" if $DEBUG == 1; #DEBUG
        }
        else
        {
                $error .= "<br />Invalid Data (|$update| != |$form{ip}|)";
        }
        print "<br/> $error <br/>" if $DEBUG ==1;

        if($values{auth} == 1 && $values{data_checked} == 1)
        {
                foreach my $key (keys %values)
                {
                        $values{$key}=~s/\'/\\\'/g;
                }
                my $exit_code = $notice_ipu->update_ip(\%values);
		$form{ip_ref} = "$values{ip}/$values{ip_slash};$values{ip_network}" unless $exit_code;

        }
        if($values{return})
        {
                print "$values{return} ";
	}
	
    } # end of ip_update vlock #end of if  [ SECOND UPDATE BLOCK ]

	if($where || $form{ipp_name} ){
	print "You have a WHERE of $where OR a name of $form{ipp_name}<br/>" if $DEBUG>=1;
	if(!$where){ 
		warn("WHERE = |$where|$form{ipp_name}|") if $DEBUG>=1;
		$where = $form{ipp_name}.';'.$form{ipp_network};
		warn("HERE = |$where|$form{ipp_name}|") if $DEBUG>=1;
	}
 use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html assigned_to_html);
 my($notice_ipp)= new Notice::DB::ip;
 $notice_ipp->show_pool(\%ippool,$where);
 my $ref;
    print qq( <form method="post" action="$action">	<table>
     <tr>
	<th class="ip">IP Range</th> <!--IP address / slash -->
        <th class="ip">VLAN</th>
        <th class="ip">Network</th>
        <th class="ip">Assigned By</th>
        <th class="ip">Assigned To</th>
        <th class="ip">Description</th>
        <th class="ip">Action</th>
     </tr>
    );
 if(%ippool){
  foreach $ref (keys %ippool){
	next unless $ippool{$ref}{ipp_name};
	my(%networks,%ippat);
	my $VLAN_html = $notice_ipp->VLAN_html("$ippool{$ref}{'ipp_VLAN'}");			#default VLAN
	my $ipp_RIR_html = $notice_ipp->ipp_RIR_html("$ippool{$ref}{'ipp_RIR'}");		#default RIR
	my $assigned_to_html = $notice_ipp->list_assigned_to(\%ippat,"$ippool{$ref}{'ipp_assigned_to'}",'nope');
	if(!$ippool{$ref}{'ipp_network'}){ $ippool{$ref}{'ipp_network'} = 0; }
 	my $network_html = $notice_ipp->Notice::DB::ip::networks(\%networks,"$ippool{$ref}{'ipp_network'}",'','skip_blank');
	my $ipp_ref = "$ippool{$ref}{ipp_name}/$ippool{$ref}{'ipp_subnet'};$ippool{$ref}{'ipp_network'}";
	print qq |
	<tr>
                <td><input type="hidden" name="ipp_ref" value="$ipp_ref"/>
                <input type="text" name="ipp_name" value="$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'}"/></td>
                <td>$VLAN_html</td>
		<td>$network_html|;
       if($user_details{pe_level} > 5){ print qq| $ippool{$ref}{'ipp_network'}|; }
	print qq|</td>
                <td>$ipp_RIR_html</td>
                <td>$assigned_to_html</td>
                <td><input type="text" name="ipp_notes" value="$ippool{$ref}{'ipp_notes'}"/></td>
		<td><input type="submit" value="$action_name" name="$action_name" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
	</tr>
	|;
  } #foreach
 }else{ print "<tr><td>no pool</td></tr>";} #if

 undef(%ippool);

print "</table></form>
";
	} # end of ip_block edit
	elsif($form{ip_ref}){######################################################################### Or we edit a single IP
	 use Notice::DB::search qw( show_pool VLAN_html ipp_RIR_html assigned_to_html);
 my($notice)= new Notice::DB::search;
 my(%iprange);
 my($cidr_ip,$network)= split('\;', $form{ip_ref});
 my($ip,$slash)= split('\/', $cidr_ip);
 $iprange{'ip'} = $ip;
 $iprange{'network'} = $network;
 $iprange{sort} = $form{sort};
 $iprange{order} = $form{order};
 $notice->ip(\%iprange);
 my $ref;
	$error .= $iprange{error};
    print qq( <form method="post" action="$action">        <table>
      <tr>
        <th class="ip"><a href="$page?sort=ip_o1$col_order&amp;ud=$ud">IP Address</a></th> <!--IP address / slash -->
        <th class="ip" colspan="2"><a href="$page?sort=ip_slash$col_order&amp;ud=$ud">Slash</a></th>
        <th class="ip"><a href="$page?sort=ip_network$col_order&amp;ud=$ud">Network</a></th>
        <th class="ip"><a href="$page?sort=ip_type$col_order&amp;ud=$ud">Type</a></th>
        <th class="ip"><a href="$page?sort=ip_usedfor$col_order&amp;ud=$ud">Used For</a></th>
        <th class="ip"><a href="$page?sort=ip_stockref$col_order&amp;ud=$ud">Stockref</a></th>
        <th class="ip"><a href="$page?sort=ip_notes$col_order&amp;ud=$ud">Notes</a></th>
        <th class="ip">Action</th>
      </tr>
    );
	#NTS probably don't need the sort option in the above table headers
 if(%iprange){
	   my $stripe = 'strip';
        my $ipdivtype = '.';
	delete $iprange{ip};
	delete $iprange{sort};
	delete $iprange{order};
	delete $iprange{error};
	delete $iprange{network};

	# NTS if we have more than one then there is a problem - so foreach is probably the wrong choice here
        IPEFE: foreach my $ref (sort keys %iprange)
        {
	   my(%networks);
 	   my $network_html = $notice->Notice::DB::ip::networks(\%networks,"$iprange{$ref}{'ip_network'}",'not_a_range','skip_blank');
	   my $ip_size=10;
	   my $ip_maxlength=15;
	# the slash should be a pull down menu so we can't have /128 in a IPv4 NTS
        if($iprange{$ref}{'ip_type'} eq 'IPv6'){$ipdivtype = ':';}else{$ipdivtype = '.';}
        my $ipaddress = "$iprange{$ref}{'ip_o1'}$ipdivtype$iprange{$ref}{'ip_o2'}$ipdivtype$iprange{$ref}{'ip_o3'}$ipdivtype$iprange{$ref}{'ip_o4'}";
        if($iprange{$ref}{'ip_type'} eq 'IPv6'){
           $ipaddress .= qq($ipdivtype$iprange{$ref}{'ip_o5'}$ipdivtype$iprange{$ref}{'ip_o6'}$ipdivtype$iprange{$ref}{'ip_o7'}$ipdivtype$iprange{$ref}{'ip_o8'});
	   $ip_size=42;
	   $ip_maxlength=39;
        }
	my $ip_ref = qq|$ipaddress/$iprange{$ref}{'ip_slash'}:$iprange{$ref}{'ip_network'}|;

	if($user_details{pe_level} > 6){
        $answer .=  qq(<tr class="$stripe"><td><input type="text" size="$ip_size" maxlength="$ip_maxlength" name="ip" value="$ipaddress"/></td>);
	$answer .=  qq(<td>/</td>);
        $answer .= qq(<td><input type="text" name="ip_slash" size="3" maxlength="3" value="$iprange{$ref}{'ip_slash'}"/></td>);
        $answer .= qq(<td>$network_html</td>);
        $answer .= qq(<td><input type="text" name="ip_type" size="3" value="$iprange{$ref}{'ip_type'}"/></td>);
	}else{
        $answer .= qq(<tr class="$stripe"><td><input type="hidden" name="ip" value="$ipaddress"/>$ipaddress</td>);
	$answer .=  qq(<td>/</td>);
        $answer .= qq(<td><input type="hidden" name="ip_slash" value="$iprange{$ref}{'ip_slash'}"/>$iprange{$ref}{'ip_slash'}</td>);
        $answer .= qq(<td>$network_html</td>);
        $answer .= qq(<td><input type="hidden" name="ip_type"  value="$iprange{$ref}{'ip_type'}"/>$iprange{$ref}{'ip_type'}</td>);
	}
        $answer .= qq(
                <td><input type="text" name="ip_usedfor" size="30" value="$iprange{$ref}{'ip_usedfor'}"/></td>
                <td><input type="text" name="ip_stockref" size="1" value="$iprange{$ref}{'ip_stockref'}"/></td>
                <td><input type="text" name="ip_notes" size="50" value="$iprange{$ref}{'ip_notes'}"/></td>
                <td><input type="hidden" name="ip_ref" size="50" value="$ip_ref"/>
                <input type="submit" value="$action_name" name="$ipaddress" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></td>
        </tr>
        );
        if($stripe eq 'stripe'){ $stripe = 'strip';}
        else{ $stripe = 'stripe';}
	}
   undef(%iprange);

$answer .= '</table></form>';
	print $answer;

 } #if
 else {  print "ERROR: $error\n"; }
}else{
		print "I can't hear you - what are we going to edit?\n";
		print "$error";
                print html_footer;
                exit;
	}

} # end if level check
else
{
	print "This option is not open to people of your Level ";
	if($user_details{pe_level}){ print "($user_details{pe_level}) ";}
	print "at this time";
}
print html_footer;

