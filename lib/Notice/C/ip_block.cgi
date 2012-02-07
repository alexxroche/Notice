#!/usr/bin/perl

use DBI;
use strict;
use Notice::Common;
use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my $ud;
#   this is a dirty hack for now so the "Guest account does not have to log in LxR 2007082
if($form{ud})
{
        $ud = Notice::Common::check_for_login($ENV{REQUEST_URI},$form{ud});
}
else
{
        $ud = Notice::Common::check_for_login($ENV{REQUEST_URI},$form{ud});
}
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
use Notice::DB::group;
my $gh = new Notice::DB::group;
my %g;
$g{pe_id} = $user_details{pe_id};
#$gh->Notice::DB::group::in_group(\%g);
$g{gr_name} = 'Senior IP sysadmin';
$gh->in_group(\%g);
# warning! dirty hack located!

$user_details{pe_level} = 4 unless($g{gg_state} >= 1);
$g{gr_name} = 'IP sysadmin';
$gh->in_group(\%g);


use Notice::HTML qw( html_header html_footer sidemenu );
use Notice::DB::ip qw( show_pool VLAN_html ipp_RIR_html insert_ipp update_ipp list_assigned_to);
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
my $edit_action = 'ip_edit.cgi' . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
my($DEBUG,$error,$col_order);

if(!$form{order}) { $col_order = '&amp;order=desend'; }

my($notice)= new Notice::DB::ip;
my(%ippool,%ippat);
my $VLAN_html = $notice->VLAN_html('24');                       #default VLAN
my $ipp_RIR_html = $notice->ipp_RIR_html('RIPE');               #default RIR
my $assigned_to_html = $notice->list_assigned_to(\%ippat,'Main Account','no_blank');#default assigned_to
my(%networks);
my $network_html = $notice->networks(\%networks,'1.0','','no_blank');#default network - should be pulled from the Notice::IP::admin table

#http://unix-intra/ip.html

if(!$form{sort}){ $form{sort} = 'ipp_name';}

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
        if( (   $form{ipp_name}!~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ &&
                $form{ipp_name}!~m/^([0-9A-F]{1,4}::?){1,7}[0-9A-F]{1,4}\/(\d{1,2}|1(0-1)\d|12[0-8])$/i )
        ){ $error .= "ipp_name |$form{ipp_name}| not match <br />"; }
        if($form{ipp_VLAN}!~m/^\d{1,4}$/){ $error .= "VLAN not match <br />"; }
        if($form{ipp_RIR}!~m/^\w+$/){ $error .= "RIR not match <br />"; }
        if($form{ipp_assigned_to}!~m/\w/){ $error .= "assin not match <br />"; }
        }
        # </DEBUG>
        if( (   $form{ipp_name}=~m/^(\d{1,3}\.){3}\d{1,3}(\/(\d|1\d|2\d|30|31|32))?$/ ||
                $form{ipp_name}=~m/^([0-9A-F]{1,4}::?){1,7}[0-9A-F]{1,4}\/(\d{1,2}|1(0-1)\d|12[0-8])$/i ) &&
        ( $form{ipp_VLAN}=~m/^\d{1,4}$/ || $form{ipp_VLAN} eq '') &&
        $form{ipp_RIR}=~m/.+/ &&
        $form{ipp_assigned_to}=~m/\w/
        ){
                $values{ipp_name}       = $form{ipp_name};
                $values{ipp_VLAN}       = $form{ipp_VLAN};
                $values{ipp_RIR}        = $form{ipp_RIR};
                $values{ipp_assigned_to}= $form{ipp_assigned_to};
                $values{ipp_notes}      = $form{ipp_notes};
                $values{ipp_network}      = $form{ipp_network};
                $values{ipp_notes}      =~s/'/\\'/g;
                $values{data_checked}   = 1;
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
                $values{ipp_network}      = $form{ipp_network};
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
	$values{pe_id} = $user_details{pe_id};
                #<DEBUG>
                if($DEBUG == 1){
                foreach my $key (keys %values)
                {
                        print "$key = $values{$key} <br />";
                }
                }
                #</DEBUG>
                #
                if($form{Update} eq 'Update'){
                        $notice->update_ipp(\%values);
                }else{
                        $notice->insert_ipp(\%values);
                }
        }
        if($values{return})
        {
                print "$values{return}";
        }
}
$notice->show_pool(\%ippool);

if($error)
{
        print "ERROR: $error";
}
my $html_table = qq|
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
    <br/>
<table class="ip">
      <tr>
        <th class="ip">|;
  if($user_details{pe_email} ne 'waaawaa_Im_a_monkey@alexx.net'){
	$html_table .= qq|<a href="$page?sort=ipp_name$col_order&amp;ud=$ud">|;
  }
  $html_table .= qq|IP Range|;
  if($user_details{pe_email} ne 'waaawaa_Im_a_monkey@alexx.net'){
        $html_table .= qq|</a>|;
   }
   $html_table .= qq|</th> <!--IP address / slash -->
        <th class="ip"><a href="$page?sort=ipp_VLAN$col_order&amp;ud=$ud">VLAN</a></th>
        <th class="ip"><a href="$page?sort=ipp_network$col_order&amp;ud=$ud">Network</a></th>
        <th class="ip"><a href="$page?sort=ipp_RIR$col_order&amp;ud=$ud">Assigned By</a></th>
        <th class="ip"><a href="$page?sort=ipp_assigned_to$col_order&amp;ud=$ud">Assigned To</a></th>
        <th class="ip"><a href="$page?sort=ipp_notes$col_order&amp;ud=$ud">Description</a></th>
        <th class="ip">Edit</th>
	|;
	if($g{gg_state} >= 1 || $user_details{pe_level} > 9){
		$html_table .= qq|<th class="ip">Delete</th>|;
	}
	$html_table .= qq|</tr>|;

print $html_table;
sub ippool_sort
{
        my $key = $form{sort};
        if($form{order} eq 'desend')
        {
                #if($key eq 'ipp_VLAN')
                if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
                {       # numeric
                        ( $ippool{$a}{"$key"} <=> $ippool{$b}{"$key"} )
                } else { # alpha
                        ( $ippool{$a}{"$key"} cmp $ippool{$b}{"$key"} )
                }
        }
        else
        {
                #if($key eq 'ipp_VLAN')
                if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
                {       # numeric
                        ( $ippool{$b}{"$key"} <=> $ippool{$a}{"$key"} )
                } else { # alpha
                        ( $ippool{$b}{"$key"} cmp $ippool{$a}{"$key"} )
                }
        }
}
my $stripe = 'stripe';

foreach my $ref (sort ippool_sort keys %ippool)
{
	# need to map the network back to a nice name
        print  qq(
        <tr class="$stripe">
                <td><a href="ip_CIDR.cgi?ud=$ud&amp;slash=$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'};$ippool{$ref}{'ipp_network'}">$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'}</a></td>

                <!--td>$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'}</td-->
                <td>$ippool{$ref}{'ipp_VLAN'}</td>
                <td>$networks{$ippool{$ref}{'ipp_network'}}</td>
                <td>$ippool{$ref}{'ipp_RIR'}</td>
                <td>$ippat{$ippool{$ref}{'ipp_assigned_to'}}</td>
                <td>$ippool{$ref}{'ipp_notes'}</td>
                <td><form method="post" action="$edit_action"><input type="submit" value="Edit" name="$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'};$ippool{$ref}{'ipp_network'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>
		);
        if($g{gg_state} >= 1 || $user_details{pe_level} > 9){
		print qq |
                <td><form method="post" action="$edit_action"><input type="submit" value="Delete" name="$ippool{$ref}{'ipp_name'}/$ippool{$ref}{'ipp_subnet'};$ippool{$ref}{'ipp_network'}" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></form></td>|;
	}
	print qq ( </tr>);
        if($stripe eq 'stripe'){ $stripe = 'strip';}
        else{ $stripe = 'stripe';}
}

undef(%ippool);

print "</table></td></tr><tr><td>";
if($g{gg_state} >= 1 || $user_details{pe_level} > 5)
{
print qq( <form method="post" action="$action">        <table>
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
                <td><input type="text" name="ipp_name"/></td>
                <td>$VLAN_html</td>
                <td>$network_html</td>
                <td>$ipp_RIR_html</td>
                <td>$assigned_to_html</td>
                <td><input type="text" name="ipp_notes"/></td>
                <td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
        </tr>
        |;

print "</table></form>
";
} # end if level check
else
{
       # print "$user_details{pe_level}";
	print "$g{gg_state}";
}
print "
</td></tr>";

print "</table>";
print "<br />";
print html_footer;
