#!/usr/bin/perl

=head1 name

test_db.pl

=head1 SYNOPSIS

checking DBIx::Class

=head1 DESCRIPTION

It sems that DBIC can form the query that I want, but then fails to give the resultset object back to me
even though they ARE in the $d->{'_column_data'}->{rent_start}

=cut

#    use warnings;
    use strict;
    use Notice::DB;
    use Config::Auto;

    my $cfg = Config::Auto::parse("config/config.pl", format => "perl");
    my %CFG = %{ $cfg };
    my $self = Notice::DB->connect($CFG{'db_dsn'},$CFG{'db_user'},$CFG{'db_pw'});
# select do_name,do_status,do_added,rent_start,rent_end,ac_name from domains LEFT JOIN rental on rent_tableid = do_id LEFT JOIN accounts on ac_id = do_acid;

my $domains = $self->resultset('Domain')->search({ },{
      join => 'rental',
      #join => 'accounts',
        #'+select' => ['rental.rent_start'],
     # '+as'     => ['rental.rent_start'],
      columns => [ 
        'do_name','do_status','do_added',
        { rent_start => 'rental.rent_start as rent_start'},
        { rent_end => 'rental.rent_end as rent_end'},
        #{ac_name => 'account.ac_name as ac_name'},
        ]
});

use Data::Dumper;
while( my $d = $domains->next){
        my($status,$domain,$added,$start,$end,$name,$ns);
    foreach my $k (keys %{ $d->{'_column_data'} }){
        $ns .= $k .',';
    }
        
       $status = $d->do_status;
       $domain = $d->do_name;
       if("$d->do_added"=~m/\d:/){ 
            $added  = $d->do_added; 
        }else{
            $added = $d->{'_column_data'}->{'do_added'};
        }
       if("$d->rent_start"=~m/\d:/){
            $start  = $d->rent_start;
        }elsif($d->{'_column_data'}->{rent_start}){
           $start =  $d->{'_column_data'}->{rent_start};
        }else{
            $start = '$localtime';
        } 
        print "d:$domain\t\ts:$status\ta:$added\tb:$start\te:$end\tn:$name\ts:$ns\n";
}
