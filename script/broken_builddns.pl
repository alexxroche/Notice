#!/usr/bin/perl

use warnings;
my %opt;
use strict;
use Notice::DB;
use Config::Auto;
use Data::Dumper;
$|=1;

our $VERSION = 0.02;

=head1 NAME

build_dns.pl - ZONE file creation

=head1 SYNOPSIS

This takes the enabled and migrating domains and builds zone files.
In most cases that will be for NSD or BIND, but we can output tinyDNS versions

=head1 Config

This is pulled for the config using Config::Auto

=cut

if($ARGV[0] && $ARGV[0]=~m/^\d+$/){ $opt{D}=$ARGV[0]; }
elsif($ARGV[0] && $ARGV[0]=~m/^-v$/){ $opt{verb}=1; }

my $cfg = Config::Auto::parse("config/config.pl", format => "perl");
my %CFG = %{ $cfg };
my $self = Notice::DB->connect($CFG{'db_dsn'},$CFG{'db_user'},$CFG{'db_pw'});
my $using_tinyDNS;
if($CFG{'using_tinyDNS'}){ $using_tinyDNS = $CFG{'using_tinyDNS'}; }
my $base = '/var/www/sites/www.gb.com/cgi-bin'; # why don't we juse CWD ?
my $nsd_out  = '/etc/nsd';
my $tds_out = '/var/www/sites/BytemarkDNS/data';
my $use_tds = 1; #should we output tinyDNS?
my $use_nsd = 1; #should we output BIND/NSD3 format?
if($CFG{'tinyDNS_path'}){ 
    $tds_out = $CFG{'tinyDNS_path'}; 
    print "Using $tds_out and the output dir\n" if $opt{D}>=10;
    $use_tds=1;
}
 
=head1 Domains

I hear you like them?

=cut


my $default_soa;
my $default_ttl = 28800; #default for the whole server, while $global_ttl is for a single zone.
my $zh_rows = $self->resultset('ConfData')->search({'cfd_key'=>{'=','default_soa'}},{})->count;
if($zh_rows==1){
    my $zh = $self->resultset('ConfData')->search({
      'cfd_key' => { '=', 'default_soa'},
       },{
        columns => 'cfd_value',
       })->single;
    my ($ttl,@def_soa)  = split/\n/, $zh->cfd_value;
    if($ttl=~m/TTL/){ $default_ttl = $ttl; }else{ unshift(@def_soa,$ttl); }
    $default_soa = join("\n", @def_soa);
}
# We put in the \n and then take it out just in case someone has added comments
my $tinyDNS_default_soa = $default_soa;
$tinyDNS_default_soa=~s/;.*\n?//gm;
$tinyDNS_default_soa=~s/\s*$//;


$tinyDNS_default_soa=~s/\s+/ /g;
$tinyDNS_default_soa=~s/^.* SOA //g;
$tinyDNS_default_soa=~s/ [\(\)]//g;
$tinyDNS_default_soa=~s/ /:/g;
    
print "gSOA:    Z\$domain:". $default_soa ."\n" if $opt{D}>=30;
print "gSOA:    Z\$domain:". $tinyDNS_default_soa ."\n" if $opt{D}>=30;
print "exTDsoa: " . 'Zgb.com.:ns0.alexx.net.:hostmaster.alexx.net.:2000000002:43200:3600:864000:28800' . "\n" if $opt{D}>=30;

if($default_ttl=~m/\$TTL (\d+)(\w)/){
    my $d_ttl = $1;
    my $d_ttl_unit = $2;
    if($d_ttl_unit=~m/w/i){ $d_ttl *= (60*60*24*7); }
    elsif($d_ttl_unit=~m/d/i){ $d_ttl *= (60*60*24); }
    elsif($d_ttl_unit=~m/h/i){ $d_ttl *= (60*60); }
    elsif($d_ttl_unit=~m/m/i){ $d_ttl *= (60); }
}


my $domains = $self->resultset('Domain')->search({ 
     -or => [
         'do_status' => { 'like', 'migrating%'},
         'do_status' => { '=', "enabled"},
       ],
    },{
    join => 'account',
    columns => [ { ac_tree => 'account.ac_tree as ac_tree'},{ac_name => 'account.ac_name as ac_name'},'do_name','do_group'],
  order_by => {-desc =>['length(do_name)']}
});
use Notice::C::Account;
my %dns; #key is a domain name
my %zone; # used to store A records for NS and other mergable entries for tinyDNS
# $zone{$do_name}{A}{$server}{IP};
# $zone{$do_name}{A}{$server}{TTL};
DOMAIN: while( my $d = $domains->next){
    my $do_name = $d->do_name;
    #$do_name .= '.'; #need trailing '.'
    my $do_group = $d->do_group;
    my $ac_name;
    my $ac_tree;
    $ac_name = $d->{'_column_data'}->{ac_name};
    $ac_tree = $d->{'_column_data'}->{ac_tree};
    #my %DEE = %{ $d }; foreach my $key (keys %DEE){ print "DEE: $key = $DEE{$key}\n"; }
    #$ac_name = $d->ac_name;
    #if($d->ac_name){ $ac_name = $d->ac_name;}
    my $account_path =  '1';
    $account_path = Notice::C::Account::_to_path($ac_tree);
    my $path = $account_path ne '1' ?  $account_path : $ac_tree ;
    $path .= 'master/';
    $path .=  substr($do_name,0,1);
    $path .= '/' . $do_name;
    my $found = '';
    my ($parent) = $do_name;
    $parent=~s/^[^\.]*\.//;
    if(-f "$base/$path"){ 
            $found = "($parent)"; 
            open(ZONE,"<","$base/$path");
            my $zone_stub; #for tinyDNS
            my $z_stub;    #for BIND/NSD
            my $global_ttl;
            my $zone_origin;
            LINE: while(my $line = <ZONE>){ 
                if($line=~m/\$TTL (\d+)(\w)/){
                    $global_ttl = $1;
                    my $g_ttl_unit = $2;
                    if($g_ttl_unit=~m/w/i){ $global_ttl *= (60*60*24*7); }
                    elsif($g_ttl_unit=~m/d/i){ $global_ttl *= (60*60*24); }
                    elsif($g_ttl_unit=~m/h/i){ $global_ttl *= (60*60); }
                    elsif($g_ttl_unit=~m/m/i){ $global_ttl *= (60); }
                    next LINE;
                }elsif($line=~m/^;inc_soa/){
                    $dns{$do_name}{inc_soa} = 1; #so if there is a line with ";inc_soa" we do that
                    next LINE;
                }
            #  If we just have a list of name servers we accept
            #  ^\s*(($ns)[\s;,])*
                $line=~s/\s*[\n\r]?$//;
            chomp($line);
            next LINE if $line=~m/^\s*$/;       # skip blank lines
            next LINE if $line=~m/^\s*;.*$/;    # skip comment lines
            if($do_name=~m/^gb.com$/){ print "LINE: ($line)\n" if $opt{D}>=14; }

   
		if($do_name=~m/\.gb\.com$/ && $line=~m/^(.+)\s+((\d{1,3}\.){3}\d{1,3})$/){
			if($1 ne ''){
				#$zone{$do_name}{A}{$1} = $2;
				print "$parent for $do_name NS $1 needs a glue record of $2\n" if $opt{d}>=0;
			}
		}
            # for now we just dump TTL if the line is just a NS
            $line=~s/^\s*(([\w\.\-:]*)[\s;,])\d+/$1/;
            
            if($do_group!~m/^\d+$/ && $line=~m/^\s*(([\w\.\-:]*)[\s;,]?)*([;#].*)?$/){
                #remove any comment
                $line=~s/\s*[#;].*$//;
                my @sz_ns = ($line=~m/\s*([\w\.:\-]+)[\s;,]?/g);
                print "found " . @sz_ns . " name servers for $do_name\n" if $opt{D}>=10;
		my $last_entry;
                ENTRY: foreach my $entry (@sz_ns){
		   #next ENTRY if($zone{$do_name}{A}{$last_entry} = $entry);
		   #if($zone{$do_name}{A}{$last_entry} = $entry){
		#	delete($zone{$do_name}{A}{$last_entry});
		#	next ENTRY;
		#   }
		#   $last_entry = $entry;
		   	 
                    print "OLNS: $entry for $do_name\n" if $opt{D}>=11;
                    # which part of an A record is it?
                    my ($server,$address);
                    if($entry=~m/[a-z]{2,}/i){ #it is a hostname
                        $server = $entry;
                    }elsif($entry=~m/(\d{1,3}\.){3}\d{1,3}/ || $entry=~m/([a-f0-9]{0,4}:){1,7}[a-f0-9]{1,4}/){
                        #if IPv6 expand it
                        $address = $entry;
		       print "Do we even use this?\n";
                    }
                    # might get a request for that... they can just add $TTL 2d to the top
                    #my $ttl = ':' . $global_ttl;
                    my $ttl = $global_ttl;
                    if($zone{$do_name}{A}{$server}){
                        $address = $zone{$do_name}{A}{$server};
                    }
                    if($address || $server){
                        if($using_tinyDNS){
                            my $new_line = '&' . "$do_name:$address:$server:$ttl";
                            $zone_stub = "$zone_stub$new_line\n";
                        }
                        if($use_nsd){
                            my $this_domain = $do_name;
                            unless($server=~m/\.$/){ $server .= '.'; }
                            unless($this_domain=~m/\.$/){ $this_domain .= '.'; }
                            $z_stub .= "$this_domain  $ttl  IN NS $server\n";
                            $z_stub .= "$server  $ttl  IN A $address\n";
                        }
                    }
                }
		delete($zone{$do_name}{A});
                if($do_name=~m/^gb.com$/){ print " Next OLNS :(:$line:):\n" if $opt{D}>=6; }
                
                next LINE;
            }else{
                if($do_name=~m/^gb.com$/){ print "nOT an OLNS :(:$line:):\n" if $opt{D}>=5; }
                print "not an OLNS: $line" if $opt{D}>=11;
            }

            warn "LINE: $line\n" if $opt{D}>=21;
            # replace @ with the actual domain name
            $line=~s/\@/$do_name/;
            warn "LINE: $line\n" if $opt{D}>=21;
            #$zone_stub .= $line;
            # strip leading spaces
            $line=~s/^\s+//g;
            warn "LINE: $line\n" if $opt{D}>=21;
            # strip trailing spaces
            chomp($line);
            warn "LINE: $line\n" if $opt{D}>=11;
            # remove spaces to make the split work
            $line=~s/\s+/ /g;
            if($do_name=~m/^gb.com$/){
                warn "LINE: $line\n" if $opt{D}>=2;
            }


            my @row = split(/ /, $line);
            #my @row = $line=~m/(.{1,}\W)/gms;
            warn "LINE: $line\n" if $opt{D}>=11;
            # BIND/NSD is tinydns (sort of)
            # =========================
                #
            # Converting to and from BIND/NSD to tinydns formats we have to use "his" conventions
            #
            # For the database each entry starts with a unique marker showing what type of DNS entry it is, so:
            #
            # $TTL is {built in, so you don't need it, or you can add it to the end of each record that does not have it}
            # NS is &
            # A is +
            # PTR is ^
            # MX  is @
            # CNAMD is +
            # SOA is Z # N.B. BUT...    
            # SOA+NS+A is .             [SOA and NS and A]
            # PTR+A is =                [PTR and A]
            # TXT  is '                 [text/SPF]
            # ; is #                    [remark/comment]
            #
            #
            # we should have soa=[9,10] => Z ; mx=[4,5] => @, a,cname,ns,ptr=[3,4] => +,C,&,^ 
            if( 
                    $row[2] eq 'NS' || 
                    $row[2] eq 'ns' || 
                    $row[3] eq 'NS' || 
                    $row[3] eq 'ns'
            ){
                my $server;
                $server = $row[4]; unless($server){ $server = $row[3]; }
                my $ttl = $row[1]=~m/^\d+$/ ? $row[1] : $global_ttl;
                my $address = $zone{$do_name}{A}{$server};
                unless($server=~m/\.$/){ $server .= '.'; } # add the root
                #unless($server=~m/$do_name/){ $server .= $do_name . '.'; } #no funny stuff!
                my $hostname;
                $hostname = $row[0];
                unless($hostname=~m/\.$/){ $hostname .= '.'; } # add the root

                print "IS a NS: 2: $row[2] 3: $row[3]\n" if $opt{D}>=20;
                if($hostname && $server){
                    if($using_tinyDNS){
                        my $new_line;
                        if($do_group=~m/^\d+$/ && ($hostname eq $do_name || $hostname eq "$do_name.")){
                            $new_line = '.';
                        }else{
                            $new_line = '&';
                        }
                        $new_line .= "$hostname:$zone{$do_name}{A}{$server}:$server:$ttl";
                        if($new_line){
                            #print "NEW LINE: >>>> $new_line <<<<::\n" if $do_name=~m/^gb.com$/;
                                $new_line .= "\n";
                            if($do_group=~m/^\d+$/){ #not a subzone
                                $dns{$do_name}{zone} .= $new_line;
                            }else{
                                #$zone_stub = "$zone_stub$new_line";
                                $zone_stub .= $new_line;
                            }
                        }else{
                            print STDERR "No new line in $do_name\n";
                        }
                    }
                    if($use_nsd){
                         my $new_line = "$hostname  IN NS $server\n";
                         if($do_group=~m/^\d+$/){ #not a subzone
                              $dns{$do_name}{z} .= $new_line;
                         }else{
                              #$zone_stub = "$zone_stub$new_line";
                              $z_stub .= $new_line;
                         }
                    }
                }
            }elsif(
                $row[2] eq 'A' ||
                $row[2] eq 'a' ||
                $row[2] eq 'AAAA' ||
                $row[3] eq 'A' ||
                $row[3] eq 'AAAA' ||
                $row[3] eq 'a'
            ){
                my $server = $row[0];
                my $record = $row[3];
                my $ttl = $row[1];
                unless($server=~m/\.$/){ $server .= '.'; } # add the root
                unless($server=~m/$do_name/){ $server .= $do_name . '.'; } #no funny stuff!
                my $address = $row[4];
                unless($address=~m/(\d{1,3}\.){3}\d{1,3}/ || $address=~m/([a-f0-9]{0,4}:){1,7}[a-f0-9]{1,4}/){ 
                    $address= $row[3]; 
                    $record = $row[2];
                    $ttl = $global_ttl;
                }
                if($address=~m/(\d{1,3}\.){3}\d{1,3}/ || $address=~m/([a-f0-9]{0,4}:){1,7}[a-f0-9]{1,4}/){ 
                    if($using_tinyDNS){
                        my $tds_add = $address;
                        $tds_add = expand_ipv6($tds_add,1) unless $tds_add=~m/^(\d{1,3}\.){3}\d{1,3}$/;
                        my $new_line = '+' . $server .':'. $tds_add .':'. $ttl;
                        print "$new_line #($do_name A record)\n" if $opt{D}>=10;
                        #$new_line =~s/:?\s*\n?/\n/; # strip pointless trailing : and make sure we have an \n
                        $new_line =~s/:?\s*\n?//; # strip pointless trailing : and make sure we have an \n
                        $new_line .= "\n";
                        $dns{$do_name}{zone} .= $new_line;
                    }
                    if($use_nsd){
                        $dns{$do_name}{z} .= "$server $ttl IN $record $address\n";
                    }
                }
            }elsif(
                $row[2] eq 'MX' ||
                $row[2] eq 'mx' ||
                $row[3] eq 'MX' ||
                $row[3] eq 'mx'
            ){
                my ($domain,$distance,$mailserver,$address);
                   $domain = $row[0];
                my $ttl = $row[1];
                   $mailserver = $row[5];
                   $distance = $row[4];
                unless($domain=~m/\.$/){ $domain .= '.'; } # add the root
                unless($domain=~m/$do_name/){ $domain .= $do_name . '.'; } #no funny stuff!
                unless($mailserver=~m/(\w{1,}\.)+\w{1,}/){
                    $mailserver = $row[4];
                    $distance = $row[3];
                    $ttl = $global_ttl;
                }
                if($zone{$do_name}{MX}{$mailserver}){
                    $address = $zone{$do_name}{MX}{$mailserver};
                }
                if($distance=~m/^\d+$/){
                    if($using_tinyDNS){
                        my $new_line = '@'. $domain .':'. $address .':'. $mailserver .':'. $distance .':'. $global_ttl;
                        print "$new_line #($do_name)\n" if $opt{D}>=10;
                        #$new_line =~s/:?\s*\n?/\n/; # strip pointless trailing : and make sure we have an \n
                        $new_line =~s/:?\s*\n?//; # strip pointless trailing : and make sure we have an \n
                        $new_line .= "\n" unless $new_line=~m/\n$/;
                        #$dns{$do_name}{zone} .= "\n" . $new_line;
                        $dns{$do_name}{zone} .= $new_line;
                    }
                    if($use_nsd){
                        $dns{$do_name}{z} .= "$domain $ttl IN MX $distance $mailserver\n";
                        if($address){
                            $dns{$do_name}{z} .= "$domain $ttl IN A $address\n";
                        }
                    }
                }
            }elsif(
                $row[2] eq 'TXT' ||
                $row[2] eq 'txt' ||
                $row[3] eq 'TXT' ||
                $row[3] eq 'txt'
            ){
                #:alexx.net:16:\046v=spf1\040+mx\040include\072smtp.alexx.net\040~all:86400

                my $server = $row[0];
                my $ttl = $row[1];
                unless($server=~m/\.$/){ $server .= '.'; } # add the root
                unless($server=~m/$do_name/){ $server .= $do_name . '.'; } #no funny stuff!
                my $txt = $line;
                $txt=~s/^$row[0] $row[1] $row[2] $row[3] //;
                unless($txt && $txt=~m/.+/){
                    $txt = $row[3];
                    $ttl = $global_ttl;
                }
                my $text = $txt;
                $txt=~s/^\s*['"]//;
                $txt=~s/['"]\s*$//;
                # Need to escape : and spaces
                $txt=~s/:/\\072/g;
                $txt=~s/ /\\040/g;
                #$txt=~s/ /\\046/g; #at the start in the example
                #$txt=~s/ /\\050/g; #but not sure why
                if($txt && $txt=~m/.+/){
                    if($using_tinyDNS){
                        my $new_line = "'" . $server .':'. $txt .':'. $global_ttl;
                        print "$new_line #($do_name TXT record)\n" if $opt{D}>=2;
                        $new_line =~s/:?\s*\n?//; # strip pointless trailing : and make sure we have an \n
                        $new_line .= "\n";
                        $dns{$do_name}{zone} .= $new_line;
                    }
                    if($use_nsd){
                        $text=~s/'/"/g;
                        $dns{$do_name}{z} .= "$server $ttl IN TXT $text\n";
                    }
                }
            #}elsif( is a PTR ){
# :www.alexx.net:28:\040\001\101\310\000\001\140\215\000\000\000\000\000\000\000\020:86400
# ^0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.8.0.6.1.0.0.0.8.c.1.4.1.0.0.2.ip6.arpa:www.alexx.net:86400

#   though this might need a + at the start of the AAAA record
            }else{
                    print "not using: $line (from $do_name)\n" if $opt{D}>=0;
                   # $zone_stub .= $line;
            }
       }
       close(ZONE);
        
        if($use_nsd && $dns{$do_name}{z}){

            # need to make sure it starts with a $TTL and has a SOA
            unless($dns{$do_name}{z_has_soa}){
                $dns{$do_name}{z} = $default_soa ."\n". $dns{$do_name}{z};
            }
            unless($dns{$do_name}{z_has_ttl}){
                $dns{$do_name}{z} = $default_ttl. "\n". $dns{$do_name}{z};
            }
        }

       if($zone_stub){
        if($do_name eq 'gb.com' && $opt{D}>=20){ 
            print "BEFORE Now the zone is: $dns{$do_name}{zone}<\\END of zone>\n"; 
            print "Adding $zone_stub::\n::";
        }
        chomp($zone_stub);
        $zone_stub .= "\n";
        #$dns{$parent}{zone} .= "#;addeding zone_stub\n$zone_stub\n#;END zone_stub\n";
        $dns{$parent}{zone} .= $zone_stub;
        #if($do_name eq 'gb.com'){ print "Now the zone is: $dns{$do_name}{zone}\n"; }
       }
       if($z_stub){
        $dns{$parent}{z} .= $z_stub;
       }
        $dns{$do_name}{path}= $path;
        
    }else{ 
       $found = "MISSING";
    }
    print qq($do_name, $ac_name, $base/$path $found\n) if $opt{D}>=7;
    if( !$dns{$parent} && $do_group=~m/\d+/){
         if($using_tinyDNS && $dns{$do_name}{inc_soa}){
            $dns{$do_name}{zone} = 'Z'. $do_name .':'. $tinyDNS_default_soa ."\n" . $dns{$do_name}{zone};
         }elsif($opt{D}>=1){
            $dns{$do_name}{zone} = ';not using default SOA or tinyDNS' . "\n" . $dns{$do_name}{zone};
         }
    }else{
        print STDERR "$do_name group is $do_group\n" if $do_group && $opt{D}>=100;
    }
    if($dns{$do_name}{zone}){
        #$dns{$do_name}{path} = "$nsd_out/$path";
        #$dns{$do_name}{path} = "/$path"; #we can stick the right start on laster
        #print "$do_name: ($dns{$do_name}{path})\n$dns{$do_name}{zone}" if $opt{D}>=1;
        print "$do_name: " if $opt{D}>=1;
        if($use_nsd && -d "$nsd_out"){
            my ($out_file,$out_dir);
            ($out_dir) = ($out_file=~m/^(.*)\/[^\/]*/);
            $out_file = $dns{$do_name}{path} ? "$nsd_out/$dns{$do_name}{path}" : "$nsd_out/$do_name"; 
            if(-f "$out_file" && -w "$out_file"){
                print "Writing $dns{$do_name}{z} to $out_file in $out_dir\n" if $opt{D}>=3;
                unless($opt{D}>=1){
                    open(FILE, ">$out_file$$") or die "Did not open $out_file";
                         print FILE $dns{$do_name}{z};
                    close(FILE);
                }

                # check that we have written a valid zonefile
                my $ok = `named-checkzone $do_name $out_file$$`;
                my $named_checkzone = `type -P 'named-checkzone'`;
                unless($named_checkzone){ $named_checkzone =  `which named-checkzone 2>\&1`; }
                if($named_checkzone=~m/named-checkzone/){
                    chomp($named_checkzone);
                    my $zone_sane = `$named_checkzone -k fail $do_name $out_file$$ 2>\&1`;
                    if($zone_sane!~m/OK$/s){
                        die "e: broken zonefile $do_name ->  ($zone_sane)" if $opt{D}>=0;
                        next DOMAIN;
                    }else{
                        rename("$out_file$$","$out_file") or `mv $out_file$$ $out_file`;
                        print "Moved $out_file$$ to $out_file\n" if $opt{D}>=4;
                        #next DOMAIN; # DEBUG!!!!!!!!!
                    }
                }else{
                    print "Can't find named-checkzone ($named_checkzone)\n" if $opt{D}>=1;
                }
                # if that worked we add this zone to the config
                # or we remove this orphan file
            }else{
               print "little problem with the zone file: $out_file or its location: $out_dir\n" if $opt{D}>=1;
                if(!-w "$out_file"){
                    print " BECAUSE I can't write to $out_file\n" if $opt{D}>=1;
                }
            }
        }else{
            print STDERR "Looks like you need to crete $tds_out\n";
        }
        #if we are $using_tinyDNS
        if( ( $using_tinyDNS || $use_tds ) && -d "$tds_out"){
          #if the $tds_out directory exists then we will populate a path unless
                print STDERR "Using tinyDNS for $do_name\n" if ($opt{D}>=1||$opt{verb}>=1);
          my ($out_file,$out_dir);
             $out_file = $tds_out .'/'. $do_name;
          ($out_dir) = ($out_file=~m/^(.*)\/[^\/]*/);
          print "($out_file)\n" if $opt{D}>=1;
           if(-f "$out_file" && -w "$out_file"){
                #
                # NOTE we could back up the old zone here
                # 
                print "                                     ;# Updating\n$dns{$do_name}{zone}" if ($opt{D}>=1||$opt{verb}>=1);
                #print " ;# Writing to $out_file \n" if $opt{D}>=0;
                unless($opt{D}>=1){
                    #open(FILE, ">$nsd_out/$dns{$do_name}{path}") or die "Did not open $nsd_out/$dns{$do_name}{path}";
                    open(FILE, ">$out_file") or die "Did not open $out_file";
                        print FILE $dns{$do_name}{zone};
                    close(FILE);
                }
            #}elsif(-w "$nsd_out/$dns{$do_name}{path}"){
            }elsif(-w "$out_dir"){
                print ";#Creating $nsd_out/$do_name\n" if $opt{D}>=0;
                unless($opt{D}>=1){
                    open(FILE, ">$tds_out/$dns{$do_name}{path}") or warn "Could not open $tds_out/$dns{$do_name}{path}";
                        print FILE $dns{$do_name}{zone};
                    close(FILE);
                }
                print $dns{$do_name}{zone} if $opt{D}>=1;
                print " - Done Creating $tds_out/$do_name\n" if $opt{D}>=0;
            }else{
                print "Need to create $out_dir for $do_name\n";
            }

        }else{
            print "Using tinyDNS? :$using_tinyDNS || $use_tds\n" if ($opt{D}>=1||$opt{verb}>=1);
            print STDERR "Err: missing path $tds_out\n";
            exit;
        }
    }else{
        print STDERR "Warn: no zone for $do_name\n" if $opt{D}>=10;
    }
}
if($CFG{'update_dns'}){
        system($CFG{'update_dns'}) unless($opt{D}>=1);
        system($CFG{'rebuild_dns'}) unless($opt{D}>=1);
        system($CFG{'reload_dns'}) unless($opt{D}>=1);
}


sub expand_ipv6 {
    my $string = shift;
    my $no_pad = shift;
    if($string!~m/^([0-9a-fA-F]{0,4}::?){0,7}[0-9a-fA-F]{0,4}$/){ print STDERR "$string is not valid IPv6\n"; return($string); }
    while($string!~m/^([0-9a-fA-F]{1,4}::?){7}[0-9a-fA-F]{1,4}$/){
        $string=~s/^([0-9a-fA-F]{0,3}:)/0$1/g;
        $string=~s/:([0-9a-fA-F]{1,3})$/:0$1/g;
        $string=~s/::/::0000:/ unless $string=~m/([0-9a-fA-F]{1,4}::?){7}/;
    }
    $string=~s/::/:/;
    #pad the zeros
    while($string!~m/^([0-9a-fA-F]{4}:?){7}[0-9a-fA-F]{4}$/){ $string=~s/:([0-9a-fA-F]{1,3}:)/:0$1/; }
    if($no_pad){ $string=~s/://g; }
    return $string;
}
