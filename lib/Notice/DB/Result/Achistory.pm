package Notice::DB::Result::Achistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Achistory

=cut

__PACKAGE__->table("achistory");

=head1 ACCESSORS

=head2 ch_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ch_acid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ch_what

  data_type: 'mediumtext'
  is_nullable: 1

=head2 ch_when

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 ch_bywhom

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 ch_towhat

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "ch_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ch_acid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ch_what",
  { data_type => "mediumtext", is_nullable => 1 },
  "ch_when",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ch_bywhom",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "ch_towhat",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("ch_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hGlgMVUd4T+MCjUwfmvOJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
