package Notice::Dispatch;

=head1 NAME

Template URL dispatcher for CGI::Application::Structured apps.

=cut 

use base 'CGI::Application::Dispatch';
require Notice;

my $page_load_time = 0;
{ #should this be here or in Notice.pm ?
  eval {
    use Time::HiRes qw( time );
    $page_load_time = time;
  };
  if($@){
    $page_load_time = time;
  }
}


=head2 dispatch_args

This dispatches the args

=cut

sub dispatch_args {
	return {
		prefix      => Notice::C, #lets protect against arbitrary code being run
		args_to_new =>{PARAMS =>{cfg_file => 'config/config.pl'}, plt => $page_load_time},
        #args_to_new => {PARAMS =>{cfg_file => ['config.ini'], format => 'equal'}}, #if you prefer
		table       => [
			''                   => {app => 'Notice', rm =>'main'},
			'en/:app'            => {i18n => 'en'}, # for i18n
			'fr/:app'            => {i18n => 'fr'},
			':app'               => {},
			':app/:rm/:id?'      => {},
			':app/:rm/:id/:cid?' => {},

		],
		default => 'main'
	};
}
1;
