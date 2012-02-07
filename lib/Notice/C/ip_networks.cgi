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
use Notice::DB::account;
use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html insert_ipp list_assigned_to);
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
print "Each Network is Assigned to an Account. This is where Networks are linked to Accounts.<br/> This enables Sysadmin of each account to view and edit their own IP addresses without contact with other addresses<br/>";
my($DEBUG,$error,$col_order);
$DEBUG=0;

if(!$form{order}) { $form{order} = 'asc'; $col_order = '&amp;order=asc'; }
if(!$form{sort}) { $form{sort} = 'ipp_network'; }

my($notice)= new Notice::DB::ip;
my($notice_accounts)= new Notice::DB::account;
my(%networks,%accounts,%ippat);
$accounts{URI} = $ud;
my $network_html = $notice->Notice::DB::ip::networks(\%networks,'1.0','','skip_blank');
my $assigned_to_html = $notice->list_assigned_to(\%ippat,'Main account','nope');#default assigned_to
$notice_accounts->list_accounts(\%accounts,'Main');
my(%vlans);

if($form{add_ipp_network})
{
	my %values;
#NTS check we are talking to a person with the right privs or in the right group
#$notice->check_position('$ENV{REMOTE_USER}','ip_admin','network_admin','Sysops');
	$values{auth} = 1; # guess they passed for now #NTS must write this part
#check we have what we need
	#<DEBUG>
	 if($DEBUG == 1){
	  foreach my $que (keys %form)
	  {
		print qq|<span class="withouterror">$que = $form{$que} </span><br/>|;
	  }
	  print "<br />";
	 }
	# </DEBUG>
	if( ( 	$form{add_ipp_network}=~m/^(.\s?)+$/ &&
		$form{ipp_assigned_to}=~m/^(.*\s?)+$/)
	){
		$values{ipp_network}	= $form{add_ipp_network};
		$values{ipp_assigned_to}= $form{ipp_assigned_to};
		$values{data_checked}	= 1;
		print "Passed the REG <br />" if $DEBUG == 1; #DEBUG
	}else{
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
		$values{URI} = $ud; # we will use this when I write it
		$values{pe_id} = $user_details{pe_id}; # for now we are a trusing fool - NTS
		$notice->insert_ipp_network(\%values);
	}
	if($values{return})
	{
		print "<br/>$values{return}";
	}
	if($values{error}) { print "<br/>$values{error}"; }
}

if($error) { print "ERROR: $error"; }
my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
<table class="ip">
      <tr>
        <th class="ip">Network</th>
        <th class="ip">Assigned To</th>
        <th class="ip">Edit</th>
        <th class="ip">Delete</th>
      </tr>
);

print $html_table;
sub vlans_sort
{
	my $key = $form{sort};
	if($form{order} eq 'asc')
	{
		if($key eq 'ipp_network')
		{	# numeric
			( $vlans{$a}{"$key"} <=> $vlans{$b}{"$key"} )
		} else { # alpha
			( $vlans{$a}{"$key"} cmp $vlans{$b}{"$key"} )
		}
	}
	else
	{
		if($key eq 'ipp_network')
                {       # numeric
                        ( $vlans{$b}{"$key"} <=> $vlans{$a}{"$key"} )
                } else { # alpha
                        ( $vlans{$b}{"$key"} cmp $vlans{$a}{"$key"} )
                }
	}
}
my $stripe = 'stripe';

my $VLAN_html = $notice->show_networks(\%vlans);

foreach my $ref (sort vlans_sort keys %vlans)
{
	
	print  qq(
	<tr class="$stripe">
		<td>$vlans{$ref}{'ipp_notes'}</td>
		<td>$accounts{$vlans{$ref}{'ipp_assigned_to'}}</td>
		<td><form method="post" action="$action"><input type="submit" value="Edit" name="$vlans{$ref}{'ipp_network'}:$vlans{$ref}{'ipp_network'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>
		<td><form method="post" action="$action"><input type="submit" value="Delete" name="$vlans{$ref}{'ipp_network'}:$vlans{$ref}{'ipp_network'}" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>
	</tr>
	);
	if($stripe eq 'stripe'){ $stripe = 'strip';}
	else{ $stripe = 'stripe';}
}

undef(%vlans);

print "</table></td></tr><tr><td>";
if($user_details{pe_level} > 5)
{
print qq( <form method="post" action="$action">	   <table>
     <tr>
        <th class="ip">Network</th>
        <th class="ip">Assigned To</th>
     </tr>
);

	print qq |
	<tr>
                <td><input type="text" name="add_ipp_network"/></td>
                <td>$assigned_to_html</td>
		<td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
	</tr>
	|;


print "</table></form>
";
} # end if level check
else
{
	print "$user_details{pe_level}";
}
print "
</td></tr>";

print "</table>";
print "<br/>This table exists because an Account may have multiple Neworks";
print html_footer;

