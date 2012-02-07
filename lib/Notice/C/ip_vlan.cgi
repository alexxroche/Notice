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
print html_header($page,$ud);
print sidemenu($page,$ud);
my($DEBUG,$error,$col_order);
$DEBUG=0;

if(!$form{order}) { $form{order} = 'asc'; $col_order = '&amp;order=desend'; }
if(!$form{sort}) { $form{sort} = 'ipp_VLAN'; }

my($notice)= new Notice::DB::ip;
my(%networks,%ippat);
my(%vlans,$delete,$update,%error,$ip_ref,$vlan);
my $network = '1.0';
my $assigned_to_html;

use Notice::DB::group;
my $gh = new Notice::DB::group;
my %g;
$g{pe_id} = $user_details{pe_id};
$g{gr_name} = 'Senior IP sysadmin';
$gh->in_group(\%g);


if($g{gg_state} >= 1 || $user_details{pe_level} > 111){

if($DEBUG == 1){
	foreach my $que (keys %ippat)
	{
       		print "$que = $ippat{$que} <br />";
        }
        print "<br />";
}

        foreach my $values (keys %form){
        # NTS need to protect $where from XSS
                if($form{$values} eq 'Edit'){ $ip_ref = $values; }
                elsif($form{$values} eq 'Update'){ $update = $values;  print "update = $values<br/>\n" if $DEBUG>=2;}
                elsif($form{$values} eq 'Delete'){ $ip_ref = $values; $delete=1;}
                print "$values = $form{$values}<br/>\n" if $DEBUG>=2;
                if($form{error}=~m/^(\d+).*/){ $error = $error{$1}; }
        }
	if($ip_ref){
		($vlan,$network) = split(/;/, $ip_ref);
	}
        #if($error){ print $error; }
}

my $athn = 'Main account';

my $network_html = $notice->Notice::DB::ip::networks(\%networks,$network,'','skip_blank');
#if($ip_ref && $vlan && $network){ $athn = $networks{$network}; }
#my $assigned_to_html = $notice->list_assigned_to(\%ippat,$athn,'nope');

if($form{ipp_VLAN}||$ip_ref)
{
	my %values;
#NTS check we are talking to a person with the right privs
#$notice->check_position('$ENV{REMOTE_USER}','Director','Admin','Sysops');
	$values{auth} = 1 if ($g{gg_state} >= 1 || $user_details{pe_level} > 111);
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
	}
	# </DEBUG>
	if($form{ipp_VLAN}=~m/^\d{1,4}$/ &&
	$form{ipp_network}=~m/^\d+(\.\d+)*$/ &&
	$form{ipp_assigned_to}=~m/^\d+(\.\d+)*$/ 
	){
		$values{ipp_VLAN}	= $form{ipp_VLAN};
		$values{ipp_assigned_to}= $form{ipp_assigned_to};
		$values{ipp_network}	= $form{ipp_network};
		$values{ipp_notes}	= $form{ipp_notes};
		$values{data_checked}	= 1;
		print "Passed the REG <br />" if $DEBUG == 1; #DEBUG
	}elsif($update){
	#	$error .= "<br/>Going for a";
	#	if($delete){
	#		$error .= " delete of VLAN $vlan in network $network";
	#	}else{
	#		$error .= "n edit of VLAN $vlan in network \"$networks{$network}\" ($network)";
	#	}
		$values{ipp_VLAN}	= $form{ipp_VLAN};
		$values{ipp_assigned_to}= $form{ipp_assigned_to};
		$values{ipp_network}	= $form{ipp_network};
		$values{ipp_notes}	= $form{ipp_notes};
		$values{update} = $update;
		$values{data_checked}	= 1;
	}elsif(!$ip_ref){
		 $error .= "<br/>Invalid Data";
	}
	print "<br/> $error <br/>" if $DEBUG ==1;

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
		$values{URI} = $ud;
		$values{pe_id} = $user_details{pe_id};
		if($delete && $ip_ref){
			$notice->delete_ipp_vlan(\%values);
		}elsif($update){
			$notice->update_ipp_vlan(\%values);
		}else{
			$notice->insert_ipp_vlan(\%values);
		}
	}
	if($values{return}) { print "<br/>$values{return}"; }
	if($values{error}) { print "<br/>$values{error}"; }
}

if($error) { print "ERROR: $error"; }
my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
<table class="ip">
      <tr>
	<th class="ip">VLAN</th>
        <th class="ip">Network</th>
        <th class="ip">Assigned To</th>
        <th class="ip">Description</th>);
if($g{gg_state} >= 1 || $user_details{pe_level} > 900){
	if(!$ip_ref || (!$delete && $ip_ref)){
		$html_table .= qq|<th class="ip">Action</th>|;
	}
	if(!$ip_ref || $delete){
		$html_table .= qq|<th class="ip">Delete</th>|;
	}
}
	$html_table .= qq|</tr>|;

if($ip_ref){ print qq|<form method="post" action="$action">|; }

print $html_table;
sub vlans_sort
{
	my $key = $form{sort};
	if($form{order} eq 'asc')
	{
		if($key eq 'ipp_VLAN')
		{	# numeric
			( $vlans{$a}{"$key"} <=> $vlans{$b}{"$key"} )
		} else { # alpha
			( $vlans{$a}{"$key"} cmp $vlans{$b}{"$key"} )
		}
	}
	else
	{
		if($key eq 'ipp_VLAN')
                {       # numeric
                        ( $vlans{$b}{"$key"} <=> $vlans{$a}{"$key"} )
                } else { # alpha
                        ( $vlans{$b}{"$key"} cmp $vlans{$a}{"$key"} )
                }
	}
}
my $stripe = 'stripe';
my $VLAN_html = $notice->VLANs(\%vlans,'',$ip_ref);

#NTS you are thinking about changing the display if you are trying to Edit or Delete

#while (my ($key,$value) = each %vlans) {
#	while (my ($keys,$values) = each %{$vlans{$key} }) {
#	    print "$keys = $values<br/>\n";
#	}
#}



foreach my $ref (sort vlans_sort keys %vlans)
{
   if($ip_ref){
	my $assigned_to_html = $notice->list_assigned_to(\%ippat,$vlans{$ref}{'ipp_assigned_to'},'nope');
	if($stripe eq 'stripe'){ $stripe = 'strip';}
	else{ $stripe = 'stripe';}
	print  qq(
        <tr class="$stripe">
                <td><input type="text" name="ipp_VLAN" value="$vlans{$ref}{'ipp_VLAN'}"></td>
                <td>$network_html</td>
                <td>$ippat{$vlans{$ref}{'ipp_assigned_to'}}</td>
                <td><input type="text" name="ipp_notes" value="$vlans{$ref}{'ipp_notes'}"></td>
        );
        if($g{gg_state} >= 1 || $user_details{pe_level} > 900){
                print qq(
                <td><input type="submit" value="Update" name="$vlans{$ref}{'ipp_VLAN'};$vlans{$ref}{'ipp_network'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
                );
        }
	print qq(</tr>);

   }else{
	$assigned_to_html = $notice->list_assigned_to(\%ippat,$athn,'nope');
	print  qq(
	<tr class="$stripe">
		<td>$vlans{$ref}{'ipp_VLAN'}</td>
		<td>$networks{$vlans{$ref}{'ipp_network'}}</td>
		<td>$ippat{$vlans{$ref}{'ipp_assigned_to'}}</td>
		<td>$vlans{$ref}{'ipp_notes'}</td>
	);
        if($g{gg_state} >= 1 || $user_details{pe_level} > 900){
		print qq(
		<td><form method="post" action="$action"><input type="submit" value="Edit" name="$vlans{$ref}{'ipp_VLAN'};$vlans{$ref}{'ipp_network'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>
		<td><form method="post" action="$action"><input type="submit" value="Delete" name="$vlans{$ref}{'ipp_VLAN'};$vlans{$ref}{'ipp_network'}" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>
		);
	}
	print qq(</tr>);
	if($stripe eq 'stripe'){ $stripe = 'strip';}
	else{ $stripe = 'stripe';}
   }
}

undef(%vlans);

print "</table>";
if($ip_ref){ print qq|</form>|; }
print "</td></tr><tr><td>";
if(!$ip_ref && ($g{gg_state} >= 1 || $user_details{pe_level} > 900))
{
print qq( <form method="post" action="$action">	   <table>
     <tr>
	<th class="ip">VLAN</th>
        <th class="ip">Network</th>
        <th class="ip">Assigned To</th>
        <th class="ip">Description</th>
     </tr>
);

	print qq |
	<tr>
                <td><input type="text" name="ipp_VLAN"/></td>
                <td>$network_html</td>
                <td>$assigned_to_html</td>
                <td><input type="text" name="ipp_notes"/></td>
		<td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
	</tr>
	|;


print "</table></form>

It is best to keep the description short and without spaces - that way the VLAN can be set up dynamically on the switches that need to run this VLAN
You can always add more information when you define a block of addresses that are going to be inside of this VLAN
";
} # end if level check
else
{
	#print "$user_details{pe_level}";
}
print "
</td></tr>";

print "</table>";
print "<br />";
print html_footer;

