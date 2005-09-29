#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'SQL::Routine',
    'VERSION_FROM' => 'lib/SQL/Routine.pm', # finds $VERSION
    'PREREQ_PM' => {
        'version' => 0,
        'only' => 0,
        'Scalar::Util' => 0,
        'List::Util' => 0,
        'List::MoreUtils' => '0.12',
        'Test::More' => 0, # but only for the test suite
        'Locale::KeyedText' => '1.6.0',
    },
);

1;
