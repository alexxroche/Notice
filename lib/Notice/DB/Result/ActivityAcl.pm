use utf8;
package Notice::DB::Result::ActivityAcl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Notice::DB::Result::ActivityAcl - Notice internal security

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<activity_acl>

=cut

__PACKAGE__->table("activity_acl");

=head1 ACCESSORS

=head2 aaid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

people.pe_id

=head2 group

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

group.gr_id

=head2 acid

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

account.ac_id

=head2 period

  data_type: 'enum'
  default_value: 'S'
  extra: {list => ["S","M","H","d","w","m","y"]}
  is_nullable: 0

=head2 tally

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

how many

=head2 action

  data_type: 'enum'
  default_value: 'search'
  extra: {list => ["search","view","add","update","delete","loiter","afk","login","logout"]}
  is_nullable: 0

what they did

=head2 object

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

action granularity; match act_log.desc

=head2 type

  data_type: 'enum'
  default_value: 'hard'
  extra: {list => ["hard","soft","silent"]}
  is_nullable: 0

what type of limit

=head2 report

  data_type: 'enum'
  default_value: 'lock_out'
  extra: {list => ["lock_out","log_off","email_manager","email_user","warn_popup","warn_embeded","none","lockout_and_email_manager"]}
  is_nullable: 0

How the system should react

=head2 description

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

The visual warning to alert the user or manager

=cut

__PACKAGE__->add_columns(
  "aaid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "group",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "acid",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "period",
  {
    data_type => "enum",
    default_value => "S",
    extra => { list => ["S", "M", "H", "d", "w", "m", "y"] },
    is_nullable => 0,
  },
  "tally",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
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
              ],
        },
    is_nullable => 0,
  },
  "object",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "type",
  {
    data_type => "enum",
    default_value => "hard",
    extra => { list => ["hard", "soft", "silent"] },
    is_nullable => 0,
  },
  "report",
  {
    data_type => "enum",
    default_value => "lock_out",
    extra => {
          list => [
                "lock_out",
                "log_off",
                "email_manager",
                "email_user",
                "warn_popup",
                "warn_embeded",
                "none",
                "lockout_and_email_manager",
              ],
        },
    is_nullable => 0,
  },
  "description",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aaid>

=back

=cut

__PACKAGE__->set_primary_key("aaid");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-06-08 20:43:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:407XEEYd3hkW1UugKoL1mg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
