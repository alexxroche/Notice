package Notice::DB::Result::Account2Coid;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Account2Coid

=cut

__PACKAGE__->table("account2COID");

=head1 ACCESSORS

=head2 acid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 co_id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "acid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "co_id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("co_id", "acid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ptO5Pc/KAWN6zLKVMaAyuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
