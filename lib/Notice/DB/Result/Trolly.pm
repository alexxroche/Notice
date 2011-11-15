package Notice::DB::Result::Trolly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Trolly

=cut

__PACKAGE__->table("trolly");

=head1 ACCESSORS

=head2 tro_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 tro_peid

  data_type: 'integer'
  is_nullable: 0

=head2 tro_startdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 tro_expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tro_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "tro_peid",
  { data_type => "integer", is_nullable => 0 },
  "tro_startdate",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "tro_expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("tro_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0dVHkps+wO08D6zAaYp/Uw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
