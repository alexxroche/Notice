#!/usr/bin/perl
# cdbdump.pl ver 0.1 20050817 alexx at alexx dor net
use strict;
use CDB_File;

sub help {
    print "Usage: $0 file.cdb\nCopyright 2005 Cahiravahilla publications\n"; 
    exit(1);
}
if( ($ARGV[0] =~ /^-+h/i) || (!$ARGV[0]) ) { &help; }

my $cdb = $ARGV[0];
if(!-f "$cdb"){ $cdb = './' . $cdb; }
if(-f "$cdb"){
    tie my %data, 'CDB_File', $cdb or die "$0: can't tie to $cdb: $!\n";
    while (my ($key, $value) = each %data) {
      print "$key\t$value\n";
    }
}else{
    print STDERR "Can't find the CDB file $cdb\n";
    &help;
}

