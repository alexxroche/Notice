package Notice::DB::Result::AssetData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AssetData

=cut

__PACKAGE__->table("asset_data");

=head1 ACCESSORS

=head2 asd_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 asd_asid

  data_type: 'integer'
  is_nullable: 0

=head2 asd_cid

  data_type: 'integer'
  is_nullable: 0

=head2 asd_value

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 asd_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "asd_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "asd_asid",
  { data_type => "integer", is_nullable => 0 },
  "asd_cid",
  { data_type => "integer", is_nullable => 0 },
  "asd_value",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "asd_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("asd_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DCsP7QFvvGUvpN6xajOQDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
