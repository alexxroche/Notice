#!/usr/bin/perl

my $oscsrtf = "./tmp/openssl_temp$$";
use DBI;
use strict;
use Notice::Common;
use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI},$form{ud});
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);
use Notice::HTML qw( html_header html_footer sidemenu );
use Notice::DB::ssl qw( list_ssl insert_ssl update_ssl delete_ssl);
$|=1;
my $page = $0; $page=~s/^.*\///;
my $action = $page . '?ud=' . $ud;
my $edit_action = $page . '?ud=' . $ud;
print html_header($page,$ud);
print sidemenu($page,$ud);
my($DEBUG,$error,$col_order,$CN,$OU);
# N.B. we should make the $O and the $OU an account name, so it all links back
$DEBUG=0;

my $viewcn;
my $editcn;
foreach my $values (keys %form){
	if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){
		if($form{'Add'} eq 'Add'){ $form{cn} = $form{cn}; $form{Insert} =1; }
		if($form{$values} eq 'View'){ $viewcn = $values; }
	}
	if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){
        	if($form{$values} eq 'Edit'){ $editcn = $values; }
	}
	if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){
		if($form{$values} eq 'Update'){ $form{Update} = $values; }
	}
}

my $csrconf_file="/tmp/.csrconf.$$";
#print $csrconf << EOF
my $csrconf_details = "[ req ]
default_bits           = 1024
default_keyfile        = ssl.key
prompt                 = no
distinguished_name     = req_distinguished_name
[ req_distinguished_name ]
";
my $csrconf = "C =GB
ST=England
L =London
O =Group NBT plc
OU=myOU
CN=myCN";

#echo "Creating a new key and CSR..."
#openssl req -days 3650 -nodes -config $tmpfile -new -keyout "$CN.key" -out "/people/admin/CA/requests/$CN.csr" || exit 2
if(!$form{order}) { $col_order = '&amp;order=asc'; }
if($form{order} eq 'asc') { $col_order = '&amp;order=desc'; }

my($notice)= new Notice::DB::ssl;
my(%ssl_certs,$certs);
# this will become a list of domains that this user can set up aliases @
#my $domain_html = $notice->list_ssl();		#list of certificates that this user can view

if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3)
{
if(!$form{sort}){ $form{sort} = 'cn';}
# we have to check that this user is in a group that is entitled to that domain
# and check that the domain is active for this account (domains can be in multiple 
# accounts, but only live in one!)

	if($DEBUG > 2){
	foreach my $que (keys %form)
	{
		print "$que = $form{$que} <br />";
	}
	print "<br />";
	}# end of DEBUG level3
if($form{'ssl_keygen'}){
	my %values;
	$values{URI} = $ud;
	foreach my $que (keys %form){
	    if($form{$que} eq 'Create'){ ($values{cn},$values{bin}) = split(/ /, $que); }
       }
	#so we lock the table, check for existing key
	# if no key, create one and insert it
	# unlock tables, $values{return} = 'key created';
	$notice->create_rsakey(\%values);
	if($values{return}){
		print "$values{return}<br/>";
	}
	if($values{error}){
		print "$values{error}<br/>";
	}
	#my $new_rsakey = `openssl genrsa 1024 2>/dev/null`;
	print "$values{new_rsakey_html}";	
}elsif($form{ssl_csrgen}){
	my %values;
        $values{URI} = $ud;
        foreach my $que (keys %form){
            if($form{$que} eq 'Create'){ ($values{cn},$values{bin}) = split(/ /, $que); }
        }
	if($values{bin} eq 'ssl_csrgen'){
		#check CSR for details
		my @csr_kvp = split (/\n/, $form{CSR});
		foreach my $kvp (@csr_kvp){
			my($key,$value) = split /=/, $kvp;
			$key=~s/\s*$//;
			$value=~s/\s*$//;
			$value=~s/^\s*//;
			$key = 'CSR_' . $key;
			$values{$key} = $value;
		}
		if($values{CSR_C} &&
		$values{CSR_ST} &&
		$values{CSR_L} &&
		$values{CSR_O} &&
		$values{CSR_OU} && ($values{CSR_OU} ne '') &&
		( $values{CSR_CN} eq $values{cn}) &&
		$values{URI} 
		){
			$values{conf} = $csrconf_details;
        		$notice->create_csr(\%values);
        		if($values{return}){
        		        print "$values{return}<br/>";
        		}
        		if($values{error}){
        		        print "$values{error}<br/>";
        		}
        		print "$values{new_csr_html}";
		}else{
			if(!$values{CSR_OU}){ print qq|<span class="error"> I need a valid Opperating Unit</span>|; }
			elsif(!$values{CSR_C}){ print qq|<span class="error"> I need a valid Country ($values{CSR_C})</span>|; }
			elsif(!$values{CSR_ST}){ print qq|<span class="error"> I need a valid Area</span>|; }
			elsif(!$values{CSR_L}){ print qq|<span class="error"> I need a valid Location</span>|; }
			elsif(!$values{CSR_O}){ print qq|<span class="error"> I need a valid Opperation</span>|; }
			elsif($values{CSR_CN} ne $values{cn}){ print qq|<span class="error"> CN has to match the Common Name</span>|; }
			if($DEBUG>=2){
				foreach my $que (keys %values){
			            if($que=~m/^CSR_/){ print qq| ($que) = ($values{$que})<br/>|; }
        			}
			}
		}
	}
}elsif($form{cn} && ( $user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3))
#then we are going for an update/insert
{
	my %values;
#NTS check we are talking to a person with the right privs
#$notice->check_position('$ENV{REMOTE_USER}','Director','Admin','Sysops');
	$values{auth} = 1;
	$values{data_checked} = 0;
#check we have what we need
	# we should have a 'cn' optionally we should have
	# a key
	# a Certificate Signing Request
	# a Certificate
	if($DEBUG >= 2){
	foreach my $que (keys %form)
	{
		print "$que = $form{$que} <br />";
	}
	print "<br />";
	}# </DEBUG>
	#NTS if key is just a number, then create a key with that 'bit long modulus' though 1024 is right for now
	#NTS more checking is needed!
	# do some string checking to see if the csr has ascii armour
	if(!$form{cn} ){ $error .= "cn is missing<br />"; $values{data_checked}+=2; }
	if($form{cn}){ $values{data_checked}++; }
	if($form{key} && ($form{key}!~m|^-----BEGIN RSA PRIVATE KEY-----[A-Za-z0-9/\+=\s]+-----END RSA PRIVATE KEY-----\s*|s &&
	   $form{key}!~m|^-----B[A-Z\s]+KEY-----[A-Za-z0-9/\+]+=\s*-----END RSA PRIVATE KEY-----\s*| &&
	   $form{key}!~m|^key=.+$|)){
		 $error .= "key is missing BEGIN <br />";
		 $values{data_checked}+=2;
	}
	if($form{csr} && $form{csr}!~m/-----BEGIN (NEW )?CERTIFICATE REQUEST-----/){ $error .= "csr is missing BEGIN <br />";  $values{data_checked}+=2; }
	if($form{crt} && $form{crt}!~m/-----BEGIN CERTIFICATE-----/){ $error .= "crt is missing BEGIN <br />";  $values{data_checked}+=2; }
	
		$values{ssl_cn}		= $form{cn};
		$values{ssl_key}	= $form{key};
		$values{ssl_csr}	= $form{csr};
		$values{ssl_crt}	= $form{crt};
		$values{ssl_location}=$form{location};
		$values{ssl_peid}	= $user_details{pe_id};
	print "<br /> $error <br />" if $DEBUG >=1;

	# { all of these checks should be in the ssl.pm NOT here!
	#if we have an update we do a evaluation of the string so we only update the parts that have changed
	#NTS you are here doing that....
	#NTS check that they are not trying to replace a valid KEY/CSR/CRT with crap (but let them wipe the value!)
	if($values{auth} == 1 && $values{data_checked} == 1)
	{
		#<DEBUG>
		if($DEBUG >= 2){
		foreach my $key (keys %values)
		{
			print "$key = $values{$key} <br />";
		}
		}
		#</DEBUG>
		#
		if($form{Update}){
			$values{URI} = $ud;
			$values{Update} = $form{Update};
		   if($form{cn} eq 'DELETE' and $user_details{pe_level} > 4){
			$notice->delete_ssl(\%values);
		   }else{
			$notice->update_ssl(\%values);
			if(!$values{error}){ $viewcn = $form{Update}; } #so we can view the SSL we just changed
				#NTS but what if we changed the CN ? 
			#$values{return} .= qq|<span class="error"> values updated</span>|;
		   }
		}elsif($form{Insert}){
			$values{URI} = $ud;
			$values{ssl_peid} = $user_details{pe_id};
			$notice->insert_ssl(\%values);
		}
	}
	if($values{return})
	{
		print "Message: $values{return}";
	}
}

if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){
$notice->list_ssl(\%ssl_certs,$certs);
}

if($error){
	print "ERROR: $error";
}elsif($viewcn){
	print "Listing $viewcn SSL Certificates";
}elsif($editcn){
	print "Edit $editcn SSL Certificates";
}else{
	print " Listing SSL Certificates"; 
}

my $html_table = qq(
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
<table class="sslcert">
      <tr>
        <th class="ip"><a href="$page?sort=cn$col_order&amp;ud=$ud">Common Name</a></th>
        <th class="ip">KEY</th>
        <th class="ip">CSR</th>
        <th class="ip">CRT</th>
        <th class="ip"><a href="$page?sort=location$col_order&amp;ud=$ud">Location</a>; Type</th>);
# if we have a CN (so we have only one ssl) we can check the SSL_grid (SSL_peid for now) to see if this user links back to the owner (group)
if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){ #this needs to check to see if the user is the SSL owner! NTS
	if(!$viewcn && !$editcn){
        	$html_table .= qq(<th class="ip">View</th>);
	}elsif($editcn){
		$html_table .= qq|<th class="ip">Update</th>|;
	}else{
        	$html_table .= qq(<th class="ip">Edit</th>);
	}
}
$html_table .= qq(
      </tr>
);

if($editcn){ print qq|<form method="post" action="$action">|; }
print $html_table;
sub ssl_sort {
	my $key = $form{sort};
	#it would be nice to sort by CRT expiry but that is not trivial.
	if($form{order} eq 'asc'){
		( $ssl_certs{$b}{"$key"} cmp $ssl_certs{$a}{"$key"} )
	}else{
		( $ssl_certs{$a}{"$key"} cmp $ssl_certs{$b}{"$key"} )
	}
}
my $stripe = 'stripe';

DISPLAY: foreach my $ref (sort ssl_sort keys %ssl_certs)
{
	next DISPLAY if($viewcn && ("$viewcn" ne "$ssl_certs{$ref}{'cn'}"));
	next DISPLAY if($editcn && ("$editcn" ne "$ssl_certs{$ref}{'cn'}"));
	my $ln=0;
	my($key_modulus,$key_details,$csr_modulus,$csr_details,$crt_modulus,$crt_start,$crt_end);
	if($stripe eq 'stripe'){ $stripe = 'strip';}
	else{ $stripe = 'stripe';}
   if(!$viewcn && !$editcn){
	if($ssl_certs{$ref}{'key'} && $ssl_certs{$ref}{'key'}!~m/^key=.+/){
		#open(KEY,">$oscsrtf.key") or die "$! QuESTION $?";
		#print KEY $ssl_certs{$ref}{'key'} or die "WjAT????  $?  THAT $!";
		#close(KEY);
		#my @key_records = `openssl rsa -noout -text -modulus -in $oscsrtf.key`;
		my @key_records = `echo "$ssl_certs{$ref}{'key'}"|openssl rsa -noout -text -modulus`;
		foreach my $csrl (@key_records){ next if $csrl!~m/Modulus/; $key_modulus = $csrl; }
		$key_details = $key_modulus; chomp($key_details); $key_details=~s/Modulus=//;
		$key_details = `echo $key_details|md5sum`; chomp($key_details); chop($key_details); 
		chomp($key_details);
		#unlink("$oscsrtf.key");
	}

	if($ssl_certs{$ref}{'csr'}){
		#open(CSR,">$oscsrtf.csr") or die "$! QUESTION $?";
		#print CSR $ssl_certs{$ref}{'csr'} or die "WHAT????  $?  THAT $!";
		#close(CSR);
		#my @csr_records = `openssl req -noout -text -modulus -in $oscsrtf.csr`;
		#my @csr_records = `openssl req -noout -text -modulus -in $oscsrtf.csr`;
		my @csr_records = `echo "$ssl_certs{$ref}{'csr'}"|openssl req -noout -text -modulus`;
		$csr_modulus = $csr_records[29]; # we should probably just take the last line or do a s/Modulus=(.+)$/$1/;
		$csr_details = $csr_records[3];
		$csr_details =~s/,/,<br\/>\n/g;
		#unlink("$oscsrtf.csr");
	}

	if($ssl_certs{$ref}{'crt'}){
		#open(CRT,">$oscsrtf.crt") or die "$! QUeSTION $?";
        	#print CRT $ssl_certs{$ref}{'crt'} or die "WHaT????  $?  THArT $!";
        	#close(CRT);
        	#my @crt_records = `openssl x509 -noout -text -modulus -in $oscsrtf.crt`;
		#warn("Trying CRT: $ssl_certs{$ref}{'cn'}");
        	my @crt_records = `echo "$ssl_certs{$ref}{'crt'}"|openssl x509 -noout -text -modulus 2>&1`;
		#warn("DONE CRT: $ssl_certs{$ref}{'cn'}");
		if($crt_records[0]=~m/unable to load/){ $crt_start = 'Certificate ERROR';
			foreach my $csrl (@crt_records){ $crt_end .= $csrl;}
		}else{
		foreach my $csrl (@crt_records){
			$crt_start = $csrl if $csrl=~m/Not Before/;
			$crt_end = $csrl if $csrl=~m/Not After/;
			next if $csrl!~m/Modulus/; $crt_modulus = $csrl; 
		}
		if(!$crt_start){
			#$crt_start = $crt_records[8];
			$crt_start = "AAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGHHHHHHH";
		}
		if(!$crt_end){
			#$crt_end .= $crt_records[9];
			$crt_end = "BLBBBBBBBBBLBLLBLBLBLBLBLBLLBLBLBLBL";
		}
		}
		#unlink("$oscsrtf.crt");
	}
	#NTS something not working in the CRT checks (needs DEBUG)...
	#NTS need to be able to edit
	#NTS Self-signed CRT Gen
	#NTS local ca CRT Gen
	#NTS KEY view only for level(10) and above or ssl_admin group
    }
	print  qq( <tr class="$stripe">);
	my $CN = $ssl_certs{$ref}{'cn'};
	$CN=~s/^\s*//; chomp($CN);
########################################################################################################
#	The Common Name
########################################################################################################
	if(!$editcn && $user_details{pe_level} > 100){
		print qq|<td class="cn"><a href="ssl.cgi?ud=$ud&amp;Edit=$ssl_certs{$ref}{'cn'}">$ssl_certs{$ref}{'cn'}</a></td>|;
	}elsif($editcn && $user_details{pe_level} > 5){ #this should be group::ssl_admin
		print qq|<td class="cn"><input type="text" name="cn" value="$ssl_certs{$ref}{'cn'}"/></td>|;

	}else{
		print qq|<td class="cn">$ssl_certs{$ref}{'cn'}<input type="hidden" name="cn" value="$ssl_certs{$ref}{'cn'}"/>|;
	}
########################################################################################################
#	The Key 
########################################################################################################
    if(!$viewcn && !$editcn){
	if($key_modulus){
		print qq(<td bgcolor="#66ff22">Good Key $key_details</td>);
	}elsif($ssl_certs{$ref}{'key'} && $ssl_certs{$ref}{'key'}!~m|^key=.+$|){
		print qq(<td bgcolor="#ff0033">Bad key</td>);
	}elsif($ssl_certs{$ref}{'key'}=~m|^key=.+$|){
		print qq|<td>Key password stored</td>|;
	}else{
		print qq(<td><form method="post" action="$action"><input type="submit" name="$ssl_certs{$ref}{'cn'} ssl_keygen" value="Create" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/><input type="hidden" value="$ssl_certs{$ref}{'cn'}" name="ssl_keygen"/></form></td>);
	}

########################################################################################################
#	The CSR 
########################################################################################################
	#chomp($key_modulus);
	#chomp($csr_modulus);
	if("$csr_modulus" eq "$key_modulus" && $csr_details){
		print qq(<td bgcolor="#66ff22">);
	}elsif($key_modulus && $csr_modulus){
		print qq(<td bgcolor="#ff0033">);
		print "BAD<br/>$key_modulus<br/>$csr_modulus";
	}elsif($key_modulus){
		my $cncsrconf = $csrconf;
		$cncsrconf=~s/myCN/$CN/;
		#$cncsrconf=~s/myOU/$ac_name/; #not implemented yet
		$cncsrconf=~s/myOU//;
		 print qq(<td><form method="post" action="$action"><textarea cols="20" rows="6" name="CSR">$cncsrconf</textarea><input type="hidden" value="$ssl_certs{$ref}{'cn'}" name="ssl_csrgen"/><input type="submit" name="$ssl_certs{$ref}{'cn'} ssl_csrgen" value="Create" class="edituser"onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form>);
	}else{
		print qq(<td>Create the key first<br/>);
	}
	#we should change the BG colour using css to green if the mudulus all match and we are within date
	#and change the BG colour to orange if we have 30 days or less to update
	#and BG colour = red if it has expired or does not match
	print qq($csr_details);
	#print qq($csr_modulus);
	#foreach my $csrl (@csr_records){ print "$ln $csrl <br/>\n"; $ln++; }
	print qq(</td>);
	#print qq(<td>$ssl_certs{$ref}{'csr'}</td>);
########################################################################################################
#	The CRT 
########################################################################################################
	if("$crt_modulus" eq "$key_modulus" && "$csr_modulus" eq "$key_modulus" && $crt_start){
            my %month=('Jan','01','Feb','02','Mar','03','Apr','04','May','05','Jun','06','Jul','07','Aug','08','Sep','09','Oct','10','Nov','11','Dec','12');
                #now we check that is it valid.
                my $now = `date +'%a %d %b %Y %H:%M:%S %Z'`;
                $now=~s/\s+/ /g; chomp($now);
                my @now_date = split/ /, $now;
                my $crtend_string = $crt_end;
                $crtend_string=~s/^\s*Not After :\s*//;
                $crtend_string=~s/\s+/ /g; chomp($crtend_string);
                my @end_date = split/ /, $crtend_string;
		if($ssl_certs{$ref}{'cn'}=~m/www.ascio.com/){
			warn"$ssl_certs{$ref}{'cn'} $crtend_string";
		}
                my $bgcolour='#66ff22';
                #check expired (or less than seven days to go)
                if(
                       ($now_date[3] > $end_date[3]) && 
			($month{$now_date[2]} < 11 || $month{$end_date[0]} > 2) ||
                     (
                        ($now_date[3] == $end_date[3]) &&
                        ( $month{$now_date[2]} > $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[2]" eq "$end_date[0]") &&
                         ( ($now_date[1]) >= ($end_date[1]-7))
                     )
                ){ $bgcolour='#ff0000';}
                # warn for near expired (30 days or a month)
                elsif(
                     (
                        ($now_date[3] >= $end_date[3]) && #you can demonstrate a warning by reversing the polarity
                        ( $month{$now_date[2]}+1 > $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[2]" eq "$end_date[0]") &&
                         ( ($now_date[2]+30) >= $end_date[1])
                     ) ||
		     ( # need to bridge the years
			 #(($now_date[3]+1) == $end_date[3]) &&
			  #($month{$now_date[2]} == 12) &&
			  ($month{$end_date[0]} == 01)
			  #("$now_date[2]" eq 'Dec' && "$end_date[0]" eq 'Jan') 
		     )
                ){ $bgcolour='#ff6633';}
                # warn for near expired (60 days or a month)
                elsif(
                     (
                        ($now_date[3] >= $end_date[3]) && #you can demonstrate a warning by reversing the polarity
                        ( $month{$now_date[2]}+2 >= $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[1]" eq "$end_date[0]") &&
                         ( ($now_date[2]+60) >= $end_date[1])
                     )
                ){ $bgcolour='#ffff22';}

                print qq(<td nowrap="nowrap" bgcolor="$bgcolour">$crt_start<br/>$crt_end</td>);
	}elsif($key_modulus && $crt_modulus){
                print qq(<td bgcolor="#ff0033">);
                print "BADDER<br/>" . substr($key_modulus,0,30) . "..<br/>" . substr($csr_modulus,0,30) . "..<br/>" . substr($crt_modulus,0,30) . "..</td>";
	}elsif($crt_start=~m/ERROR/i){
		print qq(<td bgcolor="#0033ff">);
		$key_modulus = substr($key_modulus,8,20);
		$csr_modulus = substr($csr_modulus,8,20);
		$crt_modulus = substr($crt_modulus,8,20);
		print "$crt_start<br/>$crt_end<br/>KEY $key_modulus<br/>CSR $csr_modulus<br/>CRT $crt_modulus</td>";
	}elsif($crt_end=~/Not After :/){
		my %month=('Jan','01','Feb','02','Mar','03','Apr','04','May','05','Jun','06','Jul','07','Aug','08','Sep','09','Oct','10','Nov','11','Dec','12');
                #now we check that is it valid.
		my $now = `date +'%a %d %b %Y %H:%M:%S %Z'`;
                $now=~s/\s+/ /g; chomp($now);
                my @now_date = split/ /, $now;
                my $crtend_string = $crt_end;
                $crtend_string=~s/^\s*Not After :\s*//;
                $crtend_string=~s/\s+/ /g; chomp($crtend_string);
                my @end_date = split/ /, $crtend_string;
                my $bgcolour='#66ff22';
                #check expired (or less than seven days to go)
                if(
                       ($now_date[3] > $end_date[3]) ||
                     (
                        ($now_date[3] == $end_date[3]) &&
                        ( $month{$now_date[2]} > $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[2]" eq "$end_date[0]") &&
                         ( ($now_date[1]) >= ($end_date[1]-7))
                     )
                ){ $bgcolour='#ff0000';}
		# warn for near expired (30 days or a month)
                elsif(
                     (
                        ($now_date[3] >= $end_date[3]) && #you can demonstrate a warning by reversing the polarity
                        ( $month{$now_date[2]}+1 > $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[2]" eq "$end_date[0]") &&
                         ( ($now_date[2]+30) >= $end_date[1])
                     )||
                     ( # need to bridge the years
                         ($now_date[3]+1 == $end_date[3]) &&
                         ("$now_date[2]" eq 'Dec' && "$end_date[0]" eq 'Jan')
			)
                ){ $bgcolour='#ff6633';}
                # warn for near expired (60 days or a month)
                elsif(
                     (
                        ($now_date[3] >= $end_date[3]) && #you can demonstrate a warning by reversing the polarity
                        ( $month{$now_date[2]}+2 >= $month{$end_date[0]})
                     )||
                     (
                         ($now_date[3] == $end_date[3]) &&
                         ("$now_date[1]" eq "$end_date[0]") &&
                         ( ($now_date[2]+60) >= $end_date[1])
                     )||
                     ( # need to bridge the years
                         ($now_date[3]+1 == $end_date[3]) &&
			 (
                          ("$now_date[2]" eq 'Nov' && "$end_date[0]" eq 'Jan')||
                          ("$now_date[2]" eq 'Dec' && "$end_date[0]" eq 'Feb')
			 )
                        )

                ){ $bgcolour='#ffff22';}

		print qq(<td nowrap="nowrap" bgcolor="$bgcolour">$crt_start<br/>$crt_end</td>);
        }else{
		print qq(<td>$crt_start<br/>$crt_end</td>);
	}
	
	#foreach my $csrl (@crt_records){ next if $csrl!~m/Modulus/; $key_modulus = $csrl; }
	#foreach my $csrl (@crt_records){ print "$ln -> $csrl<br/>\n"; $ln++; }
	#print qq(</td>);
########################################################################################################
#	The location 
########################################################################################################
	my $cert_location = $ssl_certs{$ref}{'location'};
	$cert_location=~s/\&/\&amp;/g;
	print qq(<td>$cert_location</td>);
     } #end of viewcn
	if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3){
	   if( $viewcn ){
		$ssl_certs{$ref}{'key'}=~s|-----END|\n<br/>-----END|;
		$ssl_certs{$ref}{'csr'}=~s|-----END|\n<br/>-----END|;
		$ssl_certs{$ref}{'crt'}=~s|-----END|\n<br/>-----END|;
		print qq|<td>$ssl_certs{$ref}{'key'}</td>|;
		print qq|<td>$ssl_certs{$ref}{'csr'}</td>|;
		print qq|<td>$ssl_certs{$ref}{'crt'}</td>|;
		print qq|<td>$ssl_certs{$ref}{'location'}</td>|;
		print qq(
		<td><form method="post" action="$edit_action"><input type="submit" value="Edit" name="$ssl_certs{$ref}{'cn'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>);
	    }elsif($editcn){
print qq|<td class="cn"><textarea cols="65" rows="20" name="key" style="overflow-x: hidden; overflow-y: scroll">$ssl_certs{$ref}{'key'}</textarea></td>|;
print qq|<td class="cn"><textarea cols="65" rows="20" name="csr" style="overflow-x: hidden; overflow-y: scroll">$ssl_certs{$ref}{'csr'}</textarea></td>|;
print qq|<td class="cn"><textarea cols="65" rows="20" name="crt" style="overflow-x: hidden; overflow-y: scroll">$ssl_certs{$ref}{'crt'}</textarea></td>|;
print qq|<td class="cn"><textarea cols="20" rows="1" name="location" style="overflow-x: hidden; overflow-y: scroll">$ssl_certs{$ref}{'location'}</textarea></td>|;
		print qq(
		<td><input type="submit" value="Update" name="$ssl_certs{$ref}{'cn'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>);

	 }else{
		print qq(
		<td><form method="post" action="$edit_action"><input type="submit" value="View" name="$ssl_certs{$ref}{'cn'}" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></form></td>);
	 }
	} #end of level check (should not need this)
	print qq(
	</tr>
	);
}
} #end of DISPLAY:

if($editcn){ print qq|</form>|; }
undef(%ssl_certs);

if($user_details{pe_menu}=~m/,5,/ && $user_details{pe_level} > 3)
{
print "</table></td></tr><tr><td>";
  if(!$viewcn && !$editcn){
print qq( <form method="post" action="$action">        <table>
     <tr>
        <th class="ip">Common Name</th>
        <th class="ip">KEY</th>
        <th class="ip">CSR</th>
        <th class="ip">CRT</th>
        <th class="ip">Server:Path</th>
     </tr>
);

        print qq |
        <tr>
                <td><input type="text" name="cn"/></td>
                <td><textarea name="key" style="overflow-x: hidden; overflow-y: scroll" rows="1" cols="20"></textarea></td>
                <td><textarea name="csr" style="overflow-x: hidden; overflow-y: scroll" rows="1" cols="20"></textarea></td>
                <td><textarea name="crt" style="overflow-x: hidden; overflow-y: scroll" rows="1" cols="20"></textarea></td>
                <td><input type="text" name="location" /></td>
                <td><input type="submit" value="Add" name="Add" class="edituser" onmouseover="this.className='edituser edituserhov'" onmouseout="this.className='edituser'" onclick="this.className='edituser'"/></td>
        </tr>
        |;

print "</table></form>
You can just add a CN (e.g. secure.example.com ) and Notice can generate the KEY and CSR for you. ";
print "</td></tr></table>";
}
#$user_details{pe_id}
} # end if level check
else { print qq|<span class="withouterror">We have no Bananas, _today_</span>|; }
print "<br />";
print html_footer;

