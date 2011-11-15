package Notice::DB::Result::Sehistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Sehistory

=cut

__PACKAGE__->table("sehistory");

=head1 ACCESSORS

=head2 sh_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 sh_asid

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sh_what

  data_type: 'mediumtext'
  is_nullable: 1

=head2 sh_when

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 sh_bywhom

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sh_towhom

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sh_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "sh_asid",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "sh_what",
  { data_type => "mediumtext", is_nullable => 1 },
  "sh_when",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "sh_bywhom",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "sh_towhom",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("sh_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lkb6UhL6eZYR4q4Ijlgw0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
