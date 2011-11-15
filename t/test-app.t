#!perl 
#
# $Id: test-app.t 52 2011-06-30 03:22:31Z alexx $
#
use strict;
use warnings;
use Test::More 'no_plan';
eval "use Test::WWW::Mechanize::CGIApp::IF_YOU_HAVE_SET_UP_THE_DATABASE";
if ($@) {
    ok( 1, 'Skipped because you have not enabled it' );
    #plan skip_all =>
    #    "test-app.t requires Test::WWW::Mechanize::CGIApp AND the Notice database to have been set up";
}else{

    use Notice;
    my $mech = Test::WWW::Mechanize::CGIApp->new;
    $mech->app(
       sub {
            my $app = Notice->new(PARAMS => {
                cfg_file => 'config/config.pl',
            });
            #my $app = Notice->new( PARAMS => { cfg_file => ['config.ini'], format => 'equal', });
            $app->run();
        }            
    );
    $mech->get_ok();
}
