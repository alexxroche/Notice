package Notice::DB::ip;

# NOTE: this is NOT part of Notice - it is _sudo code_!

use strict;
no strict "refs"; # for IPv6 as a hash key - NOTE fix this
use vars qw/ $db $dbhostname $dbusername $dbpassword /;

use DBI;
use Carp;
use Exporter;
my @ISA=('Exporter','Notice::DB');
#my @EXPORT=('show_pool','VLAN_html','ipp_RIR_html','insert_ipp','assigned_to_html','update_ipp','ip_update');
my @EXPORT=('show_pool','VLAN_html','ipp_RIR_html','insert_ipp','update_ipp','ip_update');

use Notice::DB qw( $db $dbhostname $dbusername $dbpassword );
# NTS  I'm sure this is not the best way to do this
*db = \$Notice::DB::db;
*dbhostname = \$Notice::DB::dbhostname;
*dbusername = \$Notice::DB::dbusername;
*dbpassword = \$Notice::DB::dbpassword;
my $DEBUG=0;

sub new
{
        my($self);
        my($dbh)=DBI->connect("DBI:mysql:$db:$dbhostname",$dbusername,$dbpassword,{PrintError=>0});
        if (!$dbh)
        {
                croak("Couldn't connect to database $db with $dbusername:PASSWORD\@$dbhostname");
        }
        $self={
                dbh=>$dbh,
        };
        bless($self);
        return($self);
}

sub groups {
	my %groups = (
	1.4	=> { 1 => 'IP Sysadmin', 2 => 'Senior IP Sysadmin' },
	);
	return(%groups);
} 

sub show_pool {
	my($self,$ippool,$where,$there)=@_;
	#$where is an obvious conditional,
	#$there is a conditional for when we are doing an update
	# - we use $where to check that the old values still exist and 
	#   we use $there to check that we are not going to duplicate 
	if($where){ 
		if($where!~m/([\d]{1,3}\.){3}[\d]+/ && $where!~m/([0-9a-f]{0,4}:){1,7}[0-9a-f]{1,4}/i)
		{
			$ippool->{error} = "die BAD PERSON! ||$where||";
			#warn($where);
			return('No unique');
		}
		my($ip,$cidr_ip)= split('\/', $where); # we need to split on the slash first because IPv6 uses : (or we change delimiter)
		my($slash,$network)= split('\;', $cidr_ip);
		$where = " and (ipp_name = '$ip' and ipp_network = '$network' and ipp_subnet='$slash') ";
		
	}else{
		warn("No where? $where\n") if $DEBUG>=1;
	}
	if($where && $there){
		if($there!~m|([\d]{1,3}\.){3}[\d]{1,3}/\d+:.+| && $there!~m|([0-9a-f]{0,4}:){1,7}[0-9a-f]{1,4}|i)
                {
                        $ippool->{error} = "die BAD PERSON! ||$there||";
                        #warn($there);
                        return('UM, I think this is bad - ZERO');
                }
                my($ip,$cidr_ip)= split('\/', $there); # we need to split on the slash first because IPv6 uses : (or we change delimiter)
                my($slash,$network)= split('\;', $cidr_ip);
                $where .= " || (ipp_name = '$ip' and ipp_network = '$network' and ipp_subnet='$slash')  ";
	}
	my($query)='SELECT ipp_name,ipp_subnet,ipp_RIR,ipp_VLAN,ipp_network,ipp_assigned_to,ipp_notes FROM ippool where ipp_notes is NOT NULL and ipp_RIR is NOT NULL ' . $where . ' order by ipp_name,ipp_subnet';
	#warn($query);
	($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool");
	my($sth)=($self->{dbh})->prepare($query);
	$sth->execute() or croak("Can't execute query: $query");
	my $count = 1;
	while (my $ref = $sth->fetchrow_hashref()) {
		$ippool->{"$ref$count"}->{'ipp_name'}	= "$ref->{'ipp_name'}";
		$ippool->{"$ref$count"}->{'ipp_subnet'}="$ref->{'ipp_subnet'}";
		$ippool->{"$ref$count"}->{'ipp_VLAN'} = "$ref->{'ipp_VLAN'}";
		$ippool->{"$ref$count"}->{'ipp_network'} = "$ref->{'ipp_network'}";
		$ippool->{"$ref$count"}->{'ipp_RIR'}	= "$ref->{'ipp_RIR'}";
		$ippool->{"$ref$count"}->{'ipp_assigned_to'}	= "$ref->{'ipp_assigned_to'}";
		$ippool->{"$ref$count"}->{'ipp_notes'}= "$ref->{'ipp_notes'}";
		$count++; # just want to be sure that the key is unique for each row
	}
	($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool");
	$sth->finish;
	return($count-1);
}

sub show_slash
{
        my($self,$ippool)=@_;
	my($cidr_ip,$network)= split('\;', $ippool->{slash});
	$network=~s/'/\\'/g;
	my $vlan;
	($network,$vlan) = split(',', $network);
	my($ip,$slash)= split('\/', $cidr_ip);

        if(!$ip){ $ippool->{error} = "No IP found"; return; }
        my($query)='SELECT ip_o1,ip_o2,ip_o3,ip_o4,ip_o5,ip_o6,ip_o7,ip_o8,ip_slash,ip_type,ip_usedfor,ip_network,ip_stockref,ip_notes from ip';
        if($ip=~m/:/)
        {
                 my @address = split(/\:/, $ip);
                for(my $i =0;$i<=7;$i++) { if($address[$i] eq ''){ $address[$i] = '%'; } }
                # the above line is a hack and should only be open to sysadmin to stop people
                # DoSing the DB (and it makes the next line pointless)
                if(!$address[7]){ $ippool->{error} ="No IP septiem hexadecet $address[7] from $ip"; return; }
                $query .= " where ip_o1 like '$address[0]' and ip_o2 like '$address[1]' && ip_o3 like '$address[2]' && ip_o4 like '$address[3]'";
                $query .= " &&  ip_o5 like '$address[4]' and ip_o6 like '$address[5]' && ip_o7 like '$address[6]' && ip_o8 like '$address[7]'";
        }else{
                my @address = split(/\./, $ip);
		my $class = 3;
		#depending on the $slash we want 1,2,3,4 octets
		#/0  - /8  = ip_o1
		#/9  - /16 = ip_o2
		#/17 - /24 = ip_o3
		#/25 - /32 = ip_o4
		if($slash <= 8){ $class = 0;}
		elsif($slash <= 16){ $class = 1;}
		elsif($slash <= 24){ $class = 2;}
		elsif($slash > 24){ $class = 2;}
		#then we want to limit the results to IPv4s that match the subnet created by the slash
		#if we kept the ip addresses as binary octets a match with the subnet would be easy
		#so for now we will have to use the CLASS match and refine the last relevent octect
		# somehow *grin* 
                $query .= " where"; 
                for(my $i =0;$i<=$class;$i++)
		{
			if($i>0){ $query .= " &&"; }
			$query .= " ip_o" . ($i+1) . " = '$address[$i]'"; 
		}
		my $slash_size;
		$slash_size = 127 if $slash == 25;
		$slash_size =  63 if $slash == 26;
		$slash_size =  32 if $slash == 27;
		$slash_size =  15 if $slash == 28;
		$slash_size =   7 if $slash == 29;
		$slash_size =   3 if $slash == 30;
		$slash_size =   1 if $slash == 31;
		$slash_size =   0 if $slash == 32;
		if($slash > 24 && $slash <=32){
			$query .= " && (ip_o4 >= $address[3] && ip_o4 <= ($address[3]+$slash_size) )";
		}
                # the above line only populates the select based on the slash
                # there is still a case where DoSing the DB is possible
		$query .= " && ip_network = '$network'";
        }
        ($self->{dbh})->do('LOCK TABLES ip READ') or croak ("Can't lock ip $!");
	$ippool->{query} = $query; # this just takes it back for debug.. might get rid of this?
        my($sth)=($self->{dbh})->prepare($query);
        $sth->execute() or croak("Can't execute query: $query");
        my $count = 1;
        while (my $ref = $sth->fetchrow_hashref()) {
                $ippool->{"$ref$count"}->{'ip_o1'}       = "$ref->{'ip_o1'}";
                $ippool->{"$ref$count"}->{'ip_o2'}       = "$ref->{'ip_o2'}";
                $ippool->{"$ref$count"}->{'ip_o3'}       = "$ref->{'ip_o3'}";
                $ippool->{"$ref$count"}->{'ip_o4'}       = "$ref->{'ip_o4'}";
                $ippool->{"$ref$count"}->{'ip_o5'}       = "$ref->{'ip_o5'}";
                $ippool->{"$ref$count"}->{'ip_o6'}       = "$ref->{'ip_o6'}";
                $ippool->{"$ref$count"}->{'ip_o7'}       = "$ref->{'ip_o7'}";
                $ippool->{"$ref$count"}->{'ip_o8'}       = "$ref->{'ip_o8'}";
                $ippool->{"$ref$count"}->{'ip_slash'}    = "$ref->{'ip_slash'}";
                $ippool->{"$ref$count"}->{'ip_type'}     = "$ref->{'ip_type'}";
                $ippool->{"$ref$count"}->{'ip_network'}  = "$ref->{'ip_network'}";
                $ippool->{"$ref$count"}->{'ip_usedfor'}  = "$ref->{'ip_usedfor'}";
                $ippool->{"$ref$count"}->{'ip_stockref'} = "$ref->{'ip_stockref'}";
                $ippool->{"$ref$count"}->{'ip_notes'}    = "$ref->{'ip_notes'}";
                $count++; # just want to be sure that the key is unique for each row
                #I should check this is needed

		#here we could do another select on the asset table if ip_stockref hits something
		#and do a baloon of that info in the user has rights to that.
		# then for a gold star (and possible DB thrash) we could do a select against
		# the usedfor so we could link back to the account

		# and when we add security we have to first have an array of accounts that
		# this user may look in and if usedfor does not match then we prune the results 
		# right here
        }
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ip");
        $sth->finish;
}


sub VLAN_html
{
        my($self,$default_VLAN)=@_;
	my $code = "<select name=\"ipp_VLAN\">";
	$code .= qq ( <option value="0"> N/A </option>);
	my($query)='SELECT DISTINCT ipp_VLAN from ippool where ipp_VLAN order by ipp_VLAN';
	($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
	my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
	$sth->execute() or croak("Can't execute query: $query");
	while (my $ref = $sth->fetchrow_hashref()) {
		$code .= qq(  <option value="$ref->{'ipp_VLAN'}");
		if("$ref->{'ipp_VLAN'}" eq $default_VLAN){ $code .= " selected=\"selected\""; }
		$code .= qq(> $ref->{'ipp_VLAN'} </option>); 
	} 
	$code .= "</select>";
	($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L70");
	$sth->finish;
	return($code);
}

sub VLANs
{
        my($self,$vlans,$default_VLAN,$ip_ref)=@_;
        my $code = "<select name=\"ipp_VLAN\">";
	my ($vlan,$network,$where);
	if($ip_ref){ ($vlan,$network) = split(/;/, $ip_ref); $where = qq| and ipp_network = '$network' and ipp_VLAN = '$vlan'|;}

        $code .= qq ( <option value="0"> N/A </option>);
        #my($query)='SELECT DISTINCT(ipp_VLAN,ipp_network),ipp_assigned_to,ipp_notes from ippool where ipp_VLAN and ipp_subnet is NULL and ipp_RIR is NULL order by ipp_VLAN';
        my($query)="SELECT ipp_VLAN,ipp_network,ipp_assigned_to,ipp_notes from ippool where ipp_VLAN and ((ipp_RIR is NULL || ipp_RIR ='') && (ipp_subnet is NULL || ipp_subnet ='')) $where order by ipp_VLAN,ipp_network";
	#warn $query;
        ($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
	my $count = 1;
        while (my $ref = $sth->fetchrow_hashref()) {
                $code .= qq(  <option value="$ref->{'ipp_VLAN'}");
                if("$ref->{'ipp_VLAN'}" eq "$default_VLAN"){ $code .= " selected=\"selected\""; }
                $code .= qq(> $ref->{'ipp_VLAN'} </option>);
                $vlans->{"$ref$count"}->{'ipp_VLAN'}		= "$ref->{'ipp_VLAN'}";
                $vlans->{"$ref$count"}->{'ipp_network'}		= "$ref->{'ipp_network'}";
                $vlans->{"$ref$count"}->{'ipp_assigned_to'}	= "$ref->{'ipp_assigned_to'}";
                $vlans->{"$ref$count"}->{'ipp_notes'}		= "$ref->{'ipp_notes'}";
		#warn("$ref->{'ipp_VLAN'}:$ref->{'ipp_network'} ($ref->{'ipp_assigned_to'} - $ref->{'ipp_notes'})");
		$count++;
        }
        $code .= "</select>";
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L70");
        $sth->finish;
        return($code);
}

#sub assigned_to_html
#{
#
#        my($self,$default_assigned_to,$type)=@_;
#        my $code = "<select name=";
#	$code .= qq|"ipp_assigned_to"|; # long story LxR
#        $code .= qq (>\n<option value="0"> Nobody </option>\n); # yes the >< is right
#        my($query)= qq(SELECT DISTINCT ipp_notes,ipp_assigned_to from ippool where ipp_subnet is NULL && ipp_RIR is NULL && ipp_network is NULL and ipp_assigned_to != '' order by ipp_assigned_to);
#        ($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
#        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
#        $sth->execute() or croak("Can't execute query: $query");
#        while (my $ref = $sth->fetchrow_hashref()) {
#                $code .= qq(  <option value="$ref->{'ipp_assigned_to'}");
#                if("$ref->{'ipp_assigned_to'}" eq $default_assigned_to){ $code .= " selected=\"selected\""; }
#                $code .= qq(> $ref->{'ipp_assigned_to'} </option>\n);
#        }
#        $code .= "</select>";
#        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L92");
#        $sth->finish;
#        return($code);
#}
# sub assigned_to_html is being replaced by list_assigned_to (though the former name is better)
sub list_assigned_to
{
        my($self,$accounts,$default_assigned_to,$type)=@_;
        my $code = "<select name=";
        $code .= qq|"ipp_assigned_to"|; # long story LxR
        $code .= qq (>\n);
	if(!$type){
        	$code .= qq (<option value="0">Nobody</option>\n);
	}
        my($query)= qq(SELECT DISTINCT ipp_notes,ipp_assigned_to from ippool where ipp_RIR is NULL && ipp_VLAN is NULL && ipp_network is NULL && ipp_assigned_to!='' order by ipp_assigned_to);
        ($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
	my $count=1;
        while (my $ref = $sth->fetchrow_hashref()) {
                $code .= qq(<option value="$ref->{'ipp_assigned_to'}");
		# I'm too nice - you can set the default by name or account id - I should probably stop this LxR
                if("$ref->{'ipp_assigned_to'}" eq $default_assigned_to){ $code .= " selected=\"selected\""; }
                if("$ref->{'ipp_notes'}" eq $default_assigned_to){ $code .= " selected=\"selected\""; }
                $code .= qq(>$ref->{'ipp_notes'}</option>\n);
		#$accounts->{"$ref$count"}->{'ipp_assigned_to'} = "$ref->{'ipp_notes'}";
		$accounts->{$ref->{'ipp_assigned_to'}}=$ref->{'ipp_notes'};
		$count++;
        }
        $code .= "</select>";
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L92");
        $sth->finish;
        return($code);
}

sub insert_ipp_assigned_to{
	my($self,$values)=@_;
	my $ac_id = $values->{ipp_assigned_to};
	$ac_id=~s/'/\\'/;
	#check that this person can set accounts to be assigned
	#NTS this does not cut it! we MUST populate $values->{pe_id} ourselves from $values->{URI}
	unless($values->{URI}){ $values->{return} .= qq|<span class="error">I don't think so</span>|; return; }
	#second we check that we don't already have this.
	my($search)=qq(SELECT ipp_name from ippool where ipp_RIR is NULL && ipp_VLAN is NULL && ipp_network is NULL && ipp_assigned_to='$ac_id');
        ($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE, account READ') or croak ("Can't lock tables $!");
        my($sth)=($self->{dbh})->prepare($search) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $search");
        my $rows = $sth->rows();
        if($rows == 0){
		#check we have an account with that ac_id
		my($query)= qq(SELECT ac_name from account where ac_id = '$ac_id');
        	$sth=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        	$sth->execute() or croak("Can't execute query: $query");
        	my $rows = $sth->rows();
        	if($rows == 1){
			my @row = $sth->fetchrow_array();
			my $ipp_assigned_to=$row[0];
			$ipp_assigned_to=~s/'/\\'/;
			#insert it into the ippool
			my $history = qq |INSERT into ipphistory VALUES('','$values->{pe_id}','Made $ipp_assigned_to assignable for networks',NOW(),'','DELETE from ippool where ippname="IPPAT_$ac_id"')|; 
        		$sth=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
       			$sth->execute() or croak("Can't execute query L270: $history BECAUSE $DBI::errstr  NOTE $?");
			my $insert = qq|INSERT into ippool(ipp_name,ipp_assigned_to,ipp_notes) VALUES('IPPAT_$ac_id','$ac_id','$ipp_assigned_to')|;
			# with a little re-design we could stop using ipp_name or ipp_assigned_to but this should make little improvement
			$sth=($self->{dbh})->prepare($insert) or croak("Can't prepare $!");
		        $sth->execute() or croak("Can't execute query: $insert");
			$values->{return} .= qq|<span class="withouterror">You can now assign networks to $ipp_assigned_to</span>|;
		}else{
			if($rows >1){ $values->{error} .= qq|Don't know which account to chose, so many of them!|; }
			else{ $values->{error} .= qq|Don't know that account|; }
		}
	}else{
		$values->{error} .= qq|<span class="error">Duplicate Account found</span> - row NOT added|;
	}
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L284");
        $sth->finish;
}

sub networks
{

        my($self,$networks,$default_network,$type,$skip_blank)=@_;
	 my $code = "<select name=";
        if($type){ $code .= qq|"ip_network"|; }
        else{ $code .= qq|"ipp_network"|; }
        $code .= qq (>\n);
	# this is a fun one - we don't want people to set a blank network, but we don't know if we have one until
	# we do the select - we should add this first option after the select if we get a default match that is not 0
	# NTS ^^^^^^^^^^^^^^^^^
	unless($default_network && $skip_blank){ $code .= qq( <option value="0">No network set</option>\n); }
        #my($query)= qq(SELECT DISTINCT ipp_network,ipp_notes from ippool where ipp_subnet is NULL and ipp_RIR is NULL and ipp_network !='' order by ipp_assigned_to);
        my($query)= qq(SELECT DISTINCT ipp_network,ipp_notes from ippool where ipp_subnet is NULL and ipp_RIR is NULL and ipp_network !='' and ipp_name like 'IPPN_%' order by ipp_assigned_to);
        ($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
        while (my $ref = $sth->fetchrow_hashref()) {
                $code .= qq(  <option value="$ref->{'ipp_network'}");
                if("$ref->{'ipp_network'}" eq "$default_network"){ $code .= " selected=\"selected\""; }
                $code .= qq(>$ref->{'ipp_notes'}</option>\n);
		$networks->{$ref->{'ipp_network'}}=$ref->{'ipp_notes'};
        }
        $code .= "</select>";
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
        $sth->finish;
        return($code);
}

sub show_networks
{
        my($self,$networks)=@_;
        my($query)= qq(SELECT ipp_network,ipp_assigned_to,ipp_notes from ippool where ipp_subnet is NULL and ipp_RIR is NULL and ipp_network !='' and ipp_name like 'IPPN_%' order by ipp_assigned_to);
        #my($query)= qq(SELECT ipp_network,ipp_assigned_to,ipp_notes from ippool where ipp_subnet is NULL and ipp_RIR is NULL and ipp_network !='');
        ($self->{dbh})->do('LOCK TABLES ippool READ') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
	my $count=1;
        while (my $ref = $sth->fetchrow_hashref()) {
		$networks->{"$ref$count"}->{'ipp_network'} = "$ref->{'ipp_network'}";
		$networks->{"$ref$count"}->{'ipp_assigned_to'} = "$ref->{'ipp_assigned_to'}";
		$networks->{"$ref$count"}->{'ipp_notes'} = "$ref->{'ipp_notes'}";
		$count++;
        }
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
        $sth->finish;
}

sub update_ipp_network{
	# NTS! when updating a network "assigned_to" you MUST update the VLANS at the same time
}
sub insert_ipp_network{
	my($self,$values)=@_;
	#check that this person can create networks
	#NTS this does not cut it! we MUST populate $values->{pe_id} ourselves from $values->{URI}
        unless($values->{URI}){ $values->{return} .= qq|<span class="error">I don't think so</span>|; return; }
	my $pe_id = $values->{pe_id};
        #second we check that we don't already have this.
	my $ippat = $values->{ipp_assigned_to};
	$ippat=~s/'/\\'/;
	my $ipp_notes = $values->{ipp_network};
	$ipp_notes=~s/'/\\'/;
	$ipp_notes=~s/^\s*//g;
	chomp($ipp_notes);
        my($query)=qq(SELECT ipp_assigned_to,ipp_notes from ippool where ipp_RIR is NULL && ipp_VLAN is NULL && ipp_network is NULL && ipp_assigned_to='$ippat');
        ($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
	my $rows = $sth->rows();
	if($rows == 1){
		#now we need to find the next network by doing a select on networks for $ippat and then ++
		my($find_next_network)="SELECT ipp_network,ipp_notes from ippool where ipp_assigned_to = '$ippat' and ipp_network!='' order by ipp_network";
            	($sth)=($self->{dbh})->prepare($find_next_network) or croak("Can't prepare $find_next_network" . $?);
            	$sth->execute() or croak("Can't execute query: $find_next_network". $?);
		my $ipp_network='0';
            	while (my $ref = $sth->fetchrow_hashref()) {
                	my $value = $ref->{'ipp_network'};
                	$value=~s/^$ippat\.//;
                	if(int($value) > $ipp_network){ $ipp_network = $value; }
			if($ref->{'ipp_notes'} eq $ipp_notes){
				$values->{error} .= qq|<span class="error">Looks like $ippat already has that network</span>\n|;
				($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
        			$sth->finish;
			 	return;
			}
            	}
            	$ipp_network++;
                $ipp_network = '' if($values->{ipp_assigned_to}=~m/'/);
		if($ipp_network){
			#put together the insert
			my $insert = "INSERT into ippool(ipp_name,ipp_assigned_to,ipp_network,ipp_notes) VALUES(";
			$insert .= "'IPPN_$ippat.$ipp_network','$ippat','$ippat.$ipp_network','$ipp_notes')";
	        	my $history;		# we could pull the assigned_to name and add it to the hitory 'Built network $ipp_notes for $ac_name'
	        	$history = qq |INSERT into ipphistory VALUES('','$pe_id','Built network $ipp_notes for $ippat',NOW(),'','DELETE from ippool where ippname="IPPN_$ipp_network"')|;
	        	my ($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
	       		$sth->execute() or croak("Can't execute query L270: $history BECAUSE $DBI::errstr  NOTE $?");
	        	($sth)=($self->{dbh})->prepare($insert);
	        	$sth->execute() or croak("Can't execute query: $insert $!");
	        	$values->{return} = qq|<span class="withouterror">New network added to Notice</span>|;
		}else{
			$values->{error} .= qq|<span class="errror">Can't work out what the next network number should be</span>|;
		}
        }else{
		$values->{error} .= qq|<span class="error">I hate to be difficult but I don't seem to know about that 'Assigned To' - No insert done</span>|;
	}
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
        $sth->finish;
}

sub update_ipp_vlan{
      my($self,$values)=@_;
        unless($values->{URI}){ $values->{return} .= qq|<span class="error">I don't think so</span>|; return; }
        my $pe_id = $values->{pe_id};
        #second we check that we don't already have this.
        my $ippat = $values->{ipp_assigned_to};
        $ippat=~s/'/\\'/g;
        my $ipp_network = $values->{ipp_network};
        $ipp_network=~s/'/\\'/g;
        my $ipp_VLAN = $values->{ipp_VLAN};
        $ipp_VLAN=~s/'/\\'/g;
        $ipp_VLAN=~s/\D*//g; #should just be a number from 1..4096
        my $ipp_notes = $values->{ipp_notes};
        $ipp_notes=~s/'/\\'/g;
        #$ipp_notes=~s/([^\\])\\([^\\])/$1\\\\$2/g;
        $ipp_notes=~s/^\s*//g;
	my ($vlan,$network) = split(/;/, $values->{update});

	if(!$ipp_VLAN){
		$values->{error} .= qq|<span class="error">lost the VLAN in that network - no update done</span>|;
		return;
	}
	if(!$vlan || !$network){ $values->{error} .= qq|<span class="error">lost the vlan $vlan for network $network - no update done</span>|; return; }

        chomp($ipp_notes);
	my $rows;
	my $old_assigned_to;

	#here we check that they are not trying to change a VLAN to the same as an existing one
	my $sth;
		#warn "$vlan ne $ipp_VLAN || $network ne $ipp_network";

	if($vlan ne $ipp_VLAN || $network ne $ipp_network){ #then we have a BIG change, not just an update of the description
         my $query=qq|SELECT ipp_assigned_to,ipp_notes from ippool where ipp_RIR is NULL && ipp_subnet is NULL && ipp_network='$ipp_network' and ipp_VLAN='$ipp_VLAN'|;
		#warn $query; 

        	($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE') or croak ("Can't lock ippool $!");
        	($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        	$sth->execute() or croak("Can't execute query: $query");
        	$rows = $sth->rows();
		 while (my $ref = $sth->fetchrow_hashref()) {
			$old_assigned_to = $ref->{'ipp_assigned_to'};
			warn "Setting $old_assigned_to \n";
		}
		warn "$vlan != $ipp_VLAN || $network != $ipp_network\n";
	}else{
		warn "$vlan == $ipp_VLAN && $network == $ipp_network\n";
	}
        my $create_network;
	my $old_notes;
	if($rows == 0){
		# NTS not sure this is written gooooouud?
                #now we need to check that this is a valid network within that ipp_assigned_to (and collect the old details for the rollback
                my($find_network)="SELECT ipp_network,ipp_notes,ipp_VLAN,ipp_assigned_to from ippool where ipp_RIR is NULL && ipp_subnet is NULL && ipp_name=ipp_VLAN and ipp_network = '$network' and ipp_VLAN='$vlan'";
                ($sth)=($self->{dbh})->prepare($find_network) or croak("Can't prepare $find_network" . $?);
                $sth->execute() or croak("Can't execute query: $find_network". $?);
                #$ipp_network =''; # we will find it again if we are being told the truth!
                $network =''; # we will find it again if we are being told the truth!
                while (my $ref = $sth->fetchrow_hashref()) {

                        my $value = $ref->{'ipp_network'};
                        $value=~s/^$ippat\.//;
                        if(int($value) > $ipp_network){ $ipp_network = $value; }
                        if($old_assigned_to && $ref->{'ipp_assigned_to'} ne $old_assigned_to){
                                $values->{error} .= qq|<span class="error">Looks like $ipp_network is already assigned to $old_assigned_to not $ref->{'ipp_assigned_to'}</span>|;
                                ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
                                $sth->finish;
                                return;
                        }
			if(!$old_assigned_to){ $old_assigned_to = $ref->{'ipp_assigned_to'};} 
			$old_notes = $ref->{'ipp_notes'};
                        #$ipp_network = $ref->{'ipp_network'};
                        $network = $ref->{'ipp_network'};
                }
		# check that they are not messing up the ippool by setting the network to one that isn't assigned to ipp_assigned_to
		 my($find_ippat)="SELECT ipp_assigned_to from ippool where ipp_RIR is NULL && ipp_subnet is NULL && ipp_name='IPPN_$ipp_network' and ipp_network = '$ipp_network' and ipp_VLAN is NULL";
                ($sth)=($self->{dbh})->prepare($find_ippat) or croak("Can't prepare $find_ippat" . $?);
                $sth->execute() or croak("Can't execute query: $find_ippat". $?);
                while (my $ref = $sth->fetchrow_hashref()) {
                        if($old_assigned_to ne $ref->{'ipp_assigned_to'}){
                                $values->{error} .= qq|<span class="error">Looks like $ipp_network is already assigned to network $old_assigned_to not network $ref->{'ipp_assigned_to'}</span>|;
                                ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
                                $sth->finish;
                                return;
                        }
                }

                if($ipp_network == ''){ #ok simple mistake - trying to add a VLAN to a network that is not
                                       #assigned to the 'assigned_to' given
                                        # we can punish them or create a new network
                        #if($network_kind==1){
                        #        my $ippool_colls = '';
                        #        my $ippool_values = qq||;
                        #        $create_network = ';INSERT into ippool(' . $ippool_colls .') VALUES(';
                        #        $create_network .= $ippool_values;
                        #        $create_network .= ')';
                        #        $ipp_network = "$ippat.0";
                        #}#else{
                         $values->{error} .= qq|<span class="error">Your network and Assigned to don't match</span>|;
                        #}
                         warn("Your network and Assigned to don't match");
                }
                $ipp_network = '' if($values->{'ipp_assigned_to'}=~m/'/);
                #warn("Network = $ipp_network but $values->{ipp_assigned_to} < not good");
                if($ipp_network){
                        #put together the update
			$ipp_notes=($self->{dbh})->quote("$ipp_notes");
			$old_notes=($self->{dbh})->quote("$old_notes");
                        my $insert = "UPDATE ippool set ipp_name='$ipp_VLAN',ipp_network='$ipp_network',ipp_VLAN='$ipp_VLAN',ipp_notes=$ipp_notes where ";
                        $insert .= "ipp_RIR is NULL && ipp_subnet is NULL && ipp_network='$network' and ipp_VLAN='$vlan'";
			#warn $insert;
                        my $history = qq |INSERT into ipphistory VALUES('','$pe_id','Updated VLAN $ipp_VLAN in $ipp_network',NOW(),'',"UPDATE ippool set ipp_name='$vlan',ipp_vlan='$vlan',ipp_network='$network',ipp_notes=$old_notes where ipp_name='$ipp_VLAN' and ipp_VLAN='$ipp_VLAN' and ipp_network='$ipp_network' and ipp_RIR is NULL && ipp_subnet is NULL")|;
			#warn "IN IPP_UPDATE_VLAN";
			#warn $history;
                        my ($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
                        $sth->execute() or croak("Can't execute query L270: $history BECAUSE $DBI::errstr  NOTE $?");
                        ($sth)=($self->{dbh})->prepare($insert);
                        $sth->execute() or croak("Can't execute query: $insert $!");
                        $values->{return} = qq|<span class="withouterror">VLAN $ipp_VLAN updated in network $ipp_network</span>|;
                }else{
                        $values->{error} .= qq|<span class="errror">Lost network details for this $ipp_network, possibly code error</span>|;
                }
        }else{
                $values->{error} .= qq|<span class="error">I think that VLAN $ipp_VLAN in network $network already exists - no update done</span>|;
        }
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L525");
        $sth->finish;
}

sub delete_ipp_vlan{
      my($self,$values)=@_;
      $values->{return} .= qq|<span class="error">This function will be written soon(ish)</span>|; return; 
}

sub insert_ipp_vlan{
	# I expect that we will have to auto-find the 'Assigned to' rather than be given it by 
	# the user, we could set $network_kind based on a group policy
	# i.e network_sysadmin_lazy get 2
	#     network_sysadmin_leet get 1
	#     sysadmin get 0
      my($self,$values)=@_;
				#set to 0 if you want to keep your DB clean
	my $network_kind=2;	#set to 1 if you want to create networks for the haploids
				#and set to 2 if 'corrent the "assigned to" for them'
        #check that this person can create networks
        #NTS this does not cut it! we MUST populate $values->{pe_id} ourselves from $values->{URI}
        unless($values->{URI}){ $values->{return} .= qq|<span class="error">I don't think so</span>|; return; }
        my $pe_id = $values->{pe_id};
        #second we check that we don't already have this.
        my $ippat = $values->{ipp_assigned_to};
        $ippat=~s/'/\\'/g;
        my $ipp_network = $values->{ipp_network};
        $ipp_network=~s/'/\\'/g;
        my $ipp_VLAN = $values->{ipp_VLAN};
        $ipp_VLAN=~s/'/\\'/g;
        $ipp_VLAN=~s/\D*//g; #should just be a number from 1..4096
        my $ipp_notes = $values->{ipp_notes};
        $ipp_notes=~s/'/\\'/g;
        $ipp_notes=~s/^\s*//g;
        chomp($ipp_notes);
	if($network_kind==2){
		$ippat = $ipp_network;
		$ippat=~s/\.\d+$//;
	}
	#NTS you MUST! read this through and sanity check that you are not using any
	# $values->
        my($query)=qq(SELECT ipp_assigned_to,ipp_notes from ippool where ipp_RIR is NULL && ipp_VLAN is NULL && ipp_network is NULL && ipp_assigned_to='$ippat');
        ($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE') or croak ("Can't lock ippool $!");
        my($sth)=($self->{dbh})->prepare($query) or croak("Can't prepare $!");
        $sth->execute() or croak("Can't execute query: $query");
        my $rows = $sth->rows();
	my $create_network;
        if($rows == 1){
                #now we need to check that this is a valid network within that ipp_assigned_to
                my($find_network)="SELECT ipp_network,ipp_notes,ipp_VLAN from ippool where ipp_assigned_to = '$ippat' and ipp_network='$ipp_network'";
                ($sth)=($self->{dbh})->prepare($find_network) or croak("Can't prepare $find_network" . $?);
                $sth->execute() or croak("Can't execute query: $find_network". $?);
		$ipp_network =''; # we will find it again if we are being told the truth!
                while (my $ref = $sth->fetchrow_hashref()) {
	
                        my $value = $ref->{'ipp_network'};
                        $value=~s/^$ippat\.//;
                        if(int($value) > $ipp_network){ $ipp_network = $value; }
                        if($ref->{'ipp_VLAN'} eq $ipp_VLAN){
                                $values->{error} .= "Looks like $ipp_network already has that VLAN\n";
                                ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
                                $sth->finish;
                                return;
                        }
			$ipp_network = $ref->{'ipp_network'};
                }
		if($ipp_network == ''){ #ok simple mistake - trying to add a VLAN to a network that is not
				       #assigned to the 'assigned_to' given
					# we can punish them or create a new network
			if($network_kind==1){
				my $ippool_colls = '';
				my $ippool_values = qq||;
				$create_network = ';INSERT into ippool(' . $ippool_colls .') VALUES(';
				$create_network .= $ippool_values;
				$create_network .= ')';
			 	$ipp_network = "$ippat.0";
			}else{
			 $values->{error} .= qq|<span class="error">Your network and Assigned to don't match</span>|;
			}
			 warn("Your network and Assigned to don't match");
		}
                $ipp_network = '' if($values->{'ipp_assigned_to'}=~m/'/);
		#warn("Network = $ipp_network but $values->{ipp_assigned_to} < not good");
                if($ipp_network){
                        #put together the insert
                        my $insert = "INSERT into ippool(ipp_name,ipp_assigned_to,ipp_network,ipp_VLAN,ipp_notes) VALUES(";
                        $insert .= "'$ipp_VLAN','$ippat','$ipp_network','$ipp_VLAN','$ipp_notes')";
                        my $history;            # we could pull the assigned_to name and add it to the hitory 'Set up VLAN $ipp_VLAN in network $ipp_network'
                        $history = qq |INSERT into ipphistory VALUES('','$pe_id','Defined VLAN $ipp_VLAN in $ipp_network',NOW(),'','DELETE from ippool where ipp_name="$ipp_VLAN" and ipp_network="$ipp_network"')|;
                        my ($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
                        $sth->execute() or croak("Can't execute query L270: $history BECAUSE $DBI::errstr  NOTE $?");
                        ($sth)=($self->{dbh})->prepare($insert);
                        $sth->execute() or croak("Can't execute query: $insert $!");
                        $values->{return} = qq|<span class="withouterror">New VLAN added to network $ipp_network</span>|;
                }else{
                        $values->{error} .= qq|<span class="errror">Generic error, network number $ipp_network possibly </span>|;
                }
        }else{
                $values->{error} .= qq|<span class="error">(626) I don't seem to know about that 'Assigned To' - No insert done</span>|;
        }
        ($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't unlock ippool L208");
        $sth->finish;
}

sub ipp_RIR_html
{
        my($self,$default_RIR)=@_;
        my $code = "<select name=\"ipp_RIR\">";
        my($query)='SELECT DISTINCT ipp_RIR from ippool where ipp_RIR order by ipp_RIR';
        my($sth)=($self->{dbh})->prepare($query);
        $sth->execute() or croak("Can't execute query: $query");
        while (my $ref = $sth->fetchrow_hashref() ){
                $code .= qq(  <option value="$ref->{'ipp_RIR'}");
		if("$ref->{'ipp_RIR'}" eq $default_RIR){ $code .= " selected=\"selected\""; }
		$code .= qq(> $ref->{'ipp_RIR'}</option> );
        }
        $code .= "</select>";
	$sth->finish;
        return($code);
}
# these two share far too much code... 
sub list_rir
{
        my($self,$values)=@_;
        my($query)='SELECT DISTINCT ipp_RIR from ippool where ipp_RIR && (ipp_RIR = ipp_name)';
        my($sth)=($self->{dbh})->prepare($query);
        $sth->execute() or croak("Can't execute query: $query");
	my $count=1;
        while (my $ref = $sth->fetchrow_hashref() ){
		$values->{"$ref$count"}->{'ipp_RIR'} = "$ref->{'ipp_RIR'}";
                $count++;
        }
        $sth->finish;
}


sub insert_ipp
{
	my($self,$values)=@_;
	my($ippname,$ippsubnet,$ippRIR,$ippassignedto,$ippVLAN,$ippnetwork,$ippnotes);
	if($values->{ipp_name}=~m/\//)
	{
		($ippname,$ippsubnet) = split(/\//, $values->{ipp_name});
		if(length($ippsubnet) < 1)
		{
		#if IPv4  /32 is IPv6 /128
			if($ippname=~m/[A-F0-9]{1,4}:/){
				$ippsubnet = '128';
			}else{
				$ippsubnet = '32';
			}
		}
	}elsif(!$values->{ipp_subnet}){
		$values->{return} = qq|<span class="error">Not added - you have to THINK before pressing buttons like an fucking epileptic monkey</span>|;
                        return;
		$ippname = uc($values->{ipp_name});
		if($ippname=~m/[A-F0-9]{1,4}:/){
			$ippsubnet = '128';
		}else{
			$ippsubnet = '32';
		}
	}else{
		$ippname = $values->{ipp_name};
		$ippsubnet=$values->{ipp_subnet};
	}
	die ("Invalid data $ippname is not an IP") if $ippname=~m/'/; # you /know/ someone is going to try it 
	# check we don't already have this:
	$ippnetwork=$values->{ipp_network};
	my $where = "$ippname/$ippsubnet:$ippnetwork";
	my(%ippool);
	&show_pool($self,\%ippool,$where);
	foreach my $ref (keys %ippool)
	{
		if(
		    ($ippool{$ref}{'ipp_name'} eq $ippname) &&
		    ($ippool{$ref}{'ipp_subnet'} eq $ippsubnet) &&
		    ($ippool{$ref}{'ipp_network'} eq $ippnetwork)
		)
		{
			$values->{return} = qq|<span class="error">Duplicate row found - not added</span>|;
			return;
		}
	}
	$ippsubnet=~s/'/\\'/g;
	$ippnetwork=~s/'/\\'/g;
        ($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE') or croak ("Can't lock ippool for the insert L93");
	$ippRIR =	$values->{ipp_RIR};
	$ippRIR=~s/'/\\'/g;
	$ippVLAN =	$values->{ipp_VLAN};
	$ippVLAN=~s/'/\\'/g;
	$ippassignedto= $values->{ipp_assigned_to};
	$ippassignedto=~s/'/\\'/g;
	$ippnotes =	$values->{ipp_notes};
	$ippnotes=~s/'/\\'/g; 
	if(!$ippname || !$ippsubnet || !$ippRIR || !$ippassignedto || $ippVLAN!~m/\d/ || !$ippnotes)
	{
		print "Missing data: <br />";
		foreach my $key (keys %{ $values })
		{
			print "$key: $values->{$key}<br />\n";
		}
		print " $ippname || $ippsubnet || $ippRIR || $ippassignedto || $ippVLAN || $ippnotes";
		exit(1);
	}
		
	my $data = qq('$ippname','$ippsubnet','$ippRIR','$ippassignedto','$ippVLAN','$ippnetwork','$ippnotes');
	my($query)='INSERT into ippool (ipp_name,ipp_subnet,ipp_RIR,ipp_assigned_to,ipp_VLAN,ipp_network,ipp_notes) VALUES (';
	$query .= "$data" . ')';
	# we need a sub ip_history(\%ippool,\%values);
	my $history = qq |INSERT into ipphistory VALUES('','$values->{pe_id}','Created $ippname/$ippsubnet',NOW(),'','DELETE from ippool where ippname="$ippname" and ipp_subnet="$ippsubnet"')|; #obv, a chain of roll backs would be needed to cover ipp_name changes
         #and still be able to roll back from the history entry.
	my ($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
       $sth->execute() or croak("Can't execute query L270: $history BECAUSE $DBI::errstr  NOTE $?");
        ($sth)=($self->{dbh})->prepare($query);
        $sth->execute() or croak("Can't execute query: $query $!");
	$values->{return} = qq|<span class="withouterror">Row added to IP pool</span>|;
}

sub update_ipp
{
	my($self,$values)=@_;
	my($ippname,$ippsubnet,$ippVLAN,$ippnetwork,$ippRIR,$ippassignedto,$ippnotes);
	if($values->{ipp_name}=~m/\//)
	{
		($ippname,$ippsubnet) = split(/\//, $values->{ipp_name});
		# We should not be this helpful - if a block has no slash then throw it back at them
		if(length($ippsubnet) < 1)
		{
		#if IPv4  /32 if IPv6 /128
			if($ippname=~m/[A-F0-9]{1,4}:/)
			{
				$ippsubnet = '128';
			}
			else
			{
				$ippsubnet = '32';
			}
		}
		#print "<br /> $ippname<br /> $ippsubnet</br>";
	}
	elsif(!$values->{ipp_subnet})
	{
		$ippname = uc($values->{ipp_name});
		if($ippname=~m/[A-F0-9]{1,4}:/)
		{
			$ippsubnet = '128';
		}
		else
		{
			$ippsubnet = '32';
		}
	}
	else
	{
		$ippname = $values->{ipp_name};
		$ippsubnet=$values->{ipp_subnet};
	}
	# check we already have this:
	my(%ippool);
	$ippnetwork=$values->{ipp_network};
	my($ipp,$cidr_ip)= split('\/', $values->{ipp_ref}); # we need to split on the slash first because IPv6 uses : (or we change delimiter)
	my($slash,$network)= split('\;', $cidr_ip);
	my $where = "$ipp/$slash;$network";
	#warn("REF: $values->{ipp_ref}");
	#warn("SUBNET: $values->{ipp_subnet} | $slash");
	#warn("NAME: $values->{ipp_name} | $ipp");
	#warn("NETWORK: $values->{ipp_network} | $network");
	my $there = qq|$values->{ipp_name}:$values->{ipp_network}|;
	#warn("THERE: $there");
	my $number_of_rows = &show_pool($self,\%ippool,$where,$there);
	if($number_of_rows < 1){ $values->{return} .= qq|<span class="error">$number_of_rows rows found - not sure what to change</span>|; return; }
	if($number_of_rows == 2){ $values->{return} .= qq|<span class="error">That is going to clash with the following existing block</span>|; return; }
	if($number_of_rows > 2){ $values->{return} .= qq|<span class="error">You _somehow_ have managed a total cluster fuc^Wbomb NOT touching that</span>|; return; }
	foreach my $ref (keys %ippool)
	{
		if( 
			$ippool{$ref}{'ipp_name'} eq $ipp &&
			$ippool{$ref}{'ipp_subnet'} eq $slash &&
			$ippool{$ref}{'ipp_network'} eq $network
		)
		{
		
			($self->{dbh})->do('LOCK TABLES ippool WRITE, ipphistory WRITE') or croak ("Can't lock ippool for the insert L93");
			my $data;
			$ippRIR =	$values->{ipp_RIR};
			$ippRIR =~s/'/\\'/g;
			#if($values->{ipp_RIR}){ $data .= "ipp_RIR='$values->{ipp_RIR}',";}
			if($values->{ipp_RIR}){ $data .= "ipp_RIR='$ippRIR',";}
			#$ippVLAN =	$values->{ipp_VLAN};
			if($values->{ipp_VLAN}){ $data .= "ipp_VLAN='$values->{ipp_VLAN}',";}
			if($values->{ipp_network}){ $data .= "ipp_network='$values->{ipp_network}',";}
			if($values->{ipp_assigned_to}){ $data .= "ipp_assigned_to='$values->{ipp_assigned_to}',";}
			$ippnotes =	$values->{ipp_notes};
			if($values->{ipp_subnet}){ $data .= "ipp_subnet='$values->{ipp_subnet}',";}
			#if($values->{ipp_notes}){ $data .= "ipp_notes='$values->{ipp_notes}',";}
			if($values->{ipp_notes}){ $data .= "ipp_notes='$ippnotes',";}
			if(!$ippname)
			{
				print "Missing data: <br />";
				foreach my $key (keys %{ $values })
				{
					print "$key: $values->{$key}<br />\n";
					#warn "$key: $values->{$key}";
				}
				print " $ippname || $ippsubnet || $ippRIR || $ippassignedto || $ippVLAN || $ippnotes";
				exit(1);
			}
			$data .= qq(ipp_name='$ippname',ipp_subnet='$ippsubnet' WHERE ipp_name='$ipp' && ipp_subnet='$slash' && ipp_network='$network');
			$data=~s/;//g; # I don't want to risk it (maybe I should just escape them?)
			my($history,$query);
			if($values->{action} eq 'delete'){
                          $history = qq |INSERT into ipphistory VALUES('','$values->{pe_id}','Deleted $ippname/$ippsubnet',NOW(),'','insert into ippool (ipp_RIR,ipp_VLAN,ipp_subnet,ipp_assigned_to,ipp_notes,ipp_name,ipp_network) VALUES("$ippool{$ref}{'ipp_RIR'}","$ippool{$ref}{'ipp_VLAN'}","$slash","$ippool{$ref}{'ipp_assigned_to'}","$ippool{$ref}{'ipp_notes'}","$ipp","$network"')|;
			  $query = qq |DELETE from ippool WHERE ipp_name='$ipp' && ipp_subnet='$slash' && ipp_network='$network'|;
			}else{
   			 #NTS this history entry is no use for rollback!
                          $history = qq |INSERT into ipphistory VALUES('','$values->{pe_id}','Changed $ippname/$ippsubnet',NOW(),'','update ippool set ipp_RIR="$ippool{$ref}{'ipp_RIR'}", ipp_VLAN="$ippool{$ref}{'ipp_VLAN'}", ipp_subnet="$slash",ipp_assigned_to="$ippool{$ref}{'ipp_assigned_to'}",ipp_notes="$ippool{$ref}{'ipp_notes'}",ipp_name="$ipp",ipp_network="$network" where ipp_name="$ippname" and ipp_subnet="$values->{ipp_subnet}" and ipp_network="$values->{ipp_network}"')|; #so we should even be able to change the ipp_name
			#and still be able to roll back from the history entry.
			$query='UPDATE ippool SET ' . "$data";
			}
                         my ($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
                         $sth->execute() or croak("Can't execute query L342: $history BECAUSE $DBI::errstr  NOTE $?");
                         #so if the history is not written then we can't do the update (and because we already locked the ip table we should be ok)
			($sth)=($self->{dbh})->prepare($query) or croak("Can't connect to the database");
			$sth->execute() or croak("Can't execute query: $query $DBI::errstr $!");
			if($values->{action} eq 'delete'){
				$values->{return} = qq|<span class="withouterror">Row DELETED from IP pool</span>|;
			}else{
				$values->{return} = qq|<span class="withouterror">Row updated to IP pool</span>|;
			}
			#($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't release the table locks");
			#$sth->finish;
			return;
		   #I think the table would stay locked if we were sent multiple updates, which could be interesting
		}
	if($ippool{$ref}{'ipp_name'} ne $ipp){ $values->{return} .= "$ippool{$ref}{'ipp_name'} ne $ipp<br/>"; }
	if($ippool{$ref}{'ipp_slash'} ne $slash ){ $values->{return} .= "$ippool{$ref}{'ipp_slash'} ne $slash<br/>"; }
	if($ippool{$ref}{'ipp_network'} ne $network ){ $values->{return} .= "$ippool{$ref}{'ipp_network'} ne $network<br/>"; }
	}
	$values->{return} .= "Row not found";
}

sub update_ip 
{
	# NTS ! if they have not changed anything then don't issue an update or history!
        my($self,$values)=@_;
        my($ip,$ipslash,$iptype,$ipusedfor,$ipstockref,$ipnotes,$ipnetwork,$where);
	# we check each $value into one of these vaiables for checking 
	# WE DO NOT LET DUFF DATA INTO THIS DATABASE! 
	# The hUMANS mUST bE Protected from themselves!
	#warn("IN Notice::DB::ip::update_ip");
	my $sth;
        $ip= $values->{ip};
        $ipslash=$values->{ip_slash};
        $ipnetwork=$values->{ip_network};
        $where=$values->{ip_ref};
        $iptype=$values->{ip_type};
        # check we already have this:
	# NTS it will be a easy to do this once we put all the IP database code together
	# &ip_search($self,$values);
	use Notice::DB::search qw( ip );
	my($notice)= new Notice::DB::search;
        my %thing;
        $thing{ip} = $ip;
        $thing{network} = $ipnetwork;
        $thing{slash} = $ipslash;
        my $exit_code = $notice-> Notice::DB::search::ip(\%thing);
		# Here we are just trying to stop the hUMaNs from updating $ip_A to == $ip_B
                #if($thing{$ref}{'ip'} ne $ippname)
                # $exit_code == 4 means no match found (should change this to be -1)
                # $exit_code == 1 means 1 match found
                # $exit_code >= 1 means many found
                if($exit_code == 1) # we are not trying to overwrite - tiny racecondition between search and LOCK... NTS
                {

                        ($self->{dbh})->do('LOCK TABLES ip WRITE, iphistory WRITE') or croak ("Can't lock ip for the insert L366 'cause: $DBI::errstr");
                        my $data;
                        if($iptype){ $data .= "ip_type='$iptype',";}
                        if($values->{ip_usedfor}){ $data .= "ip_usedfor='$values->{ip_usedfor}',";}
                        if($values->{ip_stockref}){ $data .= "ip_stockref='$values->{ip_stockref}',";}
			if($values->{ip_network}){ $data .= "ip_network='$values->{ip_network}',";}
                        if($values->{ip_notes}){ $data .= "ip_notes='$values->{ip_notes}',";}
                        if(!$ip || !$ipslash || !$iptype || !$values->{pe_id})
                        {
                                $values->{return} .=  "Missing data: <br/>";
                                foreach my $key (keys %{ $values })
                                {
                                        $values->{return} .=  "$key: $values->{$key}<br/>\n";
                                }
				$values->{return} .=  " $ip || $ipslash || $iptype || $ipusedfor || $ipstockref || $ipnotes";
                                exit(1);
                        }

			if($iptype eq 'IPv4')
 			{
        			my @address = split(/\./, "$ip");
				# here we would add the IP octets to $data if this person is an ip_admin
				my($old_cidr_ip,$old_network)= split('\;', $where);
				my($old_ip,$old_slash)= split('\/', $old_cidr_ip);
        			my @old_address = split(/\./, "$old_ip");
        			if(!$old_address[2]){ die "No IP WHAT dusiem octeti $old_address[2] from $where"; }
        			#$where = "ip_o1=$address[0] && ip_o2 = $address[1] && ip_o3 = $address[2] && ip_o4 = $address[3]";
        			$where = "ip_o1=$old_address[0] && ip_o2=$old_address[1] && ip_o3=$old_address[2] && ip_o4=$old_address[3] && ip_network='$old_network' && ip_slash='$old_slash'";
				#NTS this history entry is no use for rollback! 
        			my $history = qq |INSERT into iphistory VALUES('','$values->{pe_id}','Updated $address[0].$address[1].$address[2].$address[3]',NOW(),'',"UPDATE ip set $where where ip_o1=$address[0] && ip_o2=$address[1] && ip_o3=$address[2] && ip_o4=$address[3] && ip_network='$ipnetwork' && ip_slash='$ipslash'")|;
				($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
        			$sth->execute() or croak("Can't execute query L389: $history BECAUSE $DBI::errstr  NOTE $?");
				#so if the history is not written then we can't do the update (and because we already locked the ip table we should be ok)
 			}elsif($iptype eq 'IPv6'){
        			my @address = split/:/, $ip;
        			$where .= "ip_o1='$address[0]' && ip_o2='$address[1]' && ip_o3='$address[2]' && ip_o4='$address[3]' && ip_o5='$address[4]' && ip_o6='$address[5]' && ip_o7='$address[6]' && ip_o8='$address[7]'";
        			my $history = qq |INSERT into iphistory VALUES('','$values->{pe_id}','Updated $address[0].$address[1].$address[2].$address[3]',NOW(),'','un-update ip where ip_o1 = "$address[0]" and ip_o2 = "$address[1]" and ip_o3 = "$address[2]" and ip_o4 = "$address[3]"')|;
				($sth)=($self->{dbh})->prepare($history) or croak("Can't connect to the database");
        			$sth->execute() or croak("Can't execute query: $history bECaUSE $DBI::errstr nOTE $?");
				#so if the history is not written then we can't do the update (and because we already locked the ip table we should be ok)
			}else{
				$values->{return} .= "Don't have code for that type of address yet";
				exit(1);
			}
			$data =~s/,\s*$//;
                        $data .= qq( WHERE $where );
                        $data=~s/;//g; # I don't want to risk it (maybe I should just escape them?)
                        my($query)='UPDATE ip SET ' . "$data";
			#warn($query);
                        my($sth)=($self->{dbh})->prepare($query) or croak("Can't connect to the database");
                        $sth->execute() or croak("Can't execute query: $query $DBI::errstr $!");
			# if we have updated more than one row we have a problem [ it would be nice to record this in a panic.log ]
                        #$values->{return} = "IP address updated by you <!--($values->{pe_id})-->";
                        $values->{return} = qq(<span class="withouterror">IP address updated by you</span>);
			($self->{dbh})->do('UNLOCK TABLES') or croak ("Can't release the table locks");
                        return(0);
                }
        $values->{return} = qq|<span class="withouterror">You seem to be trying to replace or update an existing IP entry by altering another - you may be the victim or a race condition, but probably you have made a mistake, (a clash of ip address and network with existing entry) or you are messing about</span> $exit_code <br/> <span class="error">Update NOT saved - Your update has NOT been saved</span>|;
	return(1);
}

1;

