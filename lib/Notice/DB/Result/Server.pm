package Notice::DB::Result::Server;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Notice::DB::Result::Server

=cut

__PACKAGE__->table("servers");

=head1 ACCESSORS

=head2 se_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 se_operatingsystem

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 se_macaddress

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 se_cpu

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 se_aes

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 se_memory

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 se_harddiskdrives

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 se_asid

  data_type: 'integer'
  is_nullable: 1

=head2 se_uuid

  data_type: 'char'
  is_nullable: 1
  size: 36

=head2 se_trust_distance

  data_type: 'integer'
  is_nullable: 1

=head2 se_function

  data_type: 'enum'
  default_value: 'all'
  extra: {list => ["nothing","not sure","dev","email","web","emailWeb","database","emailwebdb","sign","HR","accounting","all"]}
  is_nullable: 0

=head2 se_acid

  data_type: 'integer'
  is_nullable: 1

=head2 se_sslid

  data_type: 'integer'
  is_nullable: 1

=head2 se_type

  data_type: 'enum'
  default_value: 'node'
  extra: {list => ["node","peer","master"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "se_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "se_operatingsystem",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "se_macaddress",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "se_cpu",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "se_aes",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "se_memory",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "se_harddiskdrives",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "se_asid",
  { data_type => "integer", is_nullable => 1 },
  "se_uuid",
  { data_type => "char", is_nullable => 1, size => 36 },
  "se_trust_distance",
  { data_type => "integer", is_nullable => 1 },
  "se_function",
  {
    data_type => "enum",
    default_value => "all",
    extra => {
      list => [
        "nothing",
        "not sure",
        "dev",
        "email",
        "web",
        "emailWeb",
        "database",
        "emailwebdb",
        "sign",
        "HR",
        "accounting",
        "all",
      ],
    },
    is_nullable => 0,
  },
  "se_acid",
  { data_type => "integer", is_nullable => 1 },
  "se_sslid",
  { data_type => "integer", is_nullable => 1 },
  "se_type",
  {
    data_type => "enum",
    default_value => "node",
    extra => { list => ["node", "peer", "master"] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("se_id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-24 17:01:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WZJLggdXtYdFpAom4z2phQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
