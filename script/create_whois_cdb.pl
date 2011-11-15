#!/usr/bin/perl

use CDB_File;
my $db = 'whois.cdb';
$t = new CDB_File ($db, "t.$$") or die "can't create file $db";
# template
my $template = '
    Domain name:
        DOMAIN

    Registrant:
        <private>

    Registrant type:
        UK Individual

    Registrant\'s address:
        The registrant is a non-trading individual who has opted to have their
        address omitted from the WHOIS service.

    Registrar:
        That would be registry.alexx.net
        URL: http://registry.alexx.net

    Relevant dates:
        Registered on: 06-Jun-2XXX (Why does that matter?)
        Renewal date:  06-Jun-2XXX (Private)
        Last updated:  30-Jul-2XXX (None of your bees wax)

    Registration status:
        Registered until renewal date.

    Name servers:
        ns0.not.telling.you
        ns1.do.i.look.like.a.dns.server.2.you
        ns2.did.not.think.so

    WHOIS rebuilt NOW';

my @domains = ('test.example.com','this.example.com','example.com','alexx.net');
foreach my $d (@domains){
    my $v = $template;
    if($v=~s/DOMAIN/$d/){
        my $now = `date +%c`;
        $v=~s/NOW/$now/;
        $t->insert($d,$v);
    }
}
$t->finish;

