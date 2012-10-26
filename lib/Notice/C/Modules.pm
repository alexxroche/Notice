package Notice::C::Modules;

#use warnings;
use strict;
use lib 'lib';
use base 'Notice';
my %opt;
$opt{D}=0;

# NTS pull this from the menu and modules table
my %submenu = (
   '1.0' => [
        '1' => { peer => 1, name=> 'Modules', rm => 'modules', class=> 'navigation'},
        '2' => { peer => 1, name=> 'mysql', type=>'square', indent=>'1', rm => 'modules/mysql', class=> 'navigation'},
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


####################################################################
#
# N.B. A Notice Module is NOT the same as a perl module!
#
# A Notice module should probably have been called a plugin, but we
# can visit that later.
#
# Each module (within Notice 1.0) falls into one of these categories:
    # Details: 1.2   "Information about users"
    # Sysadmin: 1.3  "Configurations"
    # Services  1.4  "Services"
# some things could be in any or more than one category.
# Notice itself is a module as it provides a function/service
# For flexibility most modules are independent of these categories.

# Why do we have modules? 
# Because it is a mistake to presume the functionality that
# the users will require.

# Each Notice::Module consists of one of more whole files and must include
# a module manifest.
# Each module may have have whole database tables and MAY include
# one or more inserts/updates to other tables.
# For this reason the manifest specifies dependent modules
# and dependent tables. (A module may include a whole copy of a 
# dependent table for portability.)
#
# this list also included module categories and module components
#
# Most modules will be a single file in lib/Notice/C/
####################################################################


my %mlist = (
# single digits are modules \d.\d are menu sections \d.\d.\d is a menu item
0   => { uuid=>'7CD530D6-4479-3FDA-AB42-8A37DDF99CEA', name=>'Installer', menu=>'1',  level=>1000, },
'0.1'   => { uuid=>'D993E342-1735-32E2-805A-E8A69089CA91', name=>'Checker',   menu=>'2',  level=>101,}, #Checker: [httpd,mysql,perl,Notice,] 
1   => { uuid=>'FC3B9074-135C-3E78-B412-5DD6FFCFA784', name=>'base',  menu=>'1',  level=>200, },
'1.0'   => { uuid=>'12fdc608-4211-11e1-9b60-00188bba79ac', name=>'Configuration', desc=>'Define how it all works', order=>'99', runmode=>'config', cat=>'sysadmin', menu=>'1',  level=>90, },
'1.0.1'=>  { uuid=>'BC6E8937-21EF-387A-8254-D17E7CC08CCB', name=>'Cookies', meta=>'because the .eu is silly'},
'1.1'   => { uuid=>'00886418-8DE1-38FE-A170-6F2EB159D839', name=>'Search',    menu=>'2',  level=>1,},
'1.1.2.1' => { uuid=>'422371CD-F2AD-38FF-B080-A356358124B8', name=>'Help',menu=>3,    level=>100,}, #lets users suggest things or ask for help with a pop-up form (link in the top right)
    #    if no BugTrack the default is to just email the notice-admin\@\${top_domain_for_this_acid}
####################################################################
'1.2'   => { uuid=>'1537E8D8-F107-3125-94D5-38BD7FC871F9', name=>'Details',   menu=>'1',  level=>1,},
'1.2.1' => { uuid=>'2B0DC7F4-F940-3BA9-9AD9-4ACE4BE588BC', name=>'Your Details',menu=>'3', runmode=>'details',  level=>1,},
'1.2.2' => { uuid=>'09A7438C-D3CE-38DD-9200-4722F781E0FB', name=>'Preferences',menu=>'3', runmode=>'prefs', deps=>'1,1.2.1', level=>1,},
'1.2.2.1'=>{ uuid=>'28FAB916-AD86-3B4D-969B-D58B79DF02C9', name=>'CSS',   menu=>'4',  level=>1,},
'1.2.2.2'=>{ uuid=>'38E2F4FD-46FD-36B5-A2E1-5FDC76D88BA8', name=>'Menu',  menu=>'4',  level=>100,}, 
'1.2.3' => { name=>'Modules', menu=>3, level=>100, desc=>'The Modules of Notice', uuid=>'a99976ee-3c6f-11e1-a234-00188bba79ac', order=>1, cat=>'base', ver=>'0.01', runmode=>'modules' },
'1.2.4' => { uuid=>'C5C9A2F2-03C2-3A10-84DE-33B409512DC7', name=>'dbSQLadmin',menu=>3, runmode=>'dbsqladmin', desc=>'direct access to the DB', level=>100,},       #mySQLadmin 1.2.4
'1.2.999'=>{ uuid=>'C8BA2B02-A63A-375A-93C4-29CCADDF4F46', name=>'Logout',    menu=>3,    level=>20,}, #Logout 1.2.999

6=> { uuid=>'F27F5CDE-BEB2-34EB-9EB5-06B7301BE6CB', name=>'HumanResources',menu=>1,    level=>50,},
'6.1.1' => { uuid=>'FA6B43B7-14E4-3DEA-ABCF-11299224D41F', name=>'Holiday',   menu=>3,    level=>4,}, #6.1 Holiday
'6.1.2' => { uuid=>'73E7ECA6-96CD-3C1F-8FDB-16F666A0D5F5', name=>'Attendance',menu=>3,    level=>20,},    #6.2 Attendance
'6.1.3' => { uuid=>'7ECC9D42-4F33-31C3-B289-4A77FF62D074', name=>'Interviews',menu=>3,    level=>20,},    #6.3 Interviews #[holds people,dates,CV,source(which is an account or a person)]
'6.1.4' => { uuid=>'D2113903-8387-310E-9F8F-393A029DE18D', name=>'Events',    menu=>3,    level=>4,}, #6.4 Events #[take code idea from peters list]
'1.3'   => { uuid=>'4F39F1FC-129A-35A1-B3EB-A58D203276C6', name=>'Services', menu=>'1',  cat=>'category', level=>1,},
3=> => { uuid=>'8cf15874-9cb8-11e0-beed-00188bba79ac', name=>'Domains', mo_id=>'3', menu=>'1',  deps=>'1', level=>4, order=>'1', desc=>'Domain names', cat=>'service', action=>'insert', ver=>'0.03'},
'3.0'   => { uuid=>'4C9F4938-E691-3312-81F6-04E4748A924E', name=>'DNS',   menu=>'2',  level=>1,},
'3.1'   => { uuid=>'16268bac-3c71-11e1-9f6f-00188bba79ac', name=>'Email', deps=>'1,2', order=>'2', cat=>'service', ver=>'0.01', runmode=>'email', menu=>'2',  level=>1,},
'3.1.1' => { uuid=>'e13a9120-de9a-4ec1-877d-34c4f719b538', name=>'IMAP/POP3', desc=>'Storage for email messages; An email account', menu=>'3',  level=>1, deps=>'0,1,3', order=>'1', cat=>'service', runmode => 'imap', action=>'insert', ver=>'0.03' },
#'3.1.1.1' => { uuid=>'E16A1BDD-356B-F319-CAAB-1E94F8A550C6', name=>'Dovecot config',  menu=>'3',  level=>1,},
#'3.1.1.2' => { uuid=>'$(uuid('roundcude','checke round')', name=>'Roundcube config', desc=>'probably in the wrong section', menu=>'3',  level=>1,},
'3.1.2' => { uuid=>'FBA114B9-7A57-3EBD-AC6B-F56F92BDFDFE', name=>'Aliases',   menu=>'3',  level=>1,},
'3.1.3' => { uuid=>'1936FBDD-53B6-3F91-ACAB-E194F8A5560C', name=>'SMTP',  menu=>'3',  level=>1,},
#'3.1.3.1' => { uuid=>'913F6BDD-356B-F319-CAAB-1E94F8A550C6', name=>'Exim config',  menu=>'3',  level=>1,},
'3.2'   => { uuid=>'597AAFAE-1437-3E4C-98B1-2B7E92219E65', name=>'Websites',  menu=>2,    level=>4,},
'3.2.1' => { uuid=>'39E16214-9317-35C5-8FB5-BEA5C6C566B3', name=>'Apache Config'},    #Checker: [Apache]  (should this be independent of Domains?
5   => { uuid=>'042C273E-E323-31AB-B449-27A2AEECA80C', name=>'SSL Certs', menu=>1,    level=>6,},
'5.1'   => { uuid=>'FFCD2FFE-2D3C-3AAA-87BD-72D27B7DC567', name=>'SSL Checker',  deps=>'3.2', menu=>2,    level=>6,},
'5.2'   => { uuid=>'E6626D80-2B2E-3C13-AB88-D4274D9A6815', name=>'Certificate Authority',  deps=>'5.1',  menu=>2,    level=>6,}, 
'5.2.1'   => { uuid=>'8C8B7539-50AB-3B45-B552-018F68AFC65B', name=>'CA Checker',   menu=>2,    level=>6,}, #use INX for a distributed root and validity check in a web of trust 
'5.3'   => { uuid=>'47104671-F492-39BC-B763-6E3A27D81786', name=>'Convergence.io server',   menu=>2,    level=>6,}, 
7=> 'PGP',
7   => { uuid=>'94B07D87-FD2C-3C18-B1B8-68D6EEA327CA', name=>'PGP',   menu=>1,    level=>4,},
'7.1'   => { uuid=>'98fdc608-4211-11e1-9b60-00188bba79ac', name=>'RESERVED for alexx', deps=>'0,1,3.1,7', desc=>'', runmode=>'', cat=>'base', ver=>'0.03', menu=>1, level=>4,},
'7.2' => {uuid=>'140DEC47-0A19-3B88-8B4A-E14A99DA283F', name=>'INX - Inter Notice Exchange'}, #enables copies of Notice talk to each other. (used by 19.1,19.2) and pipeline messages
'7.2.1' => {uuid=>'26B18C8B-7906-34A2-BADC-8A4A8AFC01F5', name=>'jsonINX'}, #enables copies of Notice talk to each other. (used by 19.1,19.2) and pipeline messages
'7.3' => {uuid=>'2A6E82D2-879A-3D84-9892-C5EB39654533', name=>'approval signing'},
'7.4' => {uuid=>'6DEC2857-09A9-3CBA-B221-BFC975F6657C', name=>'Key server'},
8   => { uuid=>'756b67a0-9cb6-11e0-aedf-00188bba79ac', name=>'Assets', deps=>'1', order=>'3', cat=>'service', action=>'insert', ver=>"0.02", runmode=>'assets', desc=>'Asset inventory and manangement',   menu=>1,    level=>4,},
9   => { uuid=>'6B1F9DE7-4AD1-3960-BDB4-234B9EF2E10A', name=>'SSH',   menu=>1,    level=>6,},
# requires module 8 so we can link SSH keys to Assets (and users)
10  => { uuid=>'C8D31F04-FCFE-3276-B0E5-B2E84E2C63B4', name=>'Billing',   menu=>3,    level=>5,},
10.1    => { uuid=>'94B3492F-3883-350B-B073-78E1C3D448D6', name=>'Invoices',  menu=>3,    level=>5,},
10.2    => { uuid=>'CC6B55EB-0961-39B5-A641-278A2E6430E7', name=>'Price List',    menu=>3,    level=>5,},
10.3    => { uuid=>'4369098F-7B39-3C8B-B0C5-D2419150E6FF', name=>'Promotions',    menu=>3,    level=>5,},
10.4    => { uuid=>'7F70CEAC-1FA5-3E8C-8E12-0B08A108C23B', name=>'History',   menu=>3,    level=>5,},
'1.4'   => { uuid=>'89BAD068-B530-3627-8921-A0C419C67D65', name=>'SysAdmin',  menu=>2,    level=>6,},
'1.4.1' => { uuid=>'8B020C28-79AD-3E2E-933F-6DB2E8F6A8AD', name=>'Accounts', desc=>'Accounts', runmode=>'account',  menu=>3,    level=>6,}, # adding a company/family
            #{child accounts} # hidden by default 1.4.1.1
'1.4.2'   => { uuid=>'1908DDD6-4E00-3509-87BB-AAA0A5BDF602', name=>'Users', menu=>2,    level=>1,},
'1.4.2.1' => { uuid=>'529F6295-F89E-35D5-B0FB-52229F60FA2F', name=>'Add Users', menu=>3,    level=>5,},
2   => { uuid=>'A90ADD06-98D3-3529-89E0-A6027E5804D8', name=>'Addresses', menu=>1,  desc=>'Addresses', runmode=>'addresses', cat=>'base',  level=>1,},
'1.3.2.1'=>{ uuid=>'EDFD9D0C-F658-3407-95F8-338B4E560D29', name=>'Groups', desc=>"Group anything within Notice", runmode=>'groups', menu=>4,  level=>1,},     # Groups is the real power of Notice - lateral mix in with the inherent hierarchical structure
4   => { uuid=>'DEBFC2F9-82E2-35A5-B9D4-C701A5FF4B3B', name=>'Internet Protocol',menu=>1,   level=>4,},
'4.1' => { uuid=>'F8F7B13C-AB9E-3565-A6C7-7F6CCB8C6C58', name=>'IP database',menu=>2,   level=>4,},
'4.1.1' => { uuid=>'D919BD55-26C7-3576-908E-C7BC50595466', name=>'Allocator', menu=>3,    level=>4,},    # Allocator  4.1
'4.1.2' => { uuid=>'5B938260-269A-3FA4-A43E-5D45B89955D2', name=>'Search',    menu=>3,    level=>4,},    # Search     4.2
'4.1.3' => { uuid=>'BC24B02D-B56F-30FD-B8FA-B48733CC8146', name=>'Blocks',    menu=>3,    level=>4,},    # Blocks     4.3
'4.1.4' => { uuid=>'3F7E634B-ADA4-3DDE-8431-8CDFF1495ABA', name=>'VLAN',  menu=>3,    level=>4,},    # VLAN       4.5
'4.1.5' => { uuid=>'14891FDA-B825-3684-929B-5E82E2C01842', name=>'Networks',  menu=>3,    level=>4,},    # Networks   4.6
'4.1.6' => { uuid=>'31C9B52C-24B5-3E29-9D70-BCCA675D8AB3', name=>'Assigned to',menu=>3,   level=>4,},    # Assigned to4.7
'4.1.7' => { uuid=>'9678313A-7B15-3CE3-B502-EB8527EB4DAA', name=>'R.I.R.',    menu=>3,    level=>4,},    # R.I.R.     4.8
'4.1.8' => { uuid=>'AAC35B0B-3041-3831-B2EF-43F863BD0C10', name=>'History',   menu=>3,    level=>4,},    # History    4.8

11  => { uuid=>'4D7FE77A-2DDB-3277-883E-2B76DB7E1946', name=>'Radius',    menu=>1,    level=>7,},
12  => { uuid=>'EC6A83E6-8EC3-36AF-AC9C-A80B20C9323C', name=>'LDAP',  menu=>1,    level=>7,},
13  => { uuid=>'72A2D823-2435-34D5-BAAA-F03AE622F417', name=>'Connections',menu=>1,   level=>7,},
'13.1'  => { uuid=>'E6EF8BCD-DF0D-3333-8FEE-551086F60F7E', name=>'Dial up',   menu=>2,    level=>7,},
'13.2'  => { uuid=>'542B1BE1-6BCB-317C-866E-7E363BD05EDB', name=>'ADSL',  menu=>2,    level=>7,},
'13.3'  => { uuid=>'61C7EB21-7C77-3348-B893-F6160C2A900C', name=>'Leased Lines',menu=>2,  level=>7,},
14  => { uuid=>'EB46C0DC-93B6-3B69-83B0-9B1D0372C97B', name=>'Databases', menu=>1,    level=>4,},
'14.1'  => { uuid=>'32E8EDEB-3662-38C3-B859-635CDA6969B5', name=>'mysql', menu=>2,    level=>4,},
'14.2'  => { uuid=>'C8857AE1-A99C-3FA0-9005-7DBCE1DD64F1', name=>'postgresql', menu=>2,    level=>4,},
'14.3'  => { uuid=>'9E08F29C-4413-3356-AD0D-BB2767F16EAC', name=>'sqlite', menu=>2,    level=>4,},
15  => { uuid=>'DC489F35-18D5-3641-A3B5-7E0215ABFB2B', name=>'CRM',   menu=>1,    level=>4,},
16  => { uuid=>'B57A66B5-5538-31CC-A692-256B62968C5E', name=>'FTP',   menu=>1,    level=>4,},
17  => { uuid=>'9D6F223E-D739-3867-A684-E13260A1595E', name=>'Genealogy', menu=>1,    level=>10,}, #[well if we have a table to link between people this should be a snap; and we can export into geneweb format
18  => { uuid=>'65BCF505-E0BA-3E33-90FD-C99B22F2C116', name=>'Virtual Currency'},
'18.1'  => { uuid=>'5EF02186-0E42-3B49-9DDF-5BB0C359336F', name=>'Karma' }, # Karma, => [ system, method, ]
19=> {uuid=>'A936F99F-F16C-30AA-AC5F-52B16B97C23A', name=>'XMPP'},
'19.1' => {uuid=>'F166C4AB-CA03-3CC6-A024-4E2149CCC91B', name=>'XMPP Server', deps=>'7',},
'19.2' => {uuid=>'4BC10B8C-3532-3758-975E-3B50E0DFAD39', name=>'INX XMPP API', deps=>'7',}, # 7.2 is technically "optional" but without, other copies of Notice will ignore you by default
20 => {uuid=>'9C82F7C9-C62B-344B-8633-0A8735B83DAC', name=>'SOAP::API', menu=>0}, # legacy module, pluggable with any other module e.g. Domains::Email::API
'21'=> {uuid=>'FCA55D9D-3160-3006-8461-B32EAAF1FD3E', name=>'Bookmarks'},
'21.1'=> {uuid=>'ACC6642C-9DAA-38B3-87AB-DCE2F98DE83C', name=>'Firefox Sync server'},
22 => {uuid=>'914EDBE0-FB51-340B-BC5B-A50E0E9FC340', name=>'BugTrack'},
'22.1' => { uuid=>'EEFC608E-10E7-3851-8D44-E040018C1309', name=>'RT request Tracker'},
'22.2' => { uuid=>'7D2CDBAF-717C-39EB-AA88-DEB29A18115E', name=>'bugzilla'},
23 => { uuid=>'7AD4C69C-D66F-39D2-89E6-216431D8522C', name=>'Documents',deps=>'1', order=>'11', cat=>'service', desc=>'Document Store', runmode=>'docs'},
'23.1' => { uuid=>'47BDD385-C33C-3DD4-8E17-EE6FC5B551CF', name=>'Syndication'},
'23.1.1' => { uuid=>'DB08A6B3-4206-3FCF-BACD-BCA981EE754C', name=>'RSS server', version=>"0.01", desc=>"RSS 2.0", note=>"use 23.1.2 Atom 1.0"},
'23.1.2' => { uuid=>'C700D3CB-AD09-33CA-BD93-4BD107BEE8D9', name=>'Atom server', version=>"0.01", desc=>"Atom 1.0"},
24 => { uuid=>'1AD2C34C-D66F-39D2-89E6-216431D8522C', name=>'OpenID'},
25 => { uuid=>'9AD8C76C-D66F-39D2-89E6-216431D8522C', name=>'Internectual Property'},
26 => { uuid=>'3cb603d4-acdc-11e1-9b44-00188bba79ac', name=>'Report'},
'26.1' => { uuid=>'60ad2722-acdc-11e1-81af-00188bba79ac', name=>'Report graphs'},
27 => { uuid=>'7713a115-1594-1155-9411-557A15059115', name=>'i18n', desc=>'i10n Internationalisation'},
28 => { uuid=>'74BDD358-3C3C-D3D4-E817-6EEF5C5B15FC', name=>'Wiki'},
'28.1' => { uuid=>'F1151111-2311-11F1-1511-11231111f1FC', name=>'FinikiWiki', runmode=>'wiki'},
30 => { uuid=>'72579BC1-5E11-30D6-B044-47874BA19EC8', name=>'Security'},
31  => { uuid=>'ADC80536-E33A-3AE8-AA49-36DF92377DC4', name=>'Calendar', runmode=>'calendar', desc=>'Calendar',  menu=>1,    level=>4,},
'31.1'  => { uuid=>'87D21124-CAA4-3992-931A-AAF54F7CADCD', name=>'CalDAV server',   menu=>1,    level=>4,},
'32'  => { uuid=>'1B4346E9-C29D-3DBD-9123-CAA335D09AA7', name=>'Contacts',   menu=>1,    level=>4,},
'32.1'  => { uuid=>'AD7AB55E-C5AF-3C71-BB75-849BBE59BC83', name=>'CardDAV server',   menu=>1,    level=>4,},
'33'  => { uuid=>'0F079FF0-62F1-3782-B52B-685A203EF501', name=>'Sales', order=>'4', desc=>'Sales', cat=>'service', runmode=>'sales', dep=>'31,32', menu=>2,    level=>4,},
40      => { uuid=>'54CE721F-173E-374B-B245-1ABB4D5621F2', name=>'Subscriptions',menu=>1, level=>4,},
40.1    => { uuid=>'1C888B19-E197-32B3-BBBF-649D3B1B8EE8', name=>'Trolly',    menu=>1,    level=>4,},
40.2    => { uuid=>'02472949-31EF-3AF7-B69A-EBC2E68DC751', name=>'Payment',   menu=>1,    level=>4,},
40.3    => { uuid=>'0AC27D37-A249-30FE-B6B7-3051E7549119', name=>'Statement', menu=>1,    level=>4,},
50 => { uuid=>'A2776FBF-E9E9-3F06-A1DA-8C5956A6E61B', name=>'Direct services', desc=>'Things that Notice can let people do'},
51  => { uuid=>'F070F90F-261F-7328-5BB2-865A02E3510F', name=>'DEDC', order=>'4', desc=>'Desired Exit Door Codes - how to use the Underground more efficiently', cat=>'service', runmode=>'sales', dep=>'31,32', menu=>2,    level=>4,},
52 => { uuid=>'12379BC9-BE11-03D6-0B44-48774AB1E98C', name=>'Adendum', desc=>'Edit books and documents',},
53 => { uuid=>'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB0', name=>'Beekeeping', desc=>'Record and manage beehives', runmode=>'beekeeping', cat=>'service'},
54 => { uuid=>'b0e75ba0-acfe-11e1-84b2-00188bba79ac', name=>'Yabe', desc=>'Reverse auction', runmode=>'yabe', cat=>'service'},
);

# NTS YOU ARE HERE doing the next few lines to the above hash
# NTS add desc,deps,cat,runmode,notes to each module + default-hierarchy=order
# NTS add catagorie  = '' || base || service || details || sysadmin || function || core
# mo_id=>'3', deps=>'1', order=>'1', desc=>'Domain names', cat=>'service', action=>'insert', ver=>'0.03',
# deps=>'1', order=>'1', cat=>'service', desc=>'', 
# cat=>'service', action=>'insert', desc=>'', 

=pod

 spare UUIDs (a notice module UUID could be "aNewModule1.2.3.4.5" )
09FDF32C-9F93-3DDC-9EDB-1374AA4BA83B
6BC0AF47-10A1-364F-AB6F-5C6BB79A270D
E9E2468D-F3B1-3B05-A77E-E5FF155E8E6C
0FFE4076-40A5-3E79-9EDF-96289EDE0B32
038D1CD7-6B66-3C48-BF68-49F9603307BF
A3513664-8508-3BCE-AF97-8EC4C99E6A96
EA8C9B00-528A-3639-BBFD-329AA3A8A687

=cut

=head1 _example_manifest

 a manifest can be in number of fomats e.g YAML. identified by the file ending

=cut 

my $_example_manifest ='
{ 
 "head": {
   "id": "123123123", "desc":"Notice::Module::manifest", "maturity": [ "idea","request","outline","functional","mature" ],
   "version": "0.01", "_comment": "this is the version of Notice Modules manifest, not the version of this modules",
 }
 "body": {
  "files": { 
    "lib": [ "lib/Notice/C/Example.pm" ], 
    "t": [ "t/0000-example.t" ], 
    "templates": [ "t/cgi-bin/tempaltes/example.tmpl","t/cgi-bin/templates/testing/tmpl" ],
  }
 "_comment": "popularity is optional",
  "popularity": "the number of installs of notice that report, (via INX) that they are using this module",
 }
}';


=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/^(?!main)/);
    $self->tt_params({submenu => \%submenu});
    if($self->param('i18n') && $self->param('debug')){ $self->tt_params({warning => '<span class="small lang i18n">Lang:' . $self->param('i18n') . '</span>'}); }
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

=head3 main

Just a list of Modules - once the list is in the database this will not only list
but will enable and disable modules for this install of Notice, 
and optionally update them from a master server

=cut

sub main: StartRunmode {
    my ($self) = @_;

    my $message = '<table id="modules" class="none">
    <tr>
        <th>Modules and Functions</th>
        <th>Menu Tag</th><th>Version</th>
        <th>Installed</th>
        <th>Enabled</th>
        <th>Category</th>
    </tr>';

    # collect the modules in the database and compare them with the list here
    my $modules_rs = $self->resultset('Module')->search({
                        #'mo_id' => { 'like', '%'},
                       },{
                        '+columns' => [ { is_active => 'mo_runmode AS is_active' } ], # WORKS
                        # '+select' => [ { concat => 'me.mo_runmode', -as => 'is_active' } ], # WORKS
                        #'+select' => [ \'me.mo_runmode AS is_active' ], #this creates the right sql, but no is_active in _column_data
                        #'+select' => [ \'mo_runmode AS is_active' ], #this creates the right sql, but no is_active in _column_data
                        # '+select' => [ 'mo_runmode', ], '+as' => [ 'is_active' ], NO help at all
                        #'+select' => [ { mo_runmode => 'me.mo_runmode', '+as' => 'is_active' }, ],
                        #'+select' => [ 'me.mo_runmode' ],
                        #rows => 1, page => 2, #LIMIT, OFFSET
                    });
     # we are going to have to join the config table to find out is a module is disabled;

    use Data::Dumper;

    ROW: while( my $mo = $modules_rs->next){
        my $mtid = $mo->mo_menu_tag;
        eval {
            
            $mlist{$mtid}{active} = 
            $mo->get_column('is_active') ne $mo->mo_runmode ? $mo->get_column('is_active') : '';
            #$mo->get_column('is_active'); #works as $mo->{_column_data}{is_active};
            #$mlist{$mtid}{active} = $mo->me->is_active; does not work
        };
        if($@){ 
            warn "$@ $! $?";
            #my %deref_mo; %deref_mo = %{ $mo }; $mlist{$mtid}{active} = $deref_mo{_column_data}{is_active} . " ERR";
            $mlist{$mtid}{active} = $mo->{_column_data}{is_active};
        }
        $mlist{$mtid}{name} = $mo->mo_name;
        $mlist{$mtid}{ver} = $mo->mo_version;
        $mlist{$mtid}{rm} = $mo->mo_runmode;    # If there is no runmode then it is Disabled.
        $mlist{$mtid}{desc} = $mo->mo_description;
        $mlist{$mtid}{cat} = $mo->mo_catagorie; # If there isn't a cat then it won't show up in any menu EVEN if a user has it in their menu!
        $mlist{$mtid}{installed} = 1;
    }


    # If they are in the database then they are installed, (and it is possible to install modules that are not in the %mlist hash!)
    #
    # How do we know if they are disabled? Disabled modules have an entry in the config table!
    #

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
    # hmm we should really keep the HTML in the templates and keep the logic as thin/clean as possible
            my $version = $mlist{$keynum}{ver} ? $mlist{$keynum}{ver} : '0.01';
            my $installed = $mlist{$keynum}{installed} ? 'checked="checked"':'';
            my $active = $mlist{$keynum}{active} ? '': 'checked="checked"';
            #my $ravenskul =qw |onclick="if (this.checked) document.getElementById('${keynum}_installed').disabled=true; else document.getElementById('${keynum}_installed').disabled = false;"|; # like clashing barrels, you can never return
            #my $re_no =qw |onclick="if(this.checked){this.checked=true;this.disabled=true};"|; #this seems easier
            #my $no_re =qw |onclick="if(!this.checked){this.disabled=true};"|; #the opposite
            my $timeless =qq |onclick="if(this.checked){this.checked=false}else{this.checked=true};alert('Not possible, yet, to install mods from here');"|; #nothing changes!
            my $disabled = '';
            #$disabled = 'disabled' if ( $self->param('debug') || $self->query->self_url=~m/debug=\d/ || ! $mlist{$keynum}{cat} ); # turning off for debug
            my %cat; # this selects which category each module is in.
            if($mlist{$keynum}{cat}){
                $cat{$mlist{$keynum}{cat}} = 'selected="selected"'; 
               # warn "$keynum = '$mlist{$keynum}{cat}'";
            }else{
                $disabled = 'disabled';
                $timeless = '';
                $installed = '';
                warn "$keynum = '$mlist{$keynum}{cat}'";
            }
            $message .= qq (<tr class="thinborder">
                <td><span class="$class">$indent$mlist{$keynum}{name}</span></td>
                <td>$keynum</td>
                <td>$version</td>
                <td>Installed:<input type="checkbox" id="${keynum}_installed" $disabled $installed $timeless /></td>
                <td>Active:<input type="checkbox" $active/>$mlist{$keynum}{active}</td>
                <td><select name="catagorie" title="$mlist{$keynum}{cat}">
                        <option name="" $cat{'null'}>Disabled</option>
                        <option name="core" title="Immutable" $cat{'core'}>Required</option>
                        <option name="base" title="required functions" $cat{'base'}>Base</option>
                        <option name="service" $cat{'service'}>Service</option>
                        <option name="function" $cat{'function'}>Function</option>
                        <option name="sysadmin" $cat{'sysadmin'}>sysAdmin</option>
                        <option name="details" $cat{'details'}>Details</option>
                        <option name="category" $cat{'category'}>Category</option>
                    </select></td>
            </tr>);
        }
    }
    $message .=qq |</table>|;

    $self->tt_params({
	message => $message,
	page => $opt{debug},

		  });
    return $self->tt_process();
    
}

=head3 mysql

This turns the module list hash into valid mysql

=cut

sub mysql: Runmode {

    my ($self) = @_;
    my $message = '';
    my $page = '';

    $opt{'src'} = 'https://raw.github.com/alexxroche/Notice/master/t/www/modules';
    #use Data::UUID;
    use Notice::C::Account;
    $opt{count}= 1;

    $page = '<pre>DELETE FROM modules; ALTER table modules AUTO_INCREMENT=0; 
LOCK TABLES `modules` WRITE;
/*!40000 ALTER TABLE `modules` DISABLE KEYS */;
<br/>INSERT INTO `modules` VALUES ';
    foreach my $keynum (sort mlist_sort keys %mlist){
        my($uuid);
        if($mlist{$keynum}{uuid} && $mlist{$keynum}{uuid} ne ''){
            $uuid = $mlist{$keynum}{uuid};
        }else{
            #my $ug = new Data::UUID;
            #my $seed = $mlist{$keynum}{name} . $mlist{$keynum}{ver};
            #$uuid = $ug->create_from_name_str("$seed","$seed");
            $uuid = "YOU ARE MISSING ONE!";
        }
        if( defined $opt{UUID}{$uuid} ){
            $opt{borked}{$keynum} = '<span class="warn error">' . $opt{UUID}{$uuid} . '</span>';
        }else{
            $opt{UUID}{$uuid} = $keynum;
        }
        if($mlist{$keynum}{name}){
            my $version = '0.01';
            if($mlist{$keynum}{ver} && $mlist{$keynum}{ver} ne ''){ $version = $mlist{$keynum}{ver}; }
            unless( defined $mlist{$keynum}{author}){ $mlist{$keynum}{author} = 'notice-dev at alexx dot net'; }
            unless($mlist{$keynum}{maint} && $mlist{$keynum}{maint} ne ''){ $mlist{$keynum}{maint} = $mlist{$keynum}{author}; }
            unless($mlist{$keynum}{order} && $mlist{$keynum}{order} ne ''){ $opt{count}++; $mlist{$keynum}{order} = $opt{count};$opt{count}++; }
            unless($mlist{$keynum}{runmode} ){ 
                    $mlist{$keynum}{runmode} = lc ( $mlist{$keynum}{name} ); 
                    $mlist{$keynum}{runmode} =~ s/\s+/_/g;
            }

            my $path = Notice::C::Account::_to_path($keynum);

            $page .= qq (\('$mlist{$keynum}{mo_id}','$mlist{$keynum}{name}','$mlist{$keynum}{desc}','$uuid',);
            $page .= qq ('$keynum','$mlist{$keynum}{order}','$mlist{$keynum}{author}',<br/>);
            $page .= qq ('$mlist{$keynum}{maint}','$mlist{$keynum}{deps}','$mlist{$keynum}{cat}',);
            $page .= qq ('$opt{src}$mlist{$keynum}{src}/${path}src',<br/>'$opt{src}$mlist{$keynum}{update}/${path}update',);
            $page .= qq ('$version','$mlist{$keynum}{runmode}','$mlist{$keynum}{action}','$mlist{$keynum}{notes}');
            $page .= '),<br/>';
            if($opt{borked}{$keynum}){ $page .= " /* $opt{borked}{$keynum} */ \n"; }
        }else{
            $page .=qq |# <span class="warn error">BORKED: $keynum</span><br/>\n|;
        }
    }
    chomp($page);
    $page=~s/\s+\n\s+$//g;
    $page=~s/,<br\/>\s*$/;/;
    $page .= '<br/>\n/*!40000 ALTER TABLE `modules` ENABLE KEYS */;<br/>\nUNLOCK TABLES; </pre> ';



    $self->tt_params({
    message => $message,
    page => $page,
          });
    return $self->tt_process();

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

