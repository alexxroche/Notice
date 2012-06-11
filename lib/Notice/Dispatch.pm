package Notice::Dispatch;

=head1 NAME

Template URL dispatcher for CGI::Application::Structured apps.

=cut 
my @clr = caller();
my $caller = 'index.cgi';
if( $clr[1]=~m/server.pl/){ $caller = ''; } # we don't want to sete page_load_time

use base 'CGI::Application::Dispatch';
require Notice;

my $page_load_time = 0;
{ #should this be here or in Notice.pm ?
  eval {
    use Time::HiRes qw( time );
    $page_load_time = time if $caller;
  };
  if($@){
    $page_load_time = time if $caller;
  }
    # If this is called by server.pl  we need to let Notice.pm set plt
    # due to persistence.
  
}

=head2 dispatch_args

This dispatches the args

=cut

my $cfg_file = 'config/config.pl';

if(! -d 'config'){ $cfg_file = '../../config/config.pl'; } # for server.pl

sub dispatch_args {
	return {
		prefix      => Notice::C, #lets protect against arbitrary code being run
		args_to_new =>{PARAMS =>{cfg_file => $cfg_file, caller => $caller, plt => $page_load_time, error_mode=>'myerror'} },
        #args_to_new => {PARAMS =>{cfg_file => ['config.ini'], format => 'equal'}}, #if you prefer
		table       => [
			''                   => {app => 'Notice', },
			'en_GB/:app/:id?/:sid?' => {i18n => 'en_GB'}, # for i18n
			'en/:app/:rm?/:id?/:sid?' => {i18n => 'en'}, # for i18n
			'fr/:app/:rm?/:id?/:sid?'=> {i18n => 'fr'},
			':app'               => {},
			':app/:rm/:id?'      => {},
			':app/:rm/:id/:sid?' => {},
			':app/:rm/:id/:sid?/:did?' => {},
            ':app/:rm/:id/:sid/:did?/:eid?'=> {},
            ':app/:rm/:id/:sid/:did?/:eid?/:*'=> { fid => 1},
			'*' => { app => 'myerror', rm=>'main'},

		],
		default => 'main',
        #error_document => '<error.tmpl',
	};
}
1;
