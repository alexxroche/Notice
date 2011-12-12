package Notice::DB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-23 16:12:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IjVWjg092psDJNcNjDnjnA

our $VERSION = 0.01; # version of the database schema, not Notice itself.

1;

__END__

=head1 NAME

Notice::DB

=head1 SYNOPSIS

The database module for Notice

=head1 DESCRIPTION

This module acts as the base class for Database actions

=head1 METHODS

=head3 load_namespaces

This loads the DBIx::Class name space

=cut

=pod

=cut

# TODO: Private methods go here. Start their names with an _ so they are skipped
# by Pod::Coverage.

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug- at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Notice>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Application>

=head1 THANKS

Gordon Van Amburg for taking the right stand with CAS

=head1 AUTHOR

Alexx Roche, C<alexx@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0 or
the Artistic License.

See http://www.opensource.org/licenses/ for more information.

=cut

