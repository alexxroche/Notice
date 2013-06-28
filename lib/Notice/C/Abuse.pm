package Notice::C::Abuse;

#use warnings;
no warnings; # DateTime::Format::Strptime causing deprecation msgs to be thrown
use strict;
use lib 'lib';
use base 'Notice';
use Data::Dumper;
my $fallback_address = 'root@localhost';
my $abuse_address = 'abuse@example.com'; #usual connected to an RT queue
my %submenu = (
   0 => [
        '1' => { peer=> 1, name=> 'Abuse', rm => 'Abuse', class=> 'navigation'},
    ],
);
my %opt=(D=>0);


=head1 NAME

Notice::C::Abuse

=head1 ABSTRACT

This presents a submission form, (or you can upload a file) that provides evidence of
email abuse.

The same function can be linked to an auto-email reader that can read abuse@$domain(s) and add genuine
abuse messages to the RT (request tracker) abuse queue.

=head1 DESCRIPTION

Each message that is sent by an authenticated user from my SMTP server has an X-ESRT header added.
This "Email Service Revocation Token". (Example exim4 config sample included).
This means that the headers of any message can be used to verify 

How this works:

the X-ESRT is a hash of "a secret string,host_name,auth_id,time-of-day"
So along with the ESRT we need the 
    hostname
    senders_id
    and the time when the message was sent, (from the MTA point-of-view).
    (note that time-zone can be an issue, so use GMT!)

Thankfully all of this is in a normal header.

Notice will check in its config for ESRT_SECRET and if it does not find one
it will endeavour to find the nearest exim config and extract it.

Becuase of this simple verification we can determin spoofed spam withouth
having to bother with DKIM. Also this script can, if it has access grab 
the MTA log lines for the offending message and include them in the Abuse ticket.

=head3 HASH

  ${hmac{sha1}{ESRT_SECRET}{${primary_hostname},$authenticated_id,$tod_log}}

The default is hmac sha1 in the form:
    echo -n "value" | openssl dgst -sha1 -hmac "key"
or
     echo -n "value" | openssl sha1 -hmac "key"
(thank you http://stackoverflow.com/a/7285256/1153645 )

but any hash can be used in the form
X-ESRT: {hash}$string
e.g.
X-ESRT: {hmac-sha512}really-really-long-string-here_but-at-least-it-is-more-secure

=head2 Example config

=head3 exim4

  exim.conf:
        acl_check_rcpt:
             accept  authenticated = *
              add_header    = Sender: $sender_address
              control       = submission
              add_header    = X-ESRT: \
            ${hmac{sha1}{ESRT_SECRET}{${primary_hostname},$authenticated_id,$tod_log}}
          endpass

=head3 SECURITY

This needs a cool-down so that people do not spam us with abuse requests
(and where we have log entries, they do not thrash our server with grep)

(oh and you will have to add the "upload spam file".

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.
main has to be public! so that we can accept anonymous complaints.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/!main/);
    $self->tt_params({ submenu => \%submenu });
}

=head2 RUN MODES

=head3 main

  * This has policy and a submission form

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $username = '';
    my $q = \%{ $self->query() };
    if($self->authen->username){ 
        $username = $self->authen->username;
        $self->tt_params({ username => $username});
    }else{
        $self->tt_params({
                title => 'Report Email abuse',
            show_login=>1,
            no_menu=>1,
              no_home => 1,
                  dest=>'abuse',
        }); 
    }
    #foreach my $ak (keys %{ $q->{'param'} } ){ warn "$ak = " . $q->param($ak); }

# you are here about to parse the form (we want to find the X-ESRT as fast as possible and if it is not there
    my $r = $self->_check_ESTR($q->param('complaint'));
    my $new_ticket = "Potential abuse reported\n";

    my $ajax_msg='';
    if($r && $r->{ESRT}){
        $ajax_msg = "We have sent this off for validation";
        $self->tt_params({ ajax_msg => $ajax_msg });
        #warn "we found \$r " . Dumper($r);
                my $logs = $self->_search_logs($r->{id});
                if(defined $logs){
                    $new_ticket .= "\n----------------------------------------------------------------------\n";
                    $new_ticket .= $logs;
                }
    }else{
        $ajax_msg = "Either your report did not have enough headers or it did NOT originate from one of our users. Thank you for taking the time.";

        if(defined $opt{D} && $opt{D}>=1){
            # then we send the report in anyway, but to a different queue
            $ajax_msg = "We will take a closer look but at first glance it seems that: " . $ajax_msg;

            # ever heard of abstration?
                if(defined $opt{debug}){
                    $new_ticket .= Dumper(\$opt{debug});
                }
                my($from,$to,$subject);
                if($q->param('reporter')){
                    $new_ticket .= " by " . $q->param('reporter');
                    $from = $q->param('reporter');
                    if($q->param('vent')){
                        $new_ticket .= " who said: " . $q->param('vent');
                    }
                }elsif($q->param('vent')){
                    $new_ticket .=". They said: " . $q->param('vent');
                }
                if($q->param('feeling')){
                    $new_ticket .= "\n Feeling: " . $q->param('feeling') . "\n";
                }
                $new_ticket .= "Full header follows: " . $q->param('complaint') . "\n";
                my $pe_id = 0;
                $pe_id = $self->param('pe_id');
                if(defined $pe_id && $pe_id=~m/^\d+$/){
                    $new_ticket .= 'peid: ' . $pe_id;
                }

                unless($from){ $from = '"Anonymous" <bin@example.com>'; }
                my $site = 'from //notice.strongbox.info/Abuse';
                unless($subject){ $subject = "Failed Abuse report $site"; }
                # we /could/ extract the subject from the headers in the report!

                use Notice::C::Email qw(_sender);
                #$to = 'failed-ESRT-abuse@strongbox.info';
                if(defined $opt{D} && $opt{D}>=1){
                    $to = $fallback_address;
                }else{
                    $to = $abuse_address;
                }
                my $e = new Notice::C::Email;
                my $sent = $e->_sender($from,$to,$subject,$new_ticket) || warn "failed to send Abuse $!";
                { no strict "refs";
                $r->{'sent'} = $sent;
                }

        }

        #$self->tt_params({ ajax_msg => $ajax_msg });
        $self->tt_params({ ajax_msg => "<span title=\"" . Dumper(\$r) . "\">$ajax_msg</span>" });
        return $self->tt_process();
    }
    # we calculate to see if the X-ESRT is valid based on the hmac_sha1_hex the other values;
    # becuse we are using the zulu time as one of the pieces of data we may have to do more than
    # one hash to be certain.

    my($from,$to,$subject);
    if($q->param('reporter')){
        $new_ticket .= " by " . $q->param('reporter');
        $from = $q->param('reporter');
        if($q->param('vent')){
            $new_ticket .= " who said: " . $q->param('vent');
        }
    }elsif($q->param('vent')){
        $new_ticket .=". They said: " . $q->param('vent');
    }
    if($q->param('feeling')){
        $new_ticket .= "\n Feeling: " . $q->param('feeling') . "\n";
    }
    #$self->tt_params({ ajax_msg => $new_ticket });
    $new_ticket .= "Full header follows: " . $q->param('complaint') . "\n";
    #$self->tt_params({ ajax_msg => "<span title=\"$new_ticket\">$ajax_msg</span>" });
    $self->tt_params({ ajax_msg => "<span title=\"Thank you for taking the time\">We will do what we can</span>" });

    my $pe_id = 0;
    $pe_id = $self->param('pe_id');
    if($pe_id && $pe_id=~m/^\d+$/){
        $new_ticket .= 'peid: ' . $pe_id;

        # maybe we should only
        # $self->_search_logs($r->{id}); 
        # if they are logged in!

    }
    # then we silently "thank them" and move on. (We don't thank them, that is done their side using javascript).
    # this reduces our load if they are trying to DDoS us.

=pod
    you have to set up:
        abuse@example.com -> |/usr/sbin/rt-mailgate --queue 'Abuse' --action correspond --url 'http://support.example.com/'
abuse-comment@example.com -> |/usr/sbin/rt-mailgate --queue 'Abuse' --action comment --url 'http://support.example.com/'

=cut

    # here we "create the ticket" by simply sending an email to abuse@$domain
    # we /could/ do direct creation using rt-mailgate or rt-addons/enhanced-mailgate
    # but that presumes that we have RT on the same server.

    unless($from){ 
        #$from = '"Anonymous" <>'; 
        $from = '"Anonymous" <bin@example.com>'; 
    }
    my $site = 'from //notice.strongbox.info/Abuse';
    unless($subject){ $subject = "Abuse report $site"; }
    # we /could/ extract the subject from the headers in the report!

    use Notice::C::Email qw(_sender);
    if(defined $opt{D} && $opt{D}>=1){
        $to = $fallback_address;
    }else{
        $to = $abuse_address;
    }
    my $e = new Notice::C::Email;
    $e->_sender($from,$to,$subject,$new_ticket);

    #if($q->param('debug')){ $self->tt_params({ hives => '1' }); }
    return $self->tt_process();
}

=head3 _ESRT_SECRET

this looks for the ESRT_SECRET

=cut

sub _ESRT_SECRET {
    my $self = shift;
    my $s='';
    my $hostname='';
    if($self->cfg('esrt')){ $s =$self->cfg('esrt'); }
    elsif($self->cfg('esrt_secret')){ $s =$self->cfg('esrt_secret'); }
    elsif($self->cfg('exim_secret')){ $s =$self->cfg('exim_secret'); }
    elsif($self->cfg('ESRT')){ $s =$self->cfg('ESRT'); }
    elsif($self->cfg('ESRT_SECRET')){ $s =$self->cfg('ESRT_SECRET'); }

    unless($s){
        my $exim_conf=`exim -bV|grep Configuration|awk '{print \$NF}'`;
        #warn "could not find exim $exim_conf" unless $exim_conf;
        #warn "located exim config at: $exim_conf" if $exim_conf;
        chomp($exim_conf);
        if(-f "$exim_conf"){
            $s=`grep ESRT_SECRET= $exim_conf|sed 's/.*=//'`;
            $hostname=`grep primary_hostname $exim_conf|head -n1|awk '{print \$NF}'`;
        }elsif(-f "/etc/exim/exim.conf"){
            $s=`grep ESRT_SECRET= /etc/exim/exim.conf|sed 's/.*=//'`;
            $hostname=`grep primary_hostname /etc/exim/exim.conf|head -n1|awk '{print \$NF}'`;
        }
    }
    chomp($s);
    chomp($hostname);
    return ($s,$hostname);
}

=head3 _test_message

example code to verify a X-ESRT:
also we can call this as a socket daemon so that it can listen for messages sent to abuse@

=cut

sub _test_message {
    my $message = shift;
    my $exim_conf=`exim -bV|grep Configuration|awk '{print \$NF}'`;
    chomp $exim_conf;
    my $ESRT_SECRET='';
    my $hostname='';
    if(-f "$exim_conf"){
        $ESRT_SECRET=`grep ESRT_SECRET= $exim_conf|sed 's/.*=//'`; chomp($ESRT_SECRET);
        $hostname=`grep primary_hostname $exim_conf|head -n1|awk '{print \$NF}'`;
    }elsif(-f "/etc/exim/exim.conf"){
        $ESRT_SECRET=`grep ESRT_SECRET= /etc/exim/exim.conf|sed 's/.*=//'`; chomp($ESRT_SECRET);
        $hostname=`grep primary_hostname /etc/exim/exim.conf|head -n1|awk '{print \$NF}'`;
    }
    chomp $hostname;

    # read message from STDIN
    # and set the following
    my $Sender = 'test@example.com';
    my $zulu='20090708164445Z';
    my $ESRT='1a8daa349a193090150206bf436c57e9c603dc0b';

    if($Sender && $zulu && $ESRT){
        #print `echo -n 'smtp.example.coma,test@example.com,20090708164445Z'|openssl sha1 -hmac '1234567890000009876543211111234567890009876543212345678900976545'`;
        print `echo -n '$hostname,$Sender,$zulu'|openssl sha1 -hmac '$ESRT_SECRET'`;
        print "exim -be '\${hmac{sha1}{$ESRT_SECRET}{\${primary_hostname},$Sender,$zulu}}'\n" if $opt{D}>=1;
        my $check = `exim -be '\${hmac{sha1}{$ESRT_SECRET}{\${primary_hostname},$Sender,$zulu}}'`;
        chomp($check);

        use Digest::SHA qw(hmac_sha1_hex);
    my $perl_check = hmac_sha1_hex($hostname,$Sender,$zulu, $ESRT_SECRET);


        if($ESRT eq $check){
            print "$Sender has been spamming\n";
            exit(1);
        }else{
            print "$check did not out " if $opt{D}>=1;
        }
    }else{
        print "Missing something: sender: '$Sender', zulu: '$zulu', ESRT: '$ESRT'\n";
    }
    print "Not sent from " . ( $hostname || 'our server' ) . "\n";
}

=head3 _parse_message

this expects an email header

it tries to extract (the sender, the zulu time, the ESRT)
which is retutned as the keys to a hash
or it will return nothing
=cut

sub _parse_message {
    my $msg = shift;
    my %r;
    return 0 unless $msg=~m/X-ESRT/;
    my @lines = split(/\n/, $msg);
    my $row_count = 0;
    HEADER: foreach my $l (@lines){
        last HEADER if $row_count>=100; # 
        # return 0 if $row_count>=100; # we don't want to parse an entire library of books
        if ($l=~m/X-ESRT:\s*(.+)\s*$/){
                $r{ESRT} = $1;
        }elsif ($l=~m/^\s*by ([^\s]+) with /){
                $r{host} = $1;
        }elsif ($l=~m/^From:\s(.+)\s*$/){
                $r{from} = $1; # if we don't find "sender"
                #$r{html_from} = '<pre>' . $1 . '</pre>'; # if we don't find "sender"
                $r{html_from} = '<pre>';
                $r{html_from} .= $1;
                $r{html_from} .= '</pre>'; # if we don't find "sender"
        }elsif ($l=~m/^Sender:\s(.+)\s*$/){
                $r{sender} = $1;
                $r{sender}=~s/\s*\n$//;
        }elsif ($l=~m/^\s*id ([^;]{15,})\s*$/){
                $r{id} = $1; # message ID (we can search the logs for this)
        }elsif ($l=~m/^\s*for [^;]+; (.+)\s*$/){
                $r{when} = $1; # if we don't find date
        }elsif ($l=~m/^Date:\s(.+)\s*$/){
                $r{date} = $1;
        }
        $row_count++;
    }
    if(%r){
        chomp(%r);
        foreach my $rk (keys %r){
            my $td = $r{$rk};
            chomp($td);
            $td=~s/\s*\n$//g;
            chomp($td);
            $r{$rk} = $td;
        }
        return \%r;
    }
    return 0;
}

=head3 _verify_ESRT

this expects a HASH ref and all that it requires to verify the ESRT
via the hmac_sh1 (or what ever hash version is being used)

=cut

sub _verify_ESRT {
    my $self = shift;
    my $r = shift;
    if($r->{ESRT}){
        #warn "FOUND ESRT: " . $r->{ESRT} . "\n";
        if($r->{ESRT}!~m/^\{.+\}.+$/){ #then we are using the default hmac_sha1_hex
            use Digest::SHA qw(hmac_sha1_hex);
            if($r->{host} && ( $r->{sender} || $r->{from} ) && ( $r->{date} || $r->{zulu} || $r->{when} )){
                # we need to check that we have zulu and sender
                unless($r->{sender}){
                    $r->{sender} = $r->{from};
                    $r->{sender}=~s/^.*\<//;
                    $r->{sender}=~s/\>.*$//;
                    $r->{sender}=~s/^.*\&lt;//;
                    $r->{sender}=~s/\&gt;.*$//;
                    $r->{sender}= lc($r->{sender});
                }
                unless($r->{zulu}){
                    # parse $r->{date} AND while we are at it, $r->{when}
                    use DateTime;
                    use Date::Format;
                    use Date::Parse;

                    # add timezone offsets
                    $Time::Zone::Zone{icst} = +7*3600;
                    $Time::Zone::Zone{jdt}  = +9*3600;

                    if(defined $r->{date}){
                        my $d = str2time $r->{date};
                        my @d = gmtime($d);
                        #my $date= strftime("%Y%m%dT%H%M%S", @d);
                        my $date= strftime("%Y-%m-%d %H:%M:%S", @d);
                        my $rd = $r->{'date'};
                        #warn sprintf('%s', "$r->{'date'}") . ' eq ' . $date;
                        #warn $rd . ' eq ' . $date;
                        $r->{zulu} = $date;
                    }
                    if(defined $r->{when}){
                        # really odd perl 5.10.1 I can't "warn $r->{when}" but I can use it!
                        #my %row = %$r;
                        #my $rw = $row{'when'};
                        #my $rw = +{$r}->{when};
                        #my $rw = sprintf('%s', "$r->{when}");
                        my $rw = $$r{when};
                        #my $rw = "@$r->{when}"; chomp($rw);
                        my $w = str2time $r->{when};
                #warn ref($r->{when});
                        my @w = gmtime($w);
                        #my $when= strftime("%Y%m%dT%H%M%S", @w);
                        my $when= strftime("%Y-%m-%d %H:%M:%S", @w);
                        #warn "<WHEN>";
                        #warn "When: $rw eq $when";
                        ##warn "When: $r->{when} eq $when";
                        #warn "</WHEN>";
                        if($r->{zulu}){
                            $r->{when_zulu} = $when;
                        }else{
                            $r->{zulu} = $when;
                        }
                    }
                }
            }else{
                warn "($r->{host} && ( $r->{sender} || $r->{from} ) && ( $r->{date} || $r->{zulu} || $r->{when} )) <<<< missing";
                chomp($r);
                warn "missing vital data for ESRT calculation: " . Dumper(\$r);
            }
            my $sender = $r->{sender};
            chomp($sender);
            $sender=~s/\s//g;
            $sender=~s/\n//g;
            my $data = $r->{host} . ',' . $sender . ',' . $r->{zulu};
            my ($key,$hostname) = $self->_ESRT_SECRET();
            my $perl_check = hmac_sha1_hex($data, $key);
            chomp($perl_check);
            my $esrt = $r->{ESRT};
            $esrt=~s/\s*\n*//g;
            chomp($esrt);
            #$opt{debug}{$r->{host}}{key} = $key;
            $opt{debug}{$r->{host}}{ESRT} = $esrt;
            $opt{debug}{$r->{host}}{data} = $data;
            $opt{debug}{$r->{host}}{hostname} = $hostname;
            $opt{debug}{$r->{host}}{HASH} = $perl_check;
            #if("$perl_check" ne $r->{'ESRT'}){
            #if("$perl_check" ne "$esrt"){
            if($perl_check!~m/$esrt/){

                # here we compare the oldest and newest date in the headers and if they are only a few seconds appart
                # then we try each of the seconds between


        # NTS you are here checking each time between $r->{zulu} and $r->{when_zulu}

                # thanks http://www.perlmonks.org/?node_id=408174
                use DateTime::Format::Strptime;
                #my $fmt = '%Y-%m-%dT%H:%M:%S.%3NZ';
                #my $fmt = '%Y%m%dT%H%M%S';
                my $fmt = '%Y-%m-%d %H:%M:%S';

                #my ($start, $end) = qw(2004-11-15T18:59:52.863Z
                #                       2004-11-15T19:07:41.972Z);

                my $parser = DateTime::Format::Strptime->new(pattern => $fmt);

                my $dt1 = $parser->parse_datetime($r->{zulu}) or warn "Abuse.pm failed to parse zulu";
                my $dt2 = $parser->parse_datetime($r->{when_zulu}) or warn "Abuse.pm failed to parse when_zulu";

                my $diff = $dt2 - $dt1;

                my $seconds = $diff->hours * 3600 + $diff->minutes * 60 + $diff->seconds;

                if($seconds <= 60){
                    warn "searching time range of $seconds seconds";
                    use DateTime;
                    use Date::Format;
                    use Date::Parse;
                    use DateTime::TimeZone;
                    my $tz = DateTime::TimeZone->new(name => "local");
                   # warn "Your timezone is " .$tz->name;
                   # warn "the offset is " . $tz->offset_for_datetime($dt1);
                    $dt1->add(seconds => $tz->offset_for_datetime($dt1));
                    # we /should/ change exim to just use GMT for its hash.
                    # then we don't have to go through the pain of tracking down which timezone
                    TIME_CHECK: for(my $i=0;$i<=$seconds;$i++){
                        $dt1->add( seconds => 1 );
                        #my $dt_loop = str2time $dt1;
                        ##my @dt = gmtime($dt_loop);
                        #my $when= strftime("%Y%m%dT%H%M%S", @w);
                        #my $next_sec= strftime("%Y-%m-%d %H:%M:%S", @dt);
                        my $next_sec= $dt1->strftime("%Y-%m-%d %H:%M:%S");
                        if($next_sec=~m/1970/ || $next_sec!~/^\d\d\d\d/){
                            warn "failed to parse $dt1";
                            last TIME_CHECK;
                        }
                        my $data =$r->{host} . ',' . $sender . ',' . $next_sec;
                        warn "trying $data";
                        my $loop_check = hmac_sha1_hex($data, $key);
                        if($loop_check eq $esrt){
                            warn "YAY! found $next_sec";
                            $opt{debug}{'found'}{ESRT} = $loop_check;
                            $r->{when_zulu} = $next_sec;
                            return 3;
                            last TIME_CHECK;
                        }else{
                            $opt{debug}{'loop'}{$next_sec} = $loop_check;
                        }
                    }
                }


                #warn "$perl_check ne " . $r->{'ESRT'} . "\n";
                warn "PERL_check: $perl_check :END_PC ne ESRT: $esrt :END_ESRT\n";
                #while(length($perl_check)>=1){
                #    my $pc = chop($perl_check);
                #    my $e = chop($esrt);
                #    if ($pc ne $e){  warn "perl_check $pc ne esrt $e\n"; }
                #}
                $data =$r->{host} . ',' . $sender . ',' . $r->{when_zulu};
                $perl_check = hmac_sha1_hex($data, $key);
                #if($perl_check ne $r->{ESRT}){
                chomp($perl_check);
                $opt{debug}{'when'}{ESRT} = $esrt;
                $opt{debug}{'when'}{data} = $data;
                $opt{debug}{'when'}{hostname} = $hostname;
                $opt{debug}{'when'}{HASH} = $perl_check;
                if($perl_check ne $esrt){
                    warn "$perl_check STILL ne " . $r->{'ESRT'} . "\n";
                    return 0;
                }else{
                    return 2;
                }
            }else{
                return 1;
            }
        }else{
            warn "we have yet to impliment other hash versions";
        }
    }else{
        warn "bad things!";
    }
    return 0;
}

=head3 _search_logs

this used the message ID to collect relevent logs

=cut

sub _search_logs{
    my $self = shift;
    my $id = shift;
    return unless $id;
    return unless $id=~m/^.{16}$/; # MsgIDv-000000-Id
    my $exim_log = '/var/log/exim/main.log';
    if($self->cfg('exim_log')){ $exim_log =$self->cfg('exim_log'); }
    elsif($self->cfg('exim_mainlog')){ $exim_log =$self->cfg('exim_mainlog'); }
    elsif($self->cfg('exim_main')){ $exim_log =$self->cfg('exim_main'); }
    else{ $exim_log = '/var/log/exim/main/log'; }
    unless(-f "$exim_log"){ 
        $exim_log = '/var/log/exim4/mainlog'; #freaks 
    }

    if(-f "$exim_log"){
        my $log = `grep $id $exim_log`;
        # we should check that the log isn't too large
        return $log;
    }
    return 0;
}

=head3 _check_ESTR

This takes in an email header and checks the ESTR

=cut

sub _check_ESTR {
    my $self = shift;
    my $complaint = shift;
    return 0 unless $complaint;
    #warn $complaint;
    #$self->tt_params({ message => 'You have no hives'});
    my $valid = 0;
    my $r = _parse_message($complaint);
    $valid = $self->_verify_ESRT($r);
    if($valid){
        return $r;
    }
    #return $self->tt_process('Notice/C/Abuse/main.tmpl');
    return 0;
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
Though it is old and was written in a rush, (feel free to fix the obvious mistakes.)
Please fix any bugs or add any features you need. You can report them through GitHub.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license:  The MIT License (MIT) or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

