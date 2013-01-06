package Notice::C::Pages;

use warnings;
use strict;
use lib 'lib';
use base 'Notice';
my $mod_id = 28;
my %submenu = (
   '28' => [
       # '1' => { name=> 'List Pages', rm => 'list', class=> 'navigation'},
        '2' => { name=> 'Add Page', rm => 'edit', class=> 'navigation'},
        '3' => { name=> 'Templates', rm => 'template', class=> 'navigation'},
    ],
);
my (%opt,$surl);
my $base_url = '/';
$opt{D}=0;
use Data::Dumper;
my $dir_delim = '::'; # if a filename has this in it then we publish it in a sub-directory
                      # i.e.  contact::index would create contact/index.html
                      # NTS we need to implement this in sub view to match!

our $VERSION = 0.07;

=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

CMS system for Notice

=head1 DESCRIPTION

Pages stores pages of data in the database.
If that particular page has a template then the tags are parsed and use to build the page.
The default template is an HTML page. 
If there are <div> or <span> tags then their id and name are extracted and used to determin how
to populate and present the page. 

e.g. <div id="menu_ul"></div> we will collect all of the links from the pages table and order them
numerically based on the pt_order column.


We present the body of the page in http://ckeditor.com

(
 though you could use
 http://www.tinymce.com/
 or
 http://markitup.jaysalvat.com/examples/html/
 or a single textarea if you like that sort of thing.
)


If we have a direct request from a page that has not been published
 we return a 404 Page not found, even if the page has been written.

Each page includes the date when it was first written, last updated
and the percentage change from the last version.

When a page is published it is processed and written to the /var/www (or where ever you define)
as a flat file! This means that you can manage the site on a desktop and just ftp the flat files
to the webserve, (they can also be compressed for a smaller client-side cache.)

(As an asside, you can intigrate git to fully monitor version control and even recover older versions.)

=head4 N.B.

At this time Pages is global to the instilation and not available to each account. Any member of the
journalist group can add and edit pages.


=head4 TODO

main page:
    Show which pages are stubs
    Add a page delete button for editors
    Add an un-publish button for editors

editor:
    prune tags - right now that does not happen! (but you can delete them all and start again)

templates:
    Write and edit templates
    Set a template for a particular page

Display helpful "chmod 744 $www_path; chown $httpd_user $www_path"

=head4 CHALLENGES

deal with page rot - we need to be able to update all affected pages when needed
   maybe cron to re-publish any pages that have been published?

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(qr/!view|!site/);
    $surl = ($self->query->self_url);
    $surl =~s/\?.*$//; #strip any GET values
    $self->tt_params({ submenu => \%submenu });
}

=head2 TABLES

Pages - of the site
CREATE TABLE `Pages` (
  `pa_id` int(255) NOT NULL AUTO_INCREMENT,
  `pa_name` varchar(255) NOT NULL,
  `pa_title` varchar(255) DEFAULT NULL,
  `pa_link` varchar(255) DEFAULT NULL COMMENT 'How the link to this page from others will look',
  `pa_published` int(1) DEFAULT NULL COMMENT 'Is it live?',
  `pa_lang` char(6) DEFAULT NULL COMMENT 'en_GB fr zn',
  `pa_added` datetime DEFAULT NULL COMMENT 'date written or published',
  `pa_updated` datetime DEFAULT NULL COMMENT 'date updated',
  `pa_owner` int(255) DEFAULT NULL COMMENT 'peid',
  `pa_change` int(3) DEFAULT '0' COMMENT 'how different is this from the last version, as a percentage',
  `pa_ge` blob,
  PRIMARY KEY (`pa_id`),
  UNIQUE KEY `pa_id` (`pa_id`)
) ENGINE=MyISAM AUTO_INCREMENT=85 DEFAULT CHARSET=latin1 COMMENT='mostly html, but can be raw text'; 

Page tags - this enables a page to find all of the other pages that it should be liked to.

e.g. a page named About and Contact could have a tag footer and then any page with <div id="footer"></div>
will have a link to the About and Contact.

We have normailsed the Tags out of the Pages table so that Contact optionally can be in the header, menu and footer.

CREATE TABLE `PageTag` (
  `pt_id` int(255) NOT NULL AUTO_INCREMENT,
  `pt_paid` int(255) NOT NULL COMMENT 'Pages.pa_id',
  `pt_ag` varchar(255) DEFAULT NULL COMMENT 'page tag id="menu" name="footer"',
  `pt_order` int(255) unsigned NOT NULL COMMENT 'if there is a list this determins the order, smallest left/top largest right/bottom',
  PRIMARY KEY (`pt_id`),
  UNIQUE KEY `pt_id` (`pt_id`)
) ENGINE=MyISAM AUTO_INCREMENT=85 DEFAULT CHARSET=latin1 COMMENT='which tags to match';

=head2 RUN MODES

=head3 main

  * Purpose - get access to all of that useful and yummy data
  * Function- List (and paginate) through the pages of the site

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my $q = $self->query();
    my $message;
    if($self->authen->username){
        my $username = $self->authen->username;
        $self->tt_params({ username => $username});
    }else{
        $self->tt_params({ dest => 'Addendum', authen_login => 'main'});
    }
    $self->tt_params({
        page => 'Here you can mange the static part of the site - the public part. This is a CMS for Notice<br />'
		  });

    my $rows_per_page =
        defined $q->param('rpp') && $q->param('rpp') && $q->param('rpp')=~m/^\d{1,3}$/ && $q->param('rpp') <= 100
      ? $q->param('rpp')
       : 10;

    my $page =
      defined $q->param('page') && $q->param('page') && $q->param('page')=~m/^\d+$/
      ? $q->param('page')
      : 1;

    my %limits;# = ( join => 'AddendumReader' );
    my %search;# = ( -or => [  ud_owner => $pe_id, ur_reader => $pe_id ] );

    # There must be a way to do these two searches with only one hit to the DB
    my $total_rows = $self->resultset('Page')->search( \%search, \%limits )->count;
        # Lets bypass pagination if the results are few
    if($total_rows <= $rows_per_page){ $page = 1; }
    $limits{page} = $page;
    $limits{rows} = $rows_per_page;
    my @pages = $self->resultset('Page')->search( \%search, \%limits )->all;
    $message .= $total_rows . " Page(s) found in this account ";

    if($total_rows > $rows_per_page || defined $q->param('debug')){
        my $pagination = $self->_page($page,$rows_per_page,$total_rows);
        $self->tt_params({ pagination => $pagination });
    }
    if(@pages){
        $self->tt_params({ pages => \@pages, message => $message });
    }
    return $self->tt_process();
    #return $self->tt_process('default.tmpl');
    
}

=head3 stats

  * Purpose - none
  * why?    - left over from starting from another module

=cut

sub stats: Runmode {
    my ($self) = @_;
    if($self->authen->username){
        my $username = $self->authen->username;
        $self->tt_params({ username => $username});
    }else{
        $self->tt_params({ dest => 'Pages', authen_login => 'main'});
    }
    $self->tt_params({
    message => 'Welcome to Notice::Pages!',
    body => '<br />We probably do not want this modules, but we can clean that up later'
    });
    #return $self->tt_process();
    return $self->tt_process('default.tmpl');
}


=head3 edit

add a document or book

This will add the document to the master list if it does not exist
and will add it to your personal list as well.

=cut

sub edit: Runmode {
    my ($self) = @_;
    my $pa_id;

    my $username;
    if($self->authen->username){
        $username = $self->authen->username;
        $self->tt_params({ username => $username});
    }
    #$self->tt_params({ message => 'Add a book or document, (or even a web page)' });
    my $q = $self->query();
    if($q->param('id') && $q->param('id')=~m/^(\d+)$/ ){
            $pa_id = $1;
    }elsif($self->param('id') && $self->param('id')=~m/^(\d+)$/ ){
            $pa_id = $1;
    }elsif($self->param('sid') && $self->param('sid')=~m/^(\d+)$/){
            $pa_id = $1;
    }

    my $is_an_admin=0;

    # the only people that can publish
    #if( $self->in_group('Editor',"$username",1) ){  # this works but only because we have overloaded in_group
    if( ! $is_an_admin && $self->in_group('Editor',$self->param('pe_id')) ){ 
      #warn "in_group said yes";
        $is_an_admin=1;
    }
    if($is_an_admin){
        $self->tt_params({ admin => 1 });
    }


    if( ( $q->param('update') && ( 
                    $q->param('update') eq "Add" || 
                    $q->param('update') eq "Save" || 
                    $q->param('update') eq "Update"
                    ) 
        ) || ( $is_an_admin && $q->param('publish') && $q->param('publish') eq "Publish" )
    ) {
        use DateTime qw /now/;
        my $now = DateTime->now();         # these three lines work but why bother?
        my %create_data = ( pa_updated => $now);
        my @create_tags;
        #my %create_data = ( ud_added => \'NOW()');   #this works, if the DB has the same time as the web server
        foreach my $ak (keys %{ $q->{'param'} } ){
          # might be better to pull this from an array, but there must be a
          # better DBIx::Class way to know which collums we are looking for
          if(
            $ak eq 'link' ||
            $ak eq 'name' ||
            $ak eq 'title'
           ){
                if($q->param($ak) ne ''){
                    $create_data{"pa_$ak"} = $q->param($ak);
                }
           }elsif(
            $ak eq 'editor1'
           ){
                if($q->param($ak) ne ''){
                    $create_data{"pa_ge"} = $q->param($ak);
                }
           # we should not need this check
           #}elsif($ak ne 'tags' && $ak ne 'update' && $ak ne 'id'){
           #  warn "Notice::C::Pages - something is up $ak: " . $q->param($ak);
           }
        }
        if( $self->param('pe_id') ){
                $create_data{'pa_owner'} = $self->param('pe_id');
        }elsif( $self->session->param('pe_id') ){
                $create_data{'pa_owner'} = $self->session->param('pe_id')
        }
        #$self->tt_params({ body => Dumper(\%create_data) });
        # NOTE how do we split long pages into seperate pages and let readers paginate through them, 
        #       AND give them the option to view it as one long page?
        if(%create_data){
            # check to see if we have this
            my $rc = $self->resultset('Page')->search({
                   -or => [
                         pa_id => $pa_id,
                         pa_name => $create_data{'pa_name'} #can't have two pages with the same name
                    ]
                })->first;
            if($rc){

                my $tags;
                my $trc;
                if($pa_id && $pa_id=~m/^\d+$/){
                    $trc = $self->resultset('PageTag')->search({ pt_paid => $pa_id });
                    TAG: while( my $t = $trc->next){
                        if($t->pt_ag){
                            $tags .= $t->pt_ag;
                            if($t->pt_order || $t->pt_inc){
                                  $tags .= ',';
                                  $tags .= $t->pt_inc ? 'inc' : '';
                                  $tags .= $t->pt_order if $t->pt_order;
                            }
                            $tags .= '; ';
                        }
                    }   
                 } # Now we know what the tags where (if there were any)

                # Check that a change has been made .. wow this might be too much heavy lifting
                # especially as they may have only changed the order in one tag - so why compare the whole page?

                if( ( $create_data{'pa_ge'} && $create_data{'pa_ge'} ne $rc->pa_ge ) ||
                    ( $create_data{'pa_title'} && $create_data{'pa_title'} ne $rc->pa_title ) ||
                    ( $create_data{'pa_name'} && $create_data{'pa_name'} ne $rc->pa_name ) ||
                    ( $create_data{'pa_link'} && $create_data{'pa_link'} ne $rc->pa_link )
                     ){
                    # NOTE Calculate the percentage change from the last version
                    $rc->update( \%create_data );
                    $self->tt_params({ message => '<a class="black" href="' . $surl . '/' . $pa_id . '">Page saved</a>' });
                }elsif( ( $q->param('tags') && $q->param('tags') eq "$tags" ) || ( ! $tags && ! defined $q->param('tags') )  ){
                    $self->tt_params({ error => 'Page already saved' }) unless $q->param('publish') eq 'Publish';
                }
                # This can be independent of the Pages table (though we should probably touch Pages.pa_updated WHERE pa_id = $pa_id)
                if($q->param('tags') ne $tags ){
                     if($pa_id && $q->param('tags') ne ''){
                        my $tag_string = $q->param('tags');
                        $tag_string =~s/\n//g;
                        $tag_string =~s/;\s*/;/g;
                        #warn "We have a tag string of: " . Dumper($tag_string);
                        my @tags = split(/;/, $tag_string);
                        foreach my $tag_couplet (@tags){
                            my ($tag,$order) = split(/,/, $tag_couplet);
                           # push @create_tags, {pt_paid => $pa_id, pt_added => $now, pt_ag => "$tag", pt_order => "$order"};
                            my %tag_data = ( pt_paid => $pa_id, pt_ag => "$tag");
                            if($order){
                                $tag_data{'pt_order'} = $order;
                                if($order=~m/\D/){
                                    $tag_data{'pt_inc'} = 1;
                                    $tag_data{'pt_order'}=~s/\D//g;
                                    #warn ".. so order is really " . $tag_data{'pt_order'} . " and inc is " . $tag_data{'pt_inc'};
                                }
                             }else{
                                $tag_data{'pt_inc'} = 0;
                                $tag_data{'pt_order'} = 0;
                             }

                            # search to know if this is an update or a create
                            my $tag_rc = $self->resultset('PageTag')->search({
                               -and => [
                                     pt_paid => "$pa_id",
                                     pt_ag => "$tag_data{'pt_ag'}" #can't have two tags with the same name for a page
                                ]
                            })->first;

                            if($tag_rc){ # update the tags
                                    $tag_rc->update( \%tag_data );
                            }else{
                                my $pt_id = $self->resultset('PageTag')->create(
                                \%tag_data
                                #{pt_paid => $pa_id, pt_ag => "$tag", pt_order => "$order"}
                                )->update;
                                #my $pt_id = $self->resultset('PageTags')->create( \@create_tags )->update->id;
                            }
                        }
                        # NTS now we need to remove any tags that have not been looped through
                        # but to do that we need to have a list of pt_id and removed from it the ones that have been updated
                        
                    $self->tt_params({ message => '<a class="black" href="' . $surl . '/' . $pa_id . '">Tags Updated</a>' });
                    }else{
                        # delete all of the tags
                        #while( my $t = $trc->next){ $t->delete; }
                        $trc->delete;
                        $self->tt_params({ message => '<a class="black" href="' . $surl . '/' . $pa_id . '">Tags removed</a>' });
                    }
                }
                
            }else{ # create new page!
                # add this to the list of docs
                $create_data{'pa_added'} = $now;
                $pa_id = $self->resultset('Page')->create( \%create_data )->update->id;
                $surl=~s/edit.*/view/;
                $self->tt_params({ message => '<a class="blue" href="' . $surl . '/' . $pa_id . '">Page added!</a>' });
                if($pa_id && $q->param('tags') ne ''){
                    my $tag_string = $q->param('tags');
                    $tag_string =~s/\n//g;
                    $tag_string =~s/;\s*//g;
                    my @tags = split(/;/, $tag_string);
                    foreach my $tag_couplet (@tags){
                        my ($tag,$order) = split(/,/, $tag_couplet);
                       # push @create_tags, {pt_paid => $pa_id, pt_added => $now, pt_ag => "$tag", pt_order => "$order"};
                        my %tag_data = ( pt_paid => $pa_id, pt_ag => "$tag", pt_order => "$order");
                        if($order=~m/\D/){
                            $tag_data{'pt_inc'} = 1;
                            $tag_data{'pt_order'}=~s/\D//g;
                         }
                            
                        my $pt_id = $self->resultset('PageTag')->create( 
                        \%tag_data
                        #{pt_paid => $pa_id, pt_ag => "$tag", pt_order => "$order"}
                        )->update;
                        #my $pt_id = $self->resultset('PageTags')->create( \@create_tags )->update->id;
                    }
                }elsif( $q->param('tags') ne ''){
                   warn "We don't have the page ID for these tags!";
                }
            }
        }
    } # /add/update/publish
    elsif( $q->param('publish') ){ # but they are not an admin
                $self->tt_params({ message => 'I can\'t let you do that Dave', error => 'You are NOT an Editor'});
    }  
    elsif( %{ $q->{'param'} } ){
        warn join(', ', keys %{ $q->{'param'} });
        warn $q->param('update');
    }

    # here we do the actual publishing (if they are an Editor )
    if( $is_an_admin && $q->param('publish') && $q->param('publish') eq "Publish"){
       $opt{publishing} = 1;
       my $www_path = '';
        if(defined $self->cfg('www_path')){
            if( ref($self->cfg('www_path')) eq 'ARRAY'){ # not sure why we would have an array
                PATH_SEARCH: foreach my $wpath (@{ $self->cfg('www_path') }){
                        $www_path = $wpath; # I'm just using the first one
                        last PATH_SEARCH;
                        # maybe you want to store the path split into an array, for some reason
                        $www_path .= '/' . $wpath;
                }
            }elsif( $self->cfg('www_path') ne ''){
                    $www_path = $self->cfg('www_path');
            }
            #else{ $www_path = '/var/www/html'; } # not sure this is a good idea
        }else{
            $www_path = '/var/www/htdoc/site';
        }
        my $filename; # lets build it
        $filename = $q->param('name') ? $q->param('name') . '.html' : 'index.html';
        $filename =~s/\s+/ /g;
        $filename =~s/ /_/g;


        my $html_path;
        if($filename=~m/$dir_delim/){
            my @full_path = split (/$dir_delim/, $filename);
            $html_path .= join('\/', @full_path);
            $www_path .= $html_path;
            $filename = $full_path[ @full_path -1 ];
            $www_path=~s/\/?$filename\/?$//;
        }

        # we know where, so check that it exists and that we can write to it
        if( ( -d "$www_path" ) && ( ( -e "$www_path/$filename" && -w "$www_path/$filename" ) || ( -w "$www_path") ) ){
            # NTS YOU ARE HERE
            my $page_html = $self->view;
            open(HTML,">$www_path/$filename") or do { $self->tt_params({ error => 'failed to open file' }); return $self->tt_process(); };
            print HTML $page_html;
            close(HTML);
            $self->tt_params({ message => 'Page ' . $filename . ' published <a href="' . $html_path . '/' . $filename . '"><span class="warning">LIVE</span> to ' . $filename . '</a>'});
        }else{
            my $message = 'We seem to have a write premission problem - no right ';
            if( ! -d "$www_path" ){
                $message .= "to write to dir $www_path";
            }
            if( ! -w "$www_path/$filename" ){
                $message .= " to file $filename";
            }
            $self->tt_params({ message => $message });
        } 

    } 

    #return $self->tt_process();

    if($pa_id && $pa_id=~m/^\d+$/){
        my $page = $self->resultset('Page')->search({ pa_id => $pa_id })->first;
        $self->tt_params({ p => $page });
        if($page){
            my $tags;
            my $trc = $self->resultset('PageTag')->search({ pt_paid => $pa_id });
            TAG: while( my $t = $trc->next){
                if($t->pt_ag){
                    $tags .= $t->pt_ag;
                    if($t->pt_order || $t->pt_inc){
                          $tags .= ',';
                          $tags .= $t->pt_inc ? 'inc' : '';
                          $tags .= $t->pt_order if $t->pt_order;
                    }
                    $tags .= '; ';
                }
            }
            if($tags){ $tags=~s/;$//; }
            $self->tt_params({ tags => $tags });
        }
    }
    $self->tt_params({ man => "Use $dir_delim to create sub-directories, i.e. Name: [ contact::index ] will create contact/index.html when published" });
    return $self->tt_process();
}

=head3 _list

list the pages

=cut

sub _list: Runmode {
    my ($self) = @_;
    my ($pe_id,$udid,$message);
    my $q = $self->query;
    if( $self->param('pe_id') ){
        $pe_id = $self->param('pe_id');
    }elsif( $self->session->param('pe_id') ){
        $pe_id = $self->session->param('pe_id')
    }
    if( $self->param('id') ){
        $udid = $self->param('id');
    }elsif( $self->session->param('id') ){
        $udid = $self->session->param('id')
    }
    if($udid && $udid=~m/^\d+$/){
        my %search = ( ud_id => $udid );
        my $doc = $self->resultset('AddendumDoc')->search( \%search )->first;
        $self->tt_params({ doc => $doc });

        %search = (  -and => [ um_udid => $udid, um_reader => $pe_id ] );
        my @errata = $self->resultset('AddendumErrata')->search( \%search );
        $self->tt_params({ errata => \@errata });
        return $self->tt_process('Notice/C/Addendum/errata.tmpl');
    }

    my $rows_per_page =
        defined $q->param('rpp') && $q->param('rpp') && $q->param('rpp')=~m/^\d{1,3}$/ && $q->param('rpp') <= 100
      ? $q->param('rpp')
       : 10;

    my $page =
      defined $q->param('page') && $q->param('page') && $q->param('page')=~m/^\d+$/
      ? $q->param('page')
      : 1;

    my %limits = ( join => 'AddendumReader' );
    my %search = ( -or => [  ud_owner => $pe_id, ur_reader => $pe_id ] );

    # There must be a way to do these two searches with only one hit to the DB
    my $total_rows = $self->resultset('AddendumDoc')->search( \%search, \%limits )->count;
        # Lets bypass pagination if the results are few
    if($total_rows <= $rows_per_page){ $page = 1; }
    $limits{page} = $page;
    $limits{rows} = $rows_per_page;
    my @pages = $self->resultset('Page')->search( \%search, \%limits );
    $message .= $total_rows . " documents found in this account ";

    if($total_rows > $rows_per_page || defined $q->param('debug')){
        my $pagination = $self->_page($page,$rows_per_page,$total_rows);
        $self->tt_params({ pagination => $pagination });
    }

    $self->tt_params({ message => $message });
    $self->tt_params({ docs => \@pages });
    return $self->tt_process();
}

=head3 view

view a page - this should only be used for review, (though it _is_ up to you.)
The idea is that the output of view will be written as a static file.

=cut

sub view: Runmode {
    my ($self) = @_;
    my $q = $self->query();
    my $pa_id;
    if($self->param('id') && $self->param('id')=~m/^(\d+)$/ ){
        $pa_id = $1;
    }elsif($self->param('sid') && $self->param('sid')=~m/^(\d+)$/){
        $pa_id = $1;
    }

  # the default is to have a blank template, but each page can have its own template.


    # look for a default template
    my $base_path = 'templates';
    my $default_tempalte_file = 'pages.html';

    if (-e "$base_path/$default_tempalte_file"){

        my $template;
        open(TEMPLATE, "<$base_path/$default_tempalte_file");
        while(<TEMPLATE>){
            $template .= $_;
        }
        close(TEMPLATE); # as it is READ ONLY at this location!



        if($pa_id && $pa_id=~m/^\d+$/){
        # Now we collect the actual page that we are looking for from the database
            my $page = $self->resultset('Page')->search({ pa_id => $pa_id })->first;
            if($page && $page->pa_ge){
                my $stub;
                my $trc = $self->resultset('PageTag')->search({ pt_paid => $pa_id });
                TAG: while( my $t = $trc->next){
                    if($t->pt_inc){
                        $stub = $t->pt_inc;
                    }
                }
                if($stub){ # This is to be included in other pages as a whole section 
                    $template = $page->pa_ge; # so we show what that stub might look like
                }else{
                    my $page_data = $page->pa_ge;
                    if($template){
        # Now we need to extract all of the tags and their id,name and classes

                    use HTML::TreeBuilder::XPath;
                    my $tree = HTML::TreeBuilder::XPath->new;
                    # soon we are going to have the option of a custom template per page
                    if (-e "$base_path/$default_tempalte_file"){
                        $tree->parse_file("$base_path/$default_tempalte_file");
                    }else{
                        $tree->parse_content("$template");
                    }

                    { no warnings; 
                      #no strict "refs";
                      
                    # With the power of HTML::TreeBuilder we could probably do all of this
                    # with just one look_down, and if your perlfu is that good... show me.

                    my (@id,@nm,@class,@markers);

                    #@id = $tree->look_down(sub{ $_[0]->attr('id') } );
                    @id = $tree->look_down('id' => qr/.+/); # this seems to be faster than the previous
                   if(1==0){ # I'm only using IDs right now
                    @nm = $tree->look_down(sub{ $_[0]->attr('name') } );
                    @class = $tree->look_down(sub{ $_[0]->attr('class') } ); #do we really want to match on classes?
                    #@class = $tree->look_down(sub{ $_[0]->attr('class') ne ''} ); # or excessive conditionals?
                    @markers = $tree->look_down(sub{ $_[0]->attr('id') ne '' || $_[0]->attr('name') ne '' || $_[0]->attr('class') ne '' } );
                   }

                    $page_data .= "<table><tr>" if $opt{D}>=10;
                    $page_data .= "<td><br />IDs: " if $opt{D}>=10;
                    #$page_data .= '<br />&nbsp; &nbsp; ' . $_->tag . ': ' . $_->attr('id'), "\n" foreach(@id);
                     $surl=~s/view\/\d*.*$/view/;
                     DIV: foreach my $id (@id){
                        $page_data .= '<br />&nbsp; &nbsp; ' . $id->tag . ': ' . $id->attr('id'), "\n" if $opt{D}>=10;
        # Now we use the tag data to know which links to collect from the database
                            my $tgrc = $self->resultset('PageTag')->search({ pt_ag => $id->attr('id') },{ order_by => {-asc => 'pt_order'} });
                            TAGGED: while( my $t = $tgrc->next){
                                my $content;
                                if($t->pt_inc && $t->pt_paid){
        # Now we use the tag data to collect from the database the pages that we need
                                    # then we need the whole Page.pa_ge
                                    my $rc = $self->resultset('Page')->search({
                                             pa_id => $t->pt_paid,
                                    },{ 'columns' => ['pa_ge'] })->first;
                                    $content .= $rc->pa_ge;
                                }elsif($t->pt_paid){
                                    # we just need the link and the page name (though the name is only really needed for publishing)
                                    my $rc = $self->resultset('Page')->search({
                                             pa_id => $t->pt_paid,
                                    },{ 'columns' => ['pa_name','pa_link'] })->first;
                                    if($opt{publishing}){
                                        $content .= '<a href="' . $base_url . '/' . $rc->pa_name . '.html">' . $rc->pa_link . '</a>';
                                    }else{
                                        $content .= '<a href="' . $surl . '/' . $t->pt_paid . '">' . $rc->pa_link . '</a>';
                                    }
                                }

                                if( $id->tag eq 'ul' ){
                                  unless($content){
                                      # warn $id->tag . ': ' . $id->attr('id'), " - has no content\n";
                                       next TAGGED; # or rather ID
                                       #next DIV; # or rather ID
                                  }
                                    $content=~s/\<\/?p\>//g;  # this is because our WYSIWYG editor adds <p> to _everything_
                                    # then we create an HTML::Element of <li> and add it
                                    #$content= '<li>' . $content . '</li>';
                                    #my $new_data = HTML::Element->new('~literal', 'text' => "$content");
                                    my $active;
                                    if($t->pt_paid && ( $t->pt_paid == $pa_id ) ){ # if this entry IS the active one 
                                        $active = ' class="active"';
                                    }
                                    my $new_data = HTML::Element->new('~literal', 'text' => '<li' . $active . '>' . $content . '</li>');
                                    #$new_data->push_content([q{li}, $content]);
                                    ##  warn Dumper($new_data);
                                    $id->insert_element($new_data);
                                }elsif( $id->tag eq 'span' ){
                                    $content=~s/\<\/?p\>//g;  # this is because our WYSIWYG editor adds <p> to _everything_
                                    my $new_data = HTML::Element->new('~literal', 'text' => "$content");
                                    #warn Dumper($new_data);
                                    $id->push_content($new_data);
                                }else{
                                    #$id->push_content('COPYRIGHT Alexx Roche 2012-2013');
                                    my $new_data = HTML::Element->new('~literal', 'text' => "$content");
                                    #warn Dumper($new_data);
                                    #$id->unshift_content($new_data);
                                    $id->insert_element($new_data);
                                }

                            }

                    }
                    $page_data .= "</td><td>" if $opt{D}>=10;
                 if(1==0){
                    $page_data .= "<br />Names: " if $opt{D}>=10;
                    $page_data .= '<br />&nbsp; &nbsp; ' . $_->tag . ': ' . $_->attr('name'), "\n" foreach(@nm);
                    $page_data .= "</td><td>" if $opt{D}>=10;
                    $page_data .= "<br />classes: " if $opt{D}>=10;
                    $page_data .= '<br />&nbsp; &nbsp; ' . $_->tag . ': ' . $_->attr('class') . "\n" foreach(@class);
                    $page_data .= "</td><td>" if $opt{D}>=10;
                    $page_data .= "<br />Markers: " if $opt{D}>=10;
                    $page_data .= '<br />&nbsp; &nbsp; ' . $_->tag . ': ' . $_->attr('id') . $_->attr('name') . $_->attr('class') . "\n" foreach(@markers);
                  }
                    $page_data .= "</td></tr></table>" if $opt{D}>=10;
                    }

                    my $this_title = '';
                    if($page && $page->pa_title){
                        $this_title = $page->pa_title;
                    }elsif($page && $page->pa_name){
                        $this_title = $page->pa_name;
                    }elsif($page && $page->pa_link){
                        $this_title = $page->pa_link;
                    }
                    my $page_title = HTML::Element->new('~literal', 'text' => "$this_title");
                    my $title = $tree->look_down( sub { $_[0]->tag() eq 'title'});
                    $title->push_content($page_title);
                    #$title->replace_with_content($page_title); # Not what we need here

                    my $page_body = HTML::Element->new('~literal', 'text' => "$page_data");
                    my $span = $tree->look_down('id' => 'page');
                    $span->push_content($page_body);

                use DateTime qw /now/;
                my $now = DateTime->now();         # these three lines work but why bother?
                my $pub_date = $now->ymd . ' ' . $now->hms;

                my $published  = HTML::Element->new('~literal', 'text' => " Published: $pub_date");
                my $cpyrtd  = HTML::Element->new('~literal', 'text' => $now->year);

                my $copyright_date = $tree->look_down('id' => qr/^copyright$/);
                    $copyright_date->push_content($cpyrtd);
                if($opt{publishing}){
                    $tree->look_down('id' => qr/^foot(er)?$/)->look_down( 
                        sub { $_[0]->attr('class') eq 'container' })->push_content($published);
                }else{
                    #$tree->look_down('id' => qr/^foot(er)?$/)->look_down(
                    #    sub { $_[0]->attr('class') eq 'container' })->push_content($published);

                    # We should let them know that this is just a preview, (though you don't have to if you want a dynamic CMS).

                        my $this_css = qq | #preview { position: absolute; left: 0; top: 0; display: block; height: 125px; width: 125px; background: url(/images/TLpreview.png) no-repeat; text-indent: -999em; z-index: 1031; text-decoration: none;} |;

                    my $back_css = HTML::Element->new('~literal', 'text' => "$this_css");
                    my $style = $tree->look_down( sub { $_[0]->tag() eq 'style'});
                    if(!$style || $style->is_empty){
                        $style = $tree->find('head');
                        $style->push_content($back_css);
                    }else{
                        $style->push_content($back_css);
                    }

                    my $back_url = $surl;
                    $back_url=~s/Pages.*/Pages/;
                    my $this_back = q{<a id="preview" href="} . $back_url . q{" title="Click to return">Close Preview</a>};
                    my $back_div = HTML::Element->new('~literal', 'text' => "$this_back");
                    my $back = $tree->find('body');
                    $back->unshift_content($back_div);

                    # Add the page load time

                    my $plt_html = HTML::Element->new('~literal', 'text' => '<span class="pageLoadTime">(Took ' . $self->plt . ' ms)</span>');
                    my $foot_div = $tree->look_down('id' => 'footer');
                    $foot_div->push_content($plt_html); #WORKS
                    #$foot_div->unshift_content($plt_html); #WORKS
                    #$foot_div->insert_element($plt_html); # WORKS
                }

        # Now we create the page from the template and the data
                    
                    $template = $tree->as_HTML;
                    
                    if($opt{publishing}){
                        return $template;
                    }

                    $tree->delete; #for the RAM!
                    $tree->destroy; #for the RAM!

                        #$template=~s/\<page \/\>/$page_data/;
                    }else{
                        $template= $page_data;
                    }
                }
            }else{
                $surl=~s/Pages.*/Pages/;
                $self->tt_params({ error => '<span class="error">404 Page Not found</span>' });
                $self->tt_params({ content => '<br /><br /><a class="blue button" href="' . $surl . '">Return to Notice</a>' });
                return $self->tt_process('error.tmpl');
                $template=~s/\<page \/\>/YOUR PAGE HERE, once we find it/;
            }
        }


        $self->tt_params({ page => $template });
    }elsif($pa_id=~m/^\d+$/){
        warn "$base_path/$default_tempalte_file not  found";
        my $this_css = qq | #preview { position: absolute; left: 0; top: 0; display: block; height: 125px; width: 125px; background: url(/images/TLpreview.png) no-repeat; text-indent: -999em; z-index: 1031; text-decoration: none;} |;
        $self->tt_params({ css => $this_css });

        my $back_url = $surl;
        $back_url=~s/Pages.*/Pages/;
        my $this_back = q{<a id="preview" href="} . $back_url . q{" title="Click to return">Close Preview</a>};
        $self->tt_params({ body => $this_back });

        my $page = $self->resultset('Page')->search({ pa_id => $pa_id })->first;
        $self->tt_params({ p => $page });
    }

    return $self->tt_process();
}

=head3 site

    forward to view
=cut

sub site: Runmode {
    my ($self) = @_;
    return $self->forward('view');
}


=head3 preview

    forward to view

=cut

sub preview: Runmode {
    my ($self) = @_;
    return $self->forward('view');
}

=head3 templates

    a list of temples 

=cut

sub template: Runmode {
    my ($self) = @_;
    #return $self->tt_process('');
    return 'This will be a template creation/editing page<br />(Took ' . $self->plt . ' ms)';
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

Copyright (C) 2013 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

