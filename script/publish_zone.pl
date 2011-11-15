#!/usr/bin/perl
#publish_zone.pl" ver 0.1 2010 alexx

use strict;
my $script_pwd=$ENV{_}; # 
$script_pwd=~s|/([^/]*)$||;
BEGIN {
        $script_pwd = `readlink -mn $ENV{_}`;
        $script_pwd=~s|/([^/]*)$||;
        chomp($script_pwd);
}
use lib "$script_pwd";
use lib '.';
use Notice::DNS;
$|=1;
my %opt=(D=>0);
my $now = `date +%Y%m%d%H%M%S`; chomp($now);
my $notice = new Notice::DNS;
my $pe_id = 1; # set this to your notice pe_id;
my %zones;
my $local_machine = `hostname`; chomp($local_machine);
my $remove_host = 'chesca'; 
if($local_machine eq 'chesca.alexx.net' ){ $remove_host = 'sam'; }
my %slaves=(1=>{'host'=>"$remove_host",'slave_is_master'=>1,'nsd_basepath'=>'/etc/nsd/','nsd_confpath'=>'/etc/nsd/conf/'});

sub help{
        print "Usage: $0 [-d|--help][-f][-b] [domain_name] [account_id]\n
	this will publish all zonefiles 
        the default is to just publish all of them and sign them if we have a key
        if there isn't a key then it will add that to the batch process
        if a domain is provided as an argument it will publish that zone
        if an account id is provided then the domain has to be enabled and under
                that account (or its children)
        if an account is provided then all zones for that account will be published
	-d increments debug level
	-f force rebuild of config (and notify key) even if no changes to zone
		-w wipe all existing zone_config and zones files from nsd (must be used with -f
	-b backup the existing zonefile in (/etc/nsd/|/var/named)(off by default )
	-u update slaves (and reload)
	\n
	G: good debug message
	w: writing a file
	E: fatal error - exiting
	r: reading a file
\n";
        print "Copyright 2010 Cahiravahilla publications\n"; 
        exit(0);
}

sub check_pwd_for_notify_key {
     #maybe it is in the cwd/pwd
    my $key_name = shift;
    my $destination = shift;
    my $notify_key; #the string
    #my @in_cwd = split(/\s+/, `ls -t K${name}.+${algorithm_number}+*.key`);
    print "SEARCH pwd for $key_name\n" if $opt{D}>=2;
    my @files = `ls -t $key_name*.key 2>/dev/null`;
    foreach my $file (sort @files){
        chomp($file);
        next unless $file;
        if(-f "$file"){
                last;
        }else{  
                sleep 1;
        }
    }
    unless( -f "$key_name*.key"){ print "checking for $key_name.*key\n" if $opt{D}>=1; sleep 1; }
    my @in_cwd = split(/\s+/, `ls -t $key_name*.key 2>/dev/null`);
    # if we want the last one just change the ls -t to ls -tr
    if($in_cwd[0]=~m/$key_name/){
        print "maybe its in the cwd/pwd ls $key_name*.key\n" if $opt{D}>=2;
        chomp($in_cwd[0]);
        print "FOUND IT! its_in_pwd $in_cwd[0]\n";
        my $found_key = `awk '{print \$NF}' $in_cwd[0]`;
        print "getting rid of mv $in_cwd[0] $destination\n" if $opt{D}>=2;
        `mv $in_cwd[0] $destination`; #don't need the ".private"
        print "rm -f $key_name*\n " if $opt{D}>=2;
        `rm -f $key_name*`; #don't need the others
        $notify_key = $found_key;
	chomp($notify_key);
        print "notify key set to $notify_key\n" if $opt{D}>=2;
    }else{
          print "shucks $in_cwd[0] was wrong: no key\n" if $opt{D}>=2;
    }
   return ($notify_key,$in_cwd[0]);
}

sub replace_line_in_file {
	my $file = shift;
	my $match = shift;
	my $replace = shift;
	open (OCONF, "<", "$file");
        open (NCONF, ">", "$file$$");
        while(<OCONF>){
            if($_=~m/$match/){
                print NCONF $replace if $replace;
            }else{
                print NCONF $_;
            }
        }
        close(OCONF);
        close(NCONF);
        rename("$file$$","$file");
}

for(my $args=0;$args<=(@ARGV -1);$args++){
        if    ($ARGV[$args]=~m/^-+h/i){ &help; }
        elsif ($ARGV[$args] eq '-d'){ $opt{D}++; }
        elsif ($ARGV[$args] eq '-f'){ $opt{force}++; }
        elsif ($ARGV[$args] eq '-r'){ $opt{report}++; }
        elsif ($ARGV[$args] eq '-u'){ $opt{update_slaves}++; }
        elsif ($ARGV[$args] eq '-w'){ $opt{wipe}++; }
        elsif ($ARGV[$args] eq '-i'){ $opt{insane}++; } #skip sanity check
        elsif ($ARGV[$args] eq '-b'){ $opt{backup_existing}++; }
        elsif ($ARGV[$args]=~m/^\d+(\.\d+)*$/){ $opt{ac_id}=$ARGV[$args]; }
        elsif ($ARGV[$args]=~m/\w+\.\w+/){	$opt{do_name}=$ARGV[$args]; }
        else{ print "what is this $ARGV[$args] you talk of?\n"; &help; }
}
unless($opt{force}){ delete($opt{wipe}); }

# list of enabled domains
$notice->list_enabled_domains(\%zones,\%opt) unless ( $opt{update_slaves} || $opt{report} );
if($opt{D}>=5 && $opt{error}==0){
	print $opt{query} . "\n";
}

my $notice_path = $notice->notice_path;
#my $nsd_basepath = $notice->nsd_basepath('ZERO');
my $nsd_basepath = Notice::DNS::nsd_basepath('ZERO');
my $nsdc=$notice->nsdc;
# should prbably pull these from the DB as well.
my $dns_path = 'named/accounts/';
my $nsd_confpath = $nsd_basepath . 'conf/';
my $nsd_zonepath = $nsd_basepath . 'zones/';
my $zones_conf = 'zones.conf';
my $nsd_conffile = 'nsd.conf';

sub sanity {
	# again we will pull all of this from the config table
	#my $nsd_uid= $notice->nsd_uid;
	# my $httpd_uid = $notice->httpd_uid;
	#Here we check that the permissions are right on $nsd_basepath, $nsd_confpath, $nsd_zonepath
	my $nsd_db_path = '/var/lib/nsd/';
	my $nsd_logpath = '/var/log/';
	my $nsd_pidpath = '/var/run/nsd/';
	my $nsd_difpath = '/var/lib/nsd/';
	my $nsd_xfrpath = '/var/lib/nsd/';
	my $nsd_db_file = 'nsd.db';
	my $nsd_logfile = 'nsd.log';
	my $nsd_pidfile = 'nsd.pid';
	my $nsd_diffile = 'ixfr.db';
	my $nsd_xfrfile = 'ixfr.state';
	my $nsd_greet   = '.';
	my $nsd_uid='nsd';
	my $httpd_uid='www-data';

	my $basic_config=qq | database: "$nsd_db_path$nsd_db_file"\n identity: "$nsd_greet"\n logfile: "$nsd_logpath$nsd_logfile"\n|;
	$basic_config.=qq | pidfile: "$nsd_pidpath$nsd_pidfile"\n username: $nsd_uid\n xfrdfile: "$nsd_xfrpath$nsd_xfrfile"\n|;
	$basic_config.=qq | difffile: "$nsd_difpath$nsd_diffile"\n zonesdir: "$nsd_zonepath"\n include: "$nsd_zonepath$zones_conf"\n|;

	my $adv_conf=qq | 
	# xfrd-reload-timeout: 10
	# server-count: 1
	# tcp-count: 10
	# statistics: 3600
	# make sure to have pidfile and database reachable from there.
	# chroot: "/etc/nsd" |;

	# need to chect that each exists and has the right uid:gid
	if(! -d "$nsd_basepath" && -w "$nsd_confpath"){ 
		`mkdir -p $nsd_basepath`; 
		`chown $nsd_uid: $nsd_confpath`;
		`chmod 2770 $nsd_confpath`;
	}
	if(! -d "$nsd_confpath" && -w "$nsd_confpath"){ 
		`mkdir -p $nsd_confpath`;
		`chown $httpd_uid:$nsd_uid $nsd_confpath`;
		`chmod 2770 $nsd_confpath`;
	}
	if(! -d "$nsd_zonepath" && -w "$nsd_zonepath"){ 
		`mkdir -p $nsd_zonepath`;
		`chown $httpd_uid:$nsd_uid $nsd_zonepath`;
		`chmod 2770 $nsd_zonepath`;
	}
	if(! -d "$nsd_pidpath" && -w "$nsd_pidpath"){
		`mkdir -p $nsd_pidpath`;
		`chown $nsd_uid: $nsd_pidpath`;
	}
	if(! -d "$nsd_difpath" && -w "$nsd_difpath"){
		`mkdir -p $nsd_difpath`;
		`chown $nsd_uid: $nsd_difpath`;
	}
	if(! -d "$nsd_xfrpath" && -w "$nsd_xfrpath"){
		`mkdir -p $nsd_xfrpath`;
		`chown $nsd_uid: $nsd_xfrpath`;
	}
	unless(-f "$nsd_basepath$nsd_conffile"){
		open(CONF,">","$nsd_basepath$nsd_conffile") or die "Can't write the base nsd3 config $nsd_basepath$nsd_conffile\n";
		print CONF $basic_config;
		close(CONF);
	}
}

if($opt{wipe}){
	`rm -rf $nsd_confpath/*`;
	`rm -rf $nsd_zonepath/*`;
}

&sanity unless($opt{D}>=1 || $opt{insane});


ZONE: foreach my $zone (keys %zones){


	#print "$zone, $zones{$zone}{do_name}, $zones{$zone}{do_acid}, $zones{$zone}{do_location}, $zones{$zone}{do_path}\n";

	# here we do some sanity checking - the do_location must have the acid_to_path(do_acid) in it... so 
	unless($zones{$zone}{do_location}=~m/$zones{$zone}{do_acid}/){
		print "looks unclean $zones{$zone}{do_location}=~m/$zones{$zone}{do_acid} \n" if $opt{D}>=3;
		$zones{$zone}{do_location}=~s|.*/master/|master/|;
		use Notice::DB::email qw (acid_to_path);
		
		$zones{$zone}{do_location} = Notice::DB::email::acid_to_path($zones{$zone}{do_acid}) . $zones{$zone}{do_location};
		print "SANITIZED: $zones{$zone}{do_location}\n"  if $opt{D}>=3;
	}
	my $name = $zones{$zone}{do_name};
	my $conf_path = "$nsd_confpath$zones{$zone}{do_location}";
	my $new_zonefile = "$notice_path$dns_path$zones{$zone}{do_path}";
	my $new_file_exists = `ls $new_zonefile 2>/dev/null`;
	my $implicit_zonefile = "$nsd_zonepath$zones{$zone}{do_path}";
	my $existing_zonefile = "$nsd_zonepath$zones{$zone}{do_path}";
	my $existing_zonepath = "$nsd_zonepath$zones{$zone}{do_location}";
	if($new_file_exists){

	#NTS here we should search the zone list for subdomains of $name that need to be included, (probably with a new call to the DB unless we
	#NTS can do this all in memory
	
	   chomp($new_file_exists);
	   print "----------------------------------------------------------------------\n" if $opt{D}>=1;
	   print "zonefile exists: $new_file_exists \n" if $opt{D}>=2; 
	   #check for existing
	   if(-f "$existing_zonefile"){
		print "checking $existing_zonefile\n" if $opt{D}>=2;
		#check that there has been a change
		my $is_new = `diff $existing_zonefile $new_zonefile`;
		unless($is_new){ 
		   print "G: No changes to $zones{$zone}{do_name}\n" if $opt{D}>=1; 
		   # does it need signing?
		   next ZONE unless $opt{force}; 
		}
		if($existing_zonefile){
	            if($opt{backup_existing}){
			print "backing up $existing_zonefile\n" if $opt{D}>=1;
		    }
		    $zones{$zone}{existing}=1;
	        }
	   }else{
		print "FIRST publish for: $existing_zonefile $nsd_basepath $zones{$zone}{do_location}\n" if $opt{D}>=1;
		   print "creating path for zonefiles (${nsd_basepath}$zones{$zone}{do_location})\n" if $opt{D}>=1;
		   $zones{$zone}{zone_path} = `mkdir -p $existing_zonepath 2>\&1`;
		if($zones{$zone}{zone_path}){
			print qq |Can not mkdir -p $existing_zonepath "$zones{$zone}{zone_path}" (L140)\n| if $opt{D}>=1;
			next ZONE;
		}
	   }
	   if(-d "$conf_path"){
		print "$conf_path already exists\n" if $opt{D}>=2;
	   }else{
		   print "creating path for zone config (${nsd_basepath}conf/$zones{$zone}{do_location})\n" if $opt{D}>=1;
	   	   $zones{$zone}{conf_path} = `mkdir -p $conf_path`;
		if($zones{$zone}{conf_path}){
			print "Denied path creation on $conf_path\n" if $opt{D}>=1;
			next ZONE;
		}
	   }
	if($opt{D}>=13){
	   foreach my $val (keys %{ $zones{$zone} }){
		print "$val = $zones{$zone}{$val}\n";
	   }
	  exit if $opt{D}>=14;
	}

	my @zone_inc = split(/\n/, `grep -E '\\s*\\\$INCLUDE ' $new_zonefile`);
	if($zone_inc[0]){
		foreach my $inc (@zone_inc){
			# we need to replace the INC with the file
			print "e: replace $inc in $name\n" if $opt{D}>=0;
			# as we don't want to load this zone we must strip it from the $zones_conf
			my $this_match = 'include: .+\/' . $name . '\"$';
			&replace_line_in_file("$nsd_confpath$zones_conf",$this_match);
			next ZONE unless( $opt{force} && $opt{D}>=1);
		}
	}

	# more sanity - we don't load zones that have no SOA
	my @has_SOA = split(/\n/, `grep -E 'SOA' $new_zonefile`);
	unless($has_SOA[0]){
		print "e: missing SOA in $new_zonefile\n" if $opt{D}>=0;
		my $this_match = 'include: .+\/' . $name . '\"$';
                &replace_line_in_file("$nsd_confpath$zones_conf",$this_match);
                next ZONE unless( $opt{force} && $opt{D}>=1);
	}

	# if we have named-checkzone then use it!
	# NTS this could be added
	my $named_checkzone = `type -P 'named-checkzone'`;
	unless($named_checkzone){ $named_checkzone =  `which named-checkzone 2>\&1`; }
	if($named_checkzone=~m/named-checkzone/){
		my $zone_sane = `named-checkzone -k fail $name $new_zonefile 2>\&1`;
		if($zone_sane!~m/OK$/s){
			print "e: broken zonefile $name\n" if $opt{D}>=0;
			next ZONE;
		}
	}else{
		print "Can't find named-checkzone ($named_checkzone)\n" if $opt{D}>=1;
	}

	#find or create a notify key
	my $notify_filename=''; #the filename
	my $notify_key='';	#the key
	my $notify_key_name='';	#the name of the key
	my $notify_algorithm='hmac-sha1'; #NOTE move this into the DB::config
	my %alg2no=('hmac-sha1'=>158);
	my $this_conf = qq |key:\n\tname: $name\n\talgorithm: $notify_algorithm\n\tsecret: |;
	# we expect it to be next to the conf (we could "remember" if we have just created the conf for the first time
	# and then just go into creating the new key

	print "[We are at the notify key section]\n" if $opt{D}>=2;#DEBUG

	# find additional conf from comments in the zonefile
	# if there are any include statements we need to change them to be explicit paths:

	print "\@zone_rem = `grep '^;' $new_zonefile`\n" if $opt{D}>=2;
	my @zone_rem = split/\n/, `grep '^;' $new_zonefile`;
	print "grep done\n" if $opt{D}>=3;#DEBUG
	my $conf;
	foreach my $rem (@zone_rem){
	    print "$rem [rem]\n" if $opt{D}>=10;#DEBUG
		#if($rem=~m/allow-transfer {\s*((((\d{1,3}\.){3}\d{1,3})|([a-f0-9]{0,4}:){0,7}:[a-f0-9]{1,4});)*\s*}/){
		if($rem=~m/allow-transfer {\s*(.+)\s*}/){
			my @addresses = split(/;/, $1);
			THISAD: foreach my $this_ad (@addresses){
			   # check $this_ad is either a valid IPv4 or IPv6
			   $this_ad=~s/\n.*//;
			   $this_ad=~s/;.*//;
			   $this_ad=~s/\s*//g;
			   chomp($this_ad);
			   next THISAD  unless($this_ad=~m/(\d{1,3}\.){3}\d{1,3}/ || $this_ad=~m/([a-f0-9]{0,4}:){0,7}:[a-f0-9]{1,4}/);
			   # need to check this part
			   $conf .= "\tprovide-xfr: $this_ad NOKEY\n"; #we probably want to be able to set a key
			}
			# then we convert each ;allow-transfer { 217.151.102.18; 87.237.58.3; 127.0.0.1; };
			# into a provide-xfr: statement
		}elsif($rem=~m/(request-xfr: .+)$/){
			$conf .= $1;
		}elsif($rem=~m/(provide-xfr: .+)$/){
			$conf .= $1;
		}elsif($rem=~m/(notify: .+)$/){
			$conf .= $1;
		}elsif($rem=~m/secret: (.+)$/){
			$notify_key = $1;
		}
	}

	if($notify_key){ print "FOUND notify key IN the zonefile: $notify_key\n" if $opt{D}>=2; } #DEBUG
	else{ print "off to look for a notify key\n" if $opt{D}>=10; } #DEBUG
	unless($notify_key){
		# go looking for it
		my $algorithm_number = $alg2no{$notify_algorithm};
		
	   print "LOOKING for notify key in $conf_path$name\n" if $opt{D}>=2;
	   if(-e "$conf_path"){
		#check that there IS a key
		$notify_filename = `ls ${conf_path}K${name}.+${algorithm_number}+*.key 2>/dev/null`;
		if($notify_filename){
		#check that there is A key (just one)
		#check that the key is good
		#read the key
		    print "reading key using `awk '{print \$NF}' ${conf_path}K${name}.+${algorithm_number}+*.key`\n" if $opt{D}>=3;
		    my $found_key = `awk '{print \$NF}' ${conf_path}K${name}.+${algorithm_number}+*.key`;
		    #check key looks valid
		    if($found_key ne ''){ #NTS probably need a better check
			print "don't worry - its in the conf dir $conf_path\n" if $opt{D}>=2;
			$notify_key = $found_key;
		    }else{
			$notify_key='';
		    }
		}
		unless($notify_key){ #has been found...
		   print "checking PWD for OLD key\n" if $opt{D}>=2;
		   ($notify_key,$notify_filename) = &check_pwd_for_notify_key("K${name}.+${algorithm_number}+",$conf_path);
		}
	   }else{
		print "$conf_path not mkdired yet\n" if $opt{D}>=2;
	   }
	   
	
	   unless($notify_key){
		print "SORRY - haven't found the $notify_key key so... lets make one\n" if $opt{D}>=2;
		# we looked in two places and found nothing... so we create it
		$notify_filename = $notice->keygen_notify($name,$notify_algorithm);
		$zones{$zone}{notify_key_date} = $now; #need to know when
		chomp($notify_filename);
		print "we got: $notify_filename\n" if $opt{D}>=2;
		print "searching PWD for new key file\n" if $opt{D}>=2;
		my $keygen_timeout = 12;
		eval { 
                        local $SIG{ALRM} = sub {die "alarm\n"};
                        alarm $keygen_timeout;
                        while( length($notify_filename) < ( length($name) + 6) ){
				if($notify_filename && $notify_filename!~m/^\d+$/){
					($notify_key,$notify_filename) = &check_pwd_for_notify_key($notify_filename,$conf_path);
				}else{
					($notify_key,$notify_filename) = &check_pwd_for_notify_key("K${name}.+${algorithm_number}+",$conf_path);
				}
			}
                        alarm 0;
                };
                if ($@) {
                  print "ldns-keygen took more than $keygen_timeout seconds: $@\n" unless $@ eq "alarm\n";
                }

		# last gasp try

		if($notify_filename && $notify_filename!~m/^\d+$/){
		}else{
			($notify_key,$notify_filename) = &check_pwd_for_notify_key("K${name}.+${algorithm_number}+",$conf_path);
			if($notify_filename){
				print "keygen took a little longer, but we found $notify_filename\n" if $opt{D}>=1;
			}else{
				print "?: Notify key, (after keygen) for $name is $notify_key $notify_filename\n" if $opt{D}>=1;
			}
		}
	   }
	}
	if($notify_key && length($notify_key)>4){
	    chomp($notify_key);
		$this_conf .=qq |"$notify_key"\n|;
		$notify_key_name = $name;
	}else{	$this_conf =''; $notify_key_name = 'NOKEY'; } # no secret - no key
		
	# write the config
	$this_conf .=qq |zone:
        name: "$name"
        zonefile: "$implicit_zonefile"\n$conf\n|;
        
	#request-xfr: AXFR 193.0.234.245 alexx.net #hidden master
	#hardcoded slaves servers NTS this could be better

	$zones{$zone}{notify_key_date} = `date +%Y%m%d%H%M%S`;
        $this_conf.=qq |notify: 193.0.234.246 $notify_key_name\n|;
        $this_conf.=qq |notify: 193.0.234.247 $notify_key_name\n|;
        $this_conf.=qq |provide-xfr: 87.226.117.20 NOKEY\n|;
        $this_conf.=qq |provide-xfr: ::1 $notify_key_name\n|;
        $this_conf.=qq |provide-xfr: 127.0.0.1 $notify_key_name\n|;
        $this_conf.=qq |provide-xfr: 193.0.234.245 $notify_key_name\n|;
        $this_conf.=qq |provide-xfr: 193.0.234.246 $notify_key_name\n|;
        $this_conf.=qq |provide-xfr: 193.0.234.247 $notify_key_name\n|;
	if($notify_key_name ne 'NOKEY'){
		$notify_filename=~s/\s//g;
		chomp($notify_filename);
		$this_conf.=qq(#notify_key|\%|$notify_filename|\%|$zones{$zone}{notify_key_date}); 
	}

	print "w: $conf_path$name\n" if $opt{D}>=1;
	open(CONF, ">", "$conf_path$name");
	print CONF $this_conf;
	close(CONF);
	print "$conf_path$name written\n" if $opt{D}>=2;


	# NTS we should check that this $name exists in /etc/nsd3/zone.conf and add it if it is missing (now that we have a valid config
	# (we might have a slave so writing zonefiles isn't needed

	# link it all up: we have to check that we have a valid entry in the /ets/nsd/conf/zones.conf files

	#check for a lock file

	#check zones.conf exists
	print "YOU ARE HERE checking $nsd_confpath$zones_conf\n" if $opt{D}>=3;
	my $new_conf_line =qq |include: "$conf_path$name"|;
	my $new_conf_signed =qq |include: "$conf_path${name}.signed"|;
	if(-f "$nsd_confpath$zones_conf"){
		# look for /^include: .+\/$name$/ 
		print "searching using grep -E '^include: .+\/$name(\.signed)?\"\$' $nsd_confpath$zones_conf\n" if $opt{D}>=2;
		print "NAME =$name nsd_confpath=$nsd_confpath zones_conf=$zones_conf\n" if $opt{D}>=2;
		my @found_entries = split(/\n/, `grep -E '^include: .+\/$name(\.signed)?"\$' $nsd_confpath$zones_conf`);
		# it`s "Fixed"
		if(@found_entries >= 2){ 
			print STDERR "E: $zones_conf has " . @found_entries . " entries for $name\n"; 
			print "You probably want to scrub $nsd_confpath$zones_conf and rebuild it\n";
			exit; 
		}
		my $found_entry = $found_entries[0];
		chomp($found_entry);
		if($found_entry){
			$zones{$zone}{conf_name} = $name;
			$zones{$zone}{conf_name} .= '.signed' if $found_entry=~m/${name}\.signed/;
			# check that the entry matches what we think it should be
			print "the Existing $zones_conf entry is $found_entry ($new_conf_line)\n" if $opt{D}>=2;
			#chomp($new_conf_line);
			if($new_conf_line ne $found_entry && $new_conf_signed ne $found_entry){
			   print "$found_entry needs to be updated to $new_conf_line\n";
				open (OCONF, "<", "$nsd_confpath$zones_conf");
				open (NCONF, ">", "$nsd_confpath$zones_conf$$");
				while(<OCONF>){
				    if($_=~m/^include: .+\/$name/){
					print NCONF $new_conf_line ."\n";
				    }else{
					print NCONF $_;
				    }
				}
				close(OCONF);
				close(NCONF);
				rename("$nsd_confpath$zones_conf$$","$nsd_confpath$zones_conf");
			}else{
			    print "G: no need to update $zones_conf for $name\n" if $opt{D}>=1;
			}
		}else{
			print "no entry for $name in $nsd_confpath$zones_conf\n" if $opt{D}>=1;
			open (ZCONF, ">>", "$nsd_confpath$zones_conf") or print "$@ $? $!";
			print "printing to $nsd_confpath$zones_conf\n" if $opt{D}>=1; 
			print ZCONF $new_conf_line."\n";
			close(ZCONF);
			$zones{$zone}{conf_name} = $name;
		}
	}else{
		#no zones.conf file!
		print "No $nsd_confpath$zones_conf so creating it\n" if $opt{D}>=1;
		open (ZCONF, ">", "$nsd_confpath$zones_conf$$");
		print ZCONF $new_conf_line."\n";
		close(ZCONF);
		rename("$nsd_confpath$zones_conf$$","$nsd_confpath$zones_conf");
		$zones{$zone}{conf_name} = $name;
	}

	   print "doing the cp -pa $new_zonefile $existing_zonefile$$\n" if $opt{D}>=2;
	   $zones{$zone}{written}= `cp -pa $new_zonefile $existing_zonefile$$`;
		# NTS here we need to add in all the DS records for subdomains and nameserver delegations
	   if($zones{$zone}{written} eq ''){
		if($opt{backup_existing} && $zones{$zone}{existing}){
			rename($existing_zonefile,"$existing_zonefile.arch");
		}
	   # might want to run a quick named-checkzone after that before the rename
		rename("$existing_zonefile$$",$existing_zonefile);
		unlink("$existing_zonefile$$"); #should not be needed

		# hahahaha! you just changed a zonefile and when cron runs publish again it is going to do a diff...
		# you work it out GENIUS! (that is why we "do" the original zonefile at the same time)	

		print "stripping pointless ^M from $existing_zonefile\n" if $opt{D}>=2;
		print `sed -i 's///g' $existing_zonefile`; #nsd3 does not like ^^M$ so why not clean these up?
		print `sed -i 's///g' $new_zonefile`; #nsd3 does not like ^^M$ so why not clean these up?
		print "stripping pointless space from front of comments in $existing_zonefile\n" if $opt{D}>=2;
		print `sed -i 's/\\s*;/;/g' $existing_zonefile`;  #nsd3 does not like \s*;
		print `sed -i 's/\\s*;/;/g' $new_zonefile`;  #nsd3 does not like \s*;
		print "G: $name updated\n" if $opt{D}>=1;

	    ## RIGHT! we should have a new zone file and its config
	    ## NOW we need to copy the config to the slave servers
	    ## this being nsd3 specific we should only need to rsync the directory structure and the $zones_conf

		$opt{update_slaves}++;
		$opt{rebuild_nsd}++;
		$opt{reload_nsd}++;

	   }else{
		print "$existing_zonefile >> $zones{$zone}{written} << not written\n" if $opt{D}>=0;
		#roll-back the config for this zone in $zones_conf
		my $this_match = 'include: .+\/' . $zones{$zone}{conf_name} . '\"$';
		&replace_line_in_file("$nsd_confpath$zones_conf",$this_match);
	   }
	}else{
		# no new zonefile found;
		print "no file for $zones{$zone}{do_name}\n" if $opt{D}>=4;
	}
}

# we should check each line of $zones_conf to make sure that it points to a real file 
# and we can save time by using %zones (which has the data we need for the zones that we know about)
#
# if a conf file is missing then we check that the zonefile exists and rebuild it


if($opt{update_slaves}){
	print "######################################################################\n" if $opt{D}>=1;
	foreach my $slave (keys %slaves){
	   unless($slaves{$slave}{nsd_confpath}){
	   	$slaves{$slave}{nsd_confpath} = $nsd_confpath;
		if($slaves{$slave}{nsd_basepath}){
			$slaves{$slave}{nsd_confpath}=~s/$nsd_basepath/$slaves{$slave}{nsd_basepath}/;
		}
	   }
	   unless($slaves{$slave}{nsd_basepath}){ $slaves{$slave}{nsd_basepath} = $nsd_basepath;}
	   my $escaped_path = $nsd_basepath;
	   my $escaped_there = $slaves{$slave}{nsd_basepath};
	   $escaped_path =~s/\//\\\//g;
	   $escaped_there=~s/\//\\\//g;
	
	   if($nsd_basepath ne $slaves{$slave}{nsd_basepath}){
		# we should make a copy and change THAT to protect against a crash during the rsync! NTS
		$escaped_path =~s{/}{\/}g;
		#`sed -i 's/^include: "\/etc\/nsd/include: "\/etc\/nsd3/' /etc/nsd3/conf/zones.conf`;
		print qq|g: sed -i 's/^include: "$escaped_path/include: "$escaped_there/' $nsd_confpath$zones_conf\n| if $opt{D}>=1;
		`sed -i 's/^include: "$escaped_path/include: "$escaped_there/' $nsd_confpath$zones_conf`;
	   }else{
		my $slave_sync = '-va -f\'- DNSSEC\' -f\'+ */\' -f \'- *\' --ignore-existing';
	     if($opt{slave_is_master} || $slaves{$slave}{slave_is_master}){
		my $sync_zconf = `rsync -var $nsd_basepath $slaves{$slave}{host}:$slaves{$slave}{nsd_basepath}` if $opt{D}>=0;
	     }else{
		# um, we will have to sed -i EACH and EVERY file in $nsd_confpath for this to work
		print "rsync $slave_sync $nsd_basepath $slaves{$slave}{host}:$slaves{$slave}{nsd_basepath}\n" if $opt{D}>=1;
		my $sync_to_slave = `rsync $slave_sync $nsd_basepath $slaves{$slave}{host}:$slaves{$slave}{nsd_basepath}` if $opt{D}>=0;
		print "rsync -va $nsd_confpath$zones_conf $slaves{$slave}{host}:$slaves{$slave}{nsd_confpath}$zones_conf\n" if $opt{D}>=1;
		if($slaves{$slave}{nsd_confpath} ne $slaves{$slave}{nsd_basepath}){
			my $sync_zconf = `rsync -var $nsd_confpath $slaves{$slave}{host}:$slaves{$slave}{nsd_confpath}` if $opt{D}>=0;
		}else{
			my $sync_zconf = `rsync -va $nsd_confpath$zones_conf $slaves{$slave}{host}:$slaves{$slave}{nsd_confpath}$zones_conf` if $opt{D}>=0;
			#my $sync_zconf = `rsync -va $nsd_confpath$zones_conf $slaves{$slave}{host}:$slaves{$slave}{nsd_confpath}$zones_conf` if $opt{D}>=0;
		}
	     }
		eval {
			local $SIG{ALRM} = sub {die "alarm\n"};
			alarm 2;
			print "ssh $slaves{$slave}{host} '$nsdc rebuild \&\& $nsdc reload'\n" if $opt{D}>=1;
			my $remote_reload = `ssh $slaves{$slave}{host} '$nsdc rebuild \&\& $nsdc reload'` if $opt{D}>=0;
			alarm 0;
		};
		if ($@) {
		  print "remove restart timed out\n$@\n" unless $@ eq "alarm\n";
		}else{
		  print "$@\n";
		}
	    }
	   if($nsd_basepath ne $slaves{$slave}{nsd_basepath}){
		print "she said\n" if $opt{D}>=1;
		`sed -i 's/^include: "$escaped_there/include: "$escaped_path/' $nsd_confpath$zones_conf`;
	   }
	 }
}
my $output='';
$output =' 2>/dev/null' unless $opt{D}>=0;
$output.=' 1>/dev/null' unless $opt{D}>=0;
#$output='';
my $reload;
if($opt{reload_nsd}){
	my $status = `$nsdc running 2>\&1` if $opt{force}>=0; chomp($status);
	print "</check status of $nsdc $status>\n" if $opt{force}>=0 && $opt{D}>=0;
	if($status){
		print "starting $nsdc\n" if $opt{D}>=1;
		$reload=qq |$nsdc start $output \&| if ($opt{D}<=0 || $opt{force}>=1);
	}else{
		print "reloading $nsdc\n" if $opt{D}>=1;
		$reload=qq |$nsdc reload $output| if ($opt{D}<=0 || $opt{force}>=1);
	}
}
if($opt{rebuild_nsd}){
	#  we should check that the user running $0 has sane access to /var/lib/nsd ... etc.
	print "rebuilding $nsdc\n" if $opt{D}>=1;
	print "$nsdc rebuild\n" if $opt{force}>=0 && $opt{D}>=0;
	if($reload && $output){ $reload = ' && ' . $reload; }
	print "rebuild with output $output\n" if $opt{D}>=0;
	print "$nsdc rebuild $output $reload\n" if $opt{D}>=0;
	print `$nsdc rebuild $output $reload` if $opt{D}>=0;
}
if($opt{update_slaves}){
	print "$nsdc update $output\n" if $opt{D}>=1;
	print `$nsdc update $output` if ($opt{D}<=1 || $opt{force}>=1);
	print "update done\n" if $opt{D}>=1;
}
	
exit(0);
