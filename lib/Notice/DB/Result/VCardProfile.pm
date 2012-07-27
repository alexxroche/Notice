use utf8;
package Notice::DB::Result::VCardProfile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::VCardProfile - These are the valid types of card entry

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vCard_profile>

=cut

__PACKAGE__->table("vCard_profile");

=head1 ACCESSORS

=head2 vcprofile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vcprofile_version

  data_type: 'enum'
  default_value: 'rfc2426'
  extra: {list => ["rfc2426"]}
  is_nullable: 1

defaults to vCard 3.0

=head2 vcprofile_feature

  data_type: 'char'
  is_nullable: 1
  size: 16

FN to CATEGORIES

=head2 vcprofile_type

  data_type: 'enum'
  default_value: 'text'
  extra: {list => ["text","bin"]}
  is_nullable: 1

if it is too large for vcd_value then user vcd_bin

=cut

__PACKAGE__->add_columns(
  "vcprofile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vcprofile_version",
  {
    data_type => "enum",
    default_value => "rfc2426",
    extra => { list => ["rfc2426"] },
    is_nullable => 1,
  },
  "vcprofile_feature",
  { data_type => "char", is_nullable => 1, size => 16 },
  "vcprofile_type",
  {
    data_type => "enum",
    default_value => "text",
    extra => { list => ["text", "bin"] },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vcprofile_id>

=back

=cut

__PACKAGE__->set_primary_key("vcprofile_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-07-03 17:52:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6dsRC1j3qkV5hFdlf5v9mA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
