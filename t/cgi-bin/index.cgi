#!/usr/bin/perl

use strict;
use warnings;
use Notice;
use Notice::Dispatch;
use CGI::Fast;
use FCGI::ProcManager;
my $page_load_time = time;
BEGIN { 
	eval {
	    use Time::HiRes qw( time );
	    $page_load_time = time;
	};
	if($@){
	    $page_load_time = time;
	    #NTS what version of perl did time become a core function?
	}
}

my $CONFIG_FILE;
$CONFIG_FILE = $ENV{CONFIG_FILE} ? $ENV{CONFIG_FILE} :'config/config.pl'; 
my($proc_manager) = FCGI::ProcManager -> new({processes => 2});
$proc_manager -> pm_manage();
my($cgi);

while ($cgi = CGI::Fast -> new() ) {
        $proc_manager -> pm_pre_dispatch();
        CGI::Application::Dispatch -> dispatch(					# This and the next line both work
        #Notice::Dispatch->dispatch(						# This and the above line both work
         args_to_new => {QUERY => $cgi,PARAMS =>{cfg_file => $CONFIG_FILE, cgi_start_time => $page_load_time }},
         prefix      => 'Notice::C',
         table       => [
                ''                   => {app => 'Notice', rm=>'main'},
                '/'                   => {app => 'Notice', rm=>'main'},
                'en/:app'               => {i18n => 'en'}, # this called by https://localhost/cgi-bin/index.cgi/en/main
                'fr/:app'               => {i18n => 'fr'}, # this called by https://localhost/cgi-bin/index.cgi/fr/main
                ':app'               => {},
                'cgi-bin/:app'       => {},
                'cgi-bin/index.cgi'  => {},
                'cgi-bin/index.cgi/fr/:app'     => {i18n => 'fr'},
                'cgi-bin/index.cgi/:app'     => {},
                'cgi-bin/index.cgi/:app/:rm' => {},
                'fr/:app/:rm/:id?'      => {i18n => 'fr'},
                'en_GB/:app/:rm/:id?'      => {i18n => 'en_GB'},
                ':app/:rm/:id?'      => {},
                ':app/:rm/:id/:sid?' => {},
                ':app/:rm/:id/:sid/:extra1?' => {},
        ],
	default => 'main'
        );
        $proc_manager -> pm_post_dispatch();
}
