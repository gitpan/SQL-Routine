use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'SQL::Routine',
	VERSION_FROM => 'lib/SQL/Routine.pm', # finds $VERSION
	PREREQ_PM => {
		'Locale::KeyedText' => '1.00',
	},
);
