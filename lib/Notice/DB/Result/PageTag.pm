use utf8;
package Notice::DB::Result::PageTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::PageTag - which tags to match

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PageTag>

=cut

__PACKAGE__->table("PageTag");

=head1 ACCESSORS

=head2 pt_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pt_paid

  data_type: 'integer'
  is_nullable: 0

Pages.pa_id

=head2 pt_ag

  data_type: 'varchar'
  is_nullable: 1
  size: 255

page tag id="menu" name="footer"

=head2 pt_order

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

if there is a list this determins the order, smallest left/top largest right/bottom

=head2 pt_inc

  data_type: 'integer'
  is_nullable: 1

do we include this page or just its link

=cut

__PACKAGE__->add_columns(
  "pt_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pt_paid",
  { data_type => "integer", is_nullable => 0 },
  "pt_ag",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pt_order",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "pt_inc",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pt_id>

=back

=cut

__PACKAGE__->set_primary_key("pt_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-01-04 13:20:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6tY4p/e7HgYStIgbJNodow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
