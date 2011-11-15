package Notice::DB::Result::NoticeOxcid;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::NoticeOxcid

=cut

__PACKAGE__->table("notice_oxcid");

=head1 ACCESSORS

=head2 ox_cid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ox_doid

  data_type: 'integer'
  is_nullable: 0

=head2 ox_acid

  data_type: 'integer'
  is_nullable: 0

=head2 ox_admin_user

  data_type: 'varchar'
  default_value: 'oxadmin'
  is_nullable: 0
  size: 64

=head2 ox_admin_pswd

  data_type: 'varchar'
  default_value: 'oxadminpw'
  is_nullable: 0
  size: 64

=head2 ox_group

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ox_cid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ox_doid",
  { data_type => "integer", is_nullable => 0 },
  "ox_acid",
  { data_type => "integer", is_nullable => 0 },
  "ox_admin_user",
  {
    data_type => "varchar",
    default_value => "oxadmin",
    is_nullable => 0,
    size => 64,
  },
  "ox_admin_pswd",
  {
    data_type => "varchar",
    default_value => "oxadminpw",
    is_nullable => 0,
    size => 64,
  },
  "ox_group",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ox_cid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PMZJ8o2DO0dP2lntjecFiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
