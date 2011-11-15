use strict;
my %CFG;

=head1 NAME

Template development config file for CGI::Application::Structured apps.

=cut 

$CFG{db_schema} = 'Notice::DB';
$CFG{db_dsn} = "dbi:mysql:database=notice";
$CFG{db_user} = "notice_adminuser";
$CFG{db_pw} = "12345678-abcd-1234-a693-00188bba79ac";
$CFG{tt2_dir} = "templates";
$CFG{using_tinyDNS} = 1;
$CFG{tinyDNS_path} = '/var/www/sites/BytemarkDNS/data';
$CFG{update_dns} = 'sudo /var/www/sites/BytemarkDNS/upload 1>/dev/null';
$CFG{rebuild_dns} = 'sudo nsdc rebuild 1>/dev/null';
$CFG{reload_dns} = 'sudo nsdc reload';


return \%CFG;
