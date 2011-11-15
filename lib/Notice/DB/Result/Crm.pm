package Notice::DB::Result::Crm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Crm

=cut

__PACKAGE__->table("CRM");

=head1 ACCESSORS

=head2 crm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 crm_peid

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 crm_type

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 crm_key

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 128

=head2 crm_value

  data_type: 'char'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "crm_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "crm_peid",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "crm_type",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "crm_key",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 128 },
  "crm_value",
  { data_type => "char", is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("crm_id", "crm_key", "crm_peid");
__PACKAGE__->add_unique_constraint("crm_id", ["crm_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yJl7lg+MU2cIUOfBRpS86g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
