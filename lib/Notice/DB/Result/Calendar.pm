use utf8;
package Notice::DB::Result::Calendar;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::Calendar - CalDAV and CardDAV

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<calendar>

=cut

__PACKAGE__->table("calendar");

=head1 ACCESSORS

=head2 cid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 path

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ics

  data_type: 'char'
  default_value: 'd.ics'
  is_nullable: 1
  size: 64

=head2 type

  data_type: 'enum'
  default_value: 'vevent'
  extra: {list => ["vevent","vtodo","vjournal","vfreebusy","vtimezone"]}
  is_nullable: 0

=head2 version

  data_type: 'char'
  default_value: 1.0
  is_nullable: 0
  size: 4

=head2 data

  data_type: 'blob'
  is_nullable: 0

=head2 peid

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

who this is happening to

=head2 acid

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

or what this is hqppening to

=head2 start

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 end

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 added_by

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 modified

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 is_locked

  data_type: 'enum'
  default_value: 'N'
  extra: {list => ["N","Y"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "path",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "ics",
  { data_type => "char", default_value => "d.ics", is_nullable => 1, size => 64 },
  "type",
  {
    data_type => "enum",
    default_value => "vevent",
    extra => {
          list => ["vevent", "vtodo", "vjournal", "vfreebusy", "vtimezone"],
        },
    is_nullable => 0,
  },
  "version",
  { data_type => "char", default_value => "1.0", is_nullable => 0, size => 4 },
  "data",
  { data_type => "blob", is_nullable => 0 },
  "peid",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "acid",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "start",
  {
    data_type => "timestamp",
    "datetime_undef_if_invalid" => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "end",
  {
    data_type => "timestamp",
    "datetime_undef_if_invalid" => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "added_by",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "created",
  {
    data_type => "timestamp",
    "datetime_undef_if_invalid" => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "modified",
  {
    data_type => "timestamp",
    "datetime_undef_if_invalid" => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "is_locked",
  {
    data_type => "enum",
    default_value => "N",
    extra => { list => ["N", "Y"] },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cid>

=back

=cut

__PACKAGE__->set_primary_key("cid");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-05-30 18:50:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WcLgAk7evzZZ4gY9dwOMZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
