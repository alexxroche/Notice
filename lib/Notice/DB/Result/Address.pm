package Notice::DB::Result::Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Address

=cut

__PACKAGE__->table("address");

=head1 ACCESSORS

=head2 ad_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ad_acid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ad_adname

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 ad_adnumber

  data_type: 'varchar'
  default_value: 0
  is_nullable: 1
  size: 128

=head2 ad_adroad

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ad_adcity

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 ad_adcounty

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 ad_adpostcode

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 ad_adcountry

  data_type: 'char'
  default_value: 'UK'
  is_nullable: 1
  size: 2

=head2 ad_phone

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 ad_fax

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 ad_type

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 ad_notes

  data_type: 'mediumblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ad_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ad_acid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ad_adname",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "ad_adnumber",
  { data_type => "varchar", default_value => 0, is_nullable => 1, size => 128 },
  "ad_adroad",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ad_adcity",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "ad_adcounty",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "ad_adpostcode",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "ad_adcountry",
  { data_type => "char", default_value => "UK", is_nullable => 1, size => 2 },
  "ad_phone",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "ad_fax",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "ad_type",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "ad_notes",
  { data_type => "mediumblob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ad_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+wVdFt/NlHkMI6ALFLo/LQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
