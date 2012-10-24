#!/usr/bin/perl

=head1 name

create_notice_db.pl

=head1 SYNOPSIS

Creates the notice database

=head1 DESCRIPTION

This will try to install the database needed for for Notice
(It needs a lot of checks adding but it is better than nothing.)

=cut

use warnings;
use strict;
use lib './lib/','../lib';
use Notice::DB;
use Config::Auto;
$|=1;

my $cfg_location =  'config';
my $your_pwd = `echo \$PWD`; chomp($your_pwd);
if($your_pwd=~m/script$/){ 
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

$CFG{MYSQLd}=`which mysql`; chomp($CFG{MYSQLd});
my $db = $CFG{db} || 'notice';
$CFG{SQL}= "";

# NOTE check access

# NOTE check to see if there is a database
#unless( -d "/var/lib/mysql/$db"){
	$CFG{SQL}= "CREATE DATABASE IF NOT EXISTS $db;";
#}

# NOTE check to see if the privs have already been set

$CFG{SQL}.= qq|GRANT ALL ON \\\`$db\\\`.* TO \\\`$CFG{db_user}\\\`\@\\\`localhost\\\` IDENTIFIED BY '$CFG{db_pw}';|;
$CFG{SQL}.="FLUSH PRIVILEGES;";

# There might not be a root password, so if there is not then we don't want to be prompted for one
# (that is just confusing and a pointless keystroke )
if($CFG{mysql_root_pw} && $CFG{mysql_root_pw} ne ''){ $CFG{mysql_root_pw} = '-p' . $CFG{mysql_root_pw}; }

my $bin = `$CFG{MYSQLd} -u$CFG{mysql_root} $CFG{mysql_root_pw} -e "$CFG{SQL}"`;

$bin .= `$CFG{MYSQLd} -u$CFG{db_user} -p$CFG{db_pw} notice < $cfg_location/notice.mysql`;

# Check that we can now connect

my $self = Notice::DB->connect($CFG{'db_dsn'},$CFG{'db_user'},$CFG{'db_pw'});
# select do_name,do_status,do_added,rent_start,rent_end,ac_name from domains LEFT JOIN rental on rent_tableid = do_id LEFT JOIN accounts on ac_id = do_acid;

# check that we have the permissions that we need; (Why isn't this in t/mysql/(access, permissions, installed).t ?

