#!/usr/bin/env perl

=head1 NAME

server.pl - development httpd for this module

=cut 

my $port = '8060';
my $doc_root = './t/www';

BEGIN {
   unshift @INC, '../../lib', './lib'; #prefer the version of the module that we are in to the one installed on the system
   my $cgi_root = 't/cgi-bin';
   #use Cwd; $cwd = cwd;
   #my $pwd = `readlink -mn $ENV{_}`;
   #print "You are: " . $pwd;
   #$pwd=~s|/([^/]*)$||;
   #chomp($pwd);
   #print " moving from $pwd to t/cgi-bin\n";
   chdir($cgi_root) or die "This is just for dev and debuging; You should be in the root of the Module: $!";
   #print "got to " . cwd ."\n";
}


use warnings;
use strict;
use lib 'lib';
use CGI::Application::Server;
use Notice::Dispatch;
if($ARGV[0] && $ARGV[0]=~m/^\d{1,5}$/){ $port = $ARGV[0]; }
if(!-d $doc_root){ $doc_root = '../www'; }
my $server = CGI::Application::Server->new($port);
$server->document_root($doc_root);
$server->default_index('/index.html'); # we should eval to see if cgi-app-server has been patched (see script/patch)
$server->entry_points({
    '/cgi-bin/index.cgi' => "Notice::Dispatch",
});

print "access your default runmode at /cgi-bin/index.cgi\n";
$server->run;
