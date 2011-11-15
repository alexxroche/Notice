#!/usr/bin/perl

use strict;
use warnings;
use Notice;
use Notice::Dispatch;
use CGI::Fast;
use FCGI::ProcManager;
my $CONFIG_FILE;
$CONFIG_FILE = $ENV{CONFIG_FILE} ? $ENV{CONFIG_FILE} :'config/config.pl'; 
my($proc_manager) = FCGI::ProcManager -> new({processes => 2});
$proc_manager -> pm_manage();
my($cgi);
while ($cgi = CGI::Fast -> new() ) {
        $proc_manager -> pm_pre_dispatch();
        CGI::Application::Dispatch -> dispatch(					# This and the next line both work
        #Notice::Dispatch->dispatch(						# This and the above line both work
         args_to_new => {QUERY => $cgi,PARAMS =>{cfg_file => $CONFIG_FILE}},
         prefix      => 'Notice::C',
         table       => [
                ''                   => {app => 'Notice', rm=>'main'},
                '/'                   => {app => 'Notice', rm=>'main'},
                ':app'               => {},
                'cgi-bin/:app'       => {},
                'cgi-bin/index.cgi'  => {},
                'cgi-bin/index.cgi/:app'     => {},
                'cgi-bin/index.cgi/:app/:rm' => {},
                ':app/:rm/:id?'      => {},
                ':app/:rm/:id/:sid?' => {},
                ':app/:rm/:id/:sid/:extra1?' => {},
        ],
	default => 'main'
        );
        $proc_manager -> pm_post_dispatch();
}
