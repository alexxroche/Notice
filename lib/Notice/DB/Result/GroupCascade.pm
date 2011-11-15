package Notice::DB::Result::GroupCascade;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::GroupCascade

=cut

__PACKAGE__->table("group_cascade");

=head1 ACCESSORS

=head2 gc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 gc_table

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 gc_taid

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 gc_enabled

  data_type: 'enum'
  default_value: 1
  extra: {list => [0,1]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gc_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "gc_table",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "gc_taid",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "gc_enabled",
  {
    data_type => "enum",
    default_value => 1,
    extra => { list => [0, 1] },
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("gc_table", "gc_taid");
__PACKAGE__->add_unique_constraint("gc_id", ["gc_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mu5kUUTC9nDqnlmy/yDs4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
