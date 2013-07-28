package Notice::C::Billing;

use warnings;
use strict;
use base 'Notice';
use Data::Dumper;
my %opt=(D=>0);

# NTS pull this from the menu and modules table

our %submenu = (
   '1.0' => [
        '10' => { peer => 1, name=> 'Billing', rm => 'Billing', class=> 'navigation', },
        '10.1' => { peer => 1, name=> 'Products', rm => 'Billing/list_products', class=> 'navigation child'},
        '10.2' => { peer => 1, name=> 'Show', rm => 'Billing/list', class=> 'navigation child'},
        '10.3' => { peer => 1, name=> 'Find', rm => 'Billing/search', class=> 'navigation child'},
        '10.4' => { peer => 1, name=> 'Invoice', rm => 'Billing/generate_invoices', class=> 'navigation child'},
        '10.5' => { peer => 1, name=> 'Receipt', rm => 'Billing/receipt', class=> 'navigation child'},
        '10.7' => { peer => 1, name=> 'Promotions', rm => 'sales/promo', class=> 'navigation child'},
    ],
);


=head1 NAME

Notice::C::Billing

=head1 ABSTRACT

This is where a Notice Admin would configure prices issure invoices or receipts 
and check that anything that can be billed is.

Hence it is a submenu of the Configuration. The users will see the billing from
their point of view under Subscriptions.

=head1 DESCRIPTION

This lets you update configurations, (e.g. the welcome message)
and modules for this installation of Notice

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Override or add to configuration supplied by Notice::cgiapp_init.

=cut

sub setup {
    my ($self) = @_;
    $self->authen->protected_runmodes(':all');
    # we should un-select each child option
    $self->tt_params({ submenu => \%submenu });
}

=head2 RUN MODES

=head3 main

  * Let the use know which things can be billed for and how much

The first table we have to check is

module_products
and
module_product_category

this will tell us what we are selling/renting

The prices come from 

price_list
BUT we MUST also take into account
promotion

before a user can request an entry in the
trolly
and
trolly_items
table

and once payment is made we make an entry in the

rental
table.

We also consider the
country
and
currency

tables as well as the
config 
table, (so there is quite a lot going on.)


=cut

sub main: StartRunmode {
    my ($self) = @_;
    my ($message,$body,%opt);
    my $q = $self->query;
    my $surl;
       $surl = ($self->query->self_url);

    my ($ac_id,@domains);
    if($self->param('ef_acid')){ $ac_id = $self->param('ef_acid'); }
    elsif($self->param('ac_id')){ $ac_id = $self->param('ac_id'); }
    if($ac_id){
        # NTS need to join the group table so that we only list domains that are not in the
        # "no email" domains group
        @domains = $self->resultset('Domain')->search({
            do_acid=>{'=',"$ac_id"}
             },{
        });
    }
    #if($domains[0]->{_column_data}{do_name}){
    if($domains[1]->{_column_data}{do_name}){
        $opt{default_domain} = '/' . $domains[1]->{_column_data}{do_name};
    }

    $message = 'Welcome to the Billing section<br />';
    $message .=qq |In this section you can: <br/> |;

    my $page .= $self->_ajax()
      #. $q->div({-id=>'box1'},'This is div1<br /><br />')
      #. $q->div({-id=>'box2'},'Another div, div2')
    . $self->_module_buttons();

#      . $q->button(-class=>'loadpage', -id=>'generate_invoices', -value=>'Generate invoices')
#      . $q->button(-class=>'loadpage', -id=>'add_product', -value=>'Add Product')
#      . $q->button(-class=>'loadpage', -id=>'show_status', -value=>'See service status')
#      . $q->button(-class=>'loadpage', -id=>'set_price', -value=>'Set a Price');

    $self->tt_params({
    action  => "$surl/aliases",
    domains => \@domains,
    message => $message,
    page    => $page
    });
    return $self->tt_process();
}


=head3 _module_buttons

abstract the buttons

=cut

sub _module_buttons {
    my ($self) = shift;
    my $q = $self->query;
    return  $q->button(-class=>'loadpage', -id=>'generate_invoices', -value=>'Generate invoices')
      . $q->button(-class=>'loadpage', -id=>'add_product', -value=>'Add Product')
      . $q->button(-class=>'loadpage', -id=>'show_status', -value=>'See service status')
      . $q->button(-class=>'loadpage', -id=>'set_price', -value=>'Set a Price')
      . $q->button(-class=>'loadpage', -id=>'login', -value=>'Show login')
        ;

}

=head3 login

call the login module

=cut

sub login: Runmode {
    my $self = shift;

    use Notice::C::Login;
    my $page = $self->Notice::C::Login::form;

    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}){ return scalar $$page . "\n<br />" . $self->_ajax() .  $self->_module_buttons; }
    warn "too far from ajax";

    $self->tt_params({
        page    => $page . "\n<br />" . $self->_ajax() .  $self->_module_buttons
    });
    return $self->tt_process('Notice/C/Billing/main.tmpl');

}

=head3 set_price

    here an admin can set the price for a product
    this is granular to account, people, group

=cut

sub set_price: Runmode {
    my $self = shift;

# Set the menu as selected
    
    my %this_submenu = %submenu;
    $this_submenu{'1.0'}[1]{class} .= ' selected'; #Billing
    #$this_submenu{'1.0'}[9]{class} .= ' selected'; #Invoice
    $self->tt_params({ submenu => \%this_submenu });

    my $tt=$self->_get_template('product_price',{products => '<option id="1">One</option><option id="2">Too</option>'});

    my $page = "<strong>There are no products to price up. Maybe you could add a product</strong>";
    if($tt){ $page = $tt; }

    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}){ return $page; }
    $self->tt_params({
        page    => $page . "\n<br />" . $self->_ajax() .  $self->_module_buttons
    });
    return $self->tt_process('Notice/C/Billing/main.tmpl');

}



=head3 generate_invoices

    This runmode can be accessed either directly
    (if they don't have ECMAscript, and for backwards compatability )
    or via ajax! Best of both worlds.

=cut

sub generate_invoices: Runmode {
    my $self = shift;

# Set the menu as selected
    my %this_submenu = %submenu;
    $this_submenu{'1.0'}[1]{class} .= ' selected'; #Billing
    $this_submenu{'1.0'}[3]{class} = 'child navigation'; #Products
    $this_submenu{'1.0'}[9]{class} .= ' selected'; #Invoice
    $self->tt_params({ submenu => \%this_submenu });


    # if this has been called via ajax then we do something special? (do we have to?) so that this can be run long-hand old skool
    my $page = "<strong>printing invoices 123 through 98765</strong>";

    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}
       # || $ENV{'HTTP_X_REQUESTED_WITH'} eq 'XMLHttpRequest'
    ){
        return $page;
    #}else{
        # full page
    }
    $self->tt_params({
    page    => $page . "\n<br />" . $self->_ajax() .  $self->_module_buttons
    });
    return $self->tt_process('Notice/C/Billing/main.tmpl');

}

=head3 add_product

add a billable product to zero or more existing services

=cut

sub add_product: Runmode {
    my $self = shift;

# Set the menu as selected
    my %this_submenu = %submenu;
    $this_submenu{'1.0'}[1]{class} .= ' selected'; #Billing
    $this_submenu{'1.0'}[3]{class} .= ' selected'; #Products
    $this_submenu{'1.0'}[9]{class} = 'child navigation'; #Invoices
    $self->tt_params({ submenu => \%this_submenu });


    # if this has been called via ajax then we do something special? (do we have to?) so that this can be run long-hand old skool
    my $page = "<strong>First off we need to know which module(s) this product will be attacked to, (if any).</strong>";

    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}){ return $page; }
    $self->tt_params({
        page    => $page . "\n<br />" . $self->_ajax() .  $self->_module_buttons
    });
    return $self->tt_process('Notice/C/Billing/main.tmpl');

}


=head3 list_products

    A list of known products

=cut

sub list_products: Runmode {
    my $self = shift;

# Set the menu as selected
    my %this_submenu = %submenu;
    $this_submenu{'1.0'}[1]{class} .= ' selected'; #Billing
    $this_submenu{'1.0'}[3]{class} .= ' selected'; #Products
    $this_submenu{'1.0'}[9]{class} = 'child navigation'; #Invoices
    $self->tt_params({ submenu => \%this_submenu });


    # if this has been called via ajax then we do something special? (do we have to?) so that this can be run long-hand old skool
    my $page = "<strong>No products found. You can add one if you like </strong>";

    if( defined $ENV{'HTTP_X_REQUESTED_WITH'}
       # || $ENV{'HTTP_X_REQUESTED_WITH'} eq 'XMLHttpRequest'
    ){ 
        return $page;
    #}else{
        # full page
    }
    $self->tt_params({
    page    => $page . "\n<br />" . $self->_ajax() .  $self->_module_buttons
    });
    return $self->tt_process('Notice/C/Billing/main.tmpl');

}



=head3 ajax_load

runmodes called via ajax
- we are able to prevent users from accessing these directly

=cut

sub ajax_load : Runmode {
#warn "GOT ajax_load";
  my $self = shift;
    #my $requested_runmode = $self->query->param('id');
    #if( exists &{ $requested_runmode } && $requested_runmode!~m/^_/ && $requested_runmode!~m/^setup/){ #don't want to expose interenals
    #    warn "GOOD NEWS: $requested_runmode IS a runmode";
    #}else{
    #    warn "BAD NEWS: $requested_runmode does not exists";
    #}

    my $q = $self->query;
   # foreach my $ak (keys %{ $q->{'param'} } ){ warn "$ak = " . $q->param($ak); }
  #if($self->query->param('id')){
  if($self->param('id')){
    my $requested_runmode = $self->param('id');
    if( exists &{ $requested_runmode } && $requested_runmode!~m/^_/ && $requested_runmode!~m/^setup/){ #don't want to expose interenals
        warn "GOOD NEWS: $requested_runmode IS a runmode";
    }else{
        return "BAD NEWS: $requested_runmode does not exist "
        . $self->_ajax()
        . $self->_module_buttons();
    }
    return &{ $self->param('id') }
    . $self->_ajax()
    . $self->_module_buttons();
    return $self->redirect($self->query->url . '/' . $self->param('mod'));
  }elsif($self->query->param('id')){
  #}elsif($self->param('id')){
    my $requested_runmode = $self->query->param('id');
    unless( exists &{ $requested_runmode } && $requested_runmode!~m/^_/ && $requested_runmode!~m/^setup/){ #don't want to expose interenals
        return "Sorry: $requested_runmode does not exist (yet?) "
        . "\n"
        . '<div id="buttons">'
        . $self->_ajax()
        . $self->_module_buttons()
        . "\n"
        . '</div>'
        ;
    }

    our $module2run = \&{ $requested_runmode };
    return $self->$module2run
    . "\n"
    . '<div id="buttons">'
    . $self->_ajax()
    . $self->_module_buttons()
    . "\n"
    . '</div>'
    ;
    #
    #foreach my $sp ( $self->param ){ warn "$sp = " . $self->param($sp); } #debug
    #return $self->redirect($self->query->url . '/' . $self->param('mod'));
  }else{
    scalar localtime() 
    . $self->query->p('Ajax example, (Look Ma, no page reload!)')
    . $self->_ajax()
    . $self->_module_buttons();
  }
}

=head3 ajax_alter_div2

How specific do these have to be?
It would be nice to abstract them;
sub ajax_verb_id : Runmode {
}

=cut

sub ajax_alter_div2 : Runmode {
  my $self = shift;
  reverse $self->query->param('some_text');
}

=head3 _ajax

We are going to generalise this where possible so that every module
 can have access to ajax for any function that will improve the user experience.
 we can load an entire page or a single request
 but what about when we want a change to trigger a requsest?

=cut

sub _ajax {
    my $self = shift;
    my $rm = shift;
    my $mod = ($self->query->self_url);

    # This has to be a little complicated to cope:
    # with i18n in the URI
    # without i18n in the URI
    # we /may/ want to add complication so that email/edit_alias/ and email/aliases/ have the option of seperate CSS
    if($mod=~m/.*\/index.cgi\/[\w{2}][_\w{2}]?\/([^\/]*)\/?\??.*/){
        $mod= $1; # we have a languge set
    }elsif($mod=~m/.*\/index.cgi\/([^\/|\?]*)\/?\??.*$/){
        $mod=$1;
    }elsif($mod=~m/^htt[p|ps]:\/\/[^\/]+\/([^\/]+)[\/|\?|\#].*$/){
        # we could link this to the hostname in the $CFG
        $mod=$1;
    warn ".htaccess parth cleaner detected in $mod";
    }elsif($mod=~m{^(http)?[s]?:?\/\/[^\/]+\/([^\/]+)}){
        $mod=$2;
        # we could link this to the hostname in the $CFG
    }elsif($mod!~m/index\.cgi/){
        warn "UNABLE TO PARSE |$mod|";
        $mod=~s/^http(s)?:\/\/[^\/]+\///;
        $mod=~s/\/.*//;
        $mod=~s/\?.*$//;
        warn "trying $mod";
    }else{
        $mod = 'main';
    }
    # this does NOT seem to work for index.cgi/Email/aliases/edit/ (or even /Email/aliases/ )

    # we want an explicit $mod
    my $prot_host = ($self->query->url);
    $prot_host =~s/^http[s]?://;
    #$mod = '//localhost:8060/cgi-bin/index.cgi/' $mod;
    $mod = $prot_host .'/' . $mod;
    #warn "_ajax in " . $mod;
   if(defined $rm){ warn $rm; }
# /img/ajax-loader.gif /images/NoticePageThrobber.gif

     #throbber { visibility: hidden; display:none; z-index: 100; height: 100% with: 100%; background-color: #999999; }
  return '<style type="text/css">
      body { background-color: #eee }
      #box1, #box2 { border: 1px solid gray; width: 200px; height: 80px; padding: 4px; margin: 10px; }
      #box2, #b2,  .loadpage { border: 1px solid blue; }
      #centre_throbber { top: 25%; position: relative; text-align: center; margin: 0 auto; width: 50px; }
     #throbber { 
        display:none;
        top:0; left: 0; position: absolute; text-align: center; margin: auto;
     z-index: 99; height: 100%; width: 100%; background-color: #999999; 
filter:alpha(opacity=30); /* IE */
    -moz-opacity:0.3; /* Mozilla */
    opacity: 0.3; /* CSS3 */
}
  </style>
  <div id="throbber"><span id="centre_throbber"><img src="/img/ajax-loader.gif" alt="Loading..." /></span></div>
  <script type="text/javascript">
    $(function(){
      $("input.loadpage").click(function() {
          var clicked=this.id;
          var status=0;
         setTimeout(function() { 
                setTimeout(function() {

                    $("div#content").load(
                      "' . $mod . '",
                      { "rm": "ajax_load", "id": clicked },
                      function(response, status, xhr) {
                        if (status == "error") {
                            var msg = "Sorry but there was an error: ";
                            alert(msg + xhr.status + " " + xhr.statusText);
                            $("#throbber").hide();
                        }
                      });

                }, 100);
                //$("#throbber").hide(); //not needed as we reload the css at the same time
            if( ! status ){
                $("#throbber").show(); // If we do not have a reply in .5 seconds then let the user know
            };
            }, 100);
        //setTimeout(function() { alert("Request timed out - please try again"); }, 1111); // Let the user know
      });
      $(".request").click(function() {
            var clicked=this.id;
            var target=this.target;
            $(target).load(
              "' . $mod . '",
              { "rm": "ajax_function", "id": clicked, "input": clicked.text() },
                function(response, status, xhr) {
                        if (status == "error") {
                            var msg = "Sorry but that did not work: ";
                            alert(msg + xhr.status + " " + xhr.statusText);
                            $("#throbber").hide();
                        }
              });
      });
    });
    </script>';
}


1;

__END__

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.
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

