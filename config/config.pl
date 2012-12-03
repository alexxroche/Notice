use strict;
my %CFG;

=head1 NAME

Template development config file for CGI::Application::Structured apps.

=cut 

$CFG{installing}=0;
$CFG{db_schema} = 'Notice::DB';
$CFG{db_dsn} = "dbi:mysql:database=notice";
$CFG{db_user} = "notice_adminuser";
$CFG{db_pw} = "12345678-abcd-1234-a693-00188bba79ac";
$CFG{tt2_dir} = "templates";
$CFG{TEMPLATE_OPTIONS} = {
    #COMPILE_DIR => '/tmp/tt_cache',
    #DEFAULT     => 'error.tmpl',
    #PRE_PROCESS => 'defaults.tmpl',
    # http://template-toolkit.org/docs/manual/Config.html#section_TAG_STYLE
    #START_TAG => quotemeta('<%'),
    #END_TAG   => quotemeta('%>'),
    #TAG_STYLE => 'template', #the default
    #TAG_STYLE => 'php',
    #TAG_STYLE => 'asp',
};

$CFG{www_path} = "/var/www/sites/github/Notice/t/www"; #used by custom css
$CFG{DOCUMENT_ROOT} = "templates";
$CFG{using_tinyDNS} = 0;
$CFG{tinyDNS_path} = '/var/www/sites/BytemarkDNS/data';
$CFG{update_dns} = 'sudo /var/www/sites/BytemarkDNS/upload 1>/dev/null';
$CFG{rebuild_dns} = 'sudo nsdc rebuild 1>/dev/null';
$CFG{reload_dns} = 'sudo nsdc reload';
$CFG{default_lang} = 'en_GB';
$CFG{session_timeout} = '+1h';
$CFG{key} = 'NoticeNoticeNoticeNotice_key1234';
$CFG{iv} = '1234567890ABCDEF';
$CFG{admin} = ['notice-dev@alexx.net','a@b.com'];

return \%CFG;
