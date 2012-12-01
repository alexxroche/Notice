package Notice::C::Contacts;

use warnings;
use strict;
use lib 'lib';
my %opt=(D=>99); #its nice to have them
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

    if(defined $q->{'param'} && ( $q->param('Update') || $q->param('Add') ) ){
        my %p; # profile
        #warn "IN contact::view,UPDATE" if $opt{D}>=99;

        my $profile_rs = $self->resultset('VCardProfile')->search();
        while( my $prid = $profile_rs->next){
            my $pro_id = $prid->vcprofile_id;
            my $pro_fet = $prid->vcprofile_feature;
            $p{$pro_fet} = $pro_id;
            $p{'type'}{$pro_fet} = $prid->vcprofile_type;
        }

        my %card;
        my %create_data;
        PROFILE: foreach my $ak (keys %{ $q->{'param'} } ){
            if($q->param($ak) eq ''){
                # we need to know if this exists before we delete it
                warn "$ak is blank" if $opt{D}>=9001;
                # NTS maybe we are deleting ?
                next PROFILE;
            }
            if($ak=~m/^(\w+)\.(\w+)/){
                my $profile = $1;
                my $sub_pro = $2;
                if($p{$profile}){
                    #warn "$ak $profile is $p{$profile}";
            
                    # we may have to have an array
                    
                    if(defined $create_data{"$p{$profile}"}){
                      if(ref($create_data{"$p{$profile}"}) eq 'HASH'){
                            my @hold = $create_data{"$p{$profile}"};
                            #warn Dumper(\@hold);
                            delete $create_data{"$p{$profile}"};
                           push @{ $create_data{"$p{$profile}"} }, @hold;
                            #warn Dumper(\%create_data);
                           my @new = { detail => $sub_pro, value => $q->param($ak) };
                           push @{ $create_data{"$p{$profile}"} }, @new;
                      }else{
                           my @new = { detail => $sub_pro, value => $q->param($ak) };
                           push @{ $create_data{"$p{$profile}"} }, @new;
                      }
                    }else{
                        $create_data{"$p{$profile}"}{'detail'} = $sub_pro;
                        $create_data{"$p{$profile}"}{'value'} = $q->param($ak);
                    }
                }elsif($profile eq 'delete' && ( $sub_pro eq 'PHOTO' || $sub_pro eq 'LOGO') ){ 
                    warn "DELETING IMAGE " . $sub_pro;
                        $create_data{"$p{$sub_pro}"}{'detail'} = $sub_pro;
                        $create_data{"$p{$sub_pro}"}{'value'} = '';
                        $create_data{"$p{$sub_pro}"}{'bin'} = '';
                }else{ 
                    warn "$profile is not a valid vCard profile";
                }
            }else{
                
               if($ak eq 'ID'){
                    $card_id = $q->param($ak);
               }elsif($p{$ak}){
                    # we should check that this isn't a default that is being added to an existing array of hashes
                    if($p{'type'}{$ak} eq 'text'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                    }elsif($p{'type'}{$ak} eq 'bin'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                        # then we add the actual binary_data
                        if($ak eq 'PHOTO' || $ak eq 'LOGO'){
                            warn "Found a " . $ak;
                            if(my $fh = $q->param($ak)){
                                my $bufsize = 1024;
                                my $bytes_retreived = 0;
                                my $limit = $bufsize * 10240; # 10 MB limit
                                my $buffer;
                                my $file;
                                while (($bytes_retreived <= $limit) && read($fh, $buffer, $bufsize)) {
                                    $file .= $buffer;
                                    $bytes_retreived += $bufsize;
                                }
                                warn $fh . " is " .$bytes_retreived;
                                warn length $file;
                                use MIME::Base64;
                                my $file64 = encode_base64($file);
                                $create_data{"$p{$ak}"}{'bin'} = $file64;
                            }else{
                                warn "no file handel 4 U";
                            }
                        }else{
                            warn $ak;
                            $create_data{"$p{$ak}"}{'bin'} = $q->param($ak);  #NTS this isn't it
                        }
                    }
                    #else{ warn "$ak is not a valid vCard profile";
                }
            } #/if-else
        } #/foreach

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
        if(defined $card_id && $card_id >= 1){
            ADD_ROW: foreach my $vcd_row (keys %create_data){

                if(ref($create_data{$vcd_row}) eq 'HASH'){
                    my $sth = $self->resultset('VCardData')->search({ vcd_card_id => $card_id, vcd_profile_id => $vcd_row});
                    if(defined $sth && $sth != 0){
                        my %update;
                        $update{vcd_value} = $create_data{$vcd_row}{value};
                        if($create_data{$vcd_row}{bin} || $create_data{$vcd_row}{detail}){
                            if($create_data{$vcd_row}{bin}){
                                $update{vcd_bin} = $create_data{$vcd_row}{bin};
                            }elsif( $create_data{$vcd_row}{detail} ){
                                delete($create_data{$vcd_row}{detail});
                                $update{vcd_bin} = '';
                                $sth->delete;
                                next ADD_ROW;
                            }
                        }
                        $sth->update( \%update );
                    }else{
                        my %create = ( vcd_card_id => $card_id, vcd_profile_id => $vcd_row, vcd_value=> "$create_data{$vcd_row}{value}" );
                        if($create_data{$vcd_row}{bin}){
                            $create{vcd_bin} = $create_data{$vcd_row}{bin};
                        }
                        my $new_sth = $self->resultset('VCardData')->create( \%create );
                    }
                }elsif(ref($create_data{$vcd_row}) eq 'ARRAY'){
                        # we have an array of hashes, (so more than one row for each profile_type)
                        foreach my $cd_row (@{ $create_data{$vcd_row} }) {
                            my $sth = $self->resultset('VCardData')->search({ 
                                    vcd_card_id => $card_id, 
                                    vcd_profile_id => $vcd_row, 
                                    vcd_prof_detail => $cd_row->{detail}
                                })->single;
                            if(defined $sth && $sth != 0){
                                $sth->update({ vcd_value=> "$cd_row->{value}" });
                            }else{
                               $self->resultset('VCardData')->create({ vcd_card_id => $card_id,      
                                               vcd_profile_id => $vcd_row,     
                                               vcd_prof_detail => $cd_row->{detail},     
                                               vcd_value=> "$cd_row->{value}"     
                                            });
                            }
                        }
                 }else{
                        # we have something else
                        warn "ERROR: $vcd_row (" . ref($create_data{$vcd_row}) . ") = " . Dumper($create_data{$vcd_row});
                 }
             } #/foreach %create_data
         }else{
                warn "Can't create vCard $@"; # NO card_id
         }
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
            my ($surl);
            $url = ($self->query->url);
            #$url =~s/\?.*$//; #strip any GET values
            $self->tt_params({ message => "Card <a class=\"blue\" href=\"$url/Contacts/view/$card_id\">$card_id</a> added; Add another?" });
            # By default we return them to a blank new card ready for fast data entry
            #  but if they tick the show checkbox then we do that:
            if($q->param('show')){ # then show the card that was just added
                #return $self->redirect("view/$card_id");
                $self->param(id => $card_id);
                return $self->forward('view');
            }
        }else{
            $self->tt_params({ error => "That vCard has not yet to be created." });
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
            $self->tt_params({ error => "The vCard $card_id is yet to be created." });
        }
    }else{
        unless($card_id eq 'all' || $card_id=~m/^\d+$/){ $card_id = ''; }
        $self->tt_params({ no_card_selected => 1, message => "You can search for a card or enter its id:" . $card_id });
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
    my $card_id=0;
    if(defined $q->param('id') && $q->param('id')=~m/^\d+$/){ $card_id = $q->param('id'); }
    elsif(defined $self->param('id') && $self->param('id')=~m/^\d+$/){ $card_id = $self->param('id'); }
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

    #if(defined $q->{'param'} && $q->param('Update')){
    if(defined $q->{'param'} && ( $q->param('Update') || $q->param('Add') ) ){
        my %p; # profile
        #warn "IN contact::view,UPDATE" if $opt{D}>=99;

        my $profile_rs = $self->resultset('VCardProfile')->search();
        while( my $prid = $profile_rs->next){
            my $pro_id = $prid->vcprofile_id;
            my $pro_fet = $prid->vcprofile_feature;
            $p{$pro_fet} = $pro_id;
            $p{'type'}{$pro_fet} = $prid->vcprofile_type;
        }

        my %card;
        my %create_data;
        PROFILE: foreach my $ak (keys %{ $q->{'param'} } ){
            if($q->param($ak) eq ''){
                # we need to know if this exists before we delete it
                warn "$ak is blank" if $opt{D}>=9001;
                # NTS maybe we are deleting ?
                next PROFILE;
            }
            if($ak=~m/^(\w+)\.(\w+)/){
                my $profile = $1;
                my $sub_pro = $2;
                if($p{$profile}){
                    #warn "$ak $profile is $p{$profile}";
            
                    # we may have to have an array
                    
                    if(defined $create_data{"$p{$profile}"}){
                      if(ref($create_data{"$p{$profile}"}) eq 'HASH'){
                            my @hold = $create_data{"$p{$profile}"};
                            #warn Dumper(\@hold);
                            delete $create_data{"$p{$profile}"};
                           push @{ $create_data{"$p{$profile}"} }, @hold;
                            #warn Dumper(\%create_data);
                           my @new = { detail => $sub_pro, value => $q->param($ak) };
                           push @{ $create_data{"$p{$profile}"} }, @new;
                      }else{
                           my @new = { detail => $sub_pro, value => $q->param($ak) };
                           push @{ $create_data{"$p{$profile}"} }, @new;
                      }
                    }else{
                        $create_data{"$p{$profile}"}{'detail'} = $sub_pro;
                        $create_data{"$p{$profile}"}{'value'} = $q->param($ak);
                    }
                }elsif($profile eq 'delete' && ( $sub_pro eq 'PHOTO' || $sub_pro eq 'LOGO') ){ 
                    warn "DELETING IMAGE " . $sub_pro;
                        $create_data{"$p{$sub_pro}"}{'detail'} = $sub_pro;
                        $create_data{"$p{$sub_pro}"}{'value'} = '';
                        $create_data{"$p{$sub_pro}"}{'bin'} = '';
                }else{ 
                    warn "$profile is not a valid vCard profile";
                }
            }else{
                
               if($ak eq 'ID'){
                    $card_id = $q->param($ak);
               }elsif($p{$ak}){
                    # we should check that this isn't a default that is being added to an existing array of hashes
                    if($p{'type'}{$ak} eq 'text'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                    }elsif($p{'type'}{$ak} eq 'bin'){
                        $create_data{"$p{$ak}"}{'value'} = $q->param($ak);
                        # then we add the actual binary_data
                        if($ak eq 'PHOTO' || $ak eq 'LOGO'){
                            warn "Found a " . $ak;
                            if(my $fh = $q->param($ak)){
                                my $bufsize = 1024;
                                my $bytes_retreived = 0;
                                my $limit = $bufsize * 10240; # 10 MB limit
                                my $buffer;
                                my $file;
                                while (($bytes_retreived <= $limit) && read($fh, $buffer, $bufsize)) {
                                    $file .= $buffer;
                                    $bytes_retreived += $bufsize;
                                }
                                warn $fh . " is " .$bytes_retreived;
                                warn length $file;
                                use MIME::Base64;
                                my $file64 = encode_base64($file);
                                $create_data{"$p{$ak}"}{'bin'} = $file64;
                            }else{
                                warn "no file handel 4 U";
                            }
                        }else{
                            warn $ak;
                            $create_data{"$p{$ak}"}{'bin'} = $q->param($ak);  #NTS this isn't it
                        }
                    }
                    #else{ warn "$ak is not a valid vCard profile";
                }
            } #/if-else
        } #/foreach
        #warn Dumper(\%create_data) if $opt{D}>=10;

        warn "updating vCard $card_id" if $opt{D}>=10;
        unless(defined $card_id){
                    # we probably adding so lets do that
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
        }

        if(defined $card_id){
                delete($create_data{as_date}); # this is the "created date" so we never updated it.
                #my $touch_update = $self->resultset('VCard')->update_or_create({ card_id => $card_id, card_updated => \'NOW()' });
                my $touch_update = $self->resultset('VCard')->search({ card_id => $card_id});
                $touch_update->update({ card_updated => \'NOW()' });

        #If we update the card_updated first then we /might/ fail to update vCard_data and then the first update seems silly
        #If we do it the other way round then we /might/ fail to update the card_updated. Of the two I prefere the first.
        # (we could store the card_updated value so that we can roll back when we fail; I'll let you do that if you like.)
        # The other problem is that we changed card_updated even if no new data is submitted.

            # looks like we will have to loop through each row and do an update, remembing to set vcd_card_id for each one
            #  this presumes that the vcard_profile_id is unique and that simply isn't the case.
            # so we are going to have include that in the form somehow.
            # or find it here with the data that we have.

               # so from %create_data we extract the data that we use to find the row that we are interested
               # and the data that we need to update.

            UPDATE_ROW: foreach my $vcd_row (keys %create_data){

                if(ref($create_data{$vcd_row}) eq 'HASH'){
                    # we have one hash of data
                   # warn "update vCard_data set vcd_value = \"$create_data{$vcd_row}{value}\" where vcd_card_id = $card_id and vcd_profile_id = $vcd_row";
             #we should use ->single to cover the case where the user DEMANDS to break the RFC and have more versions of a profile within a single card
                    my $sth = $self->resultset('VCardData')->search({ vcd_card_id => $card_id, vcd_profile_id => $vcd_row});
                    if(defined $sth && $sth != 0){
                       # warn "Yay we already have some data for vcd_card_id='".$card_id . "' and vcd_profile_id='". $vcd_row . "' " . $sth;
                       # warn "Updating in Contact View a HASH";
                        my %update;
                        $update{vcd_value} = $create_data{$vcd_row}{value};
                        if($create_data{$vcd_row}{bin} || $create_data{$vcd_row}{detail}){
                            if($create_data{$vcd_row}{bin}){
                                $update{vcd_bin} = $create_data{$vcd_row}{bin};
                            }elsif( $create_data{$vcd_row}{detail} ){
                                delete($create_data{$vcd_row}{detail});
                                $update{vcd_bin} = '';
                                $sth->delete;
                                next UPDATE_ROW;
                            }
                        }
                        #$sth->update({ vcd_value=> "$create_data{$vcd_row}{value}" });
                        $sth->update( \%update );
                    }else{
                       # warn "NEW data in UPDATE view Contact";
                        my %create = ( vcd_card_id => $card_id, vcd_profile_id => $vcd_row, vcd_value=> "$create_data{$vcd_row}{value}" );
                        if($create_data{$vcd_row}{bin}){
                                $create{vcd_bin} = $create_data{$vcd_row}{bin};
                        }
                        my $new_sth = $self->resultset('VCardData')->create( \%create );
                        #my $new_sth = $self->resultset('VCardData')->create({ vcd_card_id => $card_id, vcd_profile_id => $vcd_row, vcd_value=> "$create_data{$vcd_row}{value}" });
                    }
                        
                }elsif(ref($create_data{$vcd_row}) eq 'ARRAY'){
                    # we have an array of hashes, (so more than one row for each profile_type)
                    #warn "$vcd_row (" . ref($create_data{$vcd_row}) . ") = " . @{ $create_data{$vcd_row} };
                    foreach my $cd_row (@{ $create_data{$vcd_row} }) {
                        #warn "UPDATE vCard_data SET vcd_value = \"$cd_row->{value}\" WHERE vcd_card_id = $card_id AND vcd_prof_detail = '$cd_row->{detail}'"; 
                        my $sth = $self->resultset('VCardData')->search({ 
                                vcd_card_id => $card_id, 
                                vcd_profile_id => $vcd_row, 
                                vcd_prof_detail => $cd_row->{detail}
                            })->single;
                        if(defined $sth && $sth != 0){
                            #warn "STH" . $sth;
                            $sth->update({ vcd_value=> "$cd_row->{value}" });
                        }else{
                           $self->resultset('VCardData')->create({ vcd_card_id => $card_id,      
                                           vcd_profile_id => $vcd_row,     
                                           vcd_prof_detail => $cd_row->{detail},     
                                           vcd_value=> "$cd_row->{value}"     
                                        });
                        }
                    }
                }else{
                    # we have something else
                    warn "ERROR: $vcd_row (" . ref($create_data{$vcd_row}) . ") = " . Dumper($create_data{$vcd_row});
                }
            }
            $self->tt_params( headmsg => qq |<span class="warning">updated.</span>|);
        }elsif(defined $q->{'param'} && $q->param('Add')){
         #NOTE this is where we are going to put in the Add code
                my $warning .= "Update failed... sorry. (Let your sysadmin know.)";
                $self->tt_params({headmsg => $warning});
                #warn Dumper($rs->as_id);
                warn "update of vCard $card_id by " . $self->authen->username . " failed";
        }


# NTS the add logic works for adding, but it is flawed
# You should only create a card if it does not exist
#
# then we can think about merging &add and &view

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
                my $p_type = $vcd->profile->vcprofile_type;
                my $p_feature = $vcd->profile->vcprofile_feature;
                my $p_detail = $vcd->vcd_prof_detail;
                my $p_value = $vcd->vcd_value;
                if($p_type eq 'bin'){
                    my $p_bin = $vcd->vcd_bin;
                    if($p_feature eq 'PHOTO' || $p_feature eq 'LOGO'){
                        my $img_type = $p_value;
                        $img_type=~s/^.*\.//;
                        $card{$p_feature}{'type'} = $img_type;
                        $card{$p_feature}{'name'} = $p_value;
                        $card{$p_feature}{'bin'} = $p_bin;
                    }elsif($p_bin && $p_bin ne ''){
                        use MIME::Base64;
                        my $p_base64 = decode_base64($p_bin);
                        $card{$p_feature}{'bin'} = $p_base64;
                        #warn $p_base64;
                    }elsif($p_feature eq 'KEY' && ( !defined $p_bin || $p_bin eq '' ) ){
                        $card{$p_feature} = $p_value;
                        #warn "$p_feature = $p_value ";
                    }else{
                        warn "type: $p_type feature: $p_feature detail: $p_detail value: $p_value bin: $p_bin is BLANK";
                    }
                }elsif($p_detail && $p_detail ne ''){
                    if(exists $card{$p_feature}){
                        if(ref($card{$p_feature}) eq 'HASH'){
                            $card{$p_feature}{$p_detail} = $p_value;
                        }else{  # we have a scalar and we _should_ have a hash!
                            my $string = $card{$p_feature};
                            delete($card{$p_feature});
                            $card{$p_feature}{$p_detail} = $p_value;
                            if($p_detail eq 'work'){
                                $card{$p_feature}{'home'} = $string;
                            }else{
                                $card{$p_feature}{'work'} = $string;
                            }
                        }
                    }else{
                        #$card{$p_feature} = {$p_detail => "$p_value"};
                        $card{$p_feature}{$p_detail} = $p_value;
                    }
                }else{
                    $card{$p_feature} = $p_value;
                }
            }
            $self->tt_params({ card => \%card });
            $self->tt_params({ cards => \@cards });
            $self->tt_params({ message => "Everything in card $card_id" });
        }else{
            $self->tt_params({ error => "vCard $card_id is yet to be created." });
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

 - yes, this /could/ be used for evil.

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

   # warn "in Contacts::sales card_id = $card_id";
    unless($card_id=~m/^\d+$/){
            $card_id = {'like' => '%'};
    }
   # warn "in Contacts::sales card_id = $card_id";
    my $card_rs = $self->resultset('VCard')->search({ card_id => $card_id });
    my $card_exists = $card_rs->count;
    if($card_exists){
            my @cards = $self->resultset('VCard')->search({
                    card_id => $card_id,
                    #card_peid => $pe_id
                },{
                    #join => { data => 'profile', },
            #        #'+columns' => [ 'vCard_profile.vcprofile_version','vCard_profile.vcprofile_feature','vCard_profile.vcprofile_type',
            #        #'vCard_data.vcd_id', 'vCard_data.vcd_prof_detail', 'vCard_data.vcd_value', 'vCard_data.vcd_bin' ],
            #        #columns => [ 'card_id', 'card_acid', 'card_encoding', 'card_updated', 
                });
            $self->tt_params({ card => \@cards });
        # VCardData.pm     VCard.pm         VCardProfile.pm
            my %vcd;
           while( my $vc = $card_rs->next){ 
             if(defined $vc->card_id && $vc->card_id=~m/^\d+$/){
                my @vcd = $self->resultset('VCardData')->search({
                    vcd_card_id => $vc->card_id
                  },{
                    join => 'profile',
                    '+columns' => [qw/profile.vcprofile_version profile.vcprofile_type profile.vcprofile_feature/],
                  });
                @{ $vcd{$vc->card_id} } = @vcd;
             } 
            }
            $self->tt_params({ vcd => \%vcd });
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

=head3 edit

  * Purpose - edit a single vCard_data row
  * State   - To be written
  * Function- This enabled additional rows to contacts

=cut

sub edit: Runmode {
    my ($self) = @_;
    my $url = $self->query->url;
    my $q = $self->query();
    $self->tt_params({ message => "Don't be evil" });
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

