package Notice::DB::Result::Sslcert;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Sslcert

=cut

__PACKAGE__->table("SSLcerts");

=head1 ACCESSORS

=head2 ssl_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ssl_peid

  data_type: 'integer'
  is_nullable: 1

=head2 ssl_cn

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ssl_crt

  data_type: 'blob'
  is_nullable: 1

=head2 ssl_key

  data_type: 'blob'
  is_nullable: 0

=head2 ssl_csr

  data_type: 'blob'
  is_nullable: 1

=head2 ssl_location

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ssl_public

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1]}
  is_nullable: 1

=head2 ssl_acid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ssl_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ssl_peid",
  { data_type => "integer", is_nullable => 1 },
  "ssl_cn",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ssl_crt",
  { data_type => "blob", is_nullable => 1 },
  "ssl_key",
  { data_type => "blob", is_nullable => 0 },
  "ssl_csr",
  { data_type => "blob", is_nullable => 1 },
  "ssl_location",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ssl_public",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1] },
    is_nullable => 1,
  },
  "ssl_acid",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ssl_cn");
__PACKAGE__->add_unique_constraint("ssl_id", ["ssl_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pkNiHeBNVq8U7mqcxNo/jg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
