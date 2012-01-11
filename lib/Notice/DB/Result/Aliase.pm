package Notice::DB::Result::Aliase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Aliase

=cut

__PACKAGE__->table("aliases");

=head1 ACCESSORS

=head2 ea_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ea_userid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 128

=head2 ea_touser

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ea_at

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 128

=head2 ea_doid

  data_type: 'integer'
  is_nullable: 0

=head2 ea_suspended

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ea_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ea_userid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 128 },
  "ea_touser",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ea_at",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 128 },
  "ea_doid",
  { data_type => "integer", is_nullable => 0 },
  "ea_suspended",
  { data_type => "tinyint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ea_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-11 18:08:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BHFVX++iBjIoANt6CG+oSg

__PACKAGE__->belongs_to('domains' => 'Notice::DB::Result::Domain', {'foreign.do_id' => 'self.ea_doid'});
__PACKAGE__->might_have('aliasdetails' => 'Notice::DB::Result::AliasDetail',
{'foreign.ead_doid' => 'self.ea_doid', 'foreign.ead_userid' => 'self.ea_userid'});


1;
