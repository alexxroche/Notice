package Notice::DB::Result::ModuleProductCatagory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::ModuleProductCatagory

=cut

__PACKAGE__->table("module_product_catagory");

=head1 ACCESSORS

=head2 mc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 mc_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mc_table

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 mc_type

  data_type: 'enum'
  extra: {list => ["insert","update","delete"]}
  is_nullable: 1

=head2 mc_what

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mc_isnumeric

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mc_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "mc_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mc_table",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "mc_type",
  {
    data_type => "enum",
    extra => { list => ["insert", "update", "delete"] },
    is_nullable => 1,
  },
  "mc_what",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mc_isnumeric",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("mc_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ltJ4pMF0YCmqlFntVUbKcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
