use utf8;
package Notice::DB::Result::VCard;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::VCard - These are the contact cards

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vCards>

=cut

__PACKAGE__->table("vCards");

=head1 ACCESSORS

=head2 card_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 card_peid

  data_type: 'integer'
  is_nullable: 1

link back to user table

=head2 card_acid

  data_type: 'integer'
  is_nullable: 1

link back to account table

=head2 card_language

  data_type: 'varchar'
  is_nullable: 1
  size: 5

en en_GB

=head2 card_encoding

  data_type: 'varchar'
  default_value: 'UTF-8'
  is_nullable: 1
  size: 32

why use anything else?

=head2 card_created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 card_updated

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "card_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "card_peid",
  { data_type => "integer", is_nullable => 1 },
  "card_acid",
  { data_type => "integer", is_nullable => 1 },
  "card_language",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "card_encoding",
  {
    data_type => "varchar",
    default_value => "UTF-8",
    is_nullable => 1,
    size => 32,
  },
  "card_created",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 0,
  },
  "card_updated",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</card_id>

=back

=cut

__PACKAGE__->set_primary_key("card_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-07-03 17:52:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sJl5uOLX3UhrQ/kkYmTGCQ

__PACKAGE__->has_many('data' => 'Notice::DB::Result::VCardData', {'foreign.vcd_card_id' => 'self.card_id'});

1;
