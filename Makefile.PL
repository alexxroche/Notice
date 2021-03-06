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
        'Cwd' => 0,
        'Carp' => 0,
        'JSON::XS' => 0,
        'IO::All' => 0,
        'DateTime' => 0,
        'Try::Tiny' => 0,
        'Test::More' => 0,
        'Date::Calc' => 0,
        'Data::ICal' => 0.18,
        'Data::UUID' => 1.0602,
        'Crypt::CBC' => 2.30,
        'Data::Page' => 0,
        'Data::UUID' => 0,
        'File::Copy' => 0,
        'File::Find' => 0,
        'File::Path' => 0,
        'File::Type' => 0,
        'MIME::Head' => 0,
        'MIME::Body' => 0,
        'MIME::Entity' => 0,
        'Time::HiRes' => 0,
        'HTML::Clean' => 0,         # less PREREQ_PM and more REC_PM
        'DBIx::Class' => 0.08115,
        'Digest::MD5' => 0,
        'Digest::SHA1' => 0,
        'Data::Dumper' => 0,
        'Scalar::Util' => 0,
        'MIME::Base64' => 0,
        'Crypt::Rijndael' => 1.08,
        'CGI::Application' => 4.3,
        'HTML::FormatText' => 0,
        'FCGI::ProcManager' => 0,
        'DateTime::TimeZone' => 0,
        'String::Clean::XSS' => 0,
        'DBIx::Class::Schema' => 0,
        'Email::Sender::Simple' => 0,
        'HTML::Selector::XPath' => 0,
        'Email::Simple::Creator' => 0,
        'Template::Multilingual' => 0,
        'DateTime::Format::MySQL' => 0,
        'Email::MIME::CreateHTML' => 0,
        'Data::ICal::Entry::Event' => 0,
        'CGI::Application::Server' => 0.01,
        'HTML::TreeBuilder::XPath' => 0,
        'CGI::Application::Dispatch' => 0,
        'DBIx::Class::Schema::Loader' => 0.04006,
        'CGI::Application::Plugin::TT' => 0,
        'CGI::Application::Plugin::DBH' => 0,
        'CGI::Application::Plugin::Stream' => 0,
        'CGI::Application::Plugin::Session' => 0,
        'CGI::Application::Plugin::Forward' => 0,
        'Template::Plugin::Calendar::Simple' => 0,
        'CGI::Application::Plugin::Redirect' => 0,
        'CGI::Application::Plugin::ConfigAuto' => 0,
        'CGI::Application::Plugin::AutoRunmode' => 0.18,
        'CGI::Application::Plugin::DBIC::Schema' => 0,
        'CGI::Application::Plugin::Authentication' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Notice-*' },
);
