package Notice::DB::Result::Imap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Imap

=cut

__PACKAGE__->table("imap");

=head1 ACCESSORS

=head2 im_userid

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 im_doid

  data_type: 'integer'
  is_nullable: 0

=head2 im_passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 74

=head2 im_home

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 im_uid

  data_type: 'integer'
  is_nullable: 0

=head2 im_gid

  data_type: 'integer'
  is_nullable: 0

=head2 im_server

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 im_quota

  data_type: 'integer'
  is_nullable: 1

=head2 im_peid

  data_type: 'integer'
  is_nullable: 1

=head2 im_pkid

  data_type: 'integer'
  is_nullable: 1

=head2 im_auth

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 im_mode

  data_type: 'char'
  default_value: 0640
  is_nullable: 1
  size: 4

=head2 im_dir_mode

  data_type: 'char'
  is_nullable: 1
  size: 4

=cut

__PACKAGE__->add_columns(
  "im_userid",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "im_doid",
  { data_type => "integer", is_nullable => 0 },
  "im_passwd",
  { data_type => "varchar", is_nullable => 1, size => 74 },
  "im_home",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "im_uid",
  { data_type => "integer", is_nullable => 0 },
  "im_gid",
  { data_type => "integer", is_nullable => 0 },
  "im_server",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "im_quota",
  { data_type => "integer", is_nullable => 1 },
  "im_peid",
  { data_type => "integer", is_nullable => 1 },
  "im_pkid",
  { data_type => "integer", is_nullable => 1 },
  "im_auth",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "im_mode",
  { data_type => "char", default_value => "0640", is_nullable => 1, size => 4 },
  "im_dir_mode",
  { data_type => "char", is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("im_userid", "im_doid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZPKKXuXSq7lJQdBbpPiTfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
