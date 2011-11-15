package Notice::DB::Result::AliasDetail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::AliasDetail

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
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ead_notes",
  { data_type => "blob", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lDMXNhaAWypvCRQU0gxNMg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
