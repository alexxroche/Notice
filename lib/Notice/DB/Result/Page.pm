use utf8;
package Notice::DB::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::Page - mostly html, but can be raw text

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Pages>

=cut

__PACKAGE__->table("Pages");

=head1 ACCESSORS

=head2 pa_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pa_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 pa_title

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pa_link

  data_type: 'varchar'
  is_nullable: 1
  size: 255

How the link to this page from others will look

=head2 pa_published

  data_type: 'integer'
  is_nullable: 1

Is it live?

=head2 pa_lang

  data_type: 'char'
  is_nullable: 1
  size: 6

en_GB fr zn

=head2 pa_added

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

date written or published

=head2 pa_updated

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

date updated

=head2 pa_owner

  data_type: 'integer'
  is_nullable: 1

peid

=head2 pa_template

  data_type: 'varchar'
  is_nullable: 1
  size: 255

overide from the pages.html template

=head2 pa_change

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

how different is this from the last version, as a percentage

=head2 pa_ge

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pa_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pa_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pa_title",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pa_link",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pa_published",
  { data_type => "integer", is_nullable => 1 },
  "pa_lang",
  { data_type => "char", is_nullable => 1, size => 6 },
  "pa_added",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "pa_updated",
  {
    data_type => "datetime",
    "datetime_undef_if_invalid" => 1,
    is_nullable => 1,
  },
  "pa_owner",
  { data_type => "integer", is_nullable => 1 },
  "pa_template",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pa_change",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "pa_ge",
  { data_type => "blob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pa_id>

=back

=cut

__PACKAGE__->set_primary_key("pa_id");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-01-04 13:20:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5hXQzSKXhdlQjvexNpHpDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
