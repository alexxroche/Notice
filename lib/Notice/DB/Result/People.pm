use utf8;
package Notice::DB::Result::People;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::People

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<people>

=cut

__PACKAGE__->table("people");

=head1 ACCESSORS

=head2 pe_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pe_raid

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 pe_fname

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_lname

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_mname

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_uname

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_alias

  data_type: 'integer'
  is_nullable: 1

=head2 pe_goesby

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_dob

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 pe_dod

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 pe_mobile

  data_type: 'tinytext'
  is_nullable: 1

=head2 pe_email

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 pe_password

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 pe_acid

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 pe_level

  data_type: 'integer'
  is_nullable: 1

=head2 pe_loggedin

  data_type: 'varchar'
  is_nullable: 1
  size: 90

=head2 pe_menu

  data_type: 'varchar'
  default_value: 1
  is_nullable: 1
  size: 512

=head2 pe_confirmed

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 pe_passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "pe_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pe_raid",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "pe_fname",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_lname",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_mname",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_uname",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_alias",
  { data_type => "integer", is_nullable => 1 },
  "pe_goesby",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_dob",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "pe_dod",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "pe_mobile",
  { data_type => "tinytext", is_nullable => 1 },
  "pe_email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pe_password",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "pe_acid",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "pe_level",
  { data_type => "integer", is_nullable => 1 },
  "pe_loggedin",
  { data_type => "varchar", is_nullable => 1, size => 90 },
  "pe_menu",
  { data_type => "varchar", default_value => 1, is_nullable => 1, size => 512 },
  "pe_confirmed",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "pe_passwd",
  { data_type => "varchar", is_nullable => 1, size => 256 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pe_id>

=back

=cut

__PACKAGE__->set_primary_key("pe_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-24 14:53:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3qgsztpQSxyBUV0YXOPigw

__PACKAGE__->has_one('accounts' => 'Notice::DB::Result::Account', {'foreign.ac_id' => 'self.pe_acid'});
1;
