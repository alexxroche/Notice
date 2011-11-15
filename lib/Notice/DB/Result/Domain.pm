package Notice::DB::Result::Domain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Domain

=cut

__PACKAGE__->table("domains");

=head1 ACCESSORS

=head2 do_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 do_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 do_status

  data_type: 'enum'
  default_value: 'remote'
  extra: {list => ["disabled","suspended","enabled","migrating out","migrating in","registering","desired","disputed","remote"]}
  is_nullable: 0

=head2 do_added

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 do_acid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 do_group

  data_type: 'integer'
  is_nullable: 1

=head2 do_peid

  data_type: 'integer'
  is_nullable: 1

=head2 do_location

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 do_masters

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "do_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "do_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "do_status",
  {
    data_type => "enum",
    default_value => "remote",
    extra => {
      list => [
        "disabled",
        "suspended",
        "enabled",
        "migrating out",
        "migrating in",
        "registering",
        "desired",
        "disputed",
        "remote",
      ],
    },
    is_nullable => 0,
  },
  "do_added",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "do_acid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "do_group",
  { data_type => "integer", is_nullable => 1 },
  "do_peid",
  { data_type => "integer", is_nullable => 1 },
  "do_location",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "do_masters",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("do_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7YdTECof6azXN0rE0AXXKA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
