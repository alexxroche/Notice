#!perl -T
#
# $Id: 01-load.t 52 2009-01-06 03:22:31Z jaldhar $
#
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok('Notice');
}

diag(
    "Testing Notice $Notice::VERSION, Perl $], $^X"
);
