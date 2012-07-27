use utf8;
package Notice::DB::Result::VCardData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::VCardData - The actual vCard data

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vCard_data>

=cut

__PACKAGE__->table("vCard_data");

=head1 ACCESSORS

=head2 vcd_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vcd_card_id

  data_type: 'integer'
  is_nullable: 0

=head2 vcd_profile_id

  data_type: 'integer'
  is_nullable: 0

=head2 vcd_prof_detail

  data_type: 'varchar'
  is_nullable: 1
  size: 255

work,home,preferred,order for e.g. multiple email addresses

=head2 vcd_value

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 vcd_bin

  data_type: 'blob'
  is_nullable: 1

for when varchar(255) is too small

=cut

__PACKAGE__->add_columns(
  "vcd_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vcd_card_id",
  { data_type => "integer", is_nullable => 0 },
  "vcd_profile_id",
  { data_type => "integer", is_nullable => 0 },
  "vcd_prof_detail",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vcd_value",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vcd_bin",
  { data_type => "blob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vcd_id>

=back

=cut

__PACKAGE__->set_primary_key("vcd_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-07-03 17:52:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yHe4nS5arFtuTuyBGZxu/A

__PACKAGE__->has_one('profile' => 'Notice::DB::Result::VCardProfile', {'foreign.vcprofile_id' => 'self.vcd_profile_id'});
__PACKAGE__->has_one('cards' => 'Notice::DB::Result::VCard', {'foreign.card_id' => 'self.vcd_card_id'});

1;
