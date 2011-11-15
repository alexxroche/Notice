package Notice::Dispatch;

=head1 NAME

Template URL dispatcher for CGI::Application::Structured apps.

=cut 

use base 'CGI::Application::Dispatch';
require Notice;

=head2 dispatch_args

This dispatches the args

=cut

sub dispatch_args {
	return {
		prefix      => Notice::C, #lets protect against arbitrary code being run
		args_to_new =>{PARAMS =>{cfg_file => 'config/config.pl'}},
        #args_to_new => {PARAMS =>{cfg_file => ['config.ini'], format => 'equal'}}, #if you prefer
		table       => [
			''                   => {app => 'Notice', rm =>'main'},
			':app'               => {},
			':app/:rm/:id?'      => {},
			':app/:rm/:id/:cid?' => {},

		],
		default => 'main'
	};
}
1;
