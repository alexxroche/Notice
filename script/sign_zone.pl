#!/usr/bin/perl
#sign_zone.pl" ver 0.1 20101023 alexx

# quick script to sign zonefiles - I have this on a server with no external network access
#  I pull the zones over using rsync/scp wrapped in a script, use this to sign them and then
#  push the signed zones and public keys back to the master DNS server
#
# if the zone has changed we sign, otherwise the only reason to touch a zone is when a key
# enters its roll-over phase (or is already in it)

# all this because zonesigner --genkeys --usensec3 alexx.net did not work



# This makes a few presumptions:
# 1. you have a collection of zonefiles written to the filesystem
# 2. and a single file that refers to them
# 3. that there is not TDL .signed (oh $deity help us! Nooooo)
# 4. you want ALL zones signed
# 5. that you want the keys rolled before they expire
#	(for now I'm using the SOA values to determin that)
# 6. you have ldns installed 
#   ( until someone else writes the dnssec-keygen, dnssec-signzone code)
# 7. We will be using the active-passive key rolling system
# 8. This script will run at least once a week, (possibly many times a day)
# 9. (some checks but) you are only writing VALID zonesfiles into the target path

# remember that the zonesfiles might be on a NFS mount being signed by a number of servers
# so we have to use the keys as a soft lock and always have a valid $zones_conf

use strict;
# just comment these next two lines if you are not using
# Notice, and hardcode the options
use Notice::DNS;
my $notice = new Notice::DNS;

###########
# options #
###########

# for bind9 I had $nsd_basepath set to '/var/named/'
# but now that i've moved to nsd3 it is '/etc/nsd/'
my $nsd='nsd'; # moved on from BIND9 for auth name service 
my $zone_rem = ';'; #REM inside of a zonefile
my $nsd_basepath = $notice->nsd_basepath('ZERO');
# should pull these from the DB as well.
my $nsd_confpath = $nsd_basepath . 'conf/';
my $nsd_zonepath = $nsd_basepath . 'zones/';
my $zones_conf = 'zones.conf';
my %opt=(D=>0); #global debug value
$opt{keep_ds}=1;
my %alg2no=('hmac-sha1'=>158,158=>'hmac-sha1','RSASHA1_NSEC3'=>'007','007'=>'RSASHA1_NSEC3');
my $algorithm_number = $alg2no{RSASHA1_NSEC3}; #the algorithm we are using (might need seperate ones for ksk and zsk
# We need to set some buffer between creating  new passive key and turning it into the active
#
# ( 1*TTL to update the DS in the parent
#   2*TTL for the parent to propergate
#   2*TTL for our system to propergate ) 
# these are still being checked - really we need to know the TTL for the parent for $key_roll
my $ksk_buffer=5;
my $zsk_buffer=2; # what should this be?

# cat /proc/sys/kernel/random/poolsize  on one of my test servers (debian) reported 4096 but munin graphed an average of 150 bytes

my $keygen_timeout=60; #seconds (might need to be more on a system with an average of 150 bytes of entropy
my $kskgen_timeout=15; #seconds (might need less time on a system with a good source of entropy)
my $zskgen_timeout=30; #seconds

my $zsk_period = 28; # how many days ksk are vaild for by default
my $ksk_period = 300; # NOTE this should be up in the config section at the top


############
# /options #
############

$|=1;
my $start = `date +%Y%m%d%H%M%S`; chomp($start);
my $this_year = `date +%Y`; chomp($this_year);
my $this_month = `date +%m`; chomp($this_month);
my $this_day = `date +%d`; chomp($this_day);
my $this_hour = `date +%H`; chomp($this_hour);
my $this_min = `date +%M`; chomp($this_min);
my $this_sec = `date +%S`; chomp($this_sec);
my %zones; #all the zone data
my %sign;  #just the ones we have to sign

sub help{
        print "Usage: $0 [-d|--help][-f][-b] [domain_name] [account_id]\n
	this will sign published zones files
		If keys are needed, missing or out-of-date then this will
		create them.
        The default action is to sign all unsigned zones
        if a zone is provided as an argument it will sign that zonefile
        if an account id is provided then the domain has to be enabled and under
                that account (or its children)
        if an account is provided then all zones for that account will be published
	-r report
		number of zones on system
		account with max zones
		number of signed zones
	  (if an account or a domain_name is listed then it reports the key status)
	-f force rebuild of config (and notify key) even if no changes to zone
	-d increment the debug level
	-b backup the existing keys (off by default )
	\n
	G: good debug message
	r: reading a file
	w: writing a file
	E: fatal error - exiting
	e: non-fatal error
	a: action/add
	u: update
\n";
        print "Copyright 2009-2010 Cahiravahilla publications\n"; 
        exit(0);
}

sub check_pwd {
     #maybe it is in the cwd/pwd
	# we might get two files
    my $key_name = shift;
    my $destination = shift; #where to move the file(s) if found
    my $type = shift;
    unless($type){ $type = 'notify';}
    my $this_key; #the string
    my $ls_args = '-t';
    my $fl_end = '.key';
    if($type eq 'zsk'){
	$ls_args='-rS';
	$fl_end = '.private';
    }elsif($type eq 'ksk'){
	$ls_args='-S';
	$fl_end = '.private';
    }
    #my @in_cwd = split(/\s+/, `ls -t K${name}.+${algorithm_number}+*.key`);
    print "SEARCH pwd ls $ls_args $key_name*$fl_end\n" if $opt{D}>=5;
    my @files = `ls $ls_args $key_name*$fl_end 2>/dev/null`;
    foreach my $file (sort @files){
        chomp($file);
        next unless $file;
        if(-f "$file"){
                last;
        }else{
                sleep 1;
        }
    }
	# yes we are doing the same thing again. This is a braces and belt situation for when
	# we have just triggered keygen. I should deal with this with a better timeout but
	# this seems to work for now. Someone else can test/debug and fix this if they find
	# a better solution.
    #unless( -f "$key_name*"){ print "checking for $key_name.*key\n" if $opt{D}>=1; sleep 1; }
    my @in_cwd = split(/\s+/, `ls $ls_args $key_name*$fl_end 2>/dev/null`);
    # if we want the last one just change the ls -t to ls -tr
    if($in_cwd[0]=~m/$key_name/){
        print "maybe its in the cwd/pwd ls $key_name*.key\n" if $opt{D}>=2;
        chomp($in_cwd[0]);
        print "Found IT! its_in_pwd $in_cwd[0]\n";
        my $found_key = `awk '{print \$NF}' $in_cwd[0]`;
        print "mv $in_cwd[0] $destination\n" if $opt{D}>=2;
        `mv $in_cwd[0] $destination`;
	unless($type eq 'notify'){
	  # if we want to preserve the DS files
 	  if($opt{keep_ds}){
		my $mv_ds = $in_cwd[0];
		$mv_ds=~s/private$/ds/;
		print "mv $mv_ds $destination\n" if $opt{D}>=2;
		`mv $mv_ds $destination` if $opt{D}>=0;
	  }
	}
	unless($type eq 'ksk'){
        	print "rm -f $key_name*\n " if $opt{D}>=2;
        	`rm -f $key_name*`; #don't need the others
	}
        $this_key = $found_key;
        chomp($this_key);
        print "$key_name set to $this_key<<\n" if $opt{D}>=2;
    }else{
          print "$in_cwd[0] was probably already moved\n" if $opt{D}>=5;
    }
   return ($this_key,"$in_cwd[0]");
}

sub replace_line_in_file {
	my $file = shift;
	my $match = shift;
	my $replace = shift;
	my $done = shift;
	open (OCONF, "<", "$file");
        open (NCONF, ">", "$file$$");
        while(<OCONF>){
            if($_=~m/$match/){
		if($replace){
		    if($replace=~m/^\/(.+)\/$/){
			my $regexp = $1;
			$replace = $_;
			$replace=~s/$match/$regexp/;
		    }
		    print "replacing $match with $replace in $file\n";
                    print NCONF $replace;
		    $done++;
		}
            }else{
                print NCONF $_;
            }
        }
        close(OCONF);
	unless($done){	print NCONF $replace if $replace; }
        close(NCONF);
        rename("$file$$","$file");
}

sub add_record {
        my $zf = shift;
        my $kfn = shift;
        my $type = shift;
	$type = $zone_rem . $type;
        unless($type){ print "E: no type for $zf\n"; exit; }
        unless($kfn=~m/K.{10,}/){ print "E: $kfn isn't long enough to be the name of a key file\n"; exit; }
        my $now = `date +%Y%m%d%H%M%S`;
        my $comment = $type . '|%|' . $kfn . '|%|' . $now;
        print "$comment" if $opt{D}>=2;
	replace_line_in_file($zf,$type,$comment);
}

# my::Getopt
for(my $args=0;$args<=(@ARGV -1);$args++){
        if    ($ARGV[$args]=~m/^-+h/i){ &help; }
        elsif ($ARGV[$args] eq '-d'){ $opt{D}++; }
        elsif ($ARGV[$args] eq '-f'){ $opt{force}++; }
        elsif ($ARGV[$args] eq '-i'){ $opt{insane}++; }
        elsif ($ARGV[$args] eq '-r'){ $opt{report}++; }
        elsif ($ARGV[$args] eq '-b'){ $opt{backup_existing}++; }
        elsif ($ARGV[$args]=~m/^\d+(\.\d+)*$/){ $opt{ac_id}=$ARGV[$args]; }
        elsif ($ARGV[$args]=~m/\w+\.\w+/){	$opt{do_name}=$ARGV[$args]; }
        else{ print "what is this $ARGV[$args] you talk of?\n"; &help; }
}

print "Starting: $start\n" if $opt{D}>=1;
# get a list of zones to sign
open (OCONF, "<", "$nsd_confpath$zones_conf");
my $count=1;
SLURP: while(<OCONF>){

 if($nsd eq 'nsd'){
  next SLURP if($opt{do_name} && $_!~m/$opt{do_name}/); # we might just want to sign one zone
  next SLURP if($opt{ac_id} && $_!~m/$opt{ac_id}/); # we might just want to sign one zone
   # if($_=~m/^include: "?(.+\/)(.+).signed/){
	#$zones{$count}{do_location}= $1;
	#$zones{$count}{do_name}= $2;
	#$zones{$count}{signed}=1;
	#if(-f "$zones{$count}{do_location}$zones{$count}{do_name}"){
#		print "u: $zones{$count}{do_name} is signed" if $opt{D}>=2;
#		unless($opt{insane}){ print " - will check keys" if $opt{D}>=2; }
#		print "\n" if $opt{D}>=2;
#	}else{
#		print "e: $zones_conf says $zones{$count}{do_location}$zones{$count}{do_name} is signed but it does not exist\n";
#		#NTS so we make a note and clean up the $zones_conf file
#	}
#    } #we don't change the zones_conf we update each config for each zone!
#    els
     if($_=~m/^include: "?(.+\/)([^"]+)"?/){
	$zones{$count}{do_location}= $1;
        $zones{$count}{do_name}= $2;
	print "checking: $zones{$count}{do_location}  $zones{$count}{do_name}\n" if $opt{D}>=1;
	if(-f "$zones{$count}{do_location}$zones{$count}{do_name}"){
	     my $signed = `grep zonefile $zones{$count}{do_location}$zones{$count}{do_name}`;
		chomp($signed);
	     #print qq |checking m/".*$zones{$count}{do_name}.signed"/\n|;
	     if($signed=~m/$zones{$count}{do_name}.signed/){
		print "looks like $zones{$count}{do_name} is already signed\n" if $opt{D}>=1;
		# check that the zonefile exists
	     }elsif($signed=~m/".*\/$zones{$count}{do_name}"/){
		print "a: $zones{$count}{do_name} needs signing ($signed)\n" if $opt{D}>=1;
	     }
	}else{
		print "e: $zones_conf says $zones{$count}{do_location}$zones{$count}{do_name} exists but I can't find it\n";
#		#NTS so we make a note and clean up the $zones_conf file
	}
    }elsif($_=~m/^include:([^\s]+)"?/){
	print "E: NEED a space after include: $1 breaks the config\n";
	exit(1);
    }else{
	print "e: $_" if $opt{D}>=1;
    }
  }else{
	print "someone else will have to write the BIND9 version\n";
	exit;
  }
    $count++;
}
close(NCONF);

my @key_types = ('ksk_active', 'zsk_active', 'ksk_passive', 'zsk_passive');

my $output=''; # suppress ldns- output (normally this should only report errors)
#$output =' 2>\&1' unless $opt{D}>=1;
$output =' 2>/dev/null' unless $opt{D}>=1;
$output.=' 1>/dev/null' unless $opt{D}>=2;

sub keygen{
        my $zone = shift;
        my $type = shift;
        my $algorithm = shift;
        my $size = shift;
        my $dev_random = shift;
        my $ksk;
        unless($type){ $type='zsk'; }
        unless($algorithm){
            if($type eq 'notify'){
                $algorithm = 'hmac-sha1';
            }elsif($type eq 'zsk'){
                $algorithm = 'RSASHA1_NSEC3';
            }elsif($type eq 'ksk'){
                $algorithm = 'RSASHA1_NSEC3';
            }
        }
        if($type eq 'notify'){
                unless($size){ $size='160';}
        }elsif($type eq 'zsk'){
                unless($size){ $size='1024';}
        }elsif($type eq 'ksk'){
                $ksk='-k';
                unless($size){ $size='2048';}
        }
	my $now = `date +%Y%m%d%H%M%S`; chomp($now);
        print "Creating a $type key of size $size using $algorithm for $zone ($now)\n";
	my $gen='';
        eval { 
                local $SIG{ALRM} = sub {die "alarm\n"};
                alarm $keygen_timeout;
        	$gen = `ldns-keygen -a $algorithm -b $size $ksk $zone`;
		print "GEN says: $gen\n" if $opt{D}>=0;
                alarm 0;
        };
	if ($@) {
               print "e: $zone ldns-keygen failed: $@\n" unless $@ eq "alarm\n";
        }else{
               print "ldns-keygen $zone done\n";
        }
        return chomp($gen);
}


ZONE: foreach my $this (keys %zones){

	my $name = $zones{$this}{do_name};
	if($opt{report}){
	    # this is just cheating for now. Eventually this will become external-check
	    # and report will just report local information
		`ldns-rrsig $name`; next ZONE; 
	}
	my $path =  $zones{$this}{do_location};
	$path=~s/$nsd_confpath/$nsd_zonepath/;
	my $zonefile =  $path . $name;
	print "zf: $zonefile\n" if $opt{D}>=5;
	next ZONE unless(-f $zonefile);
	print "----------------------------------------------------------------------\n" if $opt{D}>=2;
	print "zonefile: $zonefile\n" if $opt{D}>=2;

   # find the data on the keys for each zone

	#print "\@zone_rem = `grep '^;' $zonefile`\n" if $opt{D}>=2;
	#my @zone_rem = split/\n/, `grep '^;' $zonefile`;
	my @zone_rem;
	open(ZONE,"<",$zonefile);
	my $in_soa=0;
	WHILE: while(<ZONE>){ 
		$_=~s/\s*\n$//; #better than chomp
		if($in_soa && $_=~m/\)/){ $_=~s/\s*;.*$//; $_=~s/\s*/ /; $zones{$this}{SOA} .= $_; $in_soa=0; }
	   	elsif($_=~m/^;(.{3}_(active||passive))/){ 
			#push @zone_rem,$_; 
			my $key_type = $1;
                        @{ $zones{$this}{keys}{$key_type} } = split (/\|%\|/, $_);
			print "FOUND: ($key_type) $zones{$this}{keys}{$key_type}[1] created $zones{$this}{keys}{$key_type}[2]\n" if $opt{D}>=2;
                        #$zones{$this}{keys}{$key_type} .= split (/\|%\|/, $_);
		}
	   	elsif($_=~m/^\s*;/){ next WHILE; }
		elsif($_=~m/TTL\s*(\d+.?)/ && !$zones{$this}{TTL}){ $zones{$this}{TTL}=$1; }
		#elsif($_=~m/SOA/ && !$zones{$this}{SOA}){ 
		elsif($_=~m/SOA/){
			$in_soa=1;
			$_=~s/\s*;.*$//;
			$zones{$this}{SOA} .= $_;
			$in_soa=0 if $_=~m/\)/;
		}elsif($in_soa){ 
			$_=~s/\s*;.*$//;
			$_=~s/\s*/ /;
			$zones{$this}{SOA} .= $_; 
			$in_soa=0 if $_=~m/\)/;
		}else{ print "$_ is no use\n" if $opt{D}>=10; }
	}
	close(ZONE);

	print "SOA for $name: $zones{$this}{SOA}\n" if $opt{D}>=2;
	print "TTL for $name: $zones{$this}{TTL}\n" if $opt{D}>=2;
	
	#print "grep done\n" if $opt{D}>=6;#DEBUG
	my $conf;

     #we need to know the expire time for the keys
	#foreach my $rem (@zone_rem){
	#    print "$rem [rem]\n" if $opt{D}>=10;#DEBUG
	#	    my $key_type = $1;
	#		print "found: $_\n" if $opt{D}>=1;
	#		@{ $zones{$this}{keys}{$key_type} } = split (/\|%\|/, $_);
	#	}

   #check which keys we have and which we need to create

   # calculate sensible times based on the SOA values

	if($zones{$this}{TTL}=~m/^(\d+)(\D+)$/){
		my $val = $1; my $scale = $2;
		if($scale eq 'd'){ $zones{$this}{TTL} = ( $val * 60 * 60 * 24 ); }
		print "TTL for $name is now $zones{$this}{TTL}\n" if $opt{D}>=8;
	}

	my $key_roll = $zones{$this}{TTL}*$ksk_buffer;	
	my $zone_roll= $zones{$this}{TTL}*$zsk_buffer;
	my $zone_over= $zones{$this}{TTL}*$zsk_buffer; 

	# to save on entropy/CPU/RAM/time:
	# if we have no keys we create active_ksk active_zsk
	if(!$zones{$this}{keys}){
	    print "we need both active keys for $name\n" if $opt{D}>=1;
	    #we may have created keys so check_pwd for them
	    my $key_str = "K${name}.+${algorithm_number}+";
	    my ($ksk_name,$ksk_filename) = &check_pwd($key_str,$path,'ksk');
	    my ($zsk_name,$zsk_filename) = &check_pwd($key_str,$path,'zsk');
	    #if pwd fails we check $path (where the key should be)
	    unless($ksk_filename){ 
		my $old_key_filename = $path . $key_str . '*.private';
    		print "ls -S $old_key_filename 2>/dev/null\n" if $opt{D}>=1;
    		my @files = `ls -S $old_key_filename 2>/dev/null`;
		$ksk_filename = $files[0];
		chomp($ksk_filename);
		if($ksk_filename){
			print "setting ksk to $ksk_filename\n" if $opt{D}>=1;
		}else{
			print "$ksk_filename not found in $path\n" if $opt{D}>=1;
		}
	    }
	    unless($zsk_filename){ 
		my $old_key_filename = $path . $key_str . '*.private';
    		print "ls -S $old_key_filename 2>/dev/null\n" if $opt{D}>=1;
    		my @files = `ls -rS $old_key_filename 2>/dev/null`;
		$zsk_filename = $files[0];
		chomp($zsk_filename);
		if($zsk_filename){
			print "setting zsk to $zsk_filename\n" if $opt{D}>=1;
		}else{
			print "$zsk_filename not found in $path\n" if $opt{D}>=1;
		}
	    }
	    chomp($zsk_filename);
	    chomp($ksk_filename);
	    my @zsk_stat = stat($zsk_filename);
	    my @ksk_stat = stat($ksk_filename);
	    my $zsk_file = $zsk_filename;
	    $zsk_file=~s/^.*\///;
	    my $ksk_file = $ksk_filename;
	    $ksk_file=~s/^.*\///;

   	    # If we find TWO key sets for a zone we will use key size to help guess,
	    # then the larger is probably the KSK and the smaller is the ZSK
	    my $sig_diff_size=0;
	    if($zsk_stat[7] && $ksk_stat[7]){
			print qq |SB: $sig_diff_size = `echo "(($ksk_stat[7]-$zsk_stat[7])/2)^2"\|bc`\n| if $opt{D}>=1; 
			$sig_diff_size = `echo "(($ksk_stat[7]-$zsk_stat[7])/2)^2"|bc`; 
			chomp($sig_diff_size);
	    }
	    if( $sig_diff_size && (($ksk_stat[7]+$zsk_stat[7]) < $sig_diff_size) ){
			# we use these keys
		print  $ksk_stat[7]+$zsk_stat[7] . " < $sig_diff_size so it looks like we\n" if $opt{D}>=1;
		print "found the keys ($ksk_filename, $zsk_filename) - they should now be over in the $path for $name\n" if $opt{D}>=1;
		# (using the mtime as the creation data)
		#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
		my @zsk_age = localtime($zsk_stat[9]);
		my @ksk_age = localtime($ksk_stat[9]);
		my $this_sste = `date +%s`; chomp($this_sste);
		$zsk_age[5]+=1900;
		$ksk_age[5]+=1900;
		$zsk_age[4]+=1;
		$ksk_age[4]+=1;
		my $zsk_lag = (365 * ($this_year - $zsk_age[5]) ) + (31 * ($this_month - $zsk_age[4]) ) + ($this_day - $zsk_age[3]);
		print "zsk created $zsk_age[5] $zsk_age[4] $zsk_age[3] $zsk_age[2]:$zsk_age[1]:$zsk_age[0] ($zsk_stat[9])\n" if $opt{D}>=1;
		print "ksk created $ksk_age[5] $ksk_age[4] $ksk_age[3] $ksk_age[2]:$ksk_age[1]:$ksk_age[0] ($ksk_stat[9])\n" if $opt{D}>=1;
		my $gen_lag = 'Y:' . ($this_year - $zsk_age[5]);
		$gen_lag .= ' m:' . ($this_month - $zsk_age[4]) . " $this_month - $zsk_age[4] ";
		$gen_lag .= ' d:' . ($this_day - $zsk_age[3]) . " $this_day - $zsk_age[3] ";
		$gen_lag .= ' T:' . ($this_hour - $zsk_age[2]) . ':';
		$gen_lag .= ($this_min - $zsk_age[1]) . ':' . ($this_sec - $zsk_age[0]);
		print "that was $gen_lag ago\n";
		my $ksk_gen_lag = $this_sste - $ksk_stat[9];


		# we need to know how old the keys are so that we can know if they need to be rolled	

		my @kgl;
		if($ksk_gen_lag < 60){ $ksk_gen_lag .= " seconds"; }
		elsif($ksk_gen_lag < 3600){ $ksk_gen_lag = int($ksk_gen_lag/60) . ' Minutes and ' . ($ksk_gen_lag - ( 60 * int($ksk_gen_lag/60))); }
		elsif($ksk_gen_lag < 86400){ 
			$ksk_gen_lag = int($ksk_gen_lag/(60*60)) . ' Hours ' . ($ksk_gen_lag - ( 60 * int($ksk_gen_lag/60))) . ' mins '; 
		}else{ 
			$kgl[0] = $ksk_gen_lag;
			$kgl[1] = int($kgl[0]/(60*60*24)); $kgl[0] -= ($kgl[1]*60*60*24);
			$kgl[2] = int($kgl[0]/(60*60));	$kgl[0] -= ($kgl[2]*60*60);
			$kgl[3] = int($kgl[0]/60); $kgl[0] -= ($kgl[3]*60);
			$ksk_gen_lag = "$kgl[1] days $kgl[2] hours $kgl[3] mins $kgl[0] seconds";
		}
		print "that was $ksk_gen_lag ago\n";
		my $ksk_lag = $kgl[1];

		if($ksk_lag >= $key_roll){
			# we need a new ksk
			print "ksk is too old\n" if $opt{D}>=1;
			print "E: you have not written this part\n"; exit(1);
		}else{
			print "ksk is new enough\n" if $opt{D}>=1;
			 # make a note of each key in a comment at the end of the zonefile
                	print "adding to $zonefile\n" if $opt{D}>=1;
                	&add_record($zonefile,$ksk_file,'ksk_active');
		}
		if($zsk_lag >= $zone_roll){
			# we need a new zsk 
			print "zsk is too old\n" if $opt{D}>=1;
			print "E: you have not written this part\n"; exit(1);
		}else{
			print "zsk is new enough\n" if $opt{D}>=1;
			# make a note of each key in a comment at the end of the zonefile
                	print "adding to $zonefile\n" if $opt{D}>=1;
                	&add_record($zonefile,$zsk_file,'zsk_active');
		}
                # make a record of this zone so that we know to sign it later
		$sign{$name}{zonefile} = $zonefile;
		$sign{$name}{keys} = "$zsk_file $ksk_file";

	    }else{
		# if they are the same size or not significantly different in size
		# we scrub them and create some new ones (we /could/ try to work out which we have and create the other one if we have just one
		# but for now I'm just going to archive that key and create two new ones.)

		# NOTE if we found ONE of the keys inside of the zonefile we could just create the other...
		if(!$zsk_filename && !$ksk_filename){
			print "w: both zsk and ksk" if $opt{D}>=1;
		}elsif(!$zsk_filename){
			print "w: zsk" if $opt{D}>=1;
		}elsif(!$ksk_filename){
			print "w: ksk" if $opt{D}>=1;
		}
		if( !$ksk_filename || !-f $ksk_filename  || !$zsk_filename || !-f $zsk_filename ){
			print " are missing or not stat'ly different ( $ksk_stat[7] > $zsk_stat[7] ) in size\n" if $opt{D}>=1;

			# clean up 
			`rm $ksk_filename $zsk_filename 2>/dev/null 1>/dev/null` unless $opt{insane}>=1;
			($ksk_filename,$zsk_filename) = ('',''); # blank the names
		}else{
			print " ($sig_diff_size) ksk and zsk ARE stat'ly different ( $ksk_stat[7] > $zsk_stat[7] )\n" if $opt{D}>=1;
		}

		# create new key(s)

		my $ksk_gen = &keygen($name,'ksk');
		if($ksk_gen){
			print "we probably just have to wait for ldns-keygen to finish\n" if $opt{D}>=0;
		}else{
		    print "$ksk_gen ksk for $name created\n" if $opt{D}>=1;
		    # so we wait for it to hit out filesystem (even with the additional entropy in centos 5.5 we might have to wait
		    my $ksk_str = "K${name}.+${algorithm_number}+";
		    eval { 
	                local $SIG{ALRM} = sub {die "alarm\n"};
	                alarm $kskgen_timeout;
			while($ksk_str){
            			($ksk_name,$ksk_filename) = &check_pwd($key_str,$path,'ksk');
				if($ksk_filename=~m/$ksk_str/){ $ksk_str=''; }
			}
	                print "ksk while eval says: $ksk_filename\n" if $opt{D}>=0;
			alarm 0;
		    };
		    if ($@) {
			print "e: ksk keygen says it finished without error, but we don't see the key $@\n" unless $@ eq "alarm\n";
			print "timed out ksk $ksk_filename\n" if $@ eq "alarm\n";
			sleep $kskgen_timeout if $@ eq "alarm\n";
		    }else{		
			my $now = `date +%Y%m%d%H%M%S`; chomp($now);
			# we should be able to calculate the averate key gen time and update the timeout
			print "ldns-keygen ksk $name done good ($now)\n";
		    }

		}
		# so now that the keys have been created we move them into the zone folder next to the zonefile
		
		# make a note of each key in a comment at the end of the zonefile
		# make a record of this zone so that we know to sign it later
		
		my $zsk_name = &keygen($name);
		if($zsk_name){
                        print "we probably just have to wait for ldns-keygen to mkzsk\n" if $opt{D}>=1; 
                }else{
                    print "$zsk_name zsk for $name created\n" if $opt{D}>=1;
		    # so we wait for it to hit out filesystem (even with the additional entropy in centos 5.5 we might have to wait
                    my $zsk_str = "K${name}.+${algorithm_number}+";
                    eval {
                        local $SIG{ALRM} = sub {die "alarm\n"};
                        alarm $zskgen_timeout;
                        while($zsk_str){
                                ($zsk_name,$zsk_filename) = &check_pwd($key_str,$path,'zsk');
                                if($zsk_filename=~m/$zsk_str/ && $zsk_filename ne $ksk_filename){ $zsk_str=''; }
				# if the ksk has just been made check_pwd might find the same key twice!
                        }
                        print "zsk while eval says: $zsk_filename\n" if $opt{D}>=0;
                        alarm 0;
                    };
                    if ($@) {
                        print "e: zsk keygen says it finished without error, but we don't see the key $@\n" unless $@ eq "alarm\n";
			print "timed out zsk $zsk_filename\n" if $@ eq "alarm\n";
			sleep $zskgen_timeout if $@ eq "alarm\n";
                    }else{
                        print "ldns-keygen zsk $name done good\n";
                    }

                }

		# so now that the keys have been created we move them into the zone folder next to the zonefile
		my $ksk_file = $ksk_filename;
		$ksk_file=~s/^.*\///;
		chomp($ksk_file);
		my $zsk_file = $zsk_filename;
		$zsk_file=~s/^.*\///;
		chomp($zsk_file);
		unless($ksk_file){
                	my $old_key_filename = $path . $key_str . '*.private';
                	print "ls -S $old_key_filename 2>/dev/null\n" if $opt{D}>=1;
                	my @files = `ls -S $old_key_filename 2>/dev/null`;
                	$ksk_file = $files[0];
			print "found ksk: $ksk_file\n" if $opt{D}>=1;
			$ksk_file=~s/^.*\///;
			chomp($ksk_file);
            	}
            	unless($zsk_file){
            	    my $old_key_filename = $path . $key_str . '*.private';
            	    print "ls -S $old_key_filename 2>/dev/null\n" if $opt{D}>=1;
            	    my @files = `ls -rS $old_key_filename 2>/dev/null`;
            	    $zsk_file = $files[0];
		    $zsk_file=~s/^.*\///;
		    print "found zsk: $zsk_file\n" if $opt{D}>=1;
		    chomp($zsk_file);
            	}

		if(-f "$ksk_file"){
			print "m: mv $ksk_file $path\n" if $opt{D}>=1;
			`mv $ksk_file $path` unless $opt{D}>=2;
		}
		if(-f "$zsk_file"){
			print "m: mv $zsk_file $path\n" if $opt{D}>=1;
			`mv $zsk_file $path` unless $opt{D}>=2;
		}
		unless( -f "$path$zsk_file" && -f "$path$ksk_file"){
			if( ! -f "$path$zsk_file"){
				print "e: missing zsk ($path$zsk_file) for $name\n" if $opt{D}>=0;
			}
			if( ! -f "$path$ksk_file"){
				print "e: missing ksk ($path$ksk_file) for $name\n" if $opt{D}>=0;
			}
			exit if $opt{D}>=4;
			next ZONE;
		}

		# make a note of each key in a comment at the end of the zonefile
		print "adding to $zonefile\n" if $opt{D}>=1;
		&add_record($zonefile,$ksk_file,'ksk_active');
		&add_record($zonefile,$zsk_file,'zsk_active');

		# make a record of this zone so that we know to sign it later
		$sign{$name}{zonefile} = $zonefile;
		$sign{$name}{keys} = "$zsk_file $ksk_file";
		# we could overload $zones by removing all data that does not need singing, but this seems safer
		next ZONE;
	     } # end of "found keys in cwd" else
		
	}else{ # we DO have keys for this zone listed in the zonefile

	# NTS we are using the comments in the zonefile as a database for the zonefile
	# these could be wrong or lies! we should check the timestamp of the files listed to make sure they

	   my $ksk_filename = $path;
	   my $zsk_filename = $path;
	   if($zones{$this}{keys}{ksk_active}){
	   	$ksk_filename .= $zones{$this}{keys}{ksk_active}[1];
		print "$name: ksk_active = $zones{$this}{keys}{ksk_active}[1] created $zones{$this}{keys}{ksk_active}[2]\n" if $opt{D}>=1;
		# lets check
	    	my @ksk_stat = stat($ksk_filename);
		my @ksk_age = localtime($ksk_stat[9]);
                $ksk_age[5]+=1900;
                $ksk_age[4]+=1;
                my $ksk_lag = (365 * ($this_year - $ksk_age[5]) ) + (31 * ($this_month - $ksk_age[4]) ) + ($this_day - $ksk_age[3]);
		my $ksk_date = $ksk_age[5].$ksk_age[4].$ksk_age[3].$ksk_age[2].$ksk_age[1].$ksk_age[0];
		if($zones{$this}{keys}{ksk_active}[2] ne $ksk_date){
			print "[ksk] file-timestamp: $ksk_date ne zonefile: $zones{$this}{keys}{ksk_active}[2]\t $name $ksk_filename\n";
		}
	   }
	   if($zones{$this}{keys}{zsk_active}){
                $zsk_filename .= $zones{$this}{keys}{zsk_active}[1];
                print "$name: zsk_active = $zones{$this}{keys}{zsk_active}[1] created $zones{$this}{keys}{zsk_active}[2]\n" if $opt{D}>=1;
                # lets check
                my @zsk_stat = stat($zsk_filename);
                my @zsk_age = localtime($zsk_stat[9]);
                $zsk_age[5]+=1900;
                $zsk_age[4]+=1;
                my $zsk_lag = (365 * ($this_year - $zsk_age[5]) ) + (31 * ($this_month - $zsk_age[4]) ) + ($this_day - $zsk_age[3]);
                my $zsk_date = $zsk_age[5].$zsk_age[4].$zsk_age[3].$zsk_age[2].$zsk_age[1].$zsk_age[0];
                if($zones{$this}{keys}{zsk_active}[2] ne $zsk_date){
                        print "[zsk] file-timestamp: $zsk_date ne zonefile: $zones{$this}{keys}{zsk_active}[2]\t $name $zsk_filename\n";
                }
	   }

	   # check that the key files really exist
	
	# are something close to the gen_time listed in the zonefile?

	  # NTS here we calculate the are of the active (and passive) keys

	# if we are within ($ksk_expire - $zone_roll) and don't have passive_ksk we create one

		# NTS these timespan checks are flawed
		if( 
		   (
			(!$zones{$this}{keys}{ksk_passive}) &&
			( ( ($zones{$this}{keys}{ksk_active}[2] + ($key_roll*60*60*24) ) - $start ) <=0) 
		   ) || (
			# we might not have a key expirty so use the creation date + 28 days
			(!$zones{$this}{keys}{ksk_passive}) &&
			($start - ($zones{$this}{keys}{ksk_active}[2] + $ksk_period) <=0)
		   )
		)
		{
			print "we need a passive ksk for $name\n" if $opt{D}>=1;
			# debug
			print "because either missing ($zones{$this}{keys}{ksk_passive}) or\n" if $opt{D}>=1;
			print "start: $start - age ( $zones{$this}{keys}{ksk_active}[2] + key_roll $key_roll*60*60*24) <=0\n" if $opt{D}>=1;
			print "OR we failed to collect the mtime for the file so we have:\n" if $opt{D}>=1;
			print " ($zones{$this}{keys}{ksk_active}[2] + $ksk_period) \n" if $opt{D}>=1;

		}
	# elsif we HAVE ksk_passive to turn into the active key
		elsif(
		   (
			$zones{$this}{keys}{ksk_passive} &&
			(($start - ($zones{$this}{keys}{ksk_active}[2] + $ksk_buffer)) <=0)
		   )
		)
		{
			print "passive needs to be promoted\n" if $opt{D}>=1;
		}
	# elsif we HAVE ksk_passive that was the active key and now needs to be removed:
		elsif( 
		   (
			$zones{$this}{keys}{ksk_passive} &&
			(($start - ($zones{$this}{keys}{ksk_passive}[2])) <=0)
		   )
		)
		{
			print "We have to expire this passive key (that was the former active key)\n" if $opt{D}>=1;
		}

			################################################################
			# ok thats ksk checked, but what about the Zone Signing Keys ? #
			################################################################
	
	# if we are within ($ksk_expire - $zone_roll) and don't have passive_ksk we create one
		 if( 
                   (
                        (!$zones{$this}{keys}{zsk_passive}) &&
                        ($start - ($zones{$this}{keys}{zsk_active}[2] + $key_roll) <=0)  
                   ) || (
                        # we might not have a key expirty so use the creation date + 28 days
                        (!$zones{$this}{keys}{zsk_passive}) &&
                        ($start - ($zones{$this}{keys}{zsk_active}[2] + $ksk_period) <=0)
                   )
                )
                {
                        print "we need a passive zsk for $name\n" if $opt{D}>=1;
                }
	# elsif we HAVE zsk_passive and ($zsk_active_expires + $zone_over )
		elsif(
		   (
                        $zones{$this}{keys}{zsk_passive} &&
                        (($start - ($zones{$this}{keys}{zsk_active}[2] + $zsk_buffer)) <=0)
                   )
		)
                {
                        print "passive needs to be promoted\n" if $opt{D}>=1;
                }
        # elsif we HAVE zsk_passive that was the active key and now needs to be removed:
                elsif(
		   (
                        $zones{$this}{keys}{zsk_passive} &&
                        (($start - ($zones{$this}{keys}{zsk_passive}[2])) <=0)
                   ) 
		)
                {
                        print "We have to expire this passive key (that was the former active key)\n" if $opt{D}>=1;
                }

	  # so the keys are dealt with... but do we have a signed zonefile?
	  my $signed_exists = `ls $zonefile.signed 2>/dev/null`;
 	  unless($signed_exists){ 
		$sign{$name}{zonefile} = $zonefile;
		my $now = `date +%Y%m%d%H%M%S`; chomp($now);
		print "no signed zonefile for $name so..\n" if $opt{D}>=3;
		#foreach my $kt (keys %{ $zones{$this}{keys} } ){
		#	print "$kt \n";
		#}
		if(-f "$path$zones{$this}{keys}{zsk_active}[1]" || -f "zones{$this}{keys}{zsk_active}[1]"){
		    $zones{$this}{keys}{zsk_active}[1]=~s/.private$//;
		    print " zsk_active: $zones{$this}{keys}{zsk_active}[1] $name\n" if $opt{D}>=1;
		    if(-f "zones{$this}{keys}{zsk_active}[1]"){
			$sign{$name}{keys} = " $zones{$this}{keys}{zsk_active}[1] ";
		    }else{
			$sign{$name}{keys} = " $path$zones{$this}{keys}{zsk_active}[1] ";
		    }
		    $sign{$name}{has_zsk}=1;
		}
		if(-f "$path$zones{$this}{keys}{ksk_active}[1]" || -f "zones{$this}{keys}{ksk_active}[1]"){
		    $zones{$this}{keys}{ksk_active}[1]=~s/.private$//;
		    print " ksk_active: $zones{$this}{keys}{ksk_active}[1] $name\n" if $opt{D}>=1;
		    if(-f "zones{$this}{keys}{ksk_active}[1]"){
			$sign{$name}{keys} .= "$zones{$this}{keys}{ksk_active}[1] ";
		    }else{
			$sign{$name}{keys} .= "$path$zones{$this}{keys}{ksk_active}[1] ";
		    }
		    if($sign{$name}{has_zsk}){ $sign{$name}{has_ksk}=1; }
		    else{ delete($sign{$name}); print "e: missing zsk for $name\n"; }
		}
	  } 

	} #end of else (we do have some key)
	#$zones{$zone}{keys}{$type}{date} = `date +%Y%m%d%H%M%S`; #need to know when

#	$zones{$zone}{active_ksk}  is the explicit path of the ksk e.g. /etc/nsd/zones/1/master/a/Kalexx.net.+007+06549
#	$zones{$zone}{active_zsk}  is the explicit path of the zsk

} # end of key creation for each zone - now we should just have a list of the zones that need signing in %zones

#exit unless $opt{D}==0; # just while we debug the key generation we will not sign things

foreach my $zone (keys %sign){

	# we can probably just overloda %zones and have the keys as the name of the zone

	print "$zone needs signing using $sign{$zone}{keys}\n" if $opt{D}>=2;

	my $signed;
	#my $name = $zones{$zone}{do_name};
	my $name = $zone;
	my $zonefile = $sign{$zone}{zonefile};
	#if($zones{$zone}{zsk_this_zone}){
	if($sign{$zone}{keys}){
	    $sign{$zone}{keys}=~s/\.private\.private/.private/; #bug in my code somewhere
   # sign the zone
	    #$signed = `ldns-signzone -n -o $name  $zonefile $zones{$zone}{active_ksk} $zones{$zone}{active_zsk}`;
	    print "ldns-signzone -n -o $name  $zonefile $sign{$zone}{keys}\n";
	    $signed = `ldns-signzone -n -o $name  $zonefile $sign{$zone}{keys} 2>\&1`;
	}elsif($zones{$zone}{key_roll}){
	    #$sign{$zone}{key_roll}=~s/\.private\.private/.private/; #might have the same bug in my code somewhere
	    #$signed = `ldns-signzone -n -o $name  $zonefile $zones{$zone}{active_ksk} $zones{$zone}{active_zsk} $zones{$zone}{passive_ksk}`;
	    $signed = `ldns-signzone -n -o $name  $zonefile $sign{$zone}{key_roll} 2>\&1`;
	}
	chomp($signed);
	if($signed){
		print qq |e: failed to sign $name so um, fix that ($signed)\n| if $opt{D}>=1;
	}else{
		#update the $conf file for  s/\/$name"/$name.signed"/
		my $match =qq |zonefile: "$zonefile"|;
		my $replace =qq |\tzonefile: "${zonefile}.signed"|;
		my $conf_file = $zonefile; $conf_file=~s/^$nsd_zonepath/$nsd_confpath/;
		print qq |$signed $name so update $conf_file s/$match/$replace/\n| if $opt{D}>=0;
		replace_line_in_file($conf_file,$match,$replace);
	}
}

# clean up: we move expired keys into an archive (call this archive /dev/null if you like)

# ah, for that we would need a list of all valid/{in-use} keys for all zones... 
	

# if this is a secure key server then we need to send the signed zones and the public keys back to the master DNS server
# `move_zones.pl push`;
# `ssh $ns_zero '$nsdc rebuild && $nsdc reload' && $nsdc update`;
	
exit(0);
