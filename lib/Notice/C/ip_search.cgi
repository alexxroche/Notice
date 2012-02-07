#!/usr/bin/perl

use strict;
no strict "refs";
use Notice::HTML ('html_header','html_footer','sidemenu');
use Notice::Common;
use Notice::CGI_Lite;
use Notice::DB::search;
use Notice::DB::ip;
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI});
#my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI},$form{ud});
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my($DEBUG,$error,$col_order);
if(!$form{order}) { $col_order = '&amp;order=desc'; }
elsif($form{order} eq 'desc') { $col_order = '&amp;order=asc'; }
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
my $type = $form{type};
my $edit_action = 'ip_edit.cgi' . '?ud=' . $ud;
my(%networks);
my $notice = new Notice::DB::ip;
if(!$type){ $type = 'ip';}
my $answer = qq|<table class="ip">
      <tr>
        <th class="ip"><a href="$page?sort=ip_o1$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">IP Address</a></th> <!--IP address / slash -->
        <th class="ip"><a href="$page?sort=ip_slash$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Slash</a></th>
        <th class="ip"><a href="$page?sort=ip_network$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Network</a></th>
        <th class="ip"><a href="$page?sort=ip_type$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Type</a></th>
        <th class="ip"><a href="$page?sort=ip_usedfor$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Used For</a></th>
        <th class="ip"><a href="$page?sort=ip_stockref$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Stockref</a></th>
        <th class="ip"><a href="$page?sort=ip_notes$col_order&amp;ud=$ud&amp;type=$form{type}&amp;search=$form{search}">Notes</a></th>
        <th class="ip">Edit</th>|;
if($user_details{pe_level} > 50){ $answer .= qq(<th class="ip">Delete</th>); }
$answer .= qq|
      </tr>
|;


if($form{search})
{
	my($notice)= new Notice::DB::search;
	my %thing;
	$thing{ip} = $form{search};
	$thing{sort} = $form{sort};
	$thing{order} = $form{order};
	my $exit_code = $notice-> Notice::DB::search::ip(\%thing);
	$error .= $thing{error};
	delete $thing{error};
	delete $thing{ip};
	delete $thing{sort};
	delete $thing{order};
	#would it be faster to just use a next call within the foreach?
	my $indef_art = 'an';
	$indef_art = 'a' if $exit_code ==1;
	#NTS need to set to 'a' where needed
	

	$error .= "<br/>You searched for $indef_art $form{type} of $form{search} $thing{limit}";
	if($exit_code==4){ $error .= " but I did not find any "; }
	elsif($exit_code){ 
		if($exit_code <= 0){ $error.=": no rows found"; }
		elsif($exit_code >=2){ $error.=": $exit_code rows found"; }
		else{ $error.=": $exit_code row found"; }
	}
	delete $thing{limit};
	my $stripe = 'strip';
	my $ipdivtype = '.';
	
	foreach my $ref (sort keys %thing)
	{
	
	#if($thing{$ref}{'ip_type'} eq 'IPv6'){$ipdivtype = ':';}
	if($thing{$ref}{'ip_type'} eq 'IPv6'){$ipdivtype = ':';}else{$ipdivtype = '.';}
	my $ipaddress = "$thing{$ref}{'ip_o1'}$ipdivtype$thing{$ref}{'ip_o2'}$ipdivtype$thing{$ref}{'ip_o3'}$ipdivtype$thing{$ref}{'ip_o4'}";
	if($thing{$ref}{'ip_type'} eq 'IPv6'){
           $ipaddress .= qq($ipdivtype$thing{$ref}{'ip_o5'}$ipdivtype$thing{$ref}{'ip_o6'}$ipdivtype$thing{$ref}{'ip_o7'}$ipdivtype$thing{$ref}{'ip_o8'});
        }
	my $ip_ref = qq|$ipaddress/$thing{$ref}{'ip_slash'};$thing{$ref}{'ip_network'}|;

        $answer .=  qq(<tr class="$stripe"><td><a href="ip_edit.cgi?ud=$ud&amp;ip_ref=$ip_ref">$ipaddress</a></td>);
	my $network_html = $notice->Notice::DB::ip::networks(\%networks,"$thing{$ref}{'ip_network'}",'not_a_range');
	my $server;
	if($thing{$ref}{'ip_usedfor'}=~m/^((\w+\.)*\w+)\/?.*/){ $server = $1; }
	$answer .= qq(
                <td>/$thing{$ref}{'ip_slash'}</td>
		<td>$networks{$thing{$ref}{'ip_network'}}</td>
                <td>$thing{$ref}{'ip_type'}</td>
                <td>$thing{$ref}{'ip_usedfor'}</td>
                <td><a href="http://stocklist.netbenefit.co.uk/getserver.asp?ServerName=$server">$thing{$ref}{'ip_stockref'}</a></td>
                <td>$thing{$ref}{'ip_notes'}</td>
                <td><form method="post" action="$edit_action"><input type="submit" value="Edit IP" name="$ip_ref" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>);
	if($user_details{pe_level} > 50){
             $answer .= qq(<td><form method="post" action="$action"><input type="submit" value="Delete" name="$ip_ref" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>);
	}
	$answer .= qq(
        </tr>
        );
        if($stripe eq 'stripe'){ $stripe = 'strip';}
        else{ $stripe = 'stripe';}
	}
	undef(%thing);

}
$answer .= '</table>';

print html_header($page,$ud);
print sidemenu($page,$ud);

print qq (
<!-- Main page -->
<form method="post" action="$action">
<input type="hidden" name="type" value="$type"/>
Looking for an existing $type? You are in the right place. [0]
<br/>
<br/>
<br/>
<table>
<tr><td>
<input type="text" name="search"/>
</td>
<td>
<input type="submit" value="Search" name="$type" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></td>
</tr>
</table>
</form>
<br/>
<br/>
$error
<br/>

$answer
<br/>
<br/>
[0] if you want a new $type, then use the Add or allocator section in the menu on the left.
If you don't have that then you will need to get your System Administrator to enable that for you.
);

print html_footer;
