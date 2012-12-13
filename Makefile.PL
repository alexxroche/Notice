use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Notice',
    AUTHOR              => q{Alexx Roche <notice-dev@alexx.net>},
    VERSION_FROM        => 'lib/Notice.pm',
    ABSTRACT_FROM       => 'lib/Notice.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
or the Artistic License, Version 2.0.

See http://www.opensource.org/licenses/ for more information.
')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Date::Calc' => 0,
        'Crypt::CBC' => 2.30,
        'Data::Page' => 0,
        'Data::UUID' => 0,
        'Test::More' => 0,
        'DBIx::Class' => 0.08115,
        'HTML::Clean' => 0,         # less PREREQ_PM and more REC_PM
        'Digest::MD5' => 0,
        'Digest::SHA1' => 0,
        'Data::Dumper' => 0,
        'MIME::Base64' => 0,
        'Crypt::Rijndael' => 1.08,
        'CGI::Application' => 0,
        'String::Clean::XSS' => 0,
        'DBIx::Class::Schema' => 0,
        'Template::Multilingual' => 0,
        'CGI::Application::Server' => 0.01,
        'CGI::Application::Dispatch' => 0,
        'DBIx::Class::Schema::Loader' => 0.04006,
        'CGI::Application::Plugin::TT' => 0,
        'CGI::Application::Plugin::DBH' => 0,
        'CGI::Application::Plugin::Session' => 0,
        'CGI::Application::Plugin::Forward' => 0,
        'CGI::Application::Plugin::Redirect' => 0,
        'Template::Plugin::Calendar::Simple' => 0,
        'CGI::Application::Plugin::ConfigAuto' => 0,
        'CGI::Application::Plugin::AutoRunmode' => 0.18,
        'CGI::Application::Plugin::DBIC::Schema' => 0,
        'CGI::Application::Plugin::Authentication' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Notice-*' },
);
