#!/usr/bin/perl

use DBI;
use strict;
no strict "refs";
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
use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html insert_ipp );
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
print "Not all Accounts can or should have networks. This table adds exiting Accounts to the 'Assigned To' options";
my($DEBUG,$error,$col_order);
$DEBUG=0;
if(!$form{order}) { $form{order} = 'asc'; $col_order = '&amp;order=desend'; }
if(!$form{sort}) { $form{sort} = 'ipp_assigned_to'; }

my(%networks,%accounts);
my($notice)= new Notice::DB::ip;
my($notice_accounts)= new Notice::DB::account;
$accounts{URI} = $ud; # these two limit the user to their account branch
$networks{URI} = $ud;

if($form{ipp_assigned_to})
{
	my %values;
	$values{URI} = $ud;
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
	}
	# </DEBUG>
	if($form{ipp_assigned_to}=~m/^\d+(\.\d+)*$/ &&
	$form{Add} eq 'Add'
	){
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
		$values{pe_id} = $user_details{pe_id}; #we should not trust this
		$notice->insert_ipp_assigned_to(\%values);
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
        <th class="ip">Account</th>
        <th class="ip">Remove</th>
      </tr>
);

print $html_table;
sub networks_sort
{
	#my $key = $form{sort};
	if($form{order} eq 'asc')
	{
		#( $networks{$a}{"$key"} cmp $networks{$b}{"$key"} )
		#( $networks{$a} <=> $networks{$b} )
		#(( length($networks{$a}) <=> length($networks{$b})) ||  ( $networks{$a} cmp $networks{$b} ) )
		(( length($a) <=> length($b)) ||  ( $networks{$a} <=> $networks{$b} ) )
		#need to find a way to sort based on the $ref NTS
	}else{
        	#( $networks{$b}{"$key"} cmp $networks{$a}{"$key"} )
        	#( $networks{$b} cmp $networks{$a} )
		#( $networks{$b} <=> $networks{$a} )
		#(( length($networks{$b}) <=> length($networks{$a})) ||  ( $networks{$b} cmp $networks{$a} ) )
		(( length($b) <=> length($a)) ||  ( $networks{$b} cmp $networks{$a} ) )
	}
}
my $stripe = 'stripe';

#we should skip the accounts that are already in the list
$notice->list_assigned_to(\%networks);
my $account_html = $notice_accounts->show_accounts(\%accounts,'Main Account');

delete($networks{URI});
foreach my $ref (sort networks_sort keys %networks)
{
	#my $indent = $ref;
	#$indent=~s/\d//g;
	#if($indent=~s/\./=/g){ $indent=~s/=$/&gt;/; }
#NTS must show a balloon of $parent->$child->... onmouseover rather than the ($ac_id);
	print  qq(
	<tr class="$stripe">
		<td>($ref) $networks{$ref}</td>
		<td><form method="post" action="$action"><input type="submit" value="Remove" name="$ref" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>
	</tr>
	);
	if($stripe eq 'stripe'){ $stripe = 'strip';}
	else{ $stripe = 'stripe';}
}

undef(%networks);

print "</table></td></tr><tr><td>";
if($user_details{pe_level} > 5)
{
print qq( <form method="post" action="$action">	   <table>
     <tr>
        <th class="ip">Account</th>
        <th class="ip">Action</th>
     </tr>
);

	print qq |
	<tr>
                <td>$account_html</td>
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
print "<br/>";
print html_footer;

