package Notice::DB::Result::PeopleOpenid;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::PeopleOpenid

=cut

__PACKAGE__->table("people_openids");

=head1 ACCESSORS

=head2 openid_url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 pe_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openid_url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pe_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("openid_url");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XeZ8/ZmtsHPL4QrNmTcgYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
