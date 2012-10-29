package Notice::C::Details;

use warnings;
use strict;
use lib 'lib'; #DEBUG
use base 'Notice';
use Data::Dumper;

# NTS pull this from the menu and modules table
my %submenu = ( 
   '1.2' => [
        '1' => { peer => 1, name=> 'Preferences', rm => 'prefs', class=> 'navigation'},
        '2' => { name=> 'CSS', rm => 'css', class=> 'navigation'},
        '3' => { name=> 'Menu', rm => 'menu', class=> 'navigation'},
    ],
);


=head1 NAME

Notice::C::Details - Template controller subclass for Notice

=head1 ABSTRACT

This is where a user can view/change their details in Notice.

=head1 DESCRIPTION

This lets you update your password and email, menu and even create a css for yourself/your account/each page

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
}

=head2 RUN MODES

=head3 main

  * Let the use know which subsections of Notice::Email they have access to 

=cut

sub main: StartRunmode {
    my ($self) = @_;
    my ($message,$body,%opt,$who_rs);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);
    our $pe_id;
    our $ud_rs;
    if($self->param('ef_peid')){ $pe_id = $self->param('ef_peid'); }
    elsif($self->param('pe_id')){ $pe_id = $self->param('pe_id'); }

    if($q->param('Edit')){
        $self->tt_params({ edit => 'Edit' });
    }
    # NOTE we have to let them update their details here


    if($pe_id && $pe_id=~m/^\d+$/){
        $ud_rs = $self->resultset('People')->search({pe_id => $pe_id})->first;
    }else{
        our $username;
        $username = $self->authen->username;
        $ud_rs = $self->resultset('People')->search({pe_email => $username})->first;
    }
    if($self->param('id') && $self->param('id')=~m/^\d+$/){
        our $who_id = $self->param('id');
        $who_rs = $self->resultset('People')->search({pe_id => $who_id})->first;
    }else{
        $who_rs = $ud_rs;
    }
    our $ac_id;
    eval {
          $ac_id = $who_rs->pe_acid;
    };

    my @ranks = $self->resultset('Rank')->search({'ra_boatn' => 'before'},{ 'columns'   => ['ra_id','ra_name'] });
    my @accounts = $self->resultset('Account')->search({
        -or => [
        'ac_id' => $ac_id,
        'ac_useradd' => { '>', '40' }, 
        ],
        },{ 'columns'   => ['ac_id','ac_name'], order_by => {-asc =>['ac_id+0','ac_id']}
    });
    my @countries = $self->resultset('Country')->search({'curid' => { '!=', undef },},{'columns'   => ['iso']});
    $self->tt_params({
        ranks   => \@ranks,
        accounts=> \@accounts,
        countries=> \@countries,
    });

    
    $message = 'Welcome to the Your Details section<br />';
    $body .=qq |In this section you can: <br />add,view,edit your details in this copy of Notice, (and its associated network.)<br />|;
    
    $self->tt_params({
    action  => "$surl",
    p       => $ud_rs, #person doing the looking
    d       => $who_rs, #person being looked at (usually the same)
    submenu => \%submenu,
	message => $message,
    page    => $body
		  });
    return $self->tt_process();
}

=head3 css

View and edit the css for your account/user and even per page (eventually)

=cut


sub css: Runmode {
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;

    $message = 'Here you can update the CSS that you user for this site.<br />';
    $body .=qq |You can create a new css just for you. If you give it a name then others will be able to find and use it. They will even be able to take a copy and change it for their needs. You can even have a css for each page!<br />
        Account admin can set a default css for their account, and Notice_admin can set the default css for the whole site.<br />
|; 


    $self->tt_params({
    submenu => \%submenu,
    message => $message,
    body    => $body
          });
    return $self->tt_process();
}



=head2 mlist_sort

sort the module list hash

=cut

sub mlist_sort{
    use Scalar::Util qw(looks_like_number);
    if( ($a=~m/^$b/ || $b=~m/^$a/) && $a=~m/^\d\.\d\.\d/ && $b=~m/^\d\.\d\.\d/){
        ( substr($a,4) <=> substr($b,4) || $a cmp $b )
    }elsif($a=~m/^$b/ || $b=~m/^$a/){
        looks_like_number($b) && looks_like_number($a) ? $a <=> $b : $a cmp $b;
        #( $a <=> $b || $a cmp $b );
    }else{
        #looks_like_number($b) && looks_like_number($a) ? $a <=> $b : "$a" cmp "$b";
        no warnings;
        $a <=> $b;
    }
}


=head3 menu

View and edit which menu items turn up. The ones that you can chose from a determined by your account;group;pe_level

# We get a list of available module items (things that can become menu items)
# We get a list of the users existing menu
#
# Then we create a table showing which are enabled and let the user decide which others they want to enable

=cut

sub menu: Runmode {
    my ($self) = @_;
    my ($message,$body,%opt,%mlist);
    my $q = $self->query;
 $message = '<form method="post"><table id="modules" class="none"><tr><th>Modules and Functions</th><th>Menu Tag</th><th>Version</th><th>Available</th><th>Use</th></tr>';  

    my $ef_peid = 0;
    if($self->param('pe_id') && $self->param('pe_id')>=1){
        $ef_peid = $self->param('pe_id');
    }elsif($self->session->param('pe_id') && $self->session->param('pe_id')>=1){
        $ef_peid = $self->session->param('pe_id');
    }else{
        # NOTE we should use $username to find then from the People table
        $message = 'Who are you?';
        # NTS what about pe_menu ? Don't we plan to use the for the menu order over-ride?
    }

    my %create_data;
    my @create_data;
    if($q->param('update') && $ef_peid=~m/^\d+$/){
        my $rs = $self->resultset('Menu')->search({
                     pe_id => "$ef_peid"
                  },{});
        #NOTE we could remove the unwatned rows, but (hidden=1) is safer
        $rs->update({hidden => 1});

        UPDATE: foreach my $ak (keys %{ $q->{'param'} } ){
            next UPDATE if $ak eq 'update';
            my $pref = $q->param("${ak}_pref") ? $q->param("${ak}_pref") : '1';
            my $v = $q->param($ak);
            #push @{ %create_data }, { pe_id => "$ef_peid", menu => "$ak", pref => "$pref", hidden => '0' } ;
            $rs = $self->resultset('Menu')->update_or_create({ pe_id => "$ef_peid", menu => "$ak", pref => "$pref", hidden => '0' });
            #warn "$v = $ak";
        }
        #$rs = $self->resultset('Menu')->update_or_create( \%create_data );

        # Now we need to update their menu 
    
        # WOW this should be in its own function (as the same fuction is used in Notice.pm)
        
        my @menu_order;
        my %menu;
        my $menu_class = 'navigation'; #change the css not the class!
        my @menu_rs = $self->resultset('Menu')->search({
                        'pe_id' => { '=', $self->param('pe_id')},
                        -or => [
                                'modules.mo_catagorie' => { '=', 'base'},
                                'modules.mo_catagorie' => { '=', 'details'},
                                'modules.mo_catagorie' => { '=', 'service'},
                                'modules.mo_catagorie' => { '=', 'sysadmin'},
                        ],
                        'hidden' => { '<=', '0'}, #catagorie ?? IT IS Category !
                        },{
                        columns => ['menu','hidden',{ name => 'modules.mo_name AS name'},{ rm => 'modules.mo_runmode AS rm'} ],
                        join => 'modules',
                        order_by => {-asc =>['pref','mo_default_hierarchy','menu+0']}
                        });
        my $menu_rows = @menu_rs;
        #warn "Cols: $menu_cols, Rows: $menu_rows";

        # NOTE we can add global default menu items here
        push @menu_order, '1.2';
        $menu{'1.2'} = {hidden => '', rm => 'details', name => 'Your Details', class => "$menu_class"};

        # NOTE I _know_ that there is a better way to do this.. but my dbic-fu fails here
        for(my $i=0;$i<=$menu_rows;$i++){
            my $menu     = $menu_rs[$i]->{_column_data}{menu};
            my $hidden   = $menu_rs[$i]->{_column_data}{hidden} || '';
            my $rm       = $menu_rs[$i]->{_column_data}{rm};
            my $menu_name= $menu_rs[$i]->{_column_data}{name};
            if($menu_name && $rm){
              push @menu_order, $menu;
              $menu{$menu} = {hidden => "$hidden", rm => "$rm", name => "$menu_name", class => "$menu_class"};
            }
        }

        # Should we demand certain things?
        if(!$menu{'1.0'} && $self->param('pe_level') && $self->param('pe_level')>=100){
            push @menu_order, '1.0';
            $menu{'1.0'} = {hidden=>'',rm=>'config',name=>'Configuration', class => "$menu_class"};
        }


        $self->param(menu => \%menu);
        $self->param(menu_order => \@menu_order);
        $self->session->param(menu => \%menu);
        $self->session->param(menu_order => \@menu_order);
        $self->tt_params({menu_order => \@menu_order});
        $self->tt_params({menu => \%menu});
    
    }elsif($q->param('update')){
        warn "Someone tried to update menu prefs";
        # NTS we should let Security deal with this (kick them out! ;-)
        $self->param(warn => 'Who are you?');
    }


    my @menu = $self->resultset('Menu')->search({
        pe_id => $ef_peid
    });

    { #DEBUG
        no strict 'refs';
        foreach my $mi (@menu){
            $opt{mi}{$mi->menu} = {hidden => $mi->hidden};
        }
        #keys %{ $menu } ? warn keys %{ $menu } : warn Dumper($menu);
        #warn Dumper(%{ $opt{mi} });
    }
    
    #$self->tt_params({ menu => $menu });
    $self->tt_params({ menu => \@menu });
    #$message .= Dumper($menu);

    my $modules_rs = $self->resultset('Module')->search({
               #     mo_user_use => \'!= ""',
                       },{
                        '+columns' => [ { is_active => 'mo_runmode AS is_active' } ], # WORKS
                    });
     # we are going to have to join the config table to find out is a module is disabled;

    ROW: while( my $mo = $modules_rs->next){
        my $mtid = $mo->mo_menu_tag;
        eval {

            $mlist{$mtid}{active} =
            $mo->get_column('is_active') ne $mo->mo_runmode ? $mo->get_column('is_active') : '';
            #$mo->get_column('is_active'); #works as $mo->{_column_data}{is_active};
            #$mlist{$mtid}{active} = $mo->me->is_active; does not work
        };
        if($@){
            #my %deref_mo; %deref_mo = %{ $mo }; $mlist{$mtid}{active} = $deref_mo{_column_data}{is_active} . " ERR";
            $mlist{$mtid}{active} = $mo->{_column_data}{is_active};
        }
        $mlist{$mtid}{name} = $mo->mo_name;
        $mlist{$mtid}{ver} = $mo->mo_version;
        $mlist{$mtid}{rm} = $mo->mo_runmode;
        $mlist{$mtid}{desc} = $mo->mo_description;
        $mlist{$mtid}{installed} = $mo->mo_user_use ? 1 : '';
    }

    $body .=qq |
|; 


    MLIST: foreach my $keynum (sort mlist_sort keys %mlist){
        #next MLIST; #debug
        my($checked,$disabled);
        my $indent='';
        $indent = '&nbsp; ' if $keynum=~m/\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+\.\d+/;
        $indent .= ' &nbsp; ' if $keynum=~m/\d+\.\d+\.\d+\.\d+\.\d+/;
        my $class = 'notab';
        $class = 'onetab' if $keynum=~m/\d+\.\d+/;
        $class = 'twotab' if $keynum=~m/\d+\.\d+\.\d+/;
        $class = 'threetab' if $keynum=~m/\d+\.\d+\.\d+\.\d+/;
        $class = 'fourtab' if $keynum=~m/\d+\.\d+\.\d+\.\d+\.\d+/;

        if($mlist{$keynum}{name}){
    # hmm we should really keep the HTML in the templates and keep the logic as thin/clean as possible
            my $version = $mlist{$keynum}{ver} ? $mlist{$keynum}{ver} : '0.01';
            my $installed = $mlist{$keynum}{installed} ? 'checked="checked"':'';
            #my $active = $menu->menu ? '': 'checked="checked"';
            my $active='';
            if(defined $opt{mi}){
                $active = ( defined $opt{mi}{$keynum} ) ? 'checked="checked"' : '' ;
                if($keynum && defined $opt{mi}{$keynum}){
                    warn "this user has /some/ menu and for $keynum they have " . $opt{mi}{"$keynum"};
                }else{
                    #warn "$keynum is not known for this user";
                }
            }   
            if($active){
                $opt{mi_seen}{$keynum} = 1;
            }
            #my $ravenskul =qw |onclick="if (this.checked) document.getElementById('${keynum}_installed').disabled=true; else document.getElementById('${keynum}_installed').disabled = false;"|; # like clashing barrels, you can never return
            #my $re_no =qw |onclick="if(this.checked){this.checked=true;this.disabled=true};"|; #this seems easier
            #my $no_re =qw |onclick="if(!this.checked){this.disabled=true};"|; #the opposite
            my $timeless =qq |onclick="if(this.checked){this.checked=false}else{this.checked=true};alert('Not possible, yet, to install mods from here');"|; #nothing changes!
            my $disabled = '';
            $disabled = 'disabled' if ( $self->param('debug') || $self->query->self_url=~m/debug=\d/); # turning off for debug
            $message .= qq (<tr class="thinborder">
                <td><span class="$class">$indent$mlist{$keynum}{name}</span></td>
                <td>$keynum</td>
                <td>$version</td>
                <TD><input type="checkbox" id="${keynum}_installed" disabled="disabled" $installed $timeless /></td>
                <TD><input type="checkbox" name="${keynum}" $active/>$mlist{$keynum}{active}</td>
            </tr>);
        }
    }

    #MENU_LIST: foreach my $mel (keys %{ $opt{mi} }){
    #    next MENU_LIST if $opt{mi_seen}{$mel};
    #}

    $message .=qq |</table><input type="submit" name="update" value="Update"></form>|;

    $self->tt_params({
    message => $message,
    page => $opt{debug},
    submenu => \%submenu,
    message => $message,
    body    => $body
          });
    return $self->tt_process();
}




1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
(Other than it has not been writen yet.)
Please fix any bugs or add any features you need. 
You can report them through GitHub or CPAN.

=head1 SEE ALSO

L<Notice>, L<CGI::Application>

=head1 SUPPORT AND DOCUMENTATION

You could look for information at:

    Notice@GitHub
        http://github.com/alexxroche/Notice

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0

See http://www.opensource.org/licenses/ for more information.

=cut


