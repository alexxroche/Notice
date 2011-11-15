package Notice::DB::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Customer

=cut

__PACKAGE__->table("customer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 first_name

  data_type: 'varchar'
  is_nullable: 0
  size: 25

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "first_name",
  { data_type => "varchar", is_nullable => 0, size => 25 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AK2HU6UHy0Rk3bmmPIaBZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
