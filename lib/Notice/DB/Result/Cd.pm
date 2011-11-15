package Notice::DB::Result::Cd;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Cd

=cut

__PACKAGE__->table("cd");

=head1 ACCESSORS

=head2 cdid

  data_type: 'integer'
  is_nullable: 0

=head2 artist

  data_type: 'integer'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cdid",
  { data_type => "integer", is_nullable => 0 },
  "artist",
  { data_type => "integer", is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cdid");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ftWefxmTlF/lopAGiLPP0w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
