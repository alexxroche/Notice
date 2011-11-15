package Notice::DB::Result::Title;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Title

=cut

__PACKAGE__->table("titles");

=head1 ACCESSORS

=head2 ti_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ti_raid

  data_type: 'integer'
  is_nullable: 1

=head2 ti_name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 ti_hereditory

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1]}
  is_nullable: 1

=head2 ti_female_line

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1]}
  is_nullable: 1

=head2 ti_issue

  data_type: 'integer'
  is_nullable: 1

=head2 ti_dateofcreation

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ti_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ti_raid",
  { data_type => "integer", is_nullable => 1 },
  "ti_name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "ti_hereditory",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1] },
    is_nullable => 1,
  },
  "ti_female_line",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1] },
    is_nullable => 1,
  },
  "ti_issue",
  { data_type => "integer", is_nullable => 1 },
  "ti_dateofcreation",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ti_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eIaDEcWyEchXwn4b/Pzphw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
