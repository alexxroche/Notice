package Notice::DB::Result::GlobalConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::GlobalConfig

=cut

__PACKAGE__->table("global_config");

=head1 ACCESSORS

=head2 gc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gc_name

  data_type: 'char'
  default_value: 'Notice CRaAM'
  is_nullable: 1
  size: 64

=head2 gc_uuid

  data_type: 'char'
  is_nullable: 1
  size: 36

=head2 gc_sslid

  data_type: 'integer'
  is_nullable: 1

=head2 gc_parent

  data_type: 'char'
  default_value: '15cfb282-e35b-40c0-bb5d-83a34ed3feef'
  is_nullable: 1
  size: 36

=head2 gc_emancipated

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gc_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gc_name",
  {
    data_type => "char",
    default_value => "Notice CRaAM",
    is_nullable => 1,
    size => 64,
  },
  "gc_uuid",
  { data_type => "char", is_nullable => 1, size => 36 },
  "gc_sslid",
  { data_type => "integer", is_nullable => 1 },
  "gc_parent",
  {
    data_type => "char",
    default_value => "15cfb282-e35b-40c0-bb5d-83a34ed3feef",
    is_nullable => 1,
    size => 36,
  },
  "gc_emancipated",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("gc_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MJBh/Vg5ei7hR8OYXOyXmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
