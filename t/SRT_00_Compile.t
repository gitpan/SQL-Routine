#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 8 );

use_ok( 'SQL::Routine' );
cmp_ok( $SQL::Routine::VERSION, '==', 0.61, "SQL::Routine is the correct version" );

use_ok( 'SQL::Routine::L::en' );
cmp_ok( $SQL::Routine::L::en::VERSION, '==', 0.30, "SQL::Routine::L::en is the correct version" );

use lib 't/lib';
use_ok( 't_SRT_Util' );
use_ok( 't_SRT_Verbose' );
use_ok( 't_SRT_Terse' );
use_ok( 't_SRT_Abstract' );

1;
