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
use Notice::DB::ip qw( ipp_RIR_html );
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
print "This is a list of Regional Internet registries and RFCs that either assign IP space or specify IP ranges. <br/>It is used by Notice to know where to send the updates when there are changes to IP blocks.<br/> This list will rarely need to be changed.<br/>";
my($DEBUG,$error,$col_order);

if(!$form{order}) { $form{order} = 'asc'; $col_order = '&amp;order=desend'; }
if(!$form{sort}) { $form{sort} = 'ipp_RIR'; }
my($notice)= new Notice::DB::ip;
my(%vlans);

if($form{ipp_VLAN})
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
	print "<br/>";
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
		my($name,$vlan,$rir,$assigned_to,$notes) = split(/ /, $form{ipp_name}, 5);
		$values{ipp_name}       = $name;
                $values{ipp_VLAN}       = $vlan;
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

if($error)
{
	print "ERROR: $error";
}
my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
<table class="ip">
      <tr>
        <th class="ip">RIR [0]</th>
        <th class="ip">Edit</th>
        <th class="ip">Delete</th>
      </tr>
);

print $html_table;
sub vlans_sort
{
	my $key = $form{sort};
	if($form{order} eq 'asc'){
		( $vlans{$a}{"$key"} cmp $vlans{$b}{"$key"} )
	}else{
                ( $vlans{$b}{"$key"} cmp $vlans{$a}{"$key"} )
	}
}
my $stripe = 'stripe';

$notice->list_rir(\%vlans);

foreach my $ref (sort vlans_sort keys %vlans)
{
	print  qq(
	<tr class="$stripe">
		<td>$vlans{$ref}{'ipp_RIR'}</td>
		<td><form method="post" action="$action"><input type="submit" value="Edit" name="$vlans{$ref}{'ipp_RIR'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>
		<td><form method="post" action="$action"><input type="submit" value="Delete" name="$vlans{$ref}{'ipp_RIR'}" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>
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
        <th class="ip">RIR</th>
     </tr>
);

	print qq |
	<tr>
                <td><input type="text" name="ipp_RIR"/></td>
		<td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
	</tr>
	|;


print "</table></form><br/>
[0] Regional Internet registry or other source of IP addresses
";
} # end if level check
else
{
	print "$user_details{pe_level}";
}
print "
</td></tr>";

print "</table>";
print "<br />";
print html_footer;

