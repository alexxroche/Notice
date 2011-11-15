package Notice::DB::Result::Menu;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Menu

=cut

__PACKAGE__->table("menu");

=head1 ACCESSORS

=head2 pe_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 menu

  data_type: 'varchar'
  default_value: 1
  is_nullable: 0
  size: 32

=head2 pref

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pe_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "menu",
  { data_type => "varchar", default_value => 1, is_nullable => 0, size => 32 },
  "pref",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pe_id", "menu");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B0K2gZ9CLxVD8u1psHsXVw

__PACKAGE__->belongs_to('modules' => 'Notice::DB::Result::Module', {'foreign.mo_menu_tag' => 'self.menu'});

1;
