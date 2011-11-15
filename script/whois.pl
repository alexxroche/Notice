#!/usr/bin/perl

=head1 name

whois.pl

=head1 SYNOPSIS

A simple whois server

=head1 DESCRIPTION

Searching for a whois client turns up lots of results,
but there are very few examples of whois servers.

=cut

=head1 CONFIG

data that you can change these are just defaults for stand-alone-ish. 
The real strings should be pulled from the database.

=cut

$|=1;
my $no_db =qq |The database is being updated, please try again later\n(You could poke the sysadmin if this has been down for too long, but please be gentel)\n|;
my $copyright =qq |This is meant to be informative and give an approximate guide... and nothing more.|;
my $no_domain_found =qq |That domain is not found|;
my $string_replace =qq |That domain|;       #if we think that we have a domain we can s/// using this string
my $database = '/var/lib/whois/whois.cdb';
my $log_file = '/var/log/whois.log';
my $template =qq |
Domain name: DOMAIN
Registrant : REGISTRANT
Contact    : {
        CONTACT
}
Dates: {
        Registered on: REGISTERED
        Renewal date:  RENEWAL
        Last updated:  UPDATE
}
Status     : STATUS
Name servers: {
        NS
}

WHOIS  lookup  made at QUERY_DATE
WHOIS database rebuilt DB_DATE

--
COPYRIGHT
|;
#my $start_date = `date +%Y%m%d%H%M%S`; chomp($start_date);

=head1 USAGE and TODO

needs a chkconfig script for /etc/init.d/whoisd or 
you can kick this off from /etc/rc4.d/S99local with:

 # create a whois user and group
 # create a home for the whois database
sudo mkdir -p /var/lib/whois && chown whois: /var/lib/whois
 # install this script
sudo cp whois.pl /usr/local/sbin && echo '/usr/local/sbin/whois.pl' >> /etc/rc4.d/S99local

Needs a cdb database with the key being the domain string and the value being all of the data.
(and a script or sub in here that creates the database from our mysql)

This expects a template with VALUES in upper case. Any that we don't replace are stripped
using $data=~s/\s?\t?[A-Z]{2,}//g # which means that VARIABLES in the template must be 
longer than one character. 

=head1 _build

This builds a new database and is invoked if this script is called with a destination
for the database

=cut

if($ARGV[0]){ 
        if($database=~m/$ARGV[0]/){ &_build($ARGV[0]); }else{ print "You want what where?\n";} 
        exit;
}

sub _build {
    use warnings;
    use strict;
    use Notice::DB;
    use Config::Auto;
    use CDB_File;

    my $cfg = Config::Auto::parse("config/config.pl", format => "perl");
    my %CFG = %{ $cfg };
    my $self = Notice::DB->connect($CFG{'db_dsn'},$CFG{'db_user'},$CFG{'db_pw'});
    my %seen; #domains we have seen
# select do_name,do_status,do_added,rent_start,rent_end,ac_name from domains LEFT JOIN rental on rent_tableid = do_id LEFT JOIN accounts on ac_id = do_acid;

    my $domains = $self->resultset('Domain')->search({ },{
      join => 'rental',
      #join => 'accounts',
        #'+select' => ['rental.rent_start'],
     # '+as'     => ['rental.rent_start'],
      columns => [ 
        'do_name','do_status','do_added',
        { rent_start => 'rental.rent_start as rent_start'},
        { rent_end => 'rental.rent_end as rent_end'},
        #{ac_name => 'account.ac_name as ac_name'},
        ],
      order_by => 'do_status'
    });
    use Data::Dumper;
    my $cdb = new CDB_File($database, "$database.$$") or
                   die "$0: new CDB_File failed: $!\n";
    my $now = `date +%Y%m%d%H%M%S`; chomp($now);
    DOMAIN: while( my $d = $domains->next){
        my($status,$domain,$added,$start,$end,$name,$ns);
       $status = $d->do_status;
       $domain = $d->do_name;
        $domain = lc($domain); #just in case
    next DOMAIN if $seen{$domain};
        print "Found $domain\n" if $ARGV[1];
       if($d->do_added){ 
            $added  = $d->do_added; 
        }
       if("$d->rent_start"=~m/\d:/){
            $start  = $d->rent_start;
        }elsif($d->{'_column_data'}->{rent_start}){
           $start =  $d->{'_column_data'}->{rent_start};
        }else{
            $start = $now;
        } 
       if("$d->rent_end"=~m/\d:/){
            $end    = $d->rent_end;
        }
       if("$d->ac_name"=~m/\w+/){
            $name   = $d->{'_column_data'}->{ac_name};
            if($name && length($name)<=2){ $name = 'Private Account'; }
        }
       $ns = '# Use a DNS query for the present data';
        # We will extract it from their zone file at a later date;
       chomp($domain);
       if($status eq 'enabled' || $status=~m/mig/){ $end = 'Registered until renewal date.'; }
       elsif($status eq 'disputed' || $status eq 'suspended'){ $status = 'disabled'; }
       elsif($status eq 'registering'){ $end = 'Depends on payment'; }
    
       my $v = $template;
        $v=~s/DOMAIN/$domain/;
        if($name && $name ne ''){ 
            $v=~s/REGISTRANT/$name/; 
        }else{ 
            #$v=~s/^Registrant.*$//; 
            $v=~s/REGISTRANT/Private/; 
        }
        $v=~s/CONTACT/http:\/\/www.example.com\/ Alexx Roche Ltd UK/;
        if($added){ $v=~s/REGISTERED/$added/; }
        if($end){   $v=~s/RENEWAL/$end/; }
        if($start){ $v=~s/UPDATE/$start/; }
        $v=~s/STATUS/$status/;
        $v=~s/NS/$ns/;
        $v=~s/DB_DATE/$now/;
        $v=~s/COPYRIGHT/$copyright/;

       if( defined $v){
            print "Adding $domain to the whois\n" if $ARGV[1];
            $cdb->insert($domain, $v);
       }else{
            print "bogus domain: $domain\n";
       }
      $seen{$domain}++;
    }
    $cdb->finish or die "$0: CDB_File finish failed: $!\n";
    unlink("$database.$$") if(-f "$database.$$");
}

=head1 Whois

This is the code that creates the whois daemon

=cut

package Whois;
use strict;
use base qw(Net::Server);
use CDB_File;
my $DEBUG=0;

my $daemon = Whois->new({
        user	=> 'whois',
	group	=> 'whois',
	proto	=> 'tcp',
	port	=> 43,
	background=>1,
	log_file=> $log_file,
	#log_file=> '/var/log/whois.log',
});

$daemon->run;

sub process_request {
    my $self = shift;
    eval {
        local $SIG{'ALRM'} = sub { die "Timed Out!\n" };
        my $timeout = 30; # give the user 30 seconds to type some lines
        my $previous_alarm = alarm($timeout);
	    warn ("HERE: $previous_alarm") if $DEBUG>=2;
        while (my $query = <STDIN>) {
                last if $query =~ /^\s$/;
                chomp $query;
		my $domain = $query;
		$domain=~s/\s.*//;
		$domain=~s/[^\w\.-]//;
	     if(-f "$database"){
            tie my %whoisdb, 'CDB_File', $database or die "can't open $database: $!\n";
		    warn "tieing to $database" if $DEBUG>=2;
            my $now = `date +%Y%m%d%H%M%S`; chomp($now);
            if ($whoisdb{$domain}){
			    my $reply = $whoisdb{$domain};
                $reply=~s/\$now/$now/;
                $reply=~s/QUERY_DATE/$now/;
			    print $reply . "\n";
                print STDERR "$domain is known\n" if $DEBUG>=1;  #ths is a log message
            }else{
                if('bandwidth to burn' eq 'yes'){
                    my $reply = $no_domain_found;
                    $reply=~s/$string_replace/$domain/;
			        print $reply . "\nQuery recieved: $now\n";
                }else{
                    print "No\n";
                }
                # NOTE probably need a rate-limiter to prevent a DDoS filling up the logs.
			    print STDERR "$now $domain is not known here \n" if $DEBUG>=1; 
		    }
            last;
		    warn ("THERE: $timeout");
	     }else{
			print $no_db;
			print STDERR "DB ERROR: $database is not a file\n";
            last;
	     }
         alarm($timeout);
        }
        alarm($previous_alarm);
    	if ($@=~m/timed out/i) { print STDERR "DIED Out.\n"; print STDERR "We have zero bananas today\n"; return; }
    };
    if ($@=~m/timed out/i) { print STDERR "Timed Out.\n"; print STDERR "We have no bananas today\n"; return; }
    elsif ($@) { print STDERR "NB: $@.\n"; return; }
    else{ print STDERR "end of process\n" if $DEBUG>=2; }
}
print STDERR "GOT HERE.. which is the end\n";
1;

__END__

=head1 BUGS AND LIMITATIONS

Probably, and certainly better ways to do the same thing

=head1 SEE ALSO

L<Notice>

=head1 AUTHOR

Alexx Roche, C<< <notice-dev@alexx.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0 ;
 the GNU Lesser General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

