package Notice::C::Account;

use warnings;
use strict;
use Exporter;
my @ISA=('Exporter','Notice::C');
my @EXPORT=();
my @EXPORT_OK = qw( _name_to_child _to_path );
use lib 'lib'; #DEBUG
use base 'Notice';
use Data::Dumper;
our %opt;

our $VERSION = 0.04;

my %submenu = (
   '1.4.1' => [
        '1' => { name=> 'Tree', rm => 'tree', class=> 'navigation'},
        '2' => { name=> 'List', rm => 'list', class=> 'navigation'},
    ],
);


=head1 NAME

Template controller subclass for Notice

=head1 ABSTRACT

Template for consistent controller creation.

=head1 DESCRIPTION

Provide an overview of functionality and purpose of
web application controller here.

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

  * Defauly runmode
  * Expects the user's effective account ID (ef_acid)
  -  and will collect or deduce their real account ID (pe_acid)

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my ($message,$body,%opt,$who_rs);
    my $test='';
    my $username = $self->authen->username;
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);

    # We might be comming from the delete function so lets catch their message

    if(defined $self->session->param('message')){
        $self->tt_params({message => $self->session->param('message') });
        $self->session->param('message' => '');
    }
    if(defined $self->session->param('error')){
        $self->tt_params({error => $self->session->param('error') });
        $self->session->param('error' => '');
    }

    our $pe_id;
    our $ud_rs;
    our $ac_id;
    $ac_id = $self->_acid;
    #$ac_id = _acid($self);
    unless($ac_id=~m/^\d+$/ && $ac_id>=1){
        if($self->param('id') && $self->param('id')=~m/^\d+$/){
            our $who_id = $self->param('id');
            $who_rs = $self->resultset('People')->search({pe_id => $who_id})->first;
        }else{
            $who_rs = $ud_rs;
        }
        warn "BAAAAAAAAAAAAAAD";
        eval {
            $ac_id = $who_rs->pe_acid;
        };
    }
    my $ef_acid = $ac_id;
    if(defined $self->param('ef_acid')){ $ef_acid = $self->param('ef_acid'); }
    elsif(defined $self->session->param('ef_acid')){ $ef_acid = $self->session->param('ef_acid'); }

    #if($q->param('Change') eq 'Change Account'){
    if($q->param('Change')){
        my $new_ac = $q->param('set_acid');
        #warn Dumper($new_ac);
        if($q->param('Change') eq 'back'){
            $self->param('ef_acid' => $ac_id);
            $self->tt_params('ef_acid' => $ac_id);
            $self->session->param('ef_acid' => $ac_id);
        }elsif($new_ac=~m/^\d+$/){
            $self->param('ef_acid' => $new_ac);
            $self->tt_params({ ef_acid => $new_ac });
            $self->session->param('ef_acid' => $new_ac);
            $self->tt_params({ change => 'Back to your account' }) unless($ac_id == $new_ac);
            $ef_acid = $new_ac;
        }
        #$pe_id = 1;
    }elsif($q->param('add')){
        warn "We are adding an account!";
        #$test .= \%{ $q->{'param'} };
        $test = "Added a " . $q->param('what') . " account to " . $ef_acid . " called '" . $q->param('ac_name') . "'";
        ##warn keys %{ $q->{'param'} };
        #warn join(', ', keys %{ $q->{'param'} }); #useful debug

        $self->param('ac_parent' => $ef_acid);
        $self->param('ac_name' => $q->param('ac_name'));
        my $ac_tree;
        my $new_ac;
        # Other modules can...
        #use Notice::C::Account;
        #($new_ac,$ac_tree) = Notice::C::Account::_new_child($self);
        ($new_ac,$ac_tree) = _new_child($self);
        warn "New account created: " . $new_ac . ' with tree:' . $ac_tree;
        $test .= " - added account $new_ac, with tree: $ac_tree" if $new_ac =~m/^\d+$/;
    }else{
        #$test = 'Query: ' .  keys %{ $q->{'param'} } if $opt{D}>=1;
        if($q->param('back')){
    warn "Going back";
            $self->param('pe_acid' => $ac_id);
            $self->param('ef_acid' => $ac_id);
            $ef_acid = $ac_id;
            $self->session->param('ef_acid' => $ac_id);
            $self->tt_params({ ef_acid => $ef_acid });
        }else{
    warn "Going forward?";
            #warn keys %{ $q->{'param'} };
            if($self->param('ef_peid')){ $pe_id = $self->param('ef_peid'); }
            elsif($self->param('pe_id')){ $pe_id = $self->param('pe_id'); }
        }
    }
    
    $self->tt_params({ 
            ef_acid => $ef_acid,
            ac_id => $ac_id
    });
    #warn " ef_acid => $ef_acid, ac_id => $ac_id";

=pod

    $test = "You are in";
    if($self->param('ef_acid') == $self->param('ac_tree')){
        $test .= ' (your own) ';
    }
    $test .= " account: " . $self->param('ef_acid');
    unless($self->param('ef_acid') == $ac_id){
        $test .= " Your account is: " . $ac_id;
    }

=cut

    unless($self->param('ac_tree')){
        $self->param('ac_tree' => $self->session->param('ac_tree'));
    }

    my @accounts = $self->resultset('Account')->search({
        -or => [
        'ac_id' => $ac_id,
        'ac_useradd' => { '>', '0' },
        ],
        },{ 'columns'   => ['ac_id','ac_name'], order_by => {-asc =>['ac_id+0','ac_id']}
    });
    
    #warn "looking for children of $ef_acid";
    #$self->param('ac_parent' => $ef_acid);
    my @child_list = $self->_list_children($ef_acid,'NO TREE');
    my $csl;
    foreach my $cld (@child_list){
       $csl .= " ac_tree = '$cld' OR";
    }
    if(defined $csl){ $csl=~s/OR$// };
    #my $csl = {'-or' => [ $csl ]};
    my @children = $self->resultset('Account')->search({
        -or => [ \$csl ]
        },{ 
            'columns'   => ['ac_id','ac_name','ac_tree'], 
            order_by => {-asc =>['ac_min','ac_id']}
            #order_by => {-asc =>['ac_id+0','ac_id']}
    });
    if($self->param('pe_acid')){
        warn "settin TT_params for pe_acid";
        $self->tt_params({ pe_acid => $self->param('pe_acid')});
    }else{
        $self->tt_params({ pe_acid => $ac_id});
    }
    $self->tt_params({ ef_acid => $ef_acid });
    $self->tt_params({ ef_acid => $ac_id });

    $self->tt_params({
    accounts => \@accounts,
    #children => \@{ $self->_list_children($ef_acid) },
    children => \@children,
    test => $test,
	message => $message
		  });
    return $self->tt_process();
}

=head3 edit

  * edit an account

=cut

sub edit: Runmode {
    my ($self) = @_;
    my %search = ( ac_id => $self->session->param('ef_acid') );
    my $username = $self->authen->username;
    if($self->param('id') && $self->param('id')=~m/^(\d+)$/){
        $search{ac_id} = $1;
    }
    my $is_an_admin=0;
    if(defined $self->cfg('admin')){
        if( ref($self->cfg('admin')) eq 'ARRAY'){
            ADMIN_SEARCH: foreach my $adm (@{ $self->cfg('admin') }){
                if( $adm eq $username){
                    $is_an_admin=1;
                    last ADMIN_SEARCH;
                }
            }
        }
    }

    if( $self->session->param('pe_id') && $self->session->param('pe_id')=~m/^1$/ ||
        $self->session->param('pe_level') && $self->session->param('pe_level')=~m/^\d\d\d+$/
    ){
        $is_an_admin=1;
    }
    if($is_an_admin){
        $self->tt_params({ admin => 1 });
    }


    my $acc_list = $self->resultset('Account')->search(\%search)->first;
     #%search = ( -or => [ ac_min => {'<' => $acc_list->ac_min },  \[ "LENGTH(ac_tree) <= LENGTH(?)", $acc_list->ac_tree ] ] );
     my $parent_tree = $acc_list->ac_tree;
     $parent_tree =~s/\.\d*$//;
     #%search = ([ \[ "LENGTH(ac_tree) <= LENGTH(?)", "$parent_tree" ] ]);
     my @find = (\[ "LENGTH(ac_tree) <= LENGTH('$parent_tree')" ]);
     #my @find = (\[ "LENGTH(ac_tree) <= LENGTH('$acc_list->ac_tree')" ]);
    my @accounts = $self->resultset('Account')->search(\@find)->all;
    $self->tt_params({ accounts => \@accounts });
    %search = ( ac_id => $self->session->param('ef_acid') );
    if($self->param('id') && $self->param('id')=~m/^(\d+)$/){
        $search{ac_id} = $1;
    }
    my @ac = $self->resultset('Account')->search(\%search)->first;

    
    # Maybe they are updating
    my %update;
    my $q = $self->query;
    DATA: foreach my $ak (keys %{ $q->{'param'} } ){
        if($ak ne ''){
            if( $ak eq 'id' ||
                $ak eq 'name' ||
                $ak eq 'parent' ||
                $ak eq 'useradd' ||
                $ak eq 'tree' ||
                $ak eq 'notes' ||
                $ak eq 'min' ||
                $ak eq 'max' ){
                    my $ref = 'ac_' . $ak;
                        # ( length( do { no warnings "numeric"; $q->param($ak) & "" } ) )  #check that it is numeric before compare
                    if( @ac && ( (! defined $ac[0]->$ref ) || ( $q->param($ak) ne $ac[0]->$ref ) ) ){
                        if( ($ak eq 'min' || $ak eq 'max') && $q->param($ak)!~m/^\d+$/){ next DATA; }
                        if( ($ak eq 'tree') && $q->param($ak)!~m/^\d+(\.\d+)*$/){ next DATA; }
                        $update{$ref} = $q->param($ak);
                    }elsif($q->param($ak) eq $ac[0]->$ref){
                        #no strict 'refs';
                        #warn "$ak\t has not changed from " . $ac[0]->${"ac_$ak"};  # This does _not_ de-ref
                        #warn "$ak\t has not changed from " . $ac[0]->$ref;          # This works
                    }else{
                        warn "Error: no $ak " .$ac[0]->$ref . "!=" . $q->param($ak);
                    }
            }
        }
    }
    if($update{'ac_parent'} && $update{'ac_parent'} == $q->param('id')){
            delete($update{'ac_parent'});
    }elsif($update{'ac_parent'} && $update{'ac_parent'}=~m/^\d+$/){
        # We are going to have to update the tree and the min-max values
        
    }
    if(%update){
        if($q->param('id')){
            $update{'ac_id'} = $q->param('id');
            warn Dumper(\%update);
            my $rc = $self->resultset('Account')->search(\%search);
            $rc->update(\%update);
            # and now that we have an update we check that the new data is in the database
            @ac = $self->resultset('Account')->search(\%search)->first;
            # hmm if we have changed the parent account we may need to also do that select again
            # - then again, by using the old one, it makes it easier to roll back to the previous parent.
            $self->tt_params({ message => 'Updated' });
        }else{
            $self->tt_params({ warning => 'Which account are we updating?', message => 'Error' });
        }
    }else{
        $self->tt_params({ message => 'Nothing to update' });
        warn "Nothing to update";
    }

    $self->tt_params({ ac => \@ac });
    return $self->tt_process();
}

=head3 tree

the new tree (the old one is now called trees
and can probably be deleted

=cut

sub tree: Runmode {
    my ($self) = @_;
    my @rd = $self->resultset('People')->search->all;
    $self->tt_params({ people => \@rd });
    return $self->forward('list');
}

=head3 trees

a tree of accounts

=cut

sub trees: Runmode {
    my ($self) = @_;
    my %search;
    #my $q = $self->query;
    if($self->param('id') && $self->param('id')=~m/^(\d+)$/ && ($self->param('id') >= $self->session->param('ef_acid') ) ){
        $search{ac_id} = $1;
        my $sth = $self->resultset('Account')->search(\%search)->first;
        if($sth){
            %search = (
                -and => [
                        ac_min => {'>=' => $sth->ac_min},
                        ac_max => {'<=' => $sth->ac_max}
                ]
            );
        }else{
            %search = (
                        ac_id => $1
            );
        }
    }elsif($self->param('ef_acid') && $self->param('ef_acid')=~m/^(\d+)$/){
        $search{ac_id} = $1;
        my $sth = $self->resultset('Account')->search(\%search)->first;
        %search = ( 
            -or => [
                    ac_tree => {'like' => $sth->ac_tree . '%'},
                    ac_parent => $sth->ac_id
            ]
        );

    }else{
        # show them nothing
        $self->tt_params({ page => 'Your account has just been planted and has yet to grow into a tree' });
        return $self->tt_process('default.html');
    }

=pod
SELECT 
    me.ac_id,CONCAT( REPEAT(' ', COUNT(p.ac_name) -1), me.ac_name) AS name,me.ac_tree as t,me.ac_min,me.ac_max,me.ac_parent 
FROM account as me, account as p 
WHERE me.ac_min BETWEEN p.ac_min and p.ac_max 
GROUP BY me.ac_id 
ORDER BY me.ac_min;

SELECT me.ac_id,CONCAT( REPEAT(' ', COUNT(p.ac_name) -1), me.ac_name) AS name,me.ac_tree as t,me.ac_min,me.ac_max,me.ac_parent FROM account as me, account as p WHERE me.ac_min BETWEEN p.ac_min and p.ac_max GROUP BY me.ac_id ORDER BY me.ac_min;

=cut

   # my %rc = $self->resultset('Account')->search({
   #     'me.ac_min' => {'BETWEEN' => ['account.ac_min','account.ac_max'] }
   #     },{
   #         join => ['account'],
   #         '+column' => [{name => 'CONCAT( REPEAT(" ", COUNT(p.ac_name) -1), me.ac_name)'}],
   #         group => ['ac_tree','ac_id'],
   #         order => 'ac_min',
   #     })->all;
    my @rc = $self->resultset('Account')->search(\%search,{order_by => {-asc =>['ac_tree','ac_id']}})->all;
    my @rd = $self->resultset('People')->search->all;
    $self->tt_params({ accounts => \@rc, people => \@rd });
    return $self->tt_process('Notice/C/Account/trees.tmpl');
}

=head3 list

list the accounts

=cut

sub list: Runmode {
    my ($self) = @_;
    my %search;
    #my $q = $self->query;
    if($self->param('id') && $self->param('id')=~m/^(\d+)$/ && ($self->param('id') >= $self->session->param('ef_acid') ) ){
        $search{ac_id} = $1;
        my $sth = $self->resultset('Account')->search(\%search)->first;
        if($sth){
     # nested set
          if(1==1){
            %search = (
                -and => [
                        ac_min => {'>=' => $sth->ac_min},
                        ac_max => {'<=' => $sth->ac_max}
                ]
            );
          }
     # db-heavy
         if(1==0){
            %search = ( ac_tree => {'like' => $sth->ac_tree . '%'});
         }
        }else{
            %search = (
                        ac_id => $1
            );
        }
    }elsif($self->param('ef_acid') && $self->param('ef_acid')=~m/^(\d+)$/){
        $search{ac_id} = $1;
        my $sth = $self->resultset('Account')->search(\%search)->first;
     # nested set
          if(1==1){
            %search = (
                -and => [
                        ac_min => {'>=' => $sth->ac_min},
                        ac_max => {'<=' => $sth->ac_max}
                ]
            );
          }
     # db-heavy
         if(1==0){
            %search = ( ac_tree => {'like' => $sth->ac_tree . '%'});
         }
        #%search = ( -or => [ ac_tree => {'like' => $sth->ac_tree . '%'}, ac_parent => $sth->ac_id ]);

    }else{
        # show them nothing
        $self->tt_params({ page => 'Your account has just been planted and has yet to grow into a tree' });
        return $self->tt_process('default.html');
    }
    #my @rc = $self->resultset('Account')->search(\%search,{order_by => {-asc =>['ac_tree','ac_id']}})->all;
    my @rc = $self->resultset('Account')->search(\%search,{order_by => {-asc =>['ac_min']}})->all;
    $self->tt_params({ accounts => \@rc });
    #return $self->tt_process($self->param('id'));
    return $self->tt_process('Notice/C/Account/tree.tmpl');
}


=head3 delete

Delete an account

    This is buggy and does not clean up the ac_min ac_max
   
=cut

sub delete: Runmode {
    my ($self) = @_;
    my $q = $self->query;
    my $type; #of domain
    if( $self->param('id') ) {
        my %find = ();

        if( $self->param('id') ){
            $find{'ac_id'}=$self->param('id');
        }elsif( $self->param('sid') ){
            $find{'ac_id'}=$self->param('sid');
        }

        #warn $self->param('id') . ' ' . $self->param('sid');

        # have to limit this search to domains in their account
        my $ef_acid;
        our $ac_id;
        $ac_id = $self->_acid;
        unless($ac_id=~m/^\d+$/){
            $self->tt_params({ message => 'I need to stop you from deleting your own account', error => 'Which is your account?' });
            return $self->tt_process('Notice/C/Account/main.tmpl');
        }

        if($self->session->param('ef_acid')){
            $ef_acid = $self->session->param('ef_acid');
        }
        elsif($self->param('ef_acid')){
            $ef_acid = $self->param('ef_acid');
        }
     my $del = $self->resultset('Account')->search({
            ac_id => $find{'ac_id'},
        },{
            columns => ['ac_id','ac_min','ac_max'],
        })->first;


    # Unless you are an admin then you should not 
    #  delete an account unless 
    #       all of its child accounts have been deleted (or there are none)
    #        AND
    #       all of its users have been deleted (or there are none)
        
=pod

SELECT @myLeft := ac_min, @myRight := ac_max, @myWidth := ac_max - ac_min + 1
FROM account
WHERE ac_name = 'DELETE ME';

DELETE FROM account WHERE min BETWEEN @myLeft AND @myRight;

UPDATE account SET max = max - @myWidth WHERE max > @myRight;
UPDATE account SET min = min - @myWidth WHERE min > @myRight;

=cut

        if($del && $del->ac_id && ( $del->ac_id eq $ef_acid ) && ( $ef_acid ne $ac_id) && ( $del->ac_id ne $ac_id) ){
            my $min = $del->ac_min;
            warn "min: " . $del->ac_min;
            my $max = $del->ac_max;
            warn "max: " . $del->ac_max;
            my $width = $max - $min + 1;
    warn "by deleting " . $del->ac_id . " we remove min: $min and max: $max ; with a width of $width";
            if( $self->in_group('admin',$self->param('pe_id')) ){
                  my $wipe = $self->resultset('Account')->search({
                                ac_min => {'BETWEEN' => \"$min AND $max"}
                            },{
                                columns => ['ac_id'],
                            });
                  $wipe->delete;

                 my $genocide = $self->resultset('People')->search({ pe_acid => $del->ac_id });
                 warn "You need to:\n DELETE FROM people WHERE pe_acid = " . $del->ac_id;
                 # $genocide->delete; #never a good idea
            }
            if($min && $max){
                $del->delete();
            }else{
                warn "wow nelly! no loose cannons here!";
            }
            if($max){
                my $fix_max = $self->resultset('Account')->search({
                                    ac_max => {'>' => "$max"}
                                },{
                                    columns => ['ac_id','ac_min','ac_max'],
                                });
                while(my $f = $fix_max->next){
                    my $new_max;
                    if($f && $f->ac_max){
                        my $new_max = $f->ac_max - $width;
                        $f->update({ ac_max => $new_max });
                    }else{
                        warn "we have no new max for " . $f->ac_id;
                    }
                }
            }
            if($min){
                my $fix_min = $self->resultset('Account')->search({
                                    ac_min => {'>' => "$max"}
                                },{
                                    columns => ['ac_id','ac_min','ac_max'],
                                });
                while(my $f = $fix_min->next){
                    my $new_min;
                    if($f && $f->ac_min){
                        $new_min = $f->ac_min - $width;
                        $f->update({ ac_min => $new_min });
                    }else{
                        warn "we have no min for " . $f->ac_id;
                    }
                }
            }
            # We send them back to their own accoun
             $self->param('ef_acid' => $ac_id);
             $self->session->param('ef_acid' => $ac_id);
            $self->session->param('message' => 'Account deleted ');
            $self->session->param('error' => 'You have returned to your own account');
        }else{
            $self->session->param( message => 'Some Accounts are more solid than others - ', error => ' Not deleted');
        }
    }else{
        $self->session->param( message => 'We might try that later', error => ' Not deleted' );
    }
        
    #return $self->tt_process('Notice/C/Account/main.tmpl');
    my $url;
       $url = ($self->query->url);
       #$surl = ($self->query->self_url);
    return $self->redirect("$url/Account/");
}


=head3 _ef_acid

return the effective account ID

=cut

sub _ef_acid {
    my ($self) = @_;
    my $username = $self->authen->username;
    my $ef_acid = 0;
    if($self->session->param('ef_acid')){
        $ef_acid = $self->session->param('ef_acid');
    }elsif($self->session->param('pe_acid')){
        $ef_acid = $self->session->param('pe_acid');
    }else{
        $ef_acid = $self->_acid();
    }
    return $ef_acid;
}

=head3 _acid

return the account ID

=cut

sub _acid {
    my ($self) = @_;
    my $username = $self->authen->username;
    my $acid = 0;
    if($self->session->param('pe_acid')){
        $acid = $self->session->param('pe_acid');
    }elsif($self->session->param('pe_acid')){
        $acid = $self->session->param('pe_acid');
    }else{
        my $user_data = $self->resultset('People')->search({
            'pe_email' => { '=', "$username"},
           },{
            columns => ['pe_id','pe_acid','pe_fname','pe_lname','pe_menu']
        })->first;
        eval {
            #warn "doing it the hard way";
            $acid = $user_data->pe_acid;
        };   
        if($@){
            warn "failed to find an account for $username";
            warn $? . ' ' . $!;
        }
    }
    # should we try a few other things
    return $acid;
}   


=head3 _list_children

hopes for a parent account and then returns all of the children.
If we don't get a ac_parent we just return all children of account 1

this is used by Account::new_child

=cut

sub _list_children {
    my $self = shift;
    my $p = shift;      # from this account down
    my $t = shift;      # use the ac_tree
    my $x = shift;      # eXclude the parent

    # we should use these parent/tree values if we have them or ELSE...
    my $ac_parent = '1';
    $ac_parent = $self->param('ac_parent') if $self->param('ac_parent');
    my $ac_tree = $self->param('ac_tree');
    if($t){
        $ac_tree = $t;
    }
    if($p){
        $ac_parent = $p;
    }
    #warn "parent: $ac_parent, tree: $ac_tree";
    $self->param(message => "ac_parent in _list_children is $ac_parent") if $self->param('debug') && $self->param('debug') >=1;
    #my @children = ('1'); #should we pull the default from the database?
    my @children = (); #we should pull the default from the database?
    if($ac_tree=~m/^\d+(\.\d+)*$/){
        my $rs = $self->resultset('Account')->search({
            -or => [
                ac_parent=>$ac_parent,
                ac_tree=>{ like => "$ac_tree.\%"}
            ]},{ 
                'columns' => ['ac_tree'], order_by => {-asc =>['ac_id','ac_tree+0','ac_tree']}
        });
        while(my $crs = $rs->next){
            push(@children,$crs->ac_tree);
            #my $old_msg = $self->param('message');
            #$self->param(message => "$old_msg");
        }
    }elsif($ac_parent){
        $ac_parent = '1' unless $ac_parent=~m/^\d+$/; # again we should pull this from the database

        my $prs = $self->resultset('Account')->search({
                ac_id => $ac_parent,
               },{
                columns=>['ac_min','ac_max']
        })->first;
        #my %search = ( 'ac_parent'=> "$ac_parent" );
        my %search;
        if($prs && $prs->ac_min){
            $search{'ac_min'} = {'>=' => $prs->ac_min};
        }
        if($prs && $prs->ac_max){
            $search{'ac_max'} = {'<=' => $prs->ac_max};
        }

        # NTS you are here! we need to find all of the children using 
        if($search{'ac_min'} && $search{'ac_max'}){
            %search = ( 
                -and => [
                    'ac_min' => $search{'ac_min'},
                    'ac_max' => $search{'ac_max'}
                ]
            );
        }
    
    #warn Dumper(\%search);
        my $rs = $self->resultset('Account')->search(
                \%search,
                {columns=>['ac_tree'], order_by => {-asc =>['ac_id','ac_tree+0','ac_tree']}
        });
        while(my $crs = $rs->next){
            push(@children,$crs->ac_tree);
        }
    }
    return @children;
}

# 
# _name_to_child - given a string (usuall from a persons first name and last name) this returns an account ID
#

=head3 _tree_min_max

given $ac_id returns SELECT ac_tree,ac_min,ac_max FROM account WHERE ac_id = $ac_id;

=cut

sub _tree_min_max {
    my $self = shift;
    my $t = '1';
    my $m = '1';
    my $x = '2';
    my $ac_parent   = $self->param('ac_parent') ? $self->param('ac_parent') : '1';
    my $ac_id      = $self->param('ac_id') ? $self->param('ac_id') : '';
    unless($ac_id){ $ac_id = $ac_parent; }
    my $rs = $self->resultset('Account')->search({
        'ac_id'=>{'=' => "$ac_id"}
    },{
        columns => ['ac_tree','ac_min','ac_max']
    });
    while(my $tm = $rs->next){
        $t = $tm->ac_tree;
        $m = $tm->ac_min;
        $x = $tm->ac_max;
    }
    return ($t,$m,$x);
}

=head3 _new_child

expects ac_parent to be either a valid ac_id or (undef|NULL|'')
returns the new child account

=cut

sub _new_child {
    my $self = shift;
    my $ac_min      = $self->param('ac_min') ? $self->param('ac_min') : '';
    my $ac_max      = $self->param('ac_max') ? $self->param('ac_max') : '';
    my $ac_parent   = $self->param('ac_parent') ? $self->param('ac_parent') : '1';
    my $ac_name     = $self->param('ac_name') ? $self->param('ac_name') : '';
    my $ac_notes    = $self->param('ac_notes') ? $self->param('ac_notes') : '';
    my $ac_useradd  = $self->param('ac_useradd') ? $self->param('ac_useradd') : '';

    #SELECT ac_tree,ac_max FROM account WHERE ac_id = $ac_parent
    my($parent_tree,$min,$max) = _tree_min_max($self);
    
    warn "parent $parent_tree, min $min, max $max";
    my @offspring = _list_children($self); #all of them

    # we do NOT include grandchildren so
    my $tree_depth =$parent_tree ? $parent_tree : $self->param('ac_tree');
    #$tree_depth=~s/[^\.]//g;
    #my $generation = length($tree_depth);
    my $generation = ($tree_depth=~tr/\.//);
    my @children;
    foreach my $child (@offspring){
        my $count = ($child =~ tr/\.//);     
        if($count == $generation+1){
            push @children, $child;
        }
    }
    warn "children:" . Dumper(\@children);
    my @last_child = ('0');
    @last_child = split /\./, $children[@children -1];
    warn "last_child:" . Dumper(\@last_child);

    #warn "min $ac_min max $ac_max parent $ac_parent name $ac_name notes $ac_notes useradd $ac_useradd";
   
    # If we are adding a grandchild rather than a new child..
    if($ac_parent eq $children[@children -1]){
        push @last_child,'0';
    }
    if(@last_child >=1){ $last_child[@last_child -1]++; } #NO! I don't want any zero accounts
    else{ push @last_child,'1'; } # If this account has  no children then this is the first one
    my ($ac_tree) = join('.', @last_child); #could probably do these split and join and increment with one map but this is clearer
    warn "ac_tree $ac_tree";

    # we could nest this new account at the front using 
    #unless($ac_min){ $ac_min = $min+1;}
    #unless($ac_max){ $ac_max = $min+2;}
    # but this requires the search of ac_min and ac_max to change to
    #
    # $min_update = { ac_min => {'>' => "$min"}};
    # $max_update = { ac_max => {'>' => "$min"}};
    #
    # We nest this new account at the end
    unless($ac_min){ $ac_min = $max;}   
    unless($ac_max){ $ac_max = $max+1;}
    unless($ac_tree=~m/^\d+\.\d+/){ $ac_tree = $parent_tree . '.' . $ac_tree; }
    unless($ac_tree=~m/^\d+/){ $ac_tree = '1'; } #this is a catch all for when there are no accounts

    return ":$ac_tree:" unless ($ac_tree=~m/^\d+(\.\d+)*$/ && $ac_tree=~m/$parent_tree/);
    # update the ac_min and ac_max to make space for this new account;
    my $action  = $self->resultset('Account')->search({'ac_min' => {'>' => "$max"} }, undef);
    $action->update({'ac_min' => \'ac_min+2'});
    $action  = $self->resultset('Account')->search({'ac_max' => {'>=' => "$max"} }, undef);
    $action->update({'ac_max' => \'ac_max+2'});
    # and finally add the account
    my $data = {
                 ac_min => "$ac_min",
                 ac_max => "$ac_max",
                 ac_tree => "$ac_tree",
                 ac_name => "$ac_name",
                 ac_notes => "$ac_notes",
                 ac_parent => "$ac_parent",
                 ac_useradd => "$ac_useradd"
               };
    warn Dumper($data);
    my $comment = $self->resultset('Account')->create( $data )->update;
    my $ac_id = $comment->id;
    return ($ac_id,$ac_tree);
}

=head3 _list_child

this is used by new_child - can't remember how or why

=cut

sub _list_child {
    my ($self) = @_;
}

=head3 _name_to_child

given a string (usuall from a persons first name and last name) this returns an account ID

=cut

sub _name_to_child {
    my $self = shift;
    return unless $self->param('ac_id');
    my @ac_hi = split/\./, $self->param('ac_id');
    my($ac_parent,$ac_child,@grand); #children
    my $sproging=0; #have we started on the children yet?
    foreach my $pa (@ac_hi){
      if($pa=~m/^\d+/ && $sproging==0){
        # check that $ac_parent HAS a child account of $pa (or this might be a string)
        my $exists = list_child($self,$ac_parent,$pa);
        if($exists){
            $ac_parent = $ac_parent ? $ac_parent.'.'.$pa : $pa;
        }else{
            $ac_child = $pa; #we got $ac_parent.\d+ where there is NO such account!
            $sproging=1;
            push(@grand,$pa);
        }
      }elsif($sproging==0){
        push(@grand,$pa);
        $ac_child = $pa; $sproging=1;
      }else{
        $sproging=1;
        push(@grand,$pa);
      }
    }

#############################################################################################
# so we end up knowing the parent string and the first child and all the grand-children     #
# so we create the child, then add that to the parent and pop the grand-child into the child#
#############################################################################################
    my $new_ac = $ac_parent;
    my $c_ac_i =qq |@{["a".."z"]}@{[0..9]}?|; $c_ac_i=~s/ //g;
    #my $c_ac_i= join'',("a".."z",0..9);
    #my $c_ac_i=("a".."z",0..9); #golf anyone? [not sure that works in this situation]
    #my $c_ac_i=sprintf("%s",join"",("a".."z",0..9));
    #my $c_ac_i='abcdefghijklmnopqrstuvwxyz0123456789'; is shorted and faster! (Be clever not swotty!)
    # NTS you are here and we seem to be creating a NULL account, then the account that we want and then
    # we fail to create the grandchild account; so half success and half failure
    CHILD: while(my $child = shift(@grand)){
       my $sth;
       my $lc_child = lc($child);
       my $c_ac = (CORE::index($c_ac_i,$lc_child)+1);
       # if we have just one letter, (or digit) then 
       if(length($child)==1 && $c_ac=~m/^\d{1,2}/){
        #$new_ac = $ac_parent . '.' . (index($c_ac_i,$child)+1);
        $new_ac = $ac_parent . '.' . $c_ac;
        # check that $new_ac does not exist
        my $count = ($c_ac)+1;
        while($c_ac < $count){
            my @row = $self->resultset('Account')->search({ac_parent=>{'=',$ac_parent},ac_id=>{'=',$new_ac}},{columns=>['ac_id','ac_name']});
            if($lc_child eq lc($row[1])){ #we already have this one letter account created
                $ac_parent .= '.' . $c_ac;
                next CHILD;
            }
            if($row[0] eq $new_ac){
              $count++;
              $c_ac++;
              $new_ac = $ac_parent . '.' . $c_ac;
            }else{
              $count=$c_ac;
            }
        }
       }else{ # not in the child_account_index array
        #my $query=qq |SELECT COUNT(ac_id)+1 from account where ac_parent = ? and ac_name like ?;#WRITE|;
        #$sth=$rh->dbp($query);
        #$sth->execute($ac_parent,"$child\%");
        #my @row = $sth->fetchrow_array;
        #$child .= $row[0];
        my @row = $self->resultset('Account')->search({ac_parent=>{'=',$ac_parent},ac_name=>{'like',\"$child\%"}},{columns=>['ac_id']});
        $child .= int($row[0])+1;
        $new_ac = $ac_parent . '.' . $row[0];
       }
       # we know that $ac_parent . $child does not exists so we make it
       my $insert=qq |INSERT into account(ac_id,ac_name,ac_parent) VALUES(?,?,?);|;
         # lets obfuscate the name
         my $crypt_name = `echo '$child'|openssl enc -rc4 -a -pass pass:$new_ac`;
         chomp($crypt_name);
         if($crypt_name){ $child = $crypt_name; }
         else{ # $child = 'Your Account'; 
        }
       #$sth=$rh->dbp($insert);
       #my $worked = $sth->execute($new_ac,$child,$ac_parent) or warn "$DBI::errstr $? $!";
       my $li_id;
       $ac_parent = $new_ac;
    }
    return $new_ac;
}

=head3 _to_path

this expects an account tree and returns an expanded heirachical path
e.g. 1.2.17.3 -> 1/1.2/1.2.17/1.2.17.3

=cut

sub _to_path {
    my $ac_tree = shift;
    my $type = shift;
    my ($account_path,$last);
     unless($type eq 'short'){
        my @text = split (/\./, $ac_tree);
        foreach my $level (@text){
            $account_path .= "$last$level/";
            $last .= "$level.";
        }
     }
    return($account_path);
}

1;

__END__

=head1 BUGS AND LIMITATIONS

There are known problems with this module. How the accounts are selected is flawed, but works fine for examples.

Please fix any bugs or add any features you need. You can report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>

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
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut

