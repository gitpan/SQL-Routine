#!perl

use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	=> 'SQL::Routine',
	VERSION_FROM => 'lib/SQL/Routine.pm', # finds $VERSION
	PREREQ_PM => {
		'Locale::KeyedText' => '1.02',
	},
);

1;
