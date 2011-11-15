package Notice::DB::Result::Sslhistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Sslhistory

=cut

__PACKAGE__->table("SSLhistory");

=head1 ACCESSORS

=head2 rh_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 rh_peid

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rh_what

  data_type: 'mediumtext'
  is_nullable: 1

=head2 rh_when

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 rh_towhat

  data_type: 'mediumtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rh_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "rh_peid",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "rh_what",
  { data_type => "mediumtext", is_nullable => 1 },
  "rh_when",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "rh_towhat",
  { data_type => "mediumtext", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("rh_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LnZhxTMFi1vzXRbdqBkWpA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
