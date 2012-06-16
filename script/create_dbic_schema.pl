#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Config::Auto;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
$| = 1;

my $config = Config::Auto::parse( File::Spec->catfile("..","config","config.pl"), format => "perl" );

make_schema_at(
        'Notice::DB',
        { debug => 1,relationships => 1, 
        # use_namespaces => 1, # this is now the default
        # moniker_map => { people => 'People' }, #we probably want this
          dump_directory => File::Spec->catdir("$Bin","..","lib" )
        },
        [ $config->{db_dsn}, $config->{db_user}, $config->{db_pw} ],
);

__END__

=head1 NAME

create_dbic_schema.pl - Template DBIC schema generator for Notice

=head1 SYNOPSIS

	~/dev/MyApp1$ perl script/create_dbic_schema.pl 
	Dumping manual schema for DB to directory ~/dev/MyApp1/lib/MyApp1/DB ...
	Schema dump completed.

The generated files, using the example database would look like this:

    ~/dev/MyApp1$ find lib/MyApp1/ | grep DB
    lib/MyApp1/DB
    lib/MyApp1/DB/Result
    lib/MyApp1/DB/Result/Orders.pm
    lib/MyApp1/DB/Result/Customer.pm
    lib/MyApp1/DB.pm


=head1 AUTHOR

Gordon Van Amburg of CGI::Application::Structured

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
