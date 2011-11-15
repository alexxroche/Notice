package Notice::DB::Result::Rental;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Rental

=cut

__PACKAGE__->table("rental");

=head1 ACCESSORS

=head2 rent_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 rent_peid

  data_type: 'integer'
  is_nullable: 0

=head2 rent_priid

  data_type: 'integer'
  is_nullable: 0

=head2 rent_period

  data_type: 'char'
  is_nullable: 1
  size: 16

=head2 rent_promoid

  data_type: 'integer'
  is_nullable: 1

=head2 rent_tableid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 rent_asid

  data_type: 'integer'
  is_nullable: 1

=head2 rent_start

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 rent_end

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 rent_paid

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 rent_cleared

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 rent_transaction

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "rent_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "rent_peid",
  { data_type => "integer", is_nullable => 0 },
  "rent_priid",
  { data_type => "integer", is_nullable => 0 },
  "rent_period",
  { data_type => "char", is_nullable => 1, size => 16 },
  "rent_promoid",
  { data_type => "integer", is_nullable => 1 },
  "rent_tableid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "rent_asid",
  { data_type => "integer", is_nullable => 1 },
  "rent_start",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "rent_end",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "rent_paid",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
  "rent_cleared",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
  "rent_transaction",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("rent_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kMD+BpVXMhEzC7620sP6LA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
