package Notice::C::Contacts;

use warnings;
use strict;
use lib 'lib';
my %opt=(D=>0); #its nice to have them
use base 'Notice';
my %submenu = (
   '32' => [
        '1' => { name=> 'Add', rm => 'add', class=> 'navigation'},
        '2' => { name=> 'list', rm => 'list', class=> 'navigation'},
        '3' => { name=> 'Search', rm => 'search', class=> 'navigation'},
        '4' => { name=> 'Sales', rm => 'sales', class=> 'navigation'},
    ],
);
use Data::Dumper;

our $VERSION = 0.03;

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

built round rfc2426 but with an eye to the future
.. the future is now: rfc6350 

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
    my $url = $self->query->url;
    my $q = $self->query();
    my $card_id = 0;
    if(defined $q->param('id')){ $card_id = $q->param('id'); }
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

    my @cards = $self->resultset('VCard')->search({
                     -or => [
                        card_peid => $pe_id,
                        card_acid => $ac_id
                     ]
                       },{
                        join => {
                            data => 'profile',
                        }
                     });
    my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
    my $card_exists = $card_rs->count;
    if($card_exists){
        $self->tt_params({ card => \@cards });
    }else{
        my $helper =  keys %{ $self->schema->source_registrations->{'VCardProfile'} };
        if(length($helper) <= 50){
            my @keys = keys %{ $self->schema->source_registrations->{'VCardProfile'} };
            my $vc = $self->schema->source_registrations->{'VCardProfile'};
=pod

            warn "Got helper:\n
result_class         = " . $vc->result_class . "
resultset_attributes = " . $vc->resultset_attributes . "
name                 = " . $vc->name . "
schema               = " . $vc->schema . "
_relationships       = " . $vc->_relationships . "
source_name          = " . $vc->source_name . "
_columns_info_loaded = " . $vc->{_columns_info_loaded}  .
"_ordered_columns     = " . $vc->_ordered_columns . "
_primaries           = " . $vc->_primaries . "
resultset_class      = " . $vc->resultset_class . "
_columns             = " . Dumper(( keys %{ $vc->_columns } )) . "
_unique_constraints  = " . $vc->_unique_constraints
        ;

=cut

        }else{
            warn "Got helper size: " . length($helper);
        }
        $self->tt_params({ card => \$helper });
    }
    my @form = $self->resultset('VCardProfile')->search();
    $self->tt_params({ form => \@form });

    $self->tt_params({
	message => 'Welcome to the Contacts page!<br />Here you will be able to sort all the details you have about all the people you are going to bother',
		  });
    return $self->tt_process();
    
}

=head3 add

  * Purpose - add new contacts
  * State   - To be written
  * Function- This enabled addition to contacts

=cut

sub add: Runmode {
    my ($self) = @_;
    my $url = $self->query->url;
    my $q = $self->query();
    my $card_id;
    if(defined $q->param('id')){ $card_id = $q->param('id'); }
    my $pe_id = 0;
    my $ac_id = 0;
    $pe_id = $self->param('pe_id');
    $ac_id = $self->param('ef_acid'); # We add this card to the account that the user is looking into, not THEIR account.
    unless(defined $ac_id && $ac_id=~m/^\d+$/){
        warn "using default account ID";
        # or should we use thier username?
        # we _really_ need to know their ac_id
        my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
        my $user_details = $rs->first;
        $ac_id = $user_details->pe_acid;
    }

    if(defined $q->{'param'} && $q->param('Add')){

        my %p; # profile

        my $profile_rs = $self->resultset('VCardProfile')->search();
        while( my $prid = $profile_rs->next){
            my $pro_id = $prid->vcprofile_id;
            my $pro_fet = $prid->vcprofile_feature;
            $p{$pro_fet} = $pro_id;
            $p{'type'}{$pro_fet} = $prid->vcprofile_type;
        }

        #warn "we are adding a card to account: $ac_id";
        my %card;
        my %create_data;
        PROFILE: foreach my $ak (keys %{ $q->{'param'} } ){
            if($q->param($ak) eq ''){
                next PROFILE;
            }
            if($ak=~m/^(\w+)\.(\w+)/){
                my $profile = $1;
                my $sub_pro = $2;
                if($p{$profile}){
                    #warn $p{$profile};
                    $create_data{"$p{$profile}"}{'detail'} = $sub_pro;
                    $create_data{"$p{$profile}"}{'value'} = $q->param($ak);
                #}else{ warn "$profile is not a valid vCard profile";
                }
            }else{
               if($p{$ak}){
                    #warn $p{$ak};
                    if($p{'type'}{$ak} eq 'text'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                    }elsif($p{'type'}{$ak} eq 'bin'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                        # then we add the actual binary_data
                        $create_data{"$p{$ak}"}{'bin'} = $q->param($ak);  #NTS this isn't it
                    }
                #}else{ warn "$ak is not a valid vCard profile";
                }
            }
        }
        if(%create_data){

            # add the binmode data
            
            my $buffer; my $bytesread;
            #my $file_handle = $self->query->upload('PHOTO'); warn Dumper($file_handle);
            $q->close_upload_files(1);
          { no strict 'refs';
            if (my $file = $q->param('PHOTO')) {
                #open (my $fh, '<', $q->{'.tmpfiles'}->{*$file}->{'PHOTO'}->as_string());
                #open (my $fh, '<', $q->{'.tmpfiles'}->{*$file}->{'PHOTO'});
                my $fh = $q->param('PHOTO');
                if(defined $fh && ref($fh) && $fh ne ''){
                    warn ref($fh);
                    while ($bytesread = read($fh, $buffer, 1024)) {
                        #$create_data{PIC} .= $bytesread;
                        $create_data{PHOTO} .= $buffer;
                    }
                    warn '.tmpfiles: ' . Dumper($q->{'.tmpfiles'});
                    #warn '.tmpfiles->*$file: ' . Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file}->{'name'});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file}->{'PHOTO'});
                    #warn join('; ', keys %{ $q->{'.tmpfiles'}->{'Notice::C::Contacts::d70final.gif'} } );
                    #warn 'Dqtf ' . Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } );
                }else{
                    warn 'kqtf ' . join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } ) if $opt{D}>=20;
                }
            }else{
                warn 'sq ' . join(', ', keys %{ $self->query }) if $opt{D}>=300;
            }
            if (my $file = $q->param('LOGO')) {
                ##warn Dumper($q->{'.tmpfiles'}->{*$file});
                warn '.tmpfiles:' . Dumper($q->{'.tmpfiles'}) if $opt{D}>=30;
                foreach my $q_keys ( keys %{ $self->query }){
                    if(ref($q->{$q_keys}) eq 'ARRAY'){
                        warn ' array' . $q_keys . ':' . Dumper(\@{ $q->{$q_keys} }) if $opt{D}>=30;
                    }elsif(ref($q->{$q_keys}) eq 'HASH'){
                        warn 'HASH_' . $q_keys . ': ' . join('; ', keys %{ $q->{$q_keys} }) if $opt{D}>=30;
                    }else{
                        #warn "OTHER: q_keys: " . ref($q_keys) . " q->keys " . ref($q->{$q_keys});
                    }
                }
                #warn 'LOGO-kqtf ' . join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } );
            }
          }
        } # end no strict refs;

          warn Dumper(\%create_data) if $opt{D}>=10;

         # # search for an existing card

         #my $card_rs = $self->resultset('VCardData')->search({ \%create_data });
         #my $card_exists = $card_rs->count;
         # # create a new card
         #if($card_exists){
         # # we do an update?
         #}else{
          #add the data
            my $enc_lang = 'en'; # we should probably set this dynamically
            if(defined $self->param('i18n')){
                $enc_lang = $self->param('i18n');
            }
            $card_id = $self->resultset('VCard')->create({ 
                            card_peid => $pe_id,
                            card_acid => $ac_id,
                            card_language => $enc_lang,
                            card_created => \'NOW()', 
                            card_updated => \'NOW()' 
                        })->update->id;
            #$create_data{vcd_card_id} = $card_id;
    #warn "CREATED CARD";
            if(defined $card_id && $card_id >= 1){
                DATA_ROW: foreach my $prof (keys %create_data){
                    my %new_data;
                    %new_data = (
                            vcd_card_id => $card_id,
                            vcd_profile_id => $prof
                    );
                    if($create_data{$prof}{'detail'}){
                        $new_data{'vcd_prof_detail'} = $create_data{$prof}{'detail'};
                    }
                    if($create_data{$prof}{'value'}){
                        # even for binary we are going to store the filename in 'value'
                        $new_data{'vcd_value'} = $create_data{$prof}{'value'};
                      if($create_data{$prof}{'bin'}){
                        $new_data{'vcd_bin'} = $create_data{$prof}{'bin'};
                      }
                    }else{
                        warn "bad things in Contacts.pm::add";
                        next DATA_ROW; # because we don't want to create partial rows
                    }
                    #warn "creating data:" . Dumper(\%new_data);
                    my $data_added = $self->resultset('VCardData')->create({ %new_data })->update;
               }
            }else{
                warn "Can't create vCard $@";
            }
         #}

    #warn "DONE INSERT";
    }

    if($pe_id >= 1 && defined $card_id){
        my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
        my $card_exists = $card_rs->count;
        if($card_exists){
            my @cards = $self->resultset('VCard')->search({
                    card_id => $card_id,
                    card_peid => $pe_id
                },{
                    join => {
                        data => 'profile',
                    }
                });
            $self->tt_params({ card => \@cards });
            $self->tt_params({ message => "Everything in card $card_id" });
        }else{
            $self->tt_params({ error => "The vCard is yet to be created." });
        }
    }elsif($q->param('Add')){
        $self->tt_params({ message => "Don't be evil" });
    }

    # We can select the add.tmpl that this user needs, (if they only ever add [FN,EMAIL] then only use a form with those
    return $self->tt_process();
}

=head3 list

  * Purpose - add new contacts
  * State   - To be written
  * Function- This enabled addition to contacts

=cut

sub list: Runmode {
    my ($self) = @_;
    my $url = $self->query->url;
    my $q = $self->query();
    my $card_id;
    if(defined $q->param('id')){ $card_id = $q->param('id'); }
    elsif(defined $self->param('id')){ $card_id = $self->param('id'); }
    elsif(defined $self->param('sid')){ $card_id = $self->param('sid'); }
    elsif(defined $self->param('did')){ $card_id = $self->param('did'); }
    
    my $pe_id = 0;
    my $ac_id = 0;
    my $ef_acid = 0;
    $pe_id = $self->param('pe_id');
    $ac_id = $self->param('pe_acid');
    $ef_acid = $self->param('ef_acid');
    unless(defined $ac_id && $ac_id=~m/^\d+$/){
        # or should we use thier username?
        # we _really_ need to know their ac_id
        my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
        my $user_details = $rs->first;
        $ac_id = $user_details->pe_acid;
    }
    unless($ef_acid >= 1){ $ef_acid = $ac_id };

    if(defined $card_id && ($card_id eq 'all' || $card_id=~m/^\d+$/) ){ 
        if($card_id eq 'all'){
            $card_id = {'like' => '%'};
        }
        my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
        my $card_exists = $card_rs->count;
        if($card_exists){
            my @cards = $self->resultset('VCard')->search({
                    card_id => $card_id,
                    card_peid => $pe_id
            #    },{
            #        join => {
            #            data => 'profile',
            #        },
            #        #'+columns' => [ 'vCard_profile.vcprofile_version','vCard_profile.vcprofile_feature','vCard_profile.vcprofile_type',
            #        #'vCard_data.vcd_id', 'vCard_data.vcd_prof_detail', 'vCard_data.vcd_value', 'vCard_data.vcd_bin' ],
            #        #columns => [ 'card_id', 'card_acid', 'card_encoding', 'card_updated', 
            #        '+columns' => [
            #        #'profile.vcprofile_version','profile.vcprofile_feature','profile.vcprofile_type',
            #       'data.vcd_id', 'data.vcd_prof_detail', 'data.vcd_value', 'data.vcd_bin' 
            #        ],
                });
            $self->tt_params({ card => \@cards });
        # VCardData.pm     VCard.pm         VCardProfile.pm
           if($card_id=~m/^\d+$/){
                my @vcd = $self->resultset('VCardData')->search({
                    vcd_card_id => $card_id
                  },{
                    join => 'profile',
                    '+columns' => [qw/profile.vcprofile_version profile.vcprofile_type profile.vcprofile_feature/],
                  });
                $self->tt_params({ vcd => \@vcd });
            }
            my $message='';
            if($card_id=~m/^\d+$/){
                $message = "Everything in card $card_id";
            }else{
                $message = "All cards in account $ef_acid";
            }
            $self->tt_params({ message => $message });
            #return $self->tt_process('Notice/C/Contacts/vCard.tmpl');
        }else{
            $self->tt_params({ error => "The vCard is yet to be created." });
        }
    }else{
        unless($card_id eq 'all' || $card_id=~m/^\d+$/){ $card_id = ''; }
        $self->tt_params({ no_card_selected => 1, message => "You can search for a a card or enter its id:" . $card_id });
    }
    return $self->tt_process();
}


=head3 view

  * Purpose - view an existing contact
  * State   - To be written
  * Function- This enabled addition to contacts

=cut

sub view: Runmode {
    my ($self) = @_;
    my $url = $self->query->url;
    my $q = $self->query();
    my $card_id;
    if(defined $q->param('id')){ $card_id = $q->param('id'); }
    elsif(defined $self->param('id')){ $card_id = $self->param('id'); }
    my $pe_id = 0;
    my $ac_id = 0;
    $pe_id = $self->param('pe_id');
    $ac_id = $self->param('ef_acid'); # We add this card to the account that the user is looking into, not THEIR account.
    unless(defined $ac_id && $ac_id=~m/^\d+$/){
        warn "using default account ID";
        # or should we use thier username?
        # we _really_ need to know their ac_id
        my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
        my $user_details = $rs->first;
        $ac_id = $user_details->pe_acid;
    }

    if(defined $q->{'param'} && $q->param('Add')){

        my %p; # profile

        my $profile_rs = $self->resultset('VCardProfile')->search();
        while( my $prid = $profile_rs->next){
            my $pro_id = $prid->vcprofile_id;
            my $pro_fet = $prid->vcprofile_feature;
            $p{$pro_fet} = $pro_id;
            $p{'type'}{$pro_fet} = $prid->vcprofile_type;
        }

        #warn "we are adding a card to account: $ac_id";
        my %card;
        my %create_data;
        PROFILE: foreach my $ak (keys %{ $q->{'param'} } ){
            if($q->param($ak) eq ''){
                next PROFILE;
            }
            if($ak=~m/^(\w+)\.(\w+)/){
                my $profile = $1;
                my $sub_pro = $2;
                if($p{$profile}){
                    #warn $p{$profile};
                    $create_data{"$p{$profile}"}{'detail'} = $sub_pro;
                    $create_data{"$p{$profile}"}{'value'} = $q->param($ak);
                #}else{ warn "$profile is not a valid vCard profile";
                }
            }else{
               if($p{$ak}){
                    #warn $p{$ak};
                    if($p{'type'}{$ak} eq 'text'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                    }elsif($p{'type'}{$ak} eq 'bin'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                        # then we add the actual binary_data
                        $create_data{"$p{$ak}"}{'bin'} = $q->param($ak);  #NTS this isn't it
                    }
                #}else{ warn "$ak is not a valid vCard profile";
                }
            }
        }
        if(%create_data){

            # add the binmode data
            
            my $buffer; my $bytesread;
            #my $file_handle = $self->query->upload('PHOTO'); warn Dumper($file_handle);
            $q->close_upload_files(1);
          { no strict 'refs';
            if (my $file = $q->param('PHOTO')) {
                #open (my $fh, '<', $q->{'.tmpfiles'}->{*$file}->{'PHOTO'}->as_string());
                #open (my $fh, '<', $q->{'.tmpfiles'}->{*$file}->{'PHOTO'});
                my $fh = $q->param('PHOTO');
                if(defined $fh && ref($fh) && $fh ne ''){
                    warn ref($fh);
                    while ($bytesread = read($fh, $buffer, 1024)) {
                        #$create_data{PIC} .= $bytesread;
                        $create_data{PHOTO} .= $buffer;
                    }
                    warn '.tmpfiles: ' . Dumper($q->{'.tmpfiles'});
                    #warn '.tmpfiles->*$file: ' . Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file}->{'name'});
                    #warn Dumper($q->{'.tmpfiles'}->{*$file}->{'PHOTO'});
                    #warn join('; ', keys %{ $q->{'.tmpfiles'}->{'Notice::C::Contacts::d70final.gif'} } );
                    #warn 'Dqtf ' . Dumper($q->{'.tmpfiles'}->{*$file});
                    #warn join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } );
                }else{
                    warn 'kqtf ' . join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } ) if $opt{D}>=20;
                }
            }else{
                warn 'sq ' . join(', ', keys %{ $self->query }) if $opt{D}>=300;
            }
            if (my $file = $q->param('LOGO')) {
                ##warn Dumper($q->{'.tmpfiles'}->{*$file});
                warn '.tmpfiles:' . Dumper($q->{'.tmpfiles'}) if $opt{D}>=30;
                foreach my $q_keys ( keys %{ $self->query }){
                    if(ref($q->{$q_keys}) eq 'ARRAY'){
                        warn ' array' . $q_keys . ':' . Dumper(\@{ $q->{$q_keys} }) if $opt{D}>=30;
                    }elsif(ref($q->{$q_keys}) eq 'HASH'){
                        warn 'HASH_' . $q_keys . ': ' . join('; ', keys %{ $q->{$q_keys} }) if $opt{D}>=30;
                    }else{
                        #warn "OTHER: q_keys: " . ref($q_keys) . " q->keys " . ref($q->{$q_keys});
                    }
                }
                #warn 'LOGO-kqtf ' . join('; ', keys %{ $q->{'.tmpfiles'}->{*$file} } );
            }
          }
        } # end no strict refs;

          warn Dumper(\%create_data) if $opt{D}>=10;

         # # search for an existing card

         #my $card_rs = $self->resultset('VCardData')->search({ \%create_data });
         #my $card_exists = $card_rs->count;
         # # create a new card
         #if($card_exists){
         # # we do an update?
         #}else{
          #add the data
            my $enc_lang = 'en'; # we should probably set this dynamically
            if(defined $self->param('i18n')){
                $enc_lang = $self->param('i18n');
            }
            $card_id = $self->resultset('VCard')->create({ 
                            card_peid => $pe_id,
                            card_acid => $ac_id,
                            card_language => $enc_lang,
                            card_created => \'NOW()', 
                            card_updated => \'NOW()' 
                        })->update->id;
            #$create_data{vcd_card_id} = $card_id;
    #warn "CREATED CARD";
            if(defined $card_id && $card_id >= 1){
                DATA_ROW: foreach my $prof (keys %create_data){
                    my %new_data;
                    %new_data = (
                            vcd_card_id => $card_id,
                            vcd_profile_id => $prof
                    );
                    if($create_data{$prof}{'detail'}){
                        $new_data{'vcd_prof_detail'} = $create_data{$prof}{'detail'};
                    }
                    if($create_data{$prof}{'value'}){
                        # even for binary we are going to store the filename in 'value'
                        $new_data{'vcd_value'} = $create_data{$prof}{'value'};
                      if($create_data{$prof}{'bin'}){
                        $new_data{'vcd_bin'} = $create_data{$prof}{'bin'};
                      }
                    }else{
                        warn "bad things in Contacts.pm::add";
                        next DATA_ROW; # because we don't want to create partial rows
                    }
                    #warn "creating data:" . Dumper(\%new_data);
                    my $data_added = $self->resultset('VCardData')->create({ %new_data })->update;
               }
            }else{
                warn "Can't create vCard $@";
            }
         #}

    #warn "DONE INSERT";
    }

    if($pe_id >= 1 && defined $card_id){
        my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
        my $card_exists = $card_rs->count;
        if($card_exists){
            my @cards = $self->resultset('VCard')->search({
                    card_id => $card_id,
                    card_peid => $pe_id
                },{
                    join => {
                        data => 'profile',
                    }
                });
            my @vcd = $self->resultset('VCardData')->search({
                    vcd_card_id => $card_id
                  },{
                    join => 'profile',
                    '+columns' => [qw/profile.vcprofile_version profile.vcprofile_type profile.vcprofile_feature/],
                  });
            $self->tt_params({ vcd => \@vcd });
            my $vc_rs =$self->resultset('VCardData')->search({
                    vcd_card_id => $card_id
                  },{
                    join => 'profile',
                    '+columns' => [qw/profile.vcprofile_version profile.vcprofile_type profile.vcprofile_feature/],
                  });
            
            my %card;
            $card{ID} = $card_id;
            while( my $vcd = $vc_rs->next){
                #my $p_f = 'profile.vcprofile_feature'; my $p_feature = $vcd->$p_f;
                my $p_feature = $vcd->profile->vcprofile_feature;
                my $p_detail = $vcd->vcd_prof_detail;
                my $p_value = $vcd->vcd_value;
                if($p_detail){
                    $card{$p_feature}{$p_detail} = $p_value;
                }else{
                    $card{$p_feature} = $p_value;
                }
            }
            $self->tt_params({ card => \%card });
            $self->tt_params({ cards => \@cards });
            $self->tt_params({ message => "Everything in card $card_id" });
        }else{
            $self->tt_params({ error => "The vCard is yet to be created." });
        }
    }else{
        $self->tt_params({ message => "Don't be evil" });
    }

    # We can select the add.tmpl that this user needs, (if they only ever add [FN,EMAIL] then only use a form with those
    return $self->tt_process();
}



=head3 search

  * Purpose - a more advanced search function for the contacts
  * State   - To be written
  * Function- This enabled addition to contacts

=cut

sub search: Runmode {
    my ($self) = @_;
    my $url = $self->query->url;
    my $q = $self->query();
    $self->tt_params({ message => "Don't be evil" });
    return $self->tt_process();
}


=head3 sales

  * Purpose - This displays groups of contacts, highlighting them one at a time
  *             so that each can be contacted, but data can be added to any of the records
  * State   - To be written
  * Function- This enabled sales people to rapidly cold-call lists of contacts

 - yes, this /can/ be used for evil.

=cut

sub sales: Runmode {
    my ($self) = @_;
    $self->tt_params({ message => "Don't be evil" });
    my $url = $self->query->url;
    my $q = $self->query();
    my $card_id;
    if(defined $q->param('id')){ $card_id = $q->param('id'); }
    elsif(defined $self->param('id')){ $card_id = $self->param('id'); }
    elsif(defined $self->param('sid')){ $card_id = $self->param('sid'); }
    elsif(defined $self->param('did')){ $card_id = $self->param('did'); }
    
    my $pe_id = 0;
    my $ac_id = 0;
    my $ef_acid = 0;
    $pe_id = $self->param('pe_id');
    $ac_id = $self->param('pe_acid');
    $ef_acid = $self->param('ef_acid');
    unless(defined $ac_id && $ac_id=~m/^\d+$/){
        # or should we use thier username?
        # we _really_ need to know their ac_id
        my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
        my $user_details = $rs->first;
        $ac_id = $user_details->pe_acid;
    }
    unless($ef_acid >= 1){ $ef_acid = $ac_id };

    unless($card_id=~m/^\d+$/){
            $card_id = {'like' => '%'};
    }
        my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
        my $card_exists = $card_rs->count;
        if($card_exists){
            my @cards = $self->resultset('VCard')->search({
                    card_id => $card_id,
                    card_peid => $pe_id
            #    },{
            #        join => {
            #            data => 'profile',
            #        },
            #        #'+columns' => [ 'vCard_profile.vcprofile_version','vCard_profile.vcprofile_feature','vCard_profile.vcprofile_type',
            #        #'vCard_data.vcd_id', 'vCard_data.vcd_prof_detail', 'vCard_data.vcd_value', 'vCard_data.vcd_bin' ],
            #        #columns => [ 'card_id', 'card_acid', 'card_encoding', 'card_updated', 
                });
            $self->tt_params({ card => \@cards });
        # VCardData.pm     VCard.pm         VCardProfile.pm
           while( my $vc = $card_rs->next){ 
            my %vcd;
             if(defined $vc->card_id && $vc->card_id=~m/^\d+$/){
                my @vcd = $self->resultset('VCardData')->search({
                    vcd_card_id => $vc->card_id
                  },{
                    join => 'profile',
                    '+columns' => [qw/profile.vcprofile_version profile.vcprofile_type profile.vcprofile_feature/],
                  });
                @{ $vcd{$vc->card_id} } = @vcd;
             }
             $self->tt_params({ vcd => \%vcd });
            }
            my $message='';
            if($card_id=~m/^\d+$/){
                $message = "Everything in card $card_id";
            }else{
                $message = "All cards in account $ef_acid";
            }
            $self->tt_params({ message => $message });
            #return $self->tt_process('Notice/C/Contacts/vCard.tmpl');
        }else{
            $self->tt_params({ error => "The vCard is yet to be created." });
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

}

