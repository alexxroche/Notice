package Notice::C::Assets;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';
my %opt; #options; nice to have.
my %submenu = (
   8 => [
        '1' => { name=> 'Add', rm => 'details', class=> 'navigation'},
        '2' => { name=> 'List', rm => 'list', class=> 'navigation'},
        '3' => { name=> 'Define', rm => 'define', class=> 'navigation'},
        '99' => { name=> 'Categories', rm => 'defined', class=> 'navigation'},
    ],
);


=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

To create and manage a list of assets or possetions. 
It might also be possible to use this to run a stock-room list.

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.
Set which runmodes require authentication, (all of them).
Set the submenu.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    unless( 
            $self->param('group.asset_admin') 
            || ( $self->param('pe_id') && $self->param('pe_id') >= 2) #this is a dirty hack
    ){
        delete($submenu{8}[@{ $submenu{8} }-1]);
    }
    $self->tt_params({submenu=>\%submenu});
   # my $runmode; $runmode = ($self->query->self_url);
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
    $page .=qq |
            The assets section will have the asset definitions off in a sub section, (once we get this organised and written).
            For now you just need to know that defining an asset is not the same as adding an asset. Once an asset is defined, (e.g. "That a CD has a name, an artits and a number of tracks" ) we can then add a CD to the database, including some or all of the asset atributes.
     For now asset attributes are universal, (why define a CD twice?) but using the asc_grid it is possible to have an asset that is bound to a particular account or person, (or group of accounts or people). So if you only have Pop CDs then you probably do not need an entry for composer. The flip side to this is that each piece of asset data is stored seperatly, so if your CD does not have a composer then by leaving it blank no database space will be used. It is even possible for a user to edit their CSS so that the asset table does not display the composer option.
    |;
    
    $page .=qq ( 
        <p>
    <h4><a class="small black button so we can see it, which monkey wrote this css?" href="$surl/define">Define a new Asset</a></h4>
</p>);

    if(defined $user_msg){ $page .=qq ( $user_msg; <br /> ); }

    # Find an example asset


    if($self->resultset('Asset')->search()->count >= 1){
      my %example;
      my $exas_rs = $self->resultset('Asset')->search();
      while(my $ex=$exas_rs->next){
        $example{as_id} = $ex->as_id;
        $example{as_cid} = $ex->as_cid;
      }
        $page .=qq (<h4><strike>Edit Asset Category Data (especially delete an entry)</strike></h4>
        <h4><strike>Search</strike></h4>
        <p>
        <h4> List </h4>
        <a class="navigation" href="/cgi-bin/index.cgi/assets/list/cid/$example{as_cid}">list all of Category $example{as_cid}</a> in the asset database or
        <a class="navigation" href="/cgi-bin/index.cgi/assets/list">list all</a> Assets; 
        <a class="navigation" href="$surl/list/$example{as_id}">or just one</a> (the layout for just one is without the module wrapper, for later AJAX development)
        <br /><br /> or add/edit the Data for an asset <a class="navigation" href="/cgi-bin/index.cgi/assets/data/$example{as_cid}/$example{as_id}/">e.g. Asset $example{as_id}</a>
        </p>

        <br />
        <br />);
    }else{
        $page .=qq |Once you add an asset this page can use it as an example|;
    }

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
|     27 |      19 | Planting date                   |         2 | text     | \\d{4}.?\\d{2}.?\\d{2} |  NULL |
|     29 |      19 | Height                          |         3 | text     | \\w+                 |    NULL |
|     30 |      19 | Common Name                     |         1 | select   | \\w+                 |      10 |
|     31 |      19 | Planting Ref                    |         4 | text     | \\w+                 |    NULL |
|     32 |      19 | Cause of Death                  |        12 | text     | \\w+                 |    NULL |
|     33 |      19 | Date of Death                   |        11 | text     | \\w+                 |    NULL |
|     37 |      19 | GPS Location                    |         8 | text     | \\w+                 |    NULL |
|     35 |      19 | Trunk Circumpherence at Ground  |         6 | text     | \\w+                 |    NULL |
|     36 |      19 | Trunk Circumpherence at 1 Meter |         7 | text     | \\w+                 |    NULL |
|     54 |      19 | Leaf Colour                     |         5 | text     | \\w*                 |    NULL |
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

=head3 defined

This is a list of the assets that have already been defined
 (so that you can update their definitions

=cut

sub defined: Runmode{
    my ($self) = @_;
    my $q = $self->query();
    if($q->param('debug')){ 
        #$self->tt_params({ error => '<pre id="XSS rulez">' . $q->param('debug'). '</pre>' }); 
        my $debug = $q->param('debug');
        $debug =~s/\W/ /g;
        $self->tt_params({ error => $debug });
    }
    my @types = $self->resultset('AssetCategory')->search();
    $self->tt_params({ types => \@types});

    return $self->tt_process();
}

=head3 details

  These are the details of an existing asset (either being shown or added)
    if you want to add a type of asset then you need sub define: Runmode
  
  * Purpose - display/update/add asset details (not to be confused with the asset data)
  * Expected parameters - an asset id or asset data from the form
  * Function on success - put it in the the asset table
  * Function on failure - a good error message.. one day

  This is really the add/update function for Assets. 

=cut

sub details: Runmode{

    # NTS this is a mess! we have to collect the data and populate @asc with it
    #    as we create @asc from the database (right now it is hard coded into this Runmode
    #   then again this Runmode is designed for a specific database so why not just
    #   collect the data and create @asc with it?

    my ($self) = @_;
    my $message;
    my $warning;
    use Data::Dumper;
    my ($as_cid,$as_id);
    ##my $q = %{ $self->query() }; # can't deref like this
    #my $q = \%{ $self->query() }; # deref, but why? when...
    my $q = $self->query();   # WORKS
    #$warning .= Dumper($q->{'param'});
    if($self->param('id')){ 
        # yeah, bit of a mix up - but as we go into this we have the id for the category
        # but then we are entering a new asset so we are starting to talk about id as the id 
        # for the asset so the id for the category has to transition here, (or you could fix it? maybe)
                    
        $as_cid = $self->param('id');
        $as_cid=~s/.*\?c?id=//;
        $as_cid=~s/;.*$//;
        if($q->param('cid') && $q->param('cid')=~m/^\d+$/ && ( $as_cid != $q->param('cid')) ){
            $as_cid = $q->param('cid');
        }
        #warn "we DO have a cid of $as_cid";
        if($self->param('sid')){ 
            $as_id = $self->param('sid');
        }
    }elsif($q){
        if($q->param('cid')){ 
            $as_cid = $q->param('cid'); 
           # warn "we GOT a CID $as_cid "; 
        }elsif($q->param('sid')){ $as_id = $q->param('sid'); }
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
      warn "NOPE!";
         # we don't know which asset type they want to add!
         # Either they have not selected a category OR there ARE NONE! ooooooh
         my $error = "There are no Asset Categories yet, (how sad).<a href=\"define\">Maybe you should define one.</a><br>\n";
         my @ac_rs = $self->resultset('AssetCategory')->search();
         #if(@ac_rs && @ac_rs->count >= 1){
         if(@ac_rs){
            $error = "What category of Asset would you like to add?<br>\n";
            #$message .=qq |<div><span class="error">$as_cid</span> is .not. a valid asset type</div>|;
            $message ='';
            $self->tt_params({ title => 'Notice CRaMA Assets - please select one', ac => \@ac_rs });
         }else{
            $self->tt_params({ title => 'Notice CRaAM Assets - Shiny and new' });
            $message .=qq |<div>The cupboard is bare, (what is a cupboard? Maybe you could define that!)</div>|;
         }
         $self->tt_params({
             error => $error,
             message => $message});
         return $self->tt_process();
    }
    $message='';
    my @acd = ();
    if($as_cid){
            @acd = $self->resultset('AssetCatData')->search({ 'acd_cid' => "$as_cid"});
    }else{
            @acd = $self->resultset('AssetCatData')->search();
    }
    $self->tt_params({ acd => \@acd });
    if( ( $q->param('create') && $q->param('create') eq "new" ) ||
        ( $q->param('update') && $q->param('update') eq 'update') ) {
        #use DateTime;
        #my $now = DateTime->now();         # these three lines work but why bother?
        #my %create_data = ( as_date => $now);

        my %create_data = ( as_date => \'NOW()');   #this works, if the DB has the same time as the web server
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
            if($q->param($ak) ne ''){
                $create_data{"as_$ak"} = $q->param($ak);
            }
           }
        }
        #$warning = Dumper(%create_data);
        # Your mission is to combine the update and create into one simple and safe chunk of code.. go!
        if($q->param('update') && $q->param('update') eq 'update') {
            #$warning .= "This is still being written...";
            #$self->tt_params( headmsg => $warning );
            #my $rs = $self->resultset('Asset')->search({ as_id => $as_id, as_cid => $as_cid, })->first;
            #if(defined($rs) && $q->param('cid') && $rs->as_cid == $q->param('cid')){
            if(defined $as_id  && $as_cid){
                delete($create_data{as_date}); # this is the "created date" so we never updated it.
                $create_data{as_id} = $as_id;
                $create_data{as_cid} = $as_cid;
                #$create_data{as_id} = $rs->as_id;
                #$create_data{as_cid} = $rs->as_cid;
                my $comment = $self->resultset('Asset')->update_or_create( \%create_data );
                #warn "Asset " . $comment->id . " updated";
                $self->tt_params( headmsg => qq |<span class="warning">Asset updated.</span>
                    <a class="black" href='/cgi-bin/index.cgi/assets/data/$as_cid/$as_id/'>
                    <span class="message">You can add or edit data about this asset here</span></a>|);
            }else{
                $warning .= "Update failed... sorry. (Let your sysadmin know.)";
                $self->tt_params({headmsg => $warning});
                #warn Dumper($rs->as_id);
                warn "update of asset $as_id by " . $self->authen->username . " failed";
            }
        }else{
            my $comment = $self->resultset('Asset')->create( \%create_data );
            $comment->update;
            $as_id = $comment->id;
            #$warning = Dumper($comment);
            $self->tt_params( headmsg => qq |Asset added! <a class="black" 
                    href='/cgi-bin/index.cgi/assets/data/$as_cid/$as_id/'>
                    <span class="message">You can now add data about this asset</span></a>|);
        }
    } # end of "new" and "update"
    #else{warn Dumper($q);}

    my  @asc = ();
    if($as_id && $as_id=~m/^\d+$/){
      my $as_rs = $self->resultset('Asset')->search(
        { 'as_id' => { '=', "$as_id"}},
        {});

    # what is this all about? 
      while(my $l=$as_rs->next){
        my $as_acid = $l->as_acid;  
        my $as_owner = $l->as_owner;    
        my $as_user = $l->as_user;  
        my $as_adid = $l->as_adid;  
        my $as_grid = $l->as_grid;  
        my $as_notes = $l->as_notes;    
        unless(defined $as_notes){ $as_notes = ''; } 
        unless(defined $as_owner){ $as_owner = ''; } #pesky 'Use of uninitialized value $as_owner in string'
        #unless(defined $as_user){ $as_user = ''; }
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
      $self->tt_params({ title => 'Asset Details', submit => 'Update', update => 'update'});
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
        @acd = $self->resultset('AssetCatData')->search({ 'acd_cid' => "$as_cid"});
        $self->tt_params( title => 'Add Asset Details', acd => \@acd, submit => 'Add', create => 'new');
    }   
    my $ac_rs = $self->resultset('AssetCategory')->search(
                { 'asc_id' => { '=', "$as_cid"}},
                {});
    while(my $k=$ac_rs->next){
                #push(@asc, {type => $k->asc_name});
                my $name = $k->asc_name;
                $self->tt_params( type => $k->asc_name);
                $self->tt_params( id => $k->asc_id);
                if($name=~m/^[aeiouh]/){ $self->tt_params( ning => 'an'); }
    }
    my @ach = (
                {name=>'cid',value=>"$as_cid"}
                );

    unless(@acd){
        my $error = "&zwj;<br>";
        if($as_cid){
            @acd = $self->resultset('AssetCatData')->search({ 'acd_cid' => "$as_cid"});
        }else{
            @acd = $self->resultset('AssetCatData')->search();
        }
        if(@asc){ $self->tt_params({ acd => \@acd }); }
        unless(defined $as_id){ $as_id = 'That'; }
        $message =qq |<div><span class="error">$as_id</span> is /not/ a valid asset</div>|;
        $self->tt_params(
                title => 'Error - unknown asset',
                error => $error,
                message => $message);
        return $self->tt_process();
    }

    # NTS we need to add cat => @asc (things that this asset /could/ fit into)
    # NTS we need to add box => @containers (things that this asset /could/ fit into)
    # NTS we need accounts that this pe_id can assign assets to
    # NTS we need users => @users (array of people that this pe_id can set as users )
    # NTS we need owners => @owners (array of people that this pe_id can set as owners) 
    if($as_id){
        my @as = $self->resultset('Asset')->search({ 'as_id' => "$as_id"})->first;
        $self->tt_params({ asset => \@as });
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

  * Purpose - add/update the data to an asset
  * This is all about the asset_data table

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
        $acd_id = $self->param('id');
        #warn "$acd_id";
        if($self->resultset('Asset')->search({ 'as_cid' => "$acd_id" })->count == 1){
            my $find_asc =  $self->resultset('Asset')->search({ 'as_id' => "$as_id" })->first;
            # why do we have this?
            $acd_id = $find_asc->as_cid;
        }else{
            #if(my $asc_is = $self->resultset('AssetCategory')->search({ 'asc_id' => "$acd_id"})->first){
            if($self->resultset('AssetCategory')->search({ 'asc_id' => "$acd_id"})->first){
                # NTS you are here creating an "Add a new asset via the back door" function.
                #while(my $fasc=$find_asc->next){ $acd_id = $fasc->ac_cid; }
                #my $acd_cid = 0;
                #while(my $this_cid=$asc_is->next){ $acd_cid = $this_cid->ac_cid; }
                #$acd_cid = $asc_is->asc_id;
                #my @acd = ();
                #if($acd_cid && $acd_cid >= 1){
                    $message .= "New "; #well that seems a lot cleaner
                    #@acd = $self->resultset('AssetCatData')->search({ 'acd_cid' => "$acd_cid"});
                    #warn "Looks like we have a good Asset Cat but no asset";
                    #$self->tt_params({ acd => \@acd, message => 'New ' });
                #}
                #if(@acd){ 
                    #$self->tt_params({ asc => \@asc }); 
                    #$self->tt_params({ cid => $acd_cid }); 
                    #my $acd_name =  $acd[0]->acd_name;
                    #$message .= 'New ' . $acd_name ;
                    #$self->tt_params({ 
                    #    message => $message,
                    #    #no_data => '1',
                    #    });
                    #return $self->tt_process();
                #}else{
                #    # we had an invalid as_cid or the DB is borked
                #    $self->tt_params({ no_data => '1', message => "I don't seem to have that Asset Category on the books yet." });
                #    return $self->tt_process();
                #}
            }else{
                # give them a list of categories
                # NOTE not written yet
                $self->tt_params({ 
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
</script>',
                  page => 'You could 
<a class="small green button" href="/cgi-bin/index.cgi/assets/define">maybe defined it</a> or
<input class="small yellow button" type="button" value="try going back" onclick="goBack()" />
-<input class="small white button" type="button" value="or searching" onclick="goHome(\'/cgi-bin/index.cgi/assets\')" />',

                    message => "I don't seem to have that Asset Category on the books yet." });
                   # message => "What type of asset are you trying to add?" });
                return $self->tt_process();
            }
        }
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
        $message .=qq |<div><span class="error">$clean_acd_id</span> is _not_ a valid asset type</div>|;
        #$message .= Dumper($self);
        $self->tt_params( 
            title => 'Error - unknown asset type',
            error => $error,
            message => $message);
        return $self->tt_process();
    }

    if( ( $q->param('do') && $q->param('do') eq "Add to" ) ||
        ( $q->param('do') && $q->param('do') eq "create" ) ){
        #$message .= "What's going on here?";
         my %create_data = ( asd_date => \'NOW()');

         # If we don't find an asset then we just create one using the default of pe_id pe_acid
        
        if($q->param('sid')){
            $create_data{'asd_asid'} = $q->param('sid');
            warn "we know this asset! (suer-wheat) " . $q->param('sid');
        }else{
            # we need to quickly shim in a new asset
            my $ac_id = $self->param('pe_acid');
            unless(defined $ac_id && $ac_id=~m/^\d+$/){
                my $pe_id = $self->param('pe_id');
                # or should we use thier username?
                # we _really_ need to know their ac_id
                my $rs = $self->resultset('People')->search({ pe_id => "$pe_id" });
                my $user_details = $rs->first;
                $ac_id = $user_details->pe_acid;
            }
            my %new_asset = ( as_date => \'NOW()', as_cid => $q->param('id'), as_acid => $ac_id);
            #my $create = $self->resultset('Asset')->update_or_create( \%new_asset );
            my $create = $self->resultset('Asset')->create( \%new_asset );
            $create->update;
            my $as_id = $create->id;
            $create_data{'asd_asid'}  = $as_id;
        }
        ADD: foreach my $ak (keys %{ $q->{'param'} } ){
            if( $q->param($ak) ne '' && $ak=~m/^\d+$/){
                my %uoc = %create_data;
                $uoc{'asd_value'} = $q->param($ak);
                $uoc{'asd_cid'} = $ak;
                my $comment = $self->resultset('AssetData')->search( { asd_cid => $ak, asd_asid => $uoc{'asd_asid'} });
                #my $comment = $self->resultset('AssetData')->search( \%uoc ); #can't do this because it searches on date!
                if($comment){
                    delete($uoc{asd_date});
                }
                $comment->update_or_create( \%uoc );
            }
        }
        my $as_cid = $q->param('id'); my $as_id = $create_data{'asd_asid'};
            # NOTE fix this href using $surl = ($self->query->self_url);
        $self->tt_params( headmsg => qq |<a href="/cgi-bin/index.cgi/assets/list/$as_id/">
                <span class="warning">View New Asset</span></a> <a class="black" href='?'>&laquo;back</a>|);
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
            # you are preparing the update (key seems not to work)
            if(%create_data && %key){
                    # my %create_data = ({ as_date => \'NOW()'});   #NOTE or this
                    # my %create_data = ( as_date => \'NOW()');     #NOTE this might work
                    # $create_data{ as_date => \'NOW()'};     # this should work, (if your DB is in the same timezone as your webserver)
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
    # could loop through @asc looking or if we want something that is probably slower...
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
        if($asd{$ass} && $existing_value eq "$v"){ $asd{$ass} .=qq | selected="selected"|; }
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

=head3 search

  * This lets us search for an asset. 
  * It will have to be quite clever as there are lots of places where data could be stored:

select * from groups where gr_name like '%syca%';
select * from assets where as_notes like '%Roche%';
select * from asset_data where asd_value like '%wood%';

SELECT DISTINCT(as_id),as_cid,as_date,as_acid,as_owner,as_user,as_adid,as_grid,as_in_asid,as_notes 
 FROM assets JOIN asset_data asd ON assets.as_id=asd.asd_asid AND ( asd_value LIKE '%wood%' OR as_notes LIKE '%Roche%');

SELECT DISTINCT(as_id),as_cid,as_date,as_acid,as_owner,as_user,as_adid,as_grid,as_in_asid,as_notes
 FROM assets JOIN asset_data asd ON assets.as_id=asd.asd_asid JOIN groups gr ON gr.gr_id=asd.asd_asid AND asd_value LIKE '%syca%';

SELECT DISTINCT(as_id),as_cid,as_date,as_acid,as_owner,as_user,as_adid,as_grid,as_in_asid,as_notes FROM (
SELECT * FROM assets JOIN asset_data asd ON assets.as_id=asd.asd_asid JOIN groups gr ON gr.gr_id=asd.asd_asid AND asd_value LIKE '%syca%'
) me;

SELECT * FROM assets
JOIN asset_data asd ON assets.as_id=asd.asd_asid
#JOIN groups gr ON gr.gr_id=asd.asd_value
 AND ( 
    asd_value LIKE '%wood%' 
    OR as_notes like '%wood%' 
    #OR gr_name like '%syca%'
);

select * from asset_data where asd_asid = 31;
select * from asset_cat_data where acd_id = 30;
select * from groups where gr_id = 10;

  * we might be able to force &list into displaying the results for us

=cut

sub search: Runmode{
}

=head3 list

  * Purpose - list assets (or one asset) from the database
  * Expected parameters - are optional, but if there is one then it should be an as_id


=cut


sub list: Runmode{
    my ($self) = @_;
    my $message;
    my $as_id = $self->param('id')=~m/^\d+$/ ? $self->param('id') : '%';
    my (%Asset_search,%AssetData_search,%AssetCatData_search, %AssetCatData_search_orderby);
    #my $q = \%{ $self->query() }; # WORKS
    my $q = $self->query;
    if(defined($q->param('sid'))){ $self->param('sid' => $q->param('sid')); }
    if(defined($self->param('id')) && $self->param('id') eq 'cid' && $self->param('sid')=~m/^(\d+)$/){ 
        %AssetData_search = ('asd_cid' => { '=', "$1"});
        %AssetCatData_search =('acd_cid' => {'=', "$1"});
        %Asset_search =('as_cid' => {'=', "$1"});
        %AssetCatData_search_orderby=(order_by => 'acd_order');
    }

     my $rows_per_page =
        defined $q->param('rpp') && $q->param('rpp') && $q->param('rpp')=~m/^\d{1,3}$/ && $q->param('rpp') <= 100
      ? $q->param('rpp')
       : 10;

    my $page =
      defined $q->param('page') && $q->param('page') && $q->param('page')=~m/^\d+$/
      ? $q->param('page')
      : 1;

     # There must be a way to do these two searches with only one hit to the DB
    my $total_rows = $self->resultset('Asset')->search({ 'as_id' => { 'LIKE', "$as_id"}, %Asset_search })->count;
    $message .= $total_rows . " assets found in this account<br />";
     # Lets bypass pagination is the results are few
    if($total_rows <= $rows_per_page){ $page = 1; }
    my @assets = $self->resultset('Asset')->search({ 
                        'as_id' => { 'LIKE', "$as_id"}, %Asset_search
                    },{
                        join     => 'category',
                        page    => $page,
                        rows    => $rows_per_page,
                        #prefetch => 'category',
                    });

    if($total_rows > $rows_per_page){
        my $pagination = $self->_page($page,$rows_per_page,$total_rows);
        $message .= $pagination;
    }



    unless(@assets){
        $self->tt_params( title => 'Error - no such asset', message => "Can't seem to see that asset", error => '1');
        return $self->tt_process();
    }
    
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
# if we have a cid then pull what we DO know from the DB

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
    }elsif(defined $q->param('cid')){ 
        $cid = $q->param('cid');
    }elsif(defined $q->param('id')){ 
        $cid = $q->param('id');
    }else{
     #$message .= "id:".$self->param('id')  ."sid:". $self->param('sid'); 
    }
    if($cid=~m/^(\d+)$/){
        my %AssetCatData_search =('acd_cid' => {'=', "$1"});
        my %AssetCatData_search_orderby=(order_by => 'acd_order');
        my $ac = $self->resultset('AssetCategory')->search({ asc_id => {'=', $cid}}, {})->first;  #NOTE acs1n
        my @acd = $self->resultset('AssetCatData')->search( { %AssetCatData_search }, { %AssetCatData_search_orderby});

        if($q->param('id')){ #we might have new data or an update
            my $action = 'update';
            if( $q->param('delete') ){ $action = 'delete'; }

        # preparing the data for update or deleting
        
            $message .= "Looks like you are " . $action . "ing Asset Category " . $q->param('id') . "\n<br />";
            #$message .= Dumper($q->param);
            my $this_count=0;
            my %change;
            my %check;
            $message .= "\n<br />";
            foreach my $ak (keys %{ $q->{'param'} } ){
                my $v = $q->param($ak);
                my(@que) = (split/_/, $ak);
                if($que[0] eq 'd' ){ # && $que[(@que - 1)])=~m/^\d+$/){
                    $change{data}{$que[2]}{"acd_$que[1]"} = $q->param($ak);
                }else{
                    if($ak eq 'id'){
                        $check{asc_id} = $q->param($ak);
                    }elsif($ak ne 'update'){
                        $change{def}{"asc_$ak"} = $q->param($ak);
                    }
                }
                #$this_count++; $message .= "\n<br /> $this_count $ak = " . $q->param($ak);
            }
            #$message .= Dumper(\%change);

            my $ef_acid;
            my $username = $self->authen->username;
            if($self->param('ef_acid')){
                $ef_acid = $self->param('ef_acid');
                $message .= "effective acid = $ef_acid for $username" if $opt{debug}>=9
            }else{
                $message .= "we have no idea which acid $username is from";
            }

            #$change_domain{do_acid} = $ef_acid;
            my $sth = $self->resultset('AssetCategory')->search( \%check )->first;  #redundent? we have already made this call
                                                                                    # at acs1n (but with uglyer code)
            if(defined($sth) && defined($cid) && ($sth->asc_id eq $cid) ){
                # first we update the asset_category (if needed) before we move onto the asset_cat_data.
                if(!defined($change{def}{asc_name}) || $sth->asc_name ne $change{def}{asc_name} || #do we need to quote these?
                   !defined($change{def}{asc_description}) || $sth->asc_description ne $change{def}{asc_description} ||
                   !defined($change{def}{asc_grid}) ||  $sth->asc_grid ne $change{def}{asc_grid}
                    ){
                        my %c = %{ $change{def} };
                        $sth->update( \%c );
                        if($sth->is_changed()){
                           $message .= 'Update did not happen, sorry.';
                        }else{
                           $message .= 'Asset status updated';
                        }
                }else{ # debug
                       $message .= "<br />The definition for this asset category has not changed" if $opt{debug}>=5;
                } 

                # right! onto the main event
                if(defined($change{data})){
                    my %ch = %{ $change{data} }; 

         # we can't presume that the acd_id is ready as the HTML auto-increments and MAY CLASH with existing rows!!
         # N.B. we MUST check the acd_cid
                # we loop through $change{data} and see if there is anything with acd_id matching this AND acd_cid = $change{def}{asc_id}
            # check for blank lines (delete them from the database if they exist and from %change if they do not)
                    ASSET_DATA: foreach my $acdkey (keys %ch){
                        my $rs = $self->resultset('AssetCatData')->search({
                             #acd_cid => {'=', $change{def}{asc_id}},
                             acd_cid => {'=', $cid},
                             acd_id => {'=', $acdkey},
                            }, {})->first;
                        if(defined($rs) && $rs->acd_cid == $change{def}{asc_id}){
                             my %cha = %{ $ch{$acdkey} };
                             $cha{acd_id} = $acdkey;
                             # probably just need an update here
                             $rs = $self->resultset('AssetCatData')->update_or_create( \%cha );
                        }else{
                             my %new_data = %{ $ch{$acdkey} };
                             next ASSET_DATA unless $new_data{acd_name} ne ''; # don't want blank entries
                                #$new_data{acd_cid} = $change{def}{asc_id};
                                $new_data{acd_cid} = $cid;
                             $rs = $self->resultset('AssetCatData')->create( \%new_data )->update;
                        }
                        my $done = $rs->acd_id;
                        if($done=~m/^\d+$/){
                            $message .= "added data (" . $rs->acd_name .") $done to this asset $cid <br />\n";
                        }else{
                            $message .= Dumper($ch{$acdkey}) . " not added<br />\n";
                        }
                    }
##### debug to check that we have the data in the right order
#$self->tt_params({heading=>"Changed/updated the '".$ac->asc_name."' category", ac=>$ac,acd=>\@acd,message=>$message,page=>$page});
# return $self->tt_process(); exit;
##### end of debug

                }
            }else{
                $message .= "<br />cid = " . $cid . "<br />sth defined = " . defined($sth) . "<br /> and (" . $sth->asc_id . " eq " . $change{def}{asc_id} . ")";
            }
        # we could just update this with the data that we have, but, you know, XSS
        @acd = $self->resultset('AssetCatData')->search( { %AssetCatData_search }, { %AssetCatData_search_orderby});


            $self->tt_params({
            heading => "Changed the '" . $ac->asc_name . "' category",
            ac     => $ac,
            acd     => \@acd,
            message => $message,
            page => $page,
                  });
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
            return $self->tt_process();
        }
    }elsif(defined $q->param){
      if($q->param('name') eq ''){
            $message =qq |<span class="error">How about a name for this shiny new Asset Category of yours?</span>|;
      }else{
        $message .= "So you want to add " ;#. Dumper($q->param);

        # NOTE check that we don't already have that 
        # NOTE collect the data
        my $qp = $q->param;
        $message .= "\n<br />"; my $this_count=0;
        foreach my $ak (keys %{ $q->{'param'} } ){
                my $v = $q->param($ak);
                $this_count++; $message .= "\n<br /> $this_count $ak = " . $q->param($ak);
        }
        # NOTES insert the data
      }
    }
    #else we have a new category

    $self->tt_params({
    heading => 'Define a new type of Asset',
    message => $message,
    page => $page, #what? we are trying to keep the HTML out of the C and in the V!
          });
    return $self->tt_process();
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module, but be kind: This was me learning CGI::App 
for the first time, (hence the mess.)

I am fixing bugs and adding features. I will report them through GitHub.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

C<Alexx Roche>, <alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

