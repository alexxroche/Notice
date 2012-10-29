#!/usr/bin/perl

=head1 name

dump_notice_db.pl

=head1 SYNOPSIS

Dumps the database into config/

=head1 DESCRIPTION

This will try to dump the Notice database

=cut

use warnings;
use strict;
use lib './lib/', '../';
use Notice::DB;
use Config::Auto;
$|=1;

my $cfg_location =  'config';
my $your_pwd = `echo \$PWD`; chomp($your_pwd);
if($your_pwd=~m/script$/ || $your_pwd=~m/config$/){ 
	#warn "you are in $your_pwd, this script should be run from Notice/script/create_notice_db.pl\n"; exit;
	$cfg_location = '../config';
}

my $cfg = Config::Auto::parse("$cfg_location/config.pl", format => "perl");
my %CFG = %{ $cfg };

$CFG{debian_mysql_cfg} = '/etc/mysql/debian.cnf';
$CFG{mysql_root} = 'root';
$CFG{mysql_root_pw} = ''; # we should probably pull this from $ARGV[0] if they know it

# This is probably going to anger some people, and there may be a better way to do it
# but I have not found it yet.

my $distro_check = 'echo $(for i in `ls /etc/*-version /etc/*-release /etc/issue 2>/dev/null`; do [ $(grep ID $i) ] || cat $i|sed "s/ .*//" || [ $(grep ID $i) ] && grep ID $i|sed "s/.*=//"; done)|sed -e "s/ .*//g" -e "s/Ubuntu/Debian/"';
my $distro = `$distro_check`;

if($distro eq 'Debian' && -r $CFG{debian_mysql_cfg}){
$CFG{mysql_root} = `echo -n $(grep ^user $CFG{debian_mysql_cfg} |awk '{print \$NF}')`; 
$CFG{mysql_root_pw} = `echo -n $(grep ^password /etc/mysql/debian.cnf |awk '{print \$NF}')`; 
}

$CFG{MYSQLd}=`which mysqldump`; chomp($CFG{MYSQLd});
my $db = $CFG{db} || 'notice';
$CFG{SQL}= "";

my $bin .= `$CFG{MYSQLd} -u$CFG{db_user} -p$CFG{db_pw} notice > $cfg_location/notice_\$(date +\\%Y\\%m\\%d\\%H\\%M\\%S).mysql`;
