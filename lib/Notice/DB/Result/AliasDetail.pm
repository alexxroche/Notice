use utf8;
package Notice::DB::Result::AliasDetail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::AliasDetail - email alias details - passwords will be hashed somehow

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<alias_details>

=cut

__PACKAGE__->table("alias_details");

=head1 ACCESSORS

=head2 ead_userid

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ead_doid

  data_type: 'integer'
  is_nullable: 1

=head2 ead_website

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ead_password

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ead_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 ead_notes

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ead_userid",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ead_doid",
  { data_type => "integer", is_nullable => 1 },
  "ead_website",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ead_password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ead_date",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "ead_notes",
  { data_type => "blob", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-05-30 18:50:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G7TlclQJiQBBgLLOdqRsGw

#__PACKAGE__->set_primary_key(__PACKAGE__->columns);
__PACKAGE__->set_primary_key('ead_userid','ead_doid');
# we must migrate to using ead_id as primary key and ead_edid as the link to aliases.ea_id
1;
