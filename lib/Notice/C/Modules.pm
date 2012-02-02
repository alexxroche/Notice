package Notice::C::Modules;

#use warnings;
use strict;
use base 'Notice';

# NTS pull this from the menu and modules table
my %submenu = (
   '1.0' => [
        '1' => { peer => 1, name=> 'Modules', rm => 'modules', class=> 'navigation'},
    ],
);


=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

Provide an overview of the known modules of Notice
and control them.

=head3 global hash

Each of these should be in the modules table, but for now they are here.
It works... for now.

=head3 %mlist

%mlist - a list of the modules in a handy hash

=head3 %old_modules

%old_modules - an old list of modules back in version 0.01 of Notice

=cut

#Evil global settings (that should be pulled from the DB modules table

my %mlist = (
# single digits are modules \d.\d are menu sections \d.\d.\d is a menu item
0   => { name=>'Installer', menu=>'1',  level=>1000, },
'0.1'   => { name=>'Checker',   menu=>'2',  level=>101,}, #Checker: [httpd,mysql,perl,Notice,] 
1   => { name=>'base',  menu=>'1',  level=>200, },
'1.0'   => { name=>'Configuration', menu=>'1',  level=>90, },
'1.1'   => { name=>'Search',    menu=>'2',  level=>1,}, # Search 1.1
####################################################################
'1.2'   => { name=>'Details',   menu=>'1',  level=>1,}, # Details: 1.2
'1.2.1' => { name=>'Your Details',menu=>'3',    level=>1,},     #Your Details 2.2.1
'1.2.2' => { name=>'Preferences',menu=>'3', level=>1,},     #Preferences  1.2.2
'1.2.2.1'=>{ name=>'CSS',   menu=>'4',  level=>1,},         #CSS  1.2.2.1
'1.2.2.2'=>{ name=>'Menu',  menu=>'4',  level=>100,},           #Menu 1.2.2.2
'1.2.3' => { name=>'Modules',   menu=>3,    level=>100,},       #Modules 1.2.3
'1.2.4' => { name=>'dbSQLadmin',menu=>3,    level=>100,},       #mySQLadmin 1.2.4
'1.2.999'=>{ name=>'Logout',    menu=>3,    level=>20,}, #Logout 1.2.999

6=> => { name=>'HumanResources',menu=>1,    level=>50,},
'6.0'   => { name=>'Human Resources',menu=>2,   level=>50,},
'6.1.1' => { name=>'Holiday',   menu=>3,    level=>4,}, #6.1 Holiday
'6.1.2' => { name=>'Attendance',menu=>3,    level=>20,},    #6.2 Attendance
'6.1.3' => { name=>'Interviews',menu=>3,    level=>20,},    #6.3 Interviews #[holds people,dates,CV,source(which is an account or a person)]
'6.1.4' => { name=>'Events',    menu=>3,    level=>4,}, #6.4 Events #[take code idea from peters list]
####################################################################
'1.3'   => { name=>'Services', menu=>'1',   level=>1,}, # Services  1.3
3=> => { name=>'Domains',   menu=>'1',  level=>4,},
'3.0'   => { name=>'DNS',   menu=>'2',  level=>1,},
'3.1'   => { name=>'Email', menu=>'2',  level=>1,}, #{3.1 Email}
'3.1.1' => { name=>'IMAP/POP3', menu=>'3',  level=>1,}, #{3.1 Email}
'3.1.2' => { name=>'Aliases',   menu=>'3',  level=>1,}, #{3.1 Email}
'3.1.3' => { name=>'SMTP',  menu=>'3',  level=>1,}, #{3.1 Email}
    #Checker: [exim,dovecot,roundcube,]
'3.2'   => { name=>'Websites',  menu=>2,    level=>4,}, #{3.2 Websites}
    #Checker: [Apache]
5   => { name=>'SSL Certs', menu=>1,    level=>6,},
'5.1'   => { name=>'SSL',   menu=>2,    level=>6,},
    #if 3.2 {5.1 CA}
7   => { name=>'PGP',   menu=>1,    level=>4,},
'7.1'   => { name=>'RESERVED for alexx', menu=>1,    level=>4,}, #if 3.1 {7.1}
    #7.2 INE - Inter Notice Exchange - lets copies of Notice talk to each other
    #                  and pipeline messages
8   => { name=>'Assets',    menu=>1,    level=>4,},
9   => { name=>'SSH',   menu=>1,    level=>6,},
# requires module 8 so we can link SSH keys to Assets (and users)
10  => { name=>'Billing',   menu=>3,    level=>5,},
10.1    => { name=>'Invoices',  menu=>3,    level=>5,},
10.2    => { name=>'Price List',    menu=>3,    level=>5,},
10.3    => { name=>'Promotions',    menu=>3,    level=>5,},
10.4    => { name=>'History',   menu=>3,    level=>5,},
40  => { name=>'Subscriptions',menu=>1, level=>4,},
40.1    => { name=>'Trolly',    menu=>1,    level=>4,},
40.2    => { name=>'Payment',   menu=>1,    level=>4,},
40.3    => { name=>'Statement', menu=>1,    level=>4,},
17  => { name=>'Genealogy', menu=>1,    level=>10,}, #[well if we have a table to link between people this should be a snap
         #export into geneweb format
####################################################################
'1.4'   => { name=>'SysAdmin',  menu=>2,    level=>6,}, # Sysadmin: 1.4
'1.4.1' => { name=>'Accounts',  menu=>3,    level=>6,},     #Accounts 1.4.1 adding a company/family
            #{child accounts} # hidden by default 1.4.1.1
2   => { name=>'Addresses', menu=>1,    level=>1,},
'2.1'   => { name=>'Addresses', menu=>2,    level=>1,},
'1.4'   => { name=>'Users', menu=>2,    level=>1,}, #Users  1.4.2
'1.4.1' => { name=>'Add Users', menu=>3,    level=>5,}, #Users  1.4.2
'1.3.2.1'=>{ name=>'Groups',    menu=>4,    level=>1,},     #{1.3.2.1 Groups} #this is the real power of Notice - lateral power
                      #mixed in with the inherent hierarchical structure
4   => { name=>'IP',menu=>1,   level=>4,},
'4.1' => { name=>'IP database',menu=>2,   level=>4,},
'4.1.1' => { name=>'Allocator', menu=>3,    level=>4,},    # Allocator  4.1
'4.1.2' => { name=>'Search',    menu=>3,    level=>4,},    # Search     4.2
'4.1.3' => { name=>'Blocks',    menu=>3,    level=>4,},    # Blocks     4.3
'4.1.4' => { name=>'VLAN',  menu=>3,    level=>4,},    # VLAN       4.5
'4.1.5' => { name=>'Networks',  menu=>3,    level=>4,},    # Networks   4.6
'4.1.6' => { name=>'Assigned to',menu=>3,   level=>4,},    # Assigned to4.7
'4.1.7' => { name=>'R.I.R.',    menu=>3,    level=>4,},    # R.I.R.     4.8
'4.1.8' => { name=>'History',   menu=>3,    level=>4,},    # History    4.8

11  => { name=>'Radius',    menu=>1,    level=>7,},
12  => { name=>'LDAP',  menu=>1,    level=>7,},
13  => { name=>'Connections',menu=>1,   level=>7,},
'13.1'  => { name=>'Dial up',   menu=>2,    level=>7,}, #Dial up 13.1
'13.2'  => { name=>'ADSL',  menu=>2,    level=>7,}, #ADSL    13.2
'13.3'  => { name=>'Leased Lines',menu=>2,  level=>7,}, #Leased Lines 13.3
14  => { name=>'mySQL', menu=>1,    level=>4,},
15  => { name=>'CRM',   menu=>1,    level=>4,},
16  => { name=>'FTP',   menu=>1,    level=>4,},
####################################################################
);

my %old_modules = (
'-'=> 'This is the outdated list DO NOT USE AS REF',
0=> 'Installer',
1=> 'base',
'1.0'=> '#Checker: [httpd,mysql,perl,Notice,] 1.0',
'1.1'=> '# Search 1.1',
'1.1.1'=>   '# Cookies 1.1.1 #local ud',
'1.1.1.1'=> '# Bookmark 1.1.1.1',
    # BugTrack 1.1.2 # optional Track/bugzilla/RT/ticket system link in?
    # Help     1.1.2.1 # this lets users suggest things or ask for help with a pop-up form (link in the top right)
    #           # if no BugTrack the default is to just email the notice-admin\@\${top_domain_for_this_acid}
####################################################################
    # Details: 1.2
####################################################################
        #Your Details 1.2.1
        #Preferences  1.2.2
            #CSS  1.2.2.1
            #Menu 1.2.2.2
        #    Logout 1.2.3
        #mySQLadmin 1.2.4
####################################################################
    # Sysadmin: 1.3
####################################################################
                #Accounts 1.3.1
                        #{child accounts} # hidden by default 1.3.1.1
                #Users  1.3.2
                        #{1.3.2.1 Groups} #this is the real power of Notice - lateral power
                                          #mixed in with the inherent hierarchical structure
                #Modules 1.3.3
####################################################################
    # Services  1.4
####################################################################
2=> 'Addresses',
3=> 'Domains',
    #3.0 DNS
    #{3.1 Email}
    #Checker: [exim,dovecot,roundcube,]
    #{3.2 Websites}
    #Checker: [Apache]
4=> 'IP',
    # Allocator  4.1
    # Search     4.2
    # Blocks     4.3
    # VLAN       4.5
    # Networks   4.6
    # Assigned to4.7
    # R.I.R.     4.8
    # History    4.8
5=> 'SSL Certs',
    #5.1 CA
    #5.1.1 CA checker (uses INX for a distributed root and validity check in a web of trust way rather than top down) 
6=> 'HumanResources',
    #6.1 Holiday
    #6.2 Attendance
    #6.3 Interviews #[holds people,dates,CV,source(which is an account or a person)]
    #6.4 Events #[take code idea from peters list]
7=> 'PGP',
    #if 3.1 {7.1 for alexx}
    #7.2 INX - Inter Notice Exchange - lets copies of Notice talk to each other
    # (used by 19.1,19.2)                  and pipeline messages
    # 7.3 approval signing
8=> 'Assets',
9=> 'SSH',
    # uses 19.1 to talk to other copies of Notice and 7.3 to confirm changes
    # This way we can have a hidden master that actions only once changes are signed by the right people
    # and if a sysadmin tries to change who the "right people" are the hidden master can see that and block such actions
10=>'Billing',
11=>'Radius',
12=>'LDAP',
13=>'Connections',
    #Dial up 13.1
    #ADSL    13.2
    #Leased Lines 13.3
14=>'mySQL',
15=>'CRM',
16=>'FTP',
17=>'Genealogy', #[well if we have a table to link between people this should be a snap
                 #export into geneweb format
18=>'Virtual Currency',
        # Currency,Date,Open Rate,Close Rate,Volume,Min Rate,Avg Rate,Max Rate,Min Qty,Avg Qty,Max Qty
        # Karma, => [ system, method, ]

19=>'XMPP',
        #19.1 server
        #19.2 API module
    # 7.2 is technically "optional" but without, other copies of Notice will ignore you by default
20=>'SOAP::API',
        # pluggable with any other module e.g. Domains::Email::API
####################################################################
);

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/^(?!main)/);
    my $page_loaded = 0;
    eval {
        use Time::HiRes qw ( time );
        $page_loaded = time;
    };
    if($@){
        $page_loaded = time;
    }

    # we /could/ put this in Notice.pm but then it would be less accurate
    if($self->param('cgi_start_time')){
        $self->tt_params({page_load_time => sprintf("Page built in: %.2f seconds", ($page_loaded - $self->param('cgi_start_time')))});
    }elsif($self->param('page_load_time')){
        $self->tt_params({page_load_time => sprintf("Page loaded %.2f seconds", ($page_loaded - $self->param('page_load_time')))});
    }

    $self->tt_params({submenu => \%submenu});

    # debug message
    if($self->param('i18n')){ $self->tt_params({warning => '<span class="small lang i18n">Lang:' . $self->param('i18n') . '</span>'}); }
}

=head2 mlist_sort

sort the module list hash

=cut

sub mlist_sort{ 
    if( ($a=~m/^$b/ || $b=~m/^$a/) && $a=~m/^\d\.\d\.\d/ && $b=~m/^\d\.\d\.\d/){
        ( substr($a,4) <=> substr($b,4) || $a cmp $b )
    }elsif($a=~m/^$b/ || $b=~m/^$a/){
        ( $a <=> $b || $a cmp $b );
    }else{
        $a <=> $b; 
    }
}


=head2 RUN MODES



=head3 index

What? Why is this here? I thought that we had chosen main over index
as explained in README

=cut

sub index: StartRunmode {
    my ($c) = @_;

    my $message = "<pre><table>";
    foreach my $keynum (sort mlist_sort keys %mlist){
        my($checked,$disabled);
        my $indent;
        $indent = '&nbsp; ' if $keynum=~m/\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+\.\d+\.\d+/;
        my $class = 'notab';
        $class = 'onetab' if $keynum=~m/\d+\.\d+/;
        $class = 'twotab' if $keynum=~m/\d+\.\d+\.\d+/;
        $class = 'threetab' if $keynum=~m/\d+\.\d+\.\d+\.\d+/;
        $class = 'fourtab' if $keynum=~m/\d+\.\d+\.\d+\.\d+\.\d+/;

        if($mlist{$keynum}{name}){
            $message .= qq (<tr class="thinborder"><td><span class="$class">$indent$mlist{$keynum}{name}</span></td><td>$keynum</td></tr>);
        }
    }
    $message .= "</table>";

$message .= qq |<br/> <br/> </pre> |;
foreach my $om (sort { $a <=> $b } keys %old_modules){
    $message .= "$om = $old_modules{$om}<br />\n";
}


    $c->tt_params({
	message => $message,
	title   => 'C::Modules'
		  });
    return $c->tt_process();
    
}

1;    # End of 

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug- at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Application::Plugin::DBIC::Schema>, L<DBIx::Class>, L<CGI::Application::Structured>, L<CGI::Application::Structured::Tools>

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alexx Roche, all rights reserved.

=cut

