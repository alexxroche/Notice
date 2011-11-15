package Notice::DB::Result::Ippool;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Ippool

=cut

__PACKAGE__->table("ippool");

=head1 ACCESSORS

=head2 ipp_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 40

=head2 ipp_subnet

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 ipp_rir

  data_type: 'enum'
  extra: {list => ["IANA","ARIN","RIPE","APNIC","LACNIC","AfriNIC","RFC1918","RFC3330","RFC3849"]}
  is_nullable: 1

=head2 ipp_assigned_to

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ipp_network

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ipp_vlan

  data_type: 'integer'
  is_nullable: 1

=head2 ipp_notes

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ipp_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 40 },
  "ipp_subnet",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "ipp_rir",
  {
    data_type => "enum",
    extra => {
      list => [
        "IANA",
        "ARIN",
        "RIPE",
        "APNIC",
        "LACNIC",
        "AfriNIC",
        "RFC1918",
        "RFC3330",
        "RFC3849",
      ],
    },
    is_nullable => 1,
  },
  "ipp_assigned_to",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ipp_network",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ipp_vlan",
  { data_type => "integer", is_nullable => 1 },
  "ipp_notes",
  { data_type => "blob", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Rg9Tf9GjhzGpRu+ueQVvNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
