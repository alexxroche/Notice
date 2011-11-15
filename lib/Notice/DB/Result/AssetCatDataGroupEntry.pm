package Notice::DB::Result::AssetCatDataGroupEntry;

# Created by Alexx
# Modify any part that you need to

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AssetCatDataGroupEntry

=head1 ABSTRACT

DBIxC type module

=head1 DESCRIPTION

Provide an object class for the asset_cat_data and group_entry tables

=cut


__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table("asset_cat_data_group_entry");


=head1 ACCESSORS

=head2 gr_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gr_name

  data_type: 'varchar'
  is_nullable: 0
  size: 254

=head2 gr_function

  data_type: 'varchar'
  is_nullable: 1
  size: 254

=cut

__PACKAGE__->add_columns(
	'gr_id' => {
	  data_type => 'integer',
	  is_auto_invrement => 1,
	},
	'gr_name' => {
	  data_type => 'varchar',
	  size => 254,
	},
	'gr_function' => {
	  data_type => 'varchar',
	  size => 254,
	},
);
__PACKAGE__->result_source_instance->is_virtual(1);


__PACKAGE__->result_source_instance->view_definition(q[
SELECT gr.gr_id,gr.gr_name,gr.gr_function FROM group_members me 
  JOIN group_members gm on me.gg_miag = gm.gg_grid 
  JOIN groups gr on gr.gr_id = gm.gg_miag 
  JOIN asset_cat_data acd on acd.acd_grid = me.gg_grid 
  WHERE acd.acd_id = ? and gr.gr_id = ?
]);

# Created by Alexx
# Modify anything that you need to


# You can replace this text with custom code or comments, but it won't be preserved on regeneration

=head1 LICENSE AND COPYRIGHT

Copyright  Alexx Roche, all rights reserved.

=cut

1;

__END__
