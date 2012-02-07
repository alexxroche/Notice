#!/usr/bin/perl

use strict;
use Notice::HTML ('html_header','html_footer','sidemenu');
use Notice::Common;
my $page = $0; $page=~s/^.*\///;
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI});

print html_header($page,$ud);
print sidemenu($page,$ud);

print qq (
<!-- Main page -->
<div style="top: 0;">
<a href="$ud">Main</a> &gt;&gt; $page
</div><br/>
);
# NTS use $user_details{pe_menu} to tell them what they can do
print qq(

This is the IP management section. You can:
<ul>
<li> allocate a new ip address</li>
<li> search to see what an address or rage is used for</li>
<li> view the IP addresses within a block  </li>
<li> view the IP addreses or blocks of a network </li>
<li> maintain the VLANs per network</li>
<li> manage the networks a block can be assigned to</li>
<li> <strike> manage who the blocks are assigned by (Add a new RIR)</strike></li>
</ul> 


An IP address always belongs within a block, (a block may reside inside of a another block).<br/>
Each block is assigned to a VLAN within a network.<br/>
Each network is assigned to an account (see the Accounts option in the side menu?)<br/><br/>
Additionally each block has to come from somewhere and that<br/> is a RIR (Regional Internet registry)
and the internal ranges created by some of the RFC (Request For Comments),<br/> but that changes so
infrequently that it is maintained by hand for now.

<div style="height: 300px;  #position: relative; overflow: hidden;">
<!-- just messing about with a navigation idea NTS -->
<br/>
</div>

);

print html_footer;
