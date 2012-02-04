package Notice::DB::Result::AssetCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AssetCategory

=cut

__PACKAGE__->table("asset_categories");

=head1 ACCESSORS

=head2 asc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 asc_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 asc_description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 asc_grid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "asc_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "asc_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "asc_description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "asc_grid",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("asc_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mvTDLZrLgjbVWCStI6nfZw

__PACKAGE__->has_many('catdata' => 'Notice::DB::Result::AssetCatData', {'foreign.acd_cid' => 'self.asc_id'});

1;
