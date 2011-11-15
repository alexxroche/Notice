package Notice::DB::Result::AssetLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AssetLocation

=cut

__PACKAGE__->table("asset_location");

=head1 ACCESSORS

=head2 al_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 al_asid

  data_type: 'integer'
  is_nullable: 1

=head2 al_assetid

  data_type: 'integer'
  is_nullable: 1

=head2 al_ascompartment

  data_type: 'integer'
  is_nullable: 1

=head2 al_width

  data_type: 'integer'
  is_nullable: 1

=head2 al_height

  data_type: 'integer'
  is_nullable: 1

=head2 al_depth

  data_type: 'integer'
  is_nullable: 1

=head2 al_heightunit

  data_type: 'varchar'
  default_value: 'cm'
  is_nullable: 1
  size: 16

=head2 al_widthunit

  data_type: 'varchar'
  default_value: 'cm'
  is_nullable: 1
  size: 16

=head2 al_depthunit

  data_type: 'varchar'
  default_value: 'cm'
  is_nullable: 1
  size: 16

=head2 al_compartmentx

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=head2 al_compartmenty

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "al_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "al_asid",
  { data_type => "integer", is_nullable => 1 },
  "al_assetid",
  { data_type => "integer", is_nullable => 1 },
  "al_ascompartment",
  { data_type => "integer", is_nullable => 1 },
  "al_width",
  { data_type => "integer", is_nullable => 1 },
  "al_height",
  { data_type => "integer", is_nullable => 1 },
  "al_depth",
  { data_type => "integer", is_nullable => 1 },
  "al_heightunit",
  { data_type => "varchar", default_value => "cm", is_nullable => 1, size => 16 },
  "al_widthunit",
  { data_type => "varchar", default_value => "cm", is_nullable => 1, size => 16 },
  "al_depthunit",
  { data_type => "varchar", default_value => "cm", is_nullable => 1, size => 16 },
  "al_compartmentx",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
  "al_compartmenty",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("al_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6Htj9AxIRAS0647AbrZAJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
