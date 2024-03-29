#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;

plan( 'tests' => 27 );

use_ok( 'SQL::Routine' );
is( $SQL::Routine::VERSION, qv('0.70.3'), 'SQL::Routine is the correct version' );

use_ok( 'SQL::Routine::L::en' );
is( $SQL::Routine::L::en::VERSION, qv('0.38.2'), 'SQL::Routine::L::en is the correct version' );

use lib 't/lib';

use_ok( 't_SRT_Util' );
can_ok( 't_SRT_Util', 'message' );
can_ok( 't_SRT_Util', 'error_to_string' );

use_ok( 't_SRT_Verbose' );
can_ok( 't_SRT_Verbose', 'populate_model' );
can_ok( 't_SRT_Verbose', 'expected_model_nid_xml_output' );
can_ok( 't_SRT_Verbose', 'expected_model_sid_long_xml_output' );
can_ok( 't_SRT_Verbose', 'expected_model_sid_short_xml_output' );

use_ok( 't_SRT_Terse' );
can_ok( 't_SRT_Terse', 'populate_model' );
can_ok( 't_SRT_Terse', 'expected_model_nid_xml_output' );
can_ok( 't_SRT_Terse', 'expected_model_sid_long_xml_output' );
can_ok( 't_SRT_Terse', 'expected_model_sid_short_xml_output' );

use_ok( 't_SRT_Abstract' );
can_ok( 't_SRT_Abstract', 'populate_model' );
can_ok( 't_SRT_Abstract', 'expected_model_nid_xml_output' );
can_ok( 't_SRT_Abstract', 'expected_model_sid_long_xml_output' );
can_ok( 't_SRT_Abstract', 'expected_model_sid_short_xml_output' );

use_ok( 't_SRT_Synopsis' );
can_ok( 't_SRT_Synopsis', 'populate_model' );
can_ok( 't_SRT_Synopsis', 'expected_model_nid_xml_output' );
can_ok( 't_SRT_Synopsis', 'expected_model_sid_long_xml_output' );
can_ok( 't_SRT_Synopsis', 'expected_model_sid_short_xml_output' );

1;
