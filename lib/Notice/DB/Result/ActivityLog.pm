use utf8;
package Notice::DB::Result::ActivityLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::ActivityLog - Notice internal log

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<activity_log>

=cut

__PACKAGE__->table("activity_log");

=head1 ACCESSORS

=head2 alid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

people.pe_id

=head2 period

  data_type: 'enum'
  default_value: 'S'
  extra: {list => ["S","M","H","d","w","m","y"]}
  is_nullable: 0

=head2 tally

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

how many

=head2 action

  data_type: 'enum'
  default_value: 'search'
  extra: {list => ["search","view","add","update","delete","loiter","afk","login","logout","log"]}
  is_nullable: 0

what they did; loiter records mouse over

=head2 start

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 end

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "alid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "period",
  {
    data_type => "enum",
    default_value => "S",
    extra => { list => ["S", "M", "H", "d", "w", "m", "y"] },
    is_nullable => 0,
  },
  "tally",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "action",
  {
    data_type => "enum",
    default_value => "search",
    extra => {
          list => [
                "search",
                "view",
                "add",
                "update",
                "delete",
                "loiter",
                "afk",
                "login",
                "logout",
                "log",
              ],
        },
    is_nullable => 0,
  },
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
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "description",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</alid>

=back

=cut

__PACKAGE__->set_primary_key("alid");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-06-08 20:43:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3i716l1mpz2VdOVzTTmR1A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
