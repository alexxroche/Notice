#!/usr/bin/perl

use strict;
use DBI;
use Carp;
use vars qw/ $db $dbhostname $dbusername $dbpassword /;
use Notice::DB qw( $db $dbhostname $dbusername $dbpassword );
# NTS  I'm sure this is not the best way to do this
*db = \$Notice::DB::db;
*dbhostname = \$Notice::DB::dbhostname;
*dbusername = \$Notice::DB::dbusername;
*dbpassword = \$Notice::DB::dbpassword;
$|=1;
use Notice::HTML ('html_header','html_footer','sidemenu');
use Notice::Common;
use Notice::DB::user;
use Notice::DB::ip;
my $page = $0; $page=~s/^.*\///;
my $env_request_URI = $ENV{REQUEST_URI};
#this is either clever or stupid: I pass the URI to check_for_login and check_for_login populates $env_request_URI with 
# the user_details
#  <later> seems to not work
# <even later> you really need to be explicit in your explanations!
my $ud = Notice::Common::check_for_login($env_request_URI);
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
my($DEBUG,%networks);
$DEBUG=1;
my $notice = new Notice::DB::ip;
my $network_html = $notice->Notice::DB::ip::networks(\%networks,'1.0','not_a_range'); # NTS must pull default network from DB

my $action = $page . '?ud=' . $ud;
my $add_action = $page . '?ud=' . $ud;

print html_header($page,$ud);
print sidemenu($page,$ud);

use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();

my($col_order,$type_options,$number_options,%return,$this_slash);
my $newslash = 32;

$number_options = "<option> 1</option>\n<option> 4</option>\n<option> 8</option>\n<option>16</option>\n";

my($dbh)=DBI->connect("DBI:mysql:$db:$dbhostname",$dbusername,$dbpassword,{PrintError=>0});
if (!$dbh)
{
	croak('Couldn\'t connect to database');
}

if($user_details{pe_level} > 6)
{

   my %ip_types;
   my $ip_types_query  = "select DISTINCT(ipp_notes),ipp_network from ippool where ipp_RIR is NULL and ipp_VLAN is NULL and ipp_network !=''";
  ($dbh)->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool");
   my($sth)=($dbh)->prepare($ip_types_query);
   $sth->execute() or croak("Can't execute query: $ip_types_query");
   my $count = 1;
   while (my $ref = $sth->fetchrow_hashref()) {
   	$ip_types{"$ref->{'ipp_network'}"} = $ref->{'ipp_notes'};
   }
   ($dbh)->do('UNLOCK TABLES') or croak ("Can't unlock ippool");

   if($form{ipp_network})
   {
	if($DEBUG == 1){
        	foreach my $que (keys %form)
        	{
        	        print "$que = $form{$que} <br />";
        	}
        	print "<br />";
  	}

	my $string = $form{ipp_network};
	#sanity for $string;
	$string=~s/'/\\'/g;
	# NTS this is wrong - it should be ipp_ref rather than some random TEXT string!
	my $data_query = "SELECT ipp_name,ipp_subnet,ipp_network from ippool where ipp_network = '$string'";
	warn  "$data_query";
	($sth)=($dbh)->prepare($data_query);
        $sth->execute() or croak("Can't execute query: $data_query");
	my @data = $sth->fetchrow_array();
	$return{'address'} = $data[0];
	$this_slash = $data[1];


	my $number = $form{number}; #number of ips wanted 
	my $type;
	if($data[0]=~m/:/){ $type = 'IPv6';} else { $type = 'IPv4'; }

	my %taken;
	my $query = 'select ip_o1,ip_o2,ip_o3,ip_o4,ip_o5,ip_o6,ip_o7,ip_o8,ip_slash from ip ';
	if($type eq 'IPv4')
	{
		#my $req_slash = 256-(2^(32-"$form{number}"));
		my $req_slash = 32;
		if($form{number} == 4){ $req_slash = 30; }
		if($form{number} == 8){ $req_slash = 29; }
		if($form{number} == 16){$req_slash = 28; }
		warn("requested slash = $req_slash, (from $this_slash)");
		#NTS must check that the req_slash <= $this_slash!;
		if($req_slash <= $this_slash){ print "That's bananas for you"; warn($req_slash <= $this_slash); exit(341); }
		#warn $data[0];
		#my $split_me = $data[0];
 		#my @address = split /\./, $split_me;
 		my @address = split(/\./, "$data[0]");
		if(!$address[2]){ print "$data[0]/$data[1] seems to need more IPs"; print html_footer;
		 die "No IP dusiem octeti $address[2] from $data[0]"; }
		$query .= "where ip_o1 = $address[0] and ip_o2 = $address[1] && ip_o3 = $address[2]";
		warn $query;
		my($sth)=($dbh)->prepare($query);
        	$sth->execute() or croak("Can't execute query: $query");
		while (my @row=$sth->fetchrow_array())
        	{
        		#my $ip = $row[0]
        		#$ip=~/^\d+\.\d+\.\d+\.(\d+)\/(\d+)$/;
        		my($mask)=256-(1<<(32-$row[8]));
       			my($start)=$row[3] & $mask;
        		my($end)=$start+255-$mask;
        		warn ("going to check (my octet=$start;octet<=$end;octet++) \n");
			my $crazy_count_check=0;
        		CCCFOR: for (my $octet=$start;$octet<=$end;$octet++)
        		{
               		 	$taken{$octet}='1';
				$crazy_count_check++;
				warn("$octet is taken");
				last CCCFOR if $crazy_count_check>=256;
                	}
        	}
 		$sth->finish;
 		# now go through taken and look for the required gap
		my ($count,$start);
		WIR: for( my $j=1;$j<=255;$j++)
		{
			if(!$start && !$taken{$j}){ $start = $j; $count=1;}
			if($start && !$taken{$j}){ $count++; }
			if($count == $number){ last WIR; }
			if($start && $taken{$j} && ($j - $start < $number)){ $start = ''; $count = '';}
		}
		if($start){
			$return{start} = $start;
			$return{count} = $count;
			my $stockref = $form{ip_stockref}; # will be used later by the API
			$stockref=~s/'/\\'/g;
			my $insert = "INSERT into ip(ip_o1,ip_o2,ip_o3,ip_o4,ip_o5,ip_o6,ip_o7,ip_o8,ip_slash,ip_type,ip_usedfor,ip_network,ip_stockref,ip_notes) VALUES('$address[0]','$address[1]','$address[2]','$return{start}','','','','','$req_slash',1,'$form{usedfor}','$data[2]','$stockref','$form{notes}')";
			warn($insert);
			($sth)=($dbh)->prepare($insert);
        		$sth->execute() or croak("Can't execute query: $insert");
			#foreach my $key (keys %user_details)
			#{
			#	warn "$key = $user_details{$key}";
			#}
			if(!$user_details{pe_id}){ print "Don't know who you are"; die "I don't know who you are"; }
			#warn "Looks like $user_details{'pe_id'} just $user_details{pe_fname} did something";

			my $history = qq |INSERT into iphistory VALUES('','$user_details{pe_id}','Was given $address[0].$address[1].$address[2].$return{start}/$req_slash',NOW(),'','delete from ip where ip_o1 = "$address[0]" && ip_o2 = "$address[1]" && ip_o3 = "$address[2]" && ip_o4 = "$return{start}" and ip_slash="$req_slash" and ip_network="$data[2]"')|;
			($sth)=($dbh)->prepare($history);
        		$sth->execute() or croak("Can't execute query: $history");
		}else{
			$return{error} .= "Seems that block is full - ask for another one";
		}
	 }else{
		my @address = split/:/, $data[0];
		$query .= "where ip_o1 = $address[0] and ip_o2 = $address[1] && ip_o3 = $address[2] && ip_o4 = $address[3] and ip_o5 = $address[4] && ip_o6 = $address[5] && ip_o7 = $address[6]";
 		while (my @row=($sth->fetchrow_array)[0])
        	{
        		my($maskVI)=65536-(1<<(64-$row[8]));
        	        my($startVI)=$row[3] & $maskVI;
        	        my($endVI)=$startVI+65536-$maskVI;
        	        for (my $hexadecet=$startVI;$hexadecet<=$endVI;$hexadecet++)
        	        {
        	        	$taken{$hexadecet}='1';
        	        }
        	}
 		$sth->finish;
		 # now go through taken and look for the required gap
        	my ($count,$start);
		#this has got to be the wrong way to do this for IPv6
        	WIR: for( my $j=1;$j<=65535;$j++)
        	{
        	        if(!$start && !$taken{$j}){ $start = $j; $count=1;}
        	        if($start && !$taken{$j}){ $count++; }
        	        if($count == $number){ last WIR; }
        	        if($start && $taken{$j} && ($j - $start < $number)){ $start = ''; $count = '';}
        	}
        	$return{start} = $start;
        	$return{count} = $count;
 	   }	
	}

#NTS ISATAP code might be helpful - it should be trivial to collect the data and 

my $new = $return{address};
$new=~s/\.\d+$//;
# NTS we SERIOUSLY need to unhard code this (oh and we need to put this in the the database
# and make a history entry of this against the person issuing it and ask them what it is for.
#  (though later they will look up the asset first and then press the "issue IP" button and
#	we will take care of it all for them )
#my $newslash = 256-$return{count};
if($return{count} == 4){ $newslash = 30; }
if($return{count} == 8){ $newslash = 29; }
if($return{count} == 16){ $newslash = 28; }
print "You can have $new.$return{start}/$newslash  from $return{address}/$this_slash " if $form{ipp_network};

# print table

print "If you are not sure, then ask. <br/>";

if($user_details{pe_level} > 60){

my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
    <br/>
<form method="post" action="$action">
<table class="ip">
      <tr>
		<th class="ip">Function (Network)</th>
		<th class="ip">Number</th>
		<th class="ip">Machine/CustomerID</th>
		<th class="ip">Notes</th>
		<th class="ip">Add</th>
	      </tr>
	);

	print $html_table;
	my %users; #NTS dirty hack
	sub users_sort
	{
		my $key = $form{sort};
		if($form{order} eq 'desend')
		{
			if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
			{       # numeric
				( $users{$a}{"$key"} <=> $users{$b}{"$key"} )
			} else { # alpha
				( $users{$a}{"$key"} cmp $users{$b}{"$key"} )
			}
		}
		else
		{
			if($key eq 'ipp_VLAN' || $key eq 'ipp_name')
			{       # numeric
				( $users{$b}{"$key"} <=> $users{$a}{"$key"} )
			} else { # alpha
				( $users{$b}{"$key"} cmp $users{$a}{"$key"} )
			}
		}
	}

	foreach my $ref (sort keys %ip_types)
	{
		next if $ref eq '';
		$type_options .= "<option";
		if($ref=~m/SSL/){ $type_options .= ' selected="selected"'; }
		$type_options .= qq| value="$ref">$ip_types{$ref} ($ref)</option>\n|;

}
        print  qq(
        <tr>
                <td><select name="ipp_network">$type_options</select></td>
                <td><select name="number">$number_options</select></td>
                <td><input type="text" name="usedfor" /></td>
                <td><input type="text" name="notes" /></td>
		<td>
<input type="submit" value="Issue" name="Issue" class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></td>
        </tr>
	</table>
	</form>
</td></tr></table>
        );

} #limit access to this broken allocator
} # end of level check

if($user_details{pe_level} > 2){
	my $error;

    if($form{ip}){
	my (@address,$type,$ip,$slash,$ntwrk,$stockref,$ip_ref); $type='IPv4';
	$form{ip_usedfor}=~s/'/\\'/g;
	$form{ip_notes}=~s/'/\\'/g;
	$slash=$form{ip_slash};
	$slash=~s/'/\\'/g;
	$ntwrk = $form{ip_network};
	$ntwrk =~s/'/\\'/g;
	$stockref = $form{ip_stockref};
	$stockref=~s/'/\\'/g;
	my $query = 'SELECT ip_o1,ip_o2,ip_o3,ip_o4,ip_o5,ip_o6,ip_o7,ip_o8,ip_slash,ip_network from ip ';
        if($form{ip}=~m/:/){
		#warn "Going to send $form{ip} to ipv6calc";
		my $ipv6calc = `/usr/bin/ipv6calc  -m -i -q $form{ip}|grep IPV6=|sed 's/^IPV6=//'`;
		chomp($ip);
		#warn "got $ipv6calc back";
		@address = split(/\:/, "$ipv6calc");
		$type='IPv6';
		$ip = "$address[0]:$address[1]:$address[2]:$address[3]:$address[4]:$address[5]:$address[6]:$address[7]";
           $query .= "where ip_o1 = '$address[0]' and ip_o2 = '$address[1]' && ip_o3 = '$address[2]' && ip_o4 = '$address[3]' ";
		$query .= " && ip_o5 = '$address[4]' and ip_o6 = '$address[5]' && ip_o7 = '$address[6]' && ip_o8 = '$address[7]' && ip_network='$ntwrk'";
	}else{
		@address = split(/\./, "$form{ip}");
		$ip = "$address[0]\.$address[1]\.$address[2]\.$address[3]";
           $query .= "where ip_o1 = '$address[0]' and ip_o2 = '$address[1]' && ip_o3 = '$address[2]' && ip_o4 = '$address[3]' && ip_network='$ntwrk'";
	}
	$ip_ref = $ip . '/' . $slash . ':' . $ntwrk;
        if(!$address[3]){ $error .= " That does not look like a valid IP address to me. CODE: No IP dusiem octeti $address[2] from $ip"; }
        if(!$user_details{pe_id}){ $error .= " Don't know who you are"; die "I don't know who you are"; }
	# check we don't already have this ip address


           my($sth)=($dbh)->prepare($query);
           $sth->execute() or croak("Can't execute query: $query");
           my $rows=$sth->rows();
	   if($rows>=1){
		print "Content-type: text/html \n\n";
        print qq (<html><head><META HTTP-EQUIV="REFRESH" CONTENT="0;URL=ip_edit.cgi?error=1&amp;message=$error&amp;ud=$ud&amp;ip_ref=$ip_ref"></head><body></body></html>);
	print qq (<a href="ip_edit.cgi?ud=20080508204659_10.2.2.33_d44986ba752b66156eb03d7526738bb6_14&ip_ref=$ip_ref&amp;ud=$ud">IP already exists - click to edit</a>);
		print html_footer;
		$error='IP alrady found';
        	exit(0);
	   }

        if(!$error){
		# NTS must do a select to check we are not adding the same IP twice!
        	my $history = qq |INSERT into iphistory VALUES('','$user_details{pe_id}','Inserted $ip/$slash',NOW(),'','delete from ip where ip_o1 = "$address[0]" && ip_o2 = "$address[1]" && ip_o3 = "$address[2]" && ip_o4 = "$address[3]" && ip_o5 = "$address[4]" && ip_o6 = "$address[5]"&& ip_o7 = "$address[6]"&& ip_o8 = "$address[7]" and ip_network="$ntwrk"')|;
        	my($sth)=($dbh)->prepare($history);
        	$sth->execute() or croak("Can't execute query: $history");

        	my $insert = "INSERT into ip(ip_o1,ip_o2,ip_o3,ip_o4,ip_o5,ip_o6,ip_o7,ip_o8,ip_slash,ip_type,ip_usedfor,ip_network,ip_stockref,ip_notes) VALUES('$address[0]','$address[1]','$address[2]','$address[3]','$address[4]','$address[5]','$address[6]','$address[7]','$slash','$type','$form{ip_usedfor}','$ntwrk','$stockref','$form{ip_notes}')";
        	($sth)=($dbh)->prepare($insert);
        	$sth->execute() or $error .= "Can't execute query: $insert $DBI::errstr";
	} else {
		priint $error;
		print html_footer;
		exit(1);
        }
	if($error){
		print qq|<span class="error">$error</span><br/>|;
	}else{
		print qq|<span class="withouterror">IP address ($ip) added by you</span><br/>|;
	}
     }
	
 #NTS this does not work yet but it rather minor
 # needs call(this. or apply(this.
	    print qq(
<script type="text/javascript">
function setMaxLength()
{
   if(document.newip.ip_type.options[0]=IPv6){
	alert(Changing MaxLength to 39);
		document.newip.ip.maxlength=39;
   }else{
	alert(Changing MaxLength to 15);
		document.newip.ip.maxlength=15;
   }
	alert(You are here);
}
</script>

 <form name="newip" method="post" action="$add_action">        <table>
      <tr>
        <th class="ip">IP Address</th>
        <th class="ip" colspan="2">Slash</th>
        <th class="ip">Network</th>
        <th class="ip">Type</th>
        <th class="ip">Used For (server/customer)</th>
        <th class="ip">Stockref</th>
        <th class="ip">Notes</th>
        <th class="ip">Update</th>
      </tr>

    );
           my $stripe = 'strip';
        my $ipdivtype = '.';
           my $ip_size=10;
           my $ip_maxlength=39; #should be 15 once the javascript works
	my $answer;
        $answer .=  qq(<tr class="$stripe"><td><input type="text" size="$ip_size" maxlength="$ip_maxlength" name="ip" value="192.168.1.1"/></td>);
        $answer .= qq(<td>/</td>);
        if($user_details{pe_level} > 6){
		$answer .= qq(<td><input type="text" name="ip_slash" size="3" maxlength="3" value="32"/></td>);
	}else{
		$answer .= qq(<td><input type="hidden" name="ip_slash" value="32"/>32</td>);
	}
	$answer .= qq(<td>$network_html</td>);
        $answer .= qq(<td><select name="ip_type" onChange="newip.ip.setMaxLength(15)"><option>IPv4</option><option>IPv6</option></select></td>);
        $answer .= qq(
                <td><input type="text" name="ip_usedfor" size="30" value=""/></td>
                <td><input type="text" name="ip_stockref" size="4" value="not used yet"/></td>
                <td><input type="text" name="ip_notes" size="50" value=""/></td>
                <td><input type="submit" value="Add" name=" Add " class="deluser" onmouseover="this.className='deluser deluserhov'" onmouseout="this.className='deluser'" onclick="this.className='deluser'"/></td>
        </tr>
        );
   
$answer .= '</table></form>';
print $answer;
print qq|<span class="withouterror">Enter an ip address and their details, to be added to the database</span>|;
 }else{
	print "Check with a sysadmin if you want to allocate an ip";
 }


print html_footer;
