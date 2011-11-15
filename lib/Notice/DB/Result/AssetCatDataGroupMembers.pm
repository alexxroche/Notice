package Notice::DB::Result::AssetCatDataGroupMembers;
use strict;
use warnings;
use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AssetCatDataGroupMembers

=cut

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table("asset_cat_data_group_members");

=head1 ACCESSORS

=head2 gr_id

  data_type: 'integer'
  is_auto_increment: 1

=head2 gr_name

  data_type: 'varchar'
  is_nullable: 1
  size: 254

=cut

__PACKAGE__->add_columns(
	'gr_id' => {
	  data_type => 'integer',
	  is_auto_increment => 1,
	},
	'gr_name' => {
	  data_type => 'varchar',
	  size => 254,
	},
);
#__PACKAGE__->result_class('Notice::DB::Result::GroupMembers');
  # do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);


#__PACKAGE__->result_source_instance->name(q[
__PACKAGE__->result_source_instance->view_definition(q[
SELECT gr.gr_id,gr.gr_name FROM group_members me 
  JOIN group_members gm on me.gg_miag = gm.gg_grid 
  JOIN groups gr on gr.gr_id = gm.gg_miag 
  JOIN asset_cat_data acd on acd.acd_grid = me.gg_grid 
  and acd.acd_id = ?
]);
#__PACKAGE__->add_columns(
#  'gr_id' => {
#    data_type => 'integer',
#    is_auto_increment => 1,
#  },
#  'artist' => {
#    data_type => 'integer',
#  },
#  'title' => {
#    data_type => 'varchar',
#    size      => 100,
#  },
#);

1;
