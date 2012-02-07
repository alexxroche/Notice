#!/usr/bin/perl

use DBI;
use strict;
use Notice::Common;
use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI});
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
use Notice::HTML qw( html_header html_footer sidemenu );
use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html insert_ipp list_assigned_to);
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
my $edit_action = 'ip_edit.cgi?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
my %networks;
my($DEBUG,$error,$col_order,$slash);
$slash=$form{slash};
# check we have a CIDR ip range
if($slash!~m/[(\d{1,3}\.|[0-9a-f:]*/){ $slash='127.0.0.1/16'; }

if(!$form{order}) { $col_order = '&amp;order=desend'; }

my($notice)= new Notice::DB::ip;
my(%ippool,%ippat);
my $VLAN_html = $notice->VLAN_html('24');			#default VLAN
my $ipp_RIR_html = $notice->ipp_RIR_html('RIPE');		#default RIR
my $assigned_to_html = $notice->list_assigned_to(\%ippat,'Main account','nope');#default assigned_to

if(!$form{sort}){ $form{sort} = 'ip_name';}

if($form{ipp_name})
{
	my %values;
#NTS check we are talking to a person with the right privs
#$notice->check_position('$ENV{REMOTE_USER}','Director','Admin','Sysops');
	$values{auth} = 1;
#check we have what we need
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
		$values{ipp_name}	= $form{ipp_name};
		$values{ipp_VLAN}	= $form{ipp_VLAN};
		$values{ipp_network}	= $form{ipp_network};
		$values{ipp_RIR}	= $form{ipp_RIR};
		$values{ipp_assigned_to}= $form{ipp_assigned_to};
		$values{ipp_notes}	= $form{ipp_notes};
		$values{ipp_notes}	=~s/'/\\'/g;
		$values{data_checked}	= 1;
		print "Passed the REG <br />" if $DEBUG == 1; #DEBUG
	}
	# OR One string ipp_name which will have all of the above in one string that we have to split
	elsif($form{ipp_name})
	{
		$form{ipp_name}=~s/^\s*//;
		chomp($form{ipp_name});
		$form{ipp_name}=~s/\s+/ /g;
		my($name,$vlan,$network,$rir,$assigned_to,$notes) = split(/ /, $form{ipp_name}, 6);
		$values{ipp_name}       = $name;
                $values{ipp_VLAN}       = $vlan;
                $values{ipp_network}    = $network;
                $values{ipp_RIR}        = $rir;
                $values{ipp_assigned_to}= $assigned_to;
                $values{ipp_notes}      = $notes;
                $values{ipp_notes}      =~s/'/\\'/g;
		$values{data_checked} = 1;
	}
	else
	{
		$error .= "<br />Invalid Data";
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
		$notice->insert_ipp(\%values);
	}
	if($values{return})
	{
		print "$values{return}";
	}
}

$ippool{slash} = $slash;

$notice->show_slash(\%ippool);

if($error) { print "ERROR: $error"; }
	delete($ippool{slash});
	#print "$ippool{query}<br/>";
	delete($ippool{query});
my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
    <br />
<table class="ip">
      <tr>
        <th class="ip"><a href="$page?sort=ip_name$col_order&amp;ud=$ud&amp;slash=$slash">IP Address</a></th> <!--IP address / slash -->
        <th class="ip"><a href="$page?sort=ip_network$col_order&amp;ud=$ud&amp;slash=$slash">Network</a></th>
        <th class="ip"><a href="$page?sort=ip_VLAN$col_order&amp;ud=$ud&amp;slash=$slash">Type</a></th>
        <th class="ip"><a href="$page?sort=ip_RIR$col_order&amp;ud=$ud&amp;slash=$slash">Name</a></th>
        <th class="ip"><a href="$page?sort=ip_assigned_to$col_order&amp;ud=$ud&amp;slash=$slash">Stock Ref</a></th>
        <th class="ip"><a href="$page?sort=ip_notes$col_order&amp;ud=$ud&amp;slash=$slash">Description</a></th>
        <th class="ip">Edit</th>);
	if($user_details{pe_level} > 50){ $html_table .= qq(<th class="ip">Delete</th>); }
  $html_table .= qq(
      </tr>
);
my $network_html = $notice->networks(\%networks,'1.0','range','skip_blank');
my($ip_range,$network) = split(/;/, $slash);
my ($this_net,$vlan) = split(',', $network);

print "Within $ip_range for the $networks{$this_net} network we have: " ;
print $html_table;
sub ippool_sort
{
	my $key = $form{sort};
	if($form{order} eq 'desend')
	{
		if($key eq 'ip_VLAN')
		#if($key eq 'ip_VLAN' || $key eq 'ip_name')
		#if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
		{	# numeric
			( $ippool{$a}{"$key"} <=> $ippool{$b}{"$key"} )
		}elsif($key eq 'ip_name'){
			( $ippool{$a}{ip_o4} <=> $ippool{$b}{ip_o4} )
		} else { # alpha
			( $ippool{$a}{"$key"} cmp $ippool{$b}{"$key"} )
		}
	}
	else
	{
		if($key eq 'ip_VLAN')
		#if($key eq 'ip_VLAN' || $key eq 'ip_name')
		#if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
                {       # numeric
                        ( $ippool{$b}{"$key"} <=> $ippool{$a}{"$key"} )
		}elsif($key eq 'ip_name'){ #NTS need IPv6 code
			( $ippool{$b}{ip_o4} <=> $ippool{$a}{ip_o4} )
                } else { # alpha
                        ( $ippool{$b}{"$key"} cmp $ippool{$a}{"$key"} )
                }
	}
}
my $stripe = 'stripe';
#my $network_html = $notice->Notice::DB::ip::networks(\%networks,'1.0','range','skip_blank');

my $ipdivtype = '.';
foreach my $ref (sort ippool_sort keys %ippool)
{
	 if($ippool{$ref}{'ip_type'} eq 'IPv6'){$ipdivtype = ':';}else{$ipdivtype = '.';}
        print qq(
        <tr class="$stripe"><td>
                $ippool{$ref}{'ip_o1'}$ipdivtype$ippool{$ref}{'ip_o2'}$ipdivtype$ippool{$ref}{'ip_o3'}$ipdivtype$ippool{$ref}{'ip_o4'});
        if($ippool{$ref}{'ip_type'} eq 'IPv6')
        {
                print qq($ipdivtype$ippool{$ref}{'ip_o5'}$ipdivtype$ippool{$ref}{'ip_o6'}$ipdivtype$ippool{$ref}{'ip_o7'}$ipdivtype$ippool{$ref}{'ip_o8'}
                );
        }
	#NTS should be pulling default network
		chomp($ippool{$ref}{'ip_network'});
                my $ip_ref;
		if($ippool{$ref}{'ip_type'} eq 'IPv6'){
			$ip_ref = "$ippool{$ref}{'ip_o1'}:$ippool{$ref}{'ip_o2'}:$ippool{$ref}{'ip_o3'}:$ippool{$ref}{'ip_o4'}:";
		   	$ip_ref .="$ippool{$ref}{'ip_o5'}:$ippool{$ref}{'ip_o6'}:$ippool{$ref}{'ip_o7'}:$ippool{$ref}{'ip_o8'}";
		}else{
			$ip_ref = "$ippool{$ref}{'ip_o1'}.$ippool{$ref}{'ip_o2'}.$ippool{$ref}{'ip_o3'}.$ippool{$ref}{'ip_o4'}";
		}
		   $ip_ref .="/$ippool{$ref}{'ip_slash'}:$ippool{$ref}{'ip_network'}";
        print qq(/$ippool{$ref}{'ip_slash'}</td>
		<td>$networks{"$ippool{$ref}{'ip_network'}"}</td>
                <td>$ippool{$ref}{'ip_type'}</td>
                <td>$ippool{$ref}{'ip_usedfor'}</td>
                <td>$ippool{$ref}{'ip_stockref'}</td>
                <td>$ippool{$ref}{'ip_notes'}</td>
                <td><form method="post" action="$edit_action"><input type="submit" value="Edit IP" name="$ip_ref" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>);
	if($user_details{pe_level} > 50){
               print qq(<td><form method="post" action="$action"><input type="submit" value="Delete" name="$ippool{$ref}{'ip_o1'}" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>);
	}
	print qq(
        </tr>
        );
        if($stripe eq 'stripe'){ $stripe = 'strip';}
        else{ $stripe = 'stripe';}
}
undef(%ippool);
print "</table></td></tr><tr><td>";
my ($ip,$vlsm) = split /\//, $ip_range;
if(24 <= $vlsm && $vlsm < 32){
	my @address = split /\./, $ip;
	#find the block size
	#2^32-28 = 2^4 = 16
	my($mask)=256-(1<<(32-$vlsm));
	my($start)=$address[3] & $mask;
	my($end)=$start+255-$mask;

print "<table cellpadding='0' cellspacing='0'>
<tr><td>NW=</td><td>$address[0].$address[1].$address[2].$start</td><td>(network)</td></tr>
<tr><td>GW=</td><td>$address[0].$address[1].$address[2]." . ($start+1) . "</td><td>(gateway)</td></tr>
<tr><td>WG=</td><td>$address[0].$address[1].$address[2]." . ($end-1) . "</td><td>(waygate)</td></tr>
<tr><td>BC=</td><td>$address[0].$address[1].$address[2]." . ($end) . "</td><td>(broadcast)</td></tr>
</table>";
}


if($user_details{pe_level} > 15)
{
print qq| Add a new IP Range ?<br/>|;
print qq( <form method="post" action="$action">	   <table>
     <tr>
	<th class="ip">IP Range</th> <!--IP address / slash -->
        <th class="ip">VLAN</th>
	<th class="ip">Network</th>
        <th class="ip">Assigned By</th>
        <th class="ip">Assigned To</th>
        <th class="ip">Description</th>
     </tr>
);

	print qq |
	<tr>
                <td><input type="text" name="ipp_name" /></td>
                <td>$VLAN_html</td>
		<td>$network_html</td>
                <td>$ipp_RIR_html</td>
                <td>$assigned_to_html</td>
                <td><input type="text" name="ipp_notes" /></td>
		<td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
	</tr>
	|;


print "</table></form>
";
} # end if level check
else
{
	print "$user_details{pe_level}" if $DEBUG>=1;
}
print "
</td></tr>";

print "</table>";
print "<br />";
print html_footer;

