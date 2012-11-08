package Notice::C::Search;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';
my %submenu = (
   '1.1' => [
        '1' => { name=> 'Person', rm => 'ppl', class=> 'navigation'},
        '2' => { name=> 'Place', rm => 'plc', class=> 'navigation'},
        '3' => { name=> 'Thing', rm => 'thng', class=> 'navigation'},
        '4' => { name=> 'When', rm => 'when', class=> 'navigation'},
    ],
);
use Data::Dumper;

our $VERSION = 0.02;

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

This one is huge - it has to be the gatekeeper of information, (keeping the strict hyrachy of Notice) while being as helpful as possible.
It should be as helpful as a speedballing spanial but as discreet as George, (the porter at a gentelmans club.)

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    $self->tt_params({ submenu => \%submenu });
}

=head2 RUN MODES

=head3 main

  * Purpose - get access to all of that useful and yummy data
  * State   - To be written
  * Function- The main page lists in more details and granularity, things that can be searched for
            - rather than the defaults that are possible in the header

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $admin_msg = ', or use the extended search functions on this page';
    $self->tt_params({
	message => 'Welcome to the Search page!',
    body => "<br />Originally: <i>Person</i>, <i>Place</i> or <i>thing</i><br /> but now<br /><i>Who Where What When</i> - when the Calendar module is included.
You can use the boxes at the top to search for those things $admin_msg",
		  });
    return $self->tt_process();
    
}

=head3 people

  we need the obvious to be right

=cut

sub people: Runmode {
  my $self = shift;
    $self->redirect('ppl');
}

=head3 ppl

    * Search for people
    * That could be by their name, their title, their account name

=cut

sub ppl: Runmode {
    my ($self) = @_;
    my $q = $self->query();
    my %search;
    my $surl;
    $surl = ($self->query->self_url);
    unless($q->param('person')){
        $self->tt_params({ error => "Don't you have something better that you could be doing?" });
        return $self->tt_process();
    }
    $self->tt_params({ person => $q->param('person')});
    if($q->param('person') eq 'anyone and everyone'){ 
        %search = ( pe_fname => {'like' => '%' });
    }elsif($q->param('person') eq 'everyone' || $q->param('person') eq 'all'){ 
        $self->tt_params({ message => "That seems a little vague? Could you try being a little more specific?" });
        return $self->tt_process();
    }elsif($q->param('person')=~m/^(\w+[- ]?)+$/){
        my @names = split(/ /, $q->param('person'));
        my $pe_fname = $names[0];
        my $pe_mname = $names[1];
        my $pe_lname = $names[@names-1];
        { no warnings; # about "Use of uninitialized value $pe_mname in string"
        %search = ( -or => [ pe_lname => "$pe_lname", pe_fname => "$pe_fname", pe_fname => "$pe_mname", pe_lname => "$pe_fname" ]);
        }
    }else{
        $self->tt_params({ message => "I'm getting on a bit and can't remember that person. Sorry sir." });
        return $self->tt_process();
    }

    my %tables;


    # here we add limits so that the user only finds the people that they are looking for rather than just
    # any old person with $name
    my %limits;
    
    # we want to limit their search to their own or child accounts
    #%search{'pe_acid' => {'like' => "$pe_acid"}};

    if(%search){
        my @people = $self->resultset('People')->search(\%search, \%limits );
        if(@people){
            $self->tt_params({ people => \@people });
            #$tables{people}{th} = [{ colspan=>2, th=> 'Name'}, 'Account'];
            $tables{people}{caption} = 'People';
            $tables{people}{th} = ['Name','Family','Account'];
            #$tables{people}{tc} = ['pe_fname','pe_lname','pe_acid'];
            $tables{people}{tc} = ['pe_fname','pe_lname','pe_acid'];
            # how does tables indicate $account{pe_acid}->ac_name ?
            #$tables{people} = (th => ['Name','Account Name'], tc => [['pe_fname','pe_fname'], {a => {href => {base => 'index.cgi/search', id => 'pe_acid', link => {account => 'pe_acid'} }}} ]); #we will need this later
        }else{
            $self->tt_params({ message => "Nope, does not ring a bell, Sorry" });
            return $self->tt_process();
        }
    }else{
        $surl =~s/\?.*$/?error=I%27m%20not%20going%20to%20tell%20you%20again/;
        $self->tt_params({ message => "<a class=\"blue\" href=\"$surl\" title=\"Why do you bother?\">Sorry, whom are you looking for?</a>" });
        return $self->tt_process();
    }
    if(%tables){
        $self->tt_params({ tables => \%tables });
    }

    # there is no reason why the People table should be an exception
    # it should fall into the config table next to any other module that
    # contains ppl (vCard_data)

    # Here we check to see if any config entries suggest 
    # that we should be searching other tables or other columns to include
    my $ef_acid = 0;
    if($self->param('ef_acid')){ $ef_acid = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ef_acid = $self->param('ac_id'); }
    my $m_rs = $self->resultset('ConfData')->search({
                -or => [
                    'cfd_acid' => "$ef_acid",
                    'cfd_acid' => {'is' => \'NULL'},
                ],
                'cf_name' => "search",
                'cf_type' => "ppl",
               },{
                join     => ['config'],
                columns => ['cfd_key','cfd_value'],
            });
     # we still have to deal with joins !
     # so cfd_value must hold an array of [cols,'table headings',limits,display] (where "limits" can be joins and other DBIC things)
     # display tells the Template how each line should look, (which cols to "display" and which to use as links <a> and refs)
     while(my $v = $m_rs->next){
        use JSON::XS;
          my @values = @{ decode_json ($v->cfd_value) };
          my @cols = split(',', $values[0]);
          if(ref($values[1]) eq 'HASH'){
            @{ $tables{$v->cfd_key}{th} } = values %{ $values[1] };
          }elsif(ref($values[1]) eq 'ARRAY'){
            $tables{$v->cfd_key}{th} = $values[1];
          }else{
            $tables{$v->cfd_key}{th} = \@cols;
          }

          if($values[3]){
            $tables{$v->cfd_key}{tr} = $values[3];
          }
            
          #check that this table exists for us
          my $this_tbl = $v->cfd_key;
          my %this_search;
          foreach my $col (@cols){
            if($col=~m/address$/ || $col=~m/name$/){
                my @search_term = split(/ /, $q->param('person'));
                foreach my $st (@search_term){
                    push@{ $this_search{'-or'} }, $col => {'like' => "\%$st\%"};
                }
            }
          }
          my @this_table = $self->resultset($v->cfd_key)->search(\%this_search,{ columns => \@cols });
          $self->tt_params({ $v->cfd_key => \@this_table });
          $tables{$v->cfd_key}{tc} = \@cols;
          # NOTE we need to be able to set table.th from config as well
     }

        # if we do and it is in this branch then alert
        # if we do and it is not somewhere that this user can view then add it
    return $self->tt_process();
}

=head3 place

 a postal address

=cut

sub place: Runmode {
    my ($self) = @_;
    my $q = $self->query();
    my %search;
    $self->tt_params({ message => "sounds lovely, I've really been meaning to expand my geography" });
    return $self->tt_process();
}
    
=head3 thing

 * Search for things
 * these depend on the modules installed and the users preference (and other things)
 * 
 * It could be:
 *  a domain name
 *  an email address
 *  an asset

=cut

sub thing: Runmode {
    my ($self) = @_;
    my $q = $self->query();
    my %domain_search;
    my %email_search;
    my %asset_search;
    my $surl;
    $surl = ($self->query->self_url);
    unless($q->param('Search') eq 'thing'){
        #warn "Got here" . Dumper(\%{ $q->{'param'} });
        $self->tt_params({ error => "Don't you have something better that you could be doing?" });
        return $self->tt_process();
    }
    #foreach my $ak (sort keys %{ $q->{'param'} } ){
    my $pe_id = 0;
    my $ac_id = 0;
    $pe_id = $self->param('pe_id');
    $ac_id = $self->param('pe_acid');
    unless(defined $ac_id && $ac_id=~m/^\d+$/){
        # or should we use thier username?
        # we _really_ need to know their ac_id
        my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
        my $user_details = $rs->first;
        $ac_id = $user_details->pe_acid;
    }

    my %asset_places_to_look = (
        asset_categories    => ['asc_name','asc_description'],
        asset_data  => ['asd_value']
    );
    my %asset_limts = (
        -or => [
            as_owner => $pe_id,
            as_user => $pe_id,
            as_acid => $ac_id,
        ]
    );
    my %domain_places_to_look = (
        domains => ['do_name'],
    );
    my %email_places_to_lool = (
        imap    => ['im_userid'],
        aliases => ['ea_userid', 'ea_touser','ea_at'],
        alias_details => ['ead_website', 'ead_notes']
    );
    my %domain_limits = ( #emails use domain_limits
      -or => [
        do_acid => $ac_id,
        do_peid => $pe_id
      ]
    );
    
    if($q->param('search') eq 'anything'){
        foreach my $si ( keys %domain_places_to_look){
            foreach my $sii ( @{ $domain_places_to_look{$si} }){
                warn " $si.$sii like anything";
                $domain_search{$sii} = {'like' => '%' };
            }
        }
    }elsif($q->param('search') eq 'everthing' || $q->param('search') eq 'all'){
        $self->tt_params({ message => "Wow!? That seems like... a lot?" });
    }elsif($q->param('search')=~m/((\w\.)+\w+)$/i){
        #might be a domain name
        my @dl = split(/\./, $q->param('search'));
        my $host = $dl[0];
        my $domain = $q->param('search');
           $domain =~s/^$host//;
        my $ltd = $dl[@dl-1];
        { no warnings; # about "Use of uninitialized value $pe_mname in string"
        %domain_search = ( -or => [ do_name => $domain, do_name => $q->param('search') ] );
        }
    }else{
        warn $q->param('search');
        $self->tt_params({ warning => "ooh, I don't think we've had any of those for many many years. (but I could be wrong)." });
    }

    my %limits;

    if(%domain_search || %email_search || %asset_search){
        my @domains = $self->resultset('Domain')->search(\%domain_search, \%domain_limits );
        if(@domains){
            $self->tt_params({ domains => \@domains });
        }else{
            $self->tt_params({ message => "Nope, does not ring a bell, Sorry" });
        }
    }else{
        $surl =~s/\?.*$/?error=I%27m%20not%20going%20to%20tell%20you%20again/;
        $self->tt_params({ message => "<a class=\"blue\" href=\"$surl\" title=\"Why do you bother?\">Sorry, I could not find that.</a>" });
    }

    return $self->tt_process();
}
    

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
Please fix any bugs, add any features you need and you can report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

