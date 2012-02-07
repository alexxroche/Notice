package Notice::C::Assets;

use warnings;
use strict;
use base 'Notice';

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

To create and manage a list of assets

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    my $runmode;
    $runmode = ($self->query->self_url);
    $runmode =~s/\/$//;
    if($self->param('rm')){
        $runmode = $self->param('rm');
    }
    if($self->param('id')){
        my $id = $self->param('id');
        if($self->param('extra1')){
            my $extra = $self->param('extra1');
            $runmode =~s/\/$extra[^\/]*//;
        }
        if($self->param('sid')){
            my $sid = $self->param('sid');
            $runmode =~s/\/$sid[^\/]*//;
        }
        $runmode =~s/\/$id[^\/]*$//;
    }
    $runmode=~s/.*\///;

    my $known_as;
    #$known_as = $self->param('known_as');
    #$self->tt_params({title => 'Notice CRaAM ' . $runmode ." - $known_as at ". $ENV{REMOTE_ADDR}});

    my $page_loaded = 0;
    eval {
        use Time::HiRes qw ( time );
        $page_loaded = time;
    };
    if($@){
        $page_loaded = time;
    }

    # we /could/ put this in Notice.pm but then it would be less accurate
    if($self->param('cgi_start_time')){
        $self->tt_params({page_load_time => sprintf("Page built in: %.2f seconds", ($page_loaded - $self->param('cgi_start_time')))});
    }elsif($self->param('page_load_time')){
        $self->tt_params({page_load_time => sprintf("Page loaded %.2f seconds", ($page_loaded - $self->param('page_load_time')))});
    }

}

=head3 plt

find out when this page finished loading

=cut

sub plt {
    my $self = shift;
    my $page_loaded = 0;
    eval {
        use Time::HiRes qw ( time );
        $page_loaded = time;
    };
    if($@){
        $page_loaded = time;
    }
    $self->tt_params({page_load_time => sprintf("Took %.3f ms", (($page_loaded - $self->param('page_load_time'))*1000))});
    #return $page_loaded;
}


=head2 RUN MODES

=head3 main

the default page
This has a long way to go. If the user is not in the admin group then they should not get
warnings about undefined asset categories.

If there are no asset categories then the user should be directed, (walked through) creating one.)

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $surl;

    $surl = ($self->query->self_url);
    my $message='';
    my $user_msg;
    my $username = '';
    $username = $self->authen->username;
    if($username && $username ne ''){
        $self->tt_params({ username => $username});
    }

    # NOTE !
    # we should warn if there is an asset_category entry that has no asset_cat_data
    # select asc_id, asc_name, asc_description from asset_categories LEFT JOIN asset_cat_data ON acd_cid = asc_id WHERE acd_id is NULL;
    # so that they can go and define them


    my @c_missing_data = $self->resultset('AssetCategory')->search({
           'acd_id' => undef
        },{
            join => 'catdata',
            group_by => [qw/asc_id/],
        })->all;
      $self->tt_params({ c_missing_data => \@c_missing_data});


    # we only want fully defined Categories
    my @ac = $self->resultset('AssetCategory')->search({
           'acd_id' => { '>=', 1}
        },{
            #select => [ { distinct => [ $source->columns ] } ], as => [ $source->columns ], 
            group_by => [qw/asc_id/],
            join    => 'catdata',
        })->all;

    my $page;
    
    $page =qq ( 
        <p>
    <h4><a class="small black button so we can see it which monkey wrote this css" href="$surl/define">
<strike>Define a type of Asset</strike></a></h4>
</p>);

    if(defined $user_msg){ $page .=qq ( $user_msg; <br /> ); }

    $page .=qq (<h4><strike>Search</strike></h4>
    <p>
    <h4> List </h4>
    <a class="navigation" href="/cgi-bin/index.cgi/assets/list/cid/19">list all trees</a> in the asset database or
    <a class="navigation" href="/cgi-bin/index.cgi/assets/list/cid/20">all the fields on the farm</a>;
    <a class="navigation" href="/cgi-bin/index.cgi/assets/list">list all</a> Assets; 
    <a class="navigation" href="$surl/list/18">or just one</a> (the layout for just one is without the module wrapper, for later AJAX development)
    <br /><br /> or add/edit the Data for an asset <a class="navigation" href="/cgi-bin/index.cgi/assets/data/20/18/">e.g. Asset 18</a>
    </p>

    <br />
    <br />);

=head2 Tables

 Admin section:
    Manage the Asset Categories :
    <span class="pre">
+--------+----------+---------------------------------+----------+
| asc_id | asc_name | asc_description                 | asc_grid |
+--------+----------+---------------------------------+----------+
|     18 | Laptop   | A Laptop computer               |     NULL | 
|     19 | A Tree   | Tall thing with leaves          |     NULL | 
|     20 | A Field  | Thing with plants or animals in |     NULL | 
|     21 | Server   | A type of computer              |     NULL | 
+--------+----------+---------------------------------+----------+
</blockquote>

    and edit associated Asset Category Data: e.g.
    <span style="pre">
+--------+---------+---------------------------------+-----------+----------+---------------------+----------+
| acd_id | acd_cid | acd_name                        | acd_order | acd_type | acd_regexp          | acd_grid |
+--------+---------+---------------------------------+-----------+----------+---------------------+----------+
|     27 |      19 | Planting date                   |         2 | text     | \\d{4}.?\\d{2}.?\\d{2} |     NULL | 
|     29 |      19 | Height                          |         3 | text     | \\w+                 |     NULL | 
|     30 |      19 | Common Name                     |         1 | select   | \\w+                 |       10 | 
|     31 |      19 | Planting Ref                    |         4 | text     | \\w+                 |     NULL | 
|     32 |      19 | Cause of Death                  |        12 | text     | \\w+                 |     NULL | 
|     33 |      19 | Date of Death                   |        11 | text     | \\w+                 |     NULL | 
|     37 |      19 | GPS Location                    |         8 | text     | \\w+                 |     NULL | 
|     35 |      19 | Trunk Circumpherence at Ground  |         6 | text     | \\w+                 |     NULL | 
|     36 |      19 | Trunk Circumpherence at 1 Meter |         7 | text     | \\w+                 |     NULL | 
|     54 |      19 | Leaf Colour                     |         5 | text     | \\w*                 |     NULL | 
+--------+---------+---------------------------------+-----------+----------+---------------------+----------+
</span>
    );
=cut

    $self->tt_params({
    heading => 'Welcome to the new Assets page!',
    message => $message,
    ac      => \@ac,
    page => $page,
          });
    $self->plt;
    return $self->tt_process();
    
}

=head3 delete

This deletes an asset

=cut

sub delete: Runmode{
    my ($self) = @_;
    use Data::Dumper;
    my $q = \%{ $self->query() };  # WORKS
    my $message;
    my $warning;
    if($self->param('id')){ $message = "Deleting asset " . $self->param('id') . ' ';
        if($self->param('sid')){ $message .= $self->param('sid');}
        $message .=  ".... once that is written.";
    }else{ $message .= "Error"; }
        unless($self->param('id') || $q->param('id')){
          $warning = "Which asset are you looking for?";
      $message = Dumper($q);
    }
        $self->tt_params(
                title => 'Delete an asset',
                 message => $message,
        TEMPLATE_OPTIONS => { WRAPPER => 'site_wrapper.tmpl' },
                 warning => $warning
        );
    return $self->tt_process();
}

=head3 details

  These are the details of an existing asset (either being shown or added)
    if you want to add a type of asset then you need sub define: Runmode
  
  * Purpose - display/update/add asset details (not to be confused with the asset data)
  * Expected parameters - data
  * Function on success - put it in the the asset table
  * Function on failure - a good error message.. one day

=cut

sub details: Runmode{

    # NTS this is a mess! we have to collec the data and populate @asc with it
    #    as we create @asc from the database (right now it is hard coded into this Runmode
    #   then again this Runmode is designed for a specific database so why not just
    #   collect the data and create @asc with it?

    my ($self) = @_;
    my $message;
    my $warning;
    use Data::Dumper;
    my ($as_cid,$as_id);
    my $q = \%{ $self->query() };  # WORKS
    ##my $q = %{ $self->query() }; # BROKEN
    #my $q = $self->query();   # WORKS
    #$warning .= Dumper($q->{'param'});
    if($self->param('id')){
        $as_cid = $self->param('id');
        $as_cid=~s/.*\?id=//;
        if($self->param('sid')){ 
            $as_id = $self->param('sid');
        }
    }elsif($q){
        if($q->param('id')){ $as_cid = $q->param('id'); }
        elsif($q->param('sid')){ $as_cid = $q->param('sid'); }
          $message .= "QO = " . Dumper($q);
          $message .= "<br />\n";
          #foreach my $ref (@{ $q->param("id") }){
          #      $message .= "RREF = $ref<br />\n";
          #}
      if($as_cid){ 
            $message .= "REF = $as_cid " . ref($as_cid);
      }
          #$message .= "DUMP = " . ref($self->param('id'));
    }
    unless($as_cid && $as_cid=~m/^\d+$/){
        use String::Clean::XSS;
                $as_cid = convert_XSS("$as_cid");
                my $error = "I need to know what type of asset we are adding<br />\n";
                $message .=qq |<div><span class="error">$as_cid</span> is not a valid asset type</div>|;
                #$message .= Dumper($self);
                $self->tt_params(
                        title => 'Error - unknown asset type',
                        error => $error,
                        message => $message);
                return $self->tt_process();
    }
    $message='';

    if ( $q->param('create') && $q->param('create') eq "new" ) {
    #use DateTime;
    #my $now = DateTime->now();         # these three lines work but why bother?
    #my %create_data = ( as_date => $now);

    my %create_data = ( as_date => \'NOW()');   #this works
    # my %create_data = ({ as_date => \'NOW()'});   #or this might
    foreach my $ak (keys %{ $q->{'param'} } ){
    # might be better to pull this from an array, but there must be a
    # better DBIx::Class way to know which collums we are looking for
      if(
        $ak eq 'cid' || 
        $ak eq 'acid' ||
        $ak eq 'owner' ||
        $ak eq 'user' ||
        $ak eq 'adid' ||
        $ak eq 'grid' ||
        $ak eq 'in_asid' ||
        $ak eq 'notes'
       ){
        $create_data{"as_$ak"} = $q->param($ak);
       }
    }
    #$warning = Dumper(%create_data);
    my $comment = $self->resultset('Asset')->create( \%create_data );
        $comment->update;
    $as_id = $comment->id;
    #$warning = Dumper($comment);
        $self->tt_params( headmsg => qq |Asset added! <a href='/cgi-bin/index.cgi/assets/data/$as_cid/$as_id/'>Asset added!</a>|);
    }elsif($q->param('update') && $q->param('update') eq 'update') {
    $warning .= "This is still to be written...";
    }
     my  @asc = ();
    if($as_id && $as_id=~m/^\d+$/){
      my $as_rs = $self->resultset('Asset')->search(
        { 'as_id' => { '=', "$as_id"}},
        {});
      while(my $l=$as_rs->next){
        my $as_acid = $l->as_acid;  
        my $as_owner = $l->as_owner;    
        my $as_user = $l->as_user;  
        my $as_adid = $l->as_adid;  
        my $as_grid = $l->as_grid;  
        my $as_notes = $l->as_notes;    
            push ( @asc, 
         {ac_name => 'Account', ac_id => 'acid', ac_type => 'text', ac_regexp => '\d+(\.\d+)*', ac_value=> "$as_acid" },
             {ac_name => 'Owner',   ac_id => 'owner', ac_type => 'text', ac_regexp => '\d+', ac_value=> "$as_owner" },
             {ac_name => 'User',    ac_id => 'user', ac_type => 'text', ac_regexp => '\d+' },
             {ac_name => 'Address', ac_id => 'adid', ac_type => 'text', ac_regexp => '\d+' },
             {ac_name => 'Group',   ac_id => 'grid', ac_type => 'text', ac_regexp => '\d+' },
             {ac_name => 'Container',ac_id =>'in_asid', ac_type => 'text', ac_regexp => '\d+' },
         {ac_name => 'Notes', ac_id => 'notes', ac_type => 'textarea', ac_regexp => '', ac_value => "$as_notes" }
        );
      }
      $self->tt_params( title => 'Asset Details',
             submit => 'Update',
             update => 'update'
    );
    }else{ 
        @asc = (
                 {ac_name => 'Account', ac_id => 'acid', ac_type => 'text', ac_regexp => '\d+(\.\d+)*', ac_value=>'1.5' },
                 {ac_name => 'Owner',   ac_id => 'owner', ac_type => 'text', ac_regexp => '\d+', ac_value=>'1' },
                 {ac_name => 'User',    ac_id => 'user', ac_type => 'text', ac_regexp => '\d+' },
                 {ac_name => 'Address', ac_id => 'adid', ac_type => 'text', ac_regexp => '\d+' },
                 {ac_name => 'Group',   ac_id => 'grid', ac_type => 'text', ac_regexp => '\d+' },
                 {ac_name => 'Container',ac_id =>'in_asid', ac_type => 'text', ac_regexp => '\d+' },
         {ac_name => 'Notes', ac_id => 'notes', ac_type => 'textarea', ac_regexp => '', ac_comment => "Keep this short, as we mostly want to add notes into the Asset Data rather than here"},
                );
        @asc = $self->resultset('AssetCatData')->search(
                { 'acd_cid' => { '=', "$as_cid"}},
                {});
      $self->tt_params( title => 'Add Asset Details',
             submit => 'Add',
             create => 'new'
    );
    }   
    my $ac_rs = $self->resultset('AssetCategory')->search(
                { 'asc_id' => { '=', "$as_cid"}},
                {});
    while(my $k=$ac_rs->next){
                #push(@asc, {type => $k->asc_name});
                my $name = $k->asc_name;
                $self->tt_params( type => $k->asc_name);
                if($name=~m/^[aeiouh]/){ $self->tt_params( ning => 'an'); }
    }
    my @ach = (
                {name=>'cid',value=>"$as_cid"}
                );

    unless(@asc){
        my $error = "That isn't a valid asset ID<br />\n";
        unless(defined $as_id){ $as_id = 'That'; }
        $message =qq |<div><span class="error">$as_id</span> is not a valid asset</div>|;
        $self->tt_params(
                title => 'Error - unknown asset',
                error => $error,
                message => $message);
        return $self->tt_process();
    }


    $self->tt_params( 
         asc => \@asc,
         ach => \@ach,
         message => $message,
         warning => $warning
    );
    return $self->tt_process();
    
}

=head3 data

  * Purpose - display/add data to an asset
  * Expected parameters
  * Function on success
  * Function on failure

=cut


sub data: Runmode{
    my ($self) = @_;
    my $message;
    use Data::Dumper;
    my $acd_id;
    my $as_id;
    my $q = \%{ $self->query() };
    if($self->param('sid')){
        $as_id = $self->param('sid');
    }elsif($q && $q->param('sid')){
        $as_id = $q->param('sid');
    }
    
    if($self->param('id') && defined $as_id){
        $acd_id = $self->param('id');
    #}elsif( ref($self->param('id')) eq 'ARRAY'){
    #   $acd_id = $self->param('id')->[0];
    }elsif(! defined $self->param('sid')){
        $as_id = $self->param('id');
        my $find_asc =  $self->resultset('Asset')->search(
                { 'as_id' => { '=', "$as_id"},
        },{})->first;
        if($self->resultset('Asset')->search({ 'as_id' => { '=', "$as_id"}, },{})->count == 1){
            $acd_id = $find_asc->as_cid;
        }else{
            $self->tt_params( 
                title => 'Error - unknown asset',
                message => 'That asset has not yet been added to the database',
                no_data => '1',
                error => '<script type="text/javascript">
function goBack()
  {
  window.history.back()
  }
function goHome(url)
    {
        window.document.location.href=url
    }
</script>
</head>
<body>

<input type="button" value="Maybe try going back" onclick="goBack()" />
<input type="button" value="or searching" onclick="goHome(\'/cgi-bin/index.cgi/assets\')" />'
                );
            return $self->tt_process();
        }
        # we should only have one entry!
        #while(my $fasc=$find_asc->next){ $acd_id = $fasc->ac_cid; }
    }else{
        no strict "refs";
        if($q && $q->param('id')){
          $message .= "QO = " . Dumper($q);
          $message .= "<br />\n";
          #foreach my $ref (keys %{ $self->param('id') }){
          foreach my $ref (@{ $q->param("id") }){
            $message .= "RREF = $ref<br />\n";
          }
          $acd_id = $q->param('id');
          $message .= "REF = $acd_id " . ref($acd_id);
          #$message .= "DUMP = " . ref($self->param('id'));
        }
    }

    #my $acd_id = '';
    unless($acd_id && $acd_id=~m/^\d+$/){
    use String::Clean::XSS;
        my $clean_acd_id = convert_XSS("$acd_id");
        my $error = "I need to know what type of asset we are adding<br />\n";
        $message .=qq |<div><span class="error">$clean_acd_id</span> is not a valid asset type</div>|;
        #$message .= Dumper($self);
        $self->tt_params( 
            title => 'Error - unknown asset type',
            error => $error,
            message => $message);
        return $self->tt_process();
    }


    if ( $q->param('do') && $q->param('do') eq "Add to" ) {
    #$message .= "What's going on here?";
        ADD: foreach my $ak (keys %{ $q->{'param'} } ){
      if($q->param($ak) ne '' && $ak=~m/^\d+$/){
            my %create_data = ( asd_date => \'NOW()');
        $create_data{'asd_value'} = $q->param($ak);
        my $comment = $self->resultset('AssetData')->search( { asd_cid => $ak, asd_asid => $q->param('sid') });
        #$comment->update_or_create( \%create_data );
        $comment->create( \%create_data );
       }
    }
        $self->tt_params( headmsg => qq |Asset Data added! <a href='?'>&laquo;back</a>|);
    }elsif ( $q->param('do') && $q->param('do') eq "Update" ) {
      use DateTime;
      my $now = DateTime->now();
      my %create_data;
      my $debug .= 'id:' . $q->param('id');
      $debug .= 'sid:' . $q->param('sid');
      $debug .= '<br />\n';
      UPDATE: foreach my $ak (keys %{ $q->{'param'} } ){
        # might be better to pull this from an array, but there must be a
        my $v = $q->param($ak);
        my %key;
        if($v){
          $debug .=qq |AK:$ak = $v <br />\n |; #/ vi-fix
        }else{ next UPDATE; }
            # better DBIx::Class way to know which collums we are looking for
            if( $ak=~m/^\d+$/ && $v){
                    $create_data{'asd_value'} = $q->param($ak);
            $key{'asd_cid'} = $ak;
            $key{'asd_asid'} = $q->param('sid');
            #$key{'asd_cid'} = $id; #asset_data.asd_cid is really asset_cat_data.acd_id not asset_categories.asc_id
            }
            #$warning = Dumper(%create_data);
            # NTS you are preparing the update (key seems not to work)
            if(%create_data && %key){
                    # my %create_data = ({ as_date => \'NOW()'});   #NOTE or this
                    # my %create_data = ( as_date => \'NOW()');     #NOTE this might work
                    $create_data{'asd_date'} = $now;
                    #my $comment = $self->resultset('AssetData')->update( \%create_data, {asd_cid => $ak, asd_asid => "$q->param('sid')" });
                    my $comment = $self->resultset('AssetData')->search( { asd_cid => $ak, asd_asid => $q->param('sid') });
                    #my $comment = $self->resultset('AssetData')->update( \%create_data, \%key);
                    $comment->update_or_create( \%create_data );
                    #$warning .= "WARNING: " . Dumper($comment);
                    #$warning .= "WARNING: tried to do the update " . $comment->as_query();
                    #$self->tt_params( headmsg => qq |Asset data updated! <a href='?'>&laquo;back</a> ($comment)|);
                    $self->tt_params( headmsg => qq |Asset data updated!|);
            }else{
                $debug .= "INFO: " . Dumper(%key);
            }
      }
    }else{
        $self->tt_params( headmsg => qq |Enter Asset Data here|);
        #$debug .= Dumper($self);
    }


    my %asd;
    my @as_select; #list of asset_categories that are TYPE select
    my  @asc = $self->resultset('AssetCatData')->search(
        { 'acd_cid' => { '=', "$acd_id"}},
        {
        #join => 'assetcategory',
        ##prefetch => 'assetcategory',
        #'+select' => ['assetcategory.asc_name'],
        #'+as' => ['assetcategory.type'],
        order_by => 'acd_order',
        });
    # could loop through @asc looking or if we want something that is probaly slower...
    my $ass_rs = $self->resultset('AssetCatData')->search(
        { 'acd_cid' => { '=', "$acd_id"}, 'acd_type' => { '=', 'select'}},
        {});
    while(my $srs = $ass_rs->next){
        my $arse = $srs->acd_id;
        #my $group = $src->acd_group; # we should be using this somehow
        push(@as_select,$arse);
    }

    my $ac_rs = $self->resultset('AssetCategory')->search(
        { 'asc_id' => { '=', "$acd_id"}},
        {});
    while(my $k=$ac_rs->next){
                #push(@asc, {type => $k->asc_name});
                my $name = $k->asc_name;
                $self->tt_params( type => $k->asc_name);
                if($name=~m/^[aeiouh]/){ $self->tt_params( ning => 'an'); }
    }
    if($as_id && $as_id=~m/^\d+$/){
        my $ad = $self->resultset('AssetData')->search(
        { 'asd_asid' => { '=', "$as_id"}},
        {});
        while(my $d=$ad->next){
        my $value = $d->asd_value;
        my $key = $d->asd_cid;
        $asd{$d->asd_cid} = $value;
        #$asd{$d->asd_cid}{date} = $d->asd_date;
        $asd{cid} = $as_id;
        }
    }
    foreach my $ass (@as_select){
    my $acdgm = $self->resultset( 'AssetCatDataGroupMembers' )->search( {},
        {
            bind  => [ $ass ]
        }
    );
    my $existing_value = '';
    if($asd{$ass}){ $existing_value=$asd{$ass}; $asd{$ass}='';}
    while(my $r=$acdgm->next){
        my $v = $r->gr_id;
        my $n = $r->gr_name;
        $asd{$ass} .=qq |<option value="$v"|;
        if($asd{$ass} && $existing_value eq $v){ $asd{$ass} .=qq | selected="selected"|; }
        $asd{$ass} .=qq |>$n</option>\n|;
    }
    }
    my $submit = 'Add to';
    if(%asd){
    $submit = 'Update';
    }
    
    unless(@asc){
        my $error = "That isn't a valid acd_id<br />\n";                                                               
                $message =qq |<div><span class="error">$acd_id</span> is not valid</div>|;
                $self->tt_params(                                                                                                                                 
                        title => 'Error - unknown asset type',                                       
                        error => $error,                       
                        message => $message); 
                return $self->tt_process();
    }
    #$message='';
    $self->tt_params( submit => $submit, title => 'Asset Data', asid => $as_id, asc => \@asc, message => $message, asd => \%asd);
    return $self->tt_process();

}

=head3 list

  * Purpose - list assets (or one asset) from the database
  * Expected parameters - are optional, but if there is one then it should be an as_id
  * Function on success
  * Function on failure

=cut


sub list: Runmode{
    my ($self) = @_;
    my $as_id = $self->param('id')=~m/^\d+$/ ? $self->param('id') : '%';
    my (%Asset_search,%AssetData_search,%AssetCatData_search, %AssetCatData_search_orderby);
    if($self->param('id') eq 'cid' && $self->param('sid')=~m/^(\d+)$/){ 
        %AssetData_search = ('asd_cid' => { '=', "$1"});
        %AssetCatData_search =('acd_cid' => {'=', "$1"});
        %Asset_search =('as_cid' => {'=', "$1"});
        %AssetCatData_search_orderby=(order_by => 'acd_order');
    }

    my @assets = $self->resultset('Asset')->search(
                { 'as_id' => { 'LIKE', "$as_id"}, %Asset_search
        },
        {
    join     => 'category',
    #prefetch => 'category',
        }
        );

    unless(@assets){
        $self->tt_params( title => 'Error - no such asset', message => "Can't seem to see that asset", error => '1');
        return $self->tt_process();
    }
    
    my $message;
    my %asd;
    my %ac;
    my %type;
        my  $as_rs = $self->resultset('AssetCatData')->search( { %AssetCatData_search }, { %AssetCatData_search_orderby});
    while(my $k=$as_rs->next){
        $ac{$k->acd_id} = $k->acd_name;
        my $type = $k->acd_type;
        if($type eq 'select'){ $type{$k->acd_id} = 'select'; }
    }
    foreach my $asset (@assets){
        my %arsset = %{ $asset };
        my $as_id =$arsset{_column_data}{as_id};
        my $asd_rs = $self->resultset('AssetData')->search(
               { 'asd_asid' => { '=', "$as_id" }, 
               },
               {
               order_by => 'asd_cid',
               });
        while(my $key = $asd_rs->next){
            my $asd_id = $key->asd_id;
            my $asd_cid = $key->asd_cid;
            my $asd_value = $key->asd_value;
            my $asd_date = $key->asd_date;
            if($type{$asd_cid} && $type{$asd_cid} eq 'select'){ 
                my $acdgm = $self->resultset( 'AssetCatDataGroupEntry' )->search({},
                {
                    bind  => [ $asd_cid, $asd_value ]
                }
                );
                while(my $r=$acdgm->next){
                    my $n = $r->gr_name;
                    my $f = $r->gr_function;
                    $asd_value =qq |<a title="$f">$n</a>|;
                }
            }
            push @{ $asd{$key->asd_asid} }, { asd_id => "$asd_id", asd_cid => "$asd_cid", asd_value => "$asd_value", asd_date => $asd_date };
        } 
    };

    if($as_id=~m/^\d+$/){ $self->tt_params( no_wrapper => 1, title=> "Data for Asset $as_id" ); }
    else{ $self->tt_params( title => 'A list of assets',
        TEMPLATE_OPTIONS => { WRAPPER => 'site_wrapper.tmpl' },
            heading => 'Asset List'
        );
        }
    $self->tt_params( assets =>\@assets, asd => \%asd, message => $message, ac => \%ac);
    #if($as_id!~m/^\d+$/){ $self->tt_params( heading => 'Asset List'); }
    return $self->tt_process();

}

=head3 define

This lets you define an asset
# NTS you are here - if we have a cid then pull what we DO know from the DB

=cut

sub define: Runmode {
    use Data::Dumper;
    my ($self) = @_;
    my ($surl,$page);
    $surl = ($self->query->self_url);
    my $q = \%{ $self->query() };
    my $message='';
    my $user_msg;
    my $cid = '';
    #$cid = $self->param('cid')=~m/^\d+$/ ? $self->param('cid') : $q->param('cid');
    if(defined $self->param('id') && $self->param('id')=~m/^(\d+)$/){ 
        $cid = $1; 
    }elsif($q->param('cid')){ 
        $cid = $q->param('cid');
    }else{
     #$message .= "id:".$self->param('id')  ."sid:". $self->param('sid'); 
    }
    if($cid=~m/^(\d+)$/){
        my %AssetCatData_search =('acd_cid' => {'=', "$1"});
        my %AssetCatData_search_orderby=(order_by => 'acd_order');
        my $ac = $self->resultset('AssetCategory')->search({ asc_id => {'=', $cid}}, {})->first;
        my @acd = $self->resultset('AssetCatData')->search( { %AssetCatData_search }, { %AssetCatData_search_orderby});

        if($q->param('id')){ #we might have new data or an update

        # NTS you are HERE preparing the data for insert
            $message .= "Looks like you are updating Asset Category " . $q->param('id');
            $message .= Dumper($q->param);
            my $this_count=0;
            foreach my $ak (keys %{ $q->{'param'} } ){
                my $v = $q->param($ak);
                $message .= "\n<br />";
                $this_count++; $message .= "\n<br /> $this_count $ak = " . $q->param($ak);
            }


            $self->tt_params({
            heading => "Changed the '" . $ac->asc_name . "' category",
            ac     => $ac,
            acd     => \@acd,
            message => $message,
            page => $page,
                  });
            $self->plt;
            return $self->tt_process();

        }

        #$message .= Dumper($ac);
        if(defined $ac){
            $self->tt_params({
            heading => "Update the '" . $ac->asc_name . "' Asset category",
            ac     => $ac,
            acd     => \@acd,
            message => $message,
            page => $page,
                  });
            $self->plt;
            return $self->tt_process();
        }
    }elsif(defined $q->param){
    no strict "refs"; #debug
        $message .= "So you want to add " . Dumper($q->param);
        my $qp = $q->param;
        $message .= "\n<br />"; my $this_count=0;
        foreach my $key (keys %{ $qp }){ $this_count++; $message .= "\n<br /> $this_count $key = " . $qp->("$key"); }
    }
    #else we have a new category

    $self->tt_params({
    heading => 'Add a new type of Assets',
    message => $message,
    page => $page,
          });
    $self->plt;
    return $self->tt_process();
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module, but be kind: This was me learning CGI::App 
for the first time, (hence the mess.)

I am fixing bugs and adding features. I will report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

