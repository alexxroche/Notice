#!/usr/bin/perl

use strict;
use Notice::HTML ('html_header','html_footer','sidemenu');
use Notice::Common;
use Notice::CGI_Lite;
my $cgi=new CGI_Lite;
my %form=$cgi->parse_form_data();
my $page = $0; $page=~s/^.*\///;
my $ud = Notice::Common::check_for_login($ENV{REQUEST_URI});
my $action = $page . '?ud=' . $ud;
use Notice::DB::user;
my $find_them = new Notice::DB::user;
my %user_details;
$user_details{URI} = $ud;
$find_them->Notice::DB::user::user_details(\%user_details);

print html_header($page,$ud);
print sidemenu($page,$ud);
$|=1;
my ($col_order);
if($form{order} eq 'assend'){ $col_order = '&amp;order=desc'; }
else{ $col_order = '&amp;order=assend'; }
unless ($form{sort}){ $form{sort} = 'gr_name';}
unless ($form{order}){ $form{order} = 'assend';}
my $offset =  $form{offset}=~m/^\d+$/ ? $form{offset} : 0;
my $limit = ($form{limit} && $form{limit} < 100) ?  $form{limit} : 15;
if( ( !$offset && $offset !=0) ){ $offset = 0; }
if(!$limit || $limit > 100){ $limit = 5; }

my %group_categories = (
1 => 'People',
2 => 'Objects',
3 => 'Ideas',
);

#foreach my $env (keys %user_details){ print "$env = $user_details{$env}<br/>\n"; }

if($user_details{pe_level} >= 4) {
	# The usual reverse of the form submit name->value (should find a better way to do this)
	foreach my $values (keys %form){
                if($form{$values} eq 'View'){ $form{View} = $values; }
        }
}

use Notice::Groups;
my($notice)= new Notice::Groups;

sub add { # display the add a group box
        my $ud = shift;
        my $level = shift;
        my $th = shift;
        my $category = shift;
	my $html_data;
	my $html_table = qq|
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr valign="top">
    <td class="content" height="2">
    <br/>
<table class="default">
      <tr>|;
	my %selected_html = (
	gr_modid  => qq|<select name="gr_modid">
		<option name=''></option>
                <option name='3'>Domains</option>
                <option name='4'>IP Database</option>
                <option name='8.1'>Servers</option>
		</select>|,
	gr_public => qq|<select name="gr_public">
		<option name=''>Private</option>
		<option name='1'>Public</option></select>|,
	gr_category => qq|<select name="gr_category">
		<option name="1">People</option>
		<option name="2">Objects</option>
		<option name="3">Ideas</option></select>|,
	);
        foreach my $table_h ( sort { $a <=> $b } keys %{ $th }){
                $html_table .= qq |<th class="default"><a href="$page?sort=$th->{$table_h}[0]$col_order&amp;ud=$ud&amp;category=$category">$th->{$table_h}[1]</a></th>\n|;
		# need the first if to be if($select_html{$table_h}){ ... then use that } NTS then we can abstract this form type stuff and cut Notice
		# NTS down by a huge amount 
		if($th->{$table_h}[2] eq 'html'){
			$html_data .= qq|<td class="default"> $selected_html{$th->{$table_h}[0]}|;
			if($th->{$table_h}[4]){
				$html_data .= qq| OR $th->{$table_h}[4] |;
			}
			$html_data .= qq|</td>\n|;
		}elsif($th->{$table_h}[2] eq 'textarea'){
		   $html_data .= qq |<td class="default"><textarea name="$th->{$table_h}[0]" $th->{$table_h}[3]>$form{$th->{$table_h}[0]}</textarea></td>\n|;
		}elsif($th->{$table_h}[2] eq 'text'){
		   $html_data .= qq |<td class="default"><input type="$th->{$table_h}[2]" name="$th->{$table_h}[0]" value="$form{$th->{$table_h}[0]}" $th->{$table_h}[3]></td>\n|;
		}else{
		   $html_data .= qq |<td class="default">0: $th->{$table_h}[0] 1: $th->{$table_h}[1] 2: $th->{$table_h}[2]</td>\n|;
		}
        }
        $html_table .= qq |<th class="default-centre" colspan="2">Action</th></tr>\n|;

print $html_table;
print $html_data;
print qq |<td><input type="submit" name="Add Group" value="Add Group"></td>|;	
print qq |</tr></table></td></tr></table>\n|;

}

#############################################################################################################

if($form{View}){ # we are viewing a group
    if($user_details{pe_level} >= 4) {
	if($form{View}=~m/^\d+$/){
		print $notice->view_group($ud,$form{View},$action);
	}else{
		print "That is not a valid group\n";
	}
    }
}else{

# default view
print qq |
<!-- Main page -->

This is the <span class="error">groups</span> page (the real <span class="withouterror">power</span> of Notice)<br/>
Lots of things can be set into groups:
<br/><center><table><tr><td>
Groups of <span class="message">people</span> [ team, department, family, board, crew, union ]<br/> 
Groups of <span class="message">objects</span> [ assets, severs ] collections of physical things <br/>
Groups of <span class="message">ideas</span> [accociations, links, connections, nexus ] <br/>
<!-- Groups of digital files [ keys, certificates ] bunches <font color="#00ff00">&#42;</font>-->
</td></tr></table></center>|;

if($user_details{pe_level} >= 4) {

        #3       => [ gr_function => 'Description', 'textarea','cols="20" rows="1"'],
        my %th = (
        1       => [ gr_name    => 'Name','text','size="15"'],
        3       => [ gr_function => 'Description', 'text','size="30"'],
        5       => [ gr_public => 'Public','html'],
        7       => [ gr_modid => 'Module','html'],
        8       => [ gr_category => 'Category', 'html', '','<input type="text" name="gr_category" size="4">'],
        );
        my $category = $form{category};
        unless($category){  $category='1';}

	print qq|<span class="message">People:</span>|;
	$notice->list_groups($ud,$user_details{pe_level},\%th,$category,$action);

  if(1==1){
        $category='2';
	print qq|<br/>\n<span class="message">Objects:</span>|;
	$notice->list_groups($ud,$user_details{pe_level},\%th,$category,$action);
        $category='3';
	print qq|<br/>\n<span class="message">Ideas:</span>|;
	$notice->list_groups($ud,$user_details{pe_level},\%th,$category,$action);
   }

	print qq |
<!--font color="#00ff00">&#42;</font> technically these are assets but as this is a digital system we are probably going to get more of these--><br/>
|;
    if($user_details{pe_id} == 0){
	foreach my $enviable (keys %form)
	{
		print "<br/> $enviable $form{$enviable}\n";
	}
	print "<br/>\n   ################################################# <br/>\nENV:";
	foreach my $enviable (keys %ENV)
	{
	#	print "<br/> $enviable $ENV{$enviable}\n";
	}
    };


	print qq|<br/><span class="withouterror">Add a new group</span>|;
	&add($ud,$user_details{pe_level},\%th);
	print qq|<br/>|;
	print qq|A public group can be seen by any account and can not be deleted while there are members in it<br/>|;
	print qq|Only a system administrator can link a group to a module - normally this is done by the module itself<br/>|;
} # end of level test
#else{ print "You failed the level test because you are only: $user_details{pe_level}"; }
	

} # end of else

print html_footer;
