package Notice::DB::Result::ConfData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::ConfData

=cut

__PACKAGE__->table("conf_data");

=head1 ACCESSORS

=head2 cfd_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cfd_key

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 cfd_value

  data_type: 'blob'
  is_nullable: 1

=head2 cfd_cfid

  data_type: 'integer'
  is_nullable: 0

=head2 cfd_peid

  data_type: 'integer'
  is_nullable: 1

=head2 cfd_acid

  data_type: 'integer'
  is_nullable: 1

=head2 cfd_grid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cfd_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cfd_key",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "cfd_value",
  { data_type => "blob", is_nullable => 1 },
  "cfd_cfid",
  { data_type => "integer", is_nullable => 0 },
  "cfd_peid",
  { data_type => "integer", is_nullable => 1 },
  "cfd_acid",
  { data_type => "integer", is_nullable => 1 },
  "cfd_grid",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cfd_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-11 18:08:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y2P+uqD4SNm3HY6ODinkaw

__PACKAGE__->add_unique_constraint(
    control_update_or_create => [ qw/cfd_key cfd_value cfd_acid / ],
  );

__PACKAGE__->belongs_to('config' => 'Notice::DB::Result::Config', {'foreign.cf_id' => 'self.cfd_cfid'});
__PACKAGE__->belongs_to('ac_parent' => 'Notice::DB::Result::Account', {'foreign.ac_parent' => 'self.cfd_acid'});

=pod

we will probably want to add

__PACKAGE__->belongs_to('account' => 'Notice::DB::Result::Account', {'foreign.ac_id' => 'self.cfd_acid'});
__PACKAGE__->belongs_to('account' => 'Notice::DB::Result::People', {'foreign.pe_id' => 'self.cfd_peid'});
__PACKAGE__->belongs_to('account' => 'Notice::DB::Result::Group', {'foreign.gr_id' => 'self.cfd_grid'});


=cut


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
