#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 6 );

use lib 't/lib';
use t_SRT_Util;
use t_SRT_Verbose;
use SQL::Routine;

t_SRT_Util->message( 'Test model construction using verbose standard interface.' );

eval {
	t_SRT_Util->message( 'First create the Container object that will be populated ...' );

	my $model = SQL::Routine->new_container();
	isa_ok( $model, 'SQL::Routine::Container', "creation of Container object" );

	t_SRT_Util->message( 'Now create a set of Nodes in the Container ...' );

	t_SRT_Verbose->populate_model( $model );
	pass( "creation of Node objects" );

	t_SRT_Util->message( 'Now see if deferrable constraints are valid ...' );

	$model->assert_deferrable_constraints();
	pass( "assert all deferrable constraints" );

	t_SRT_Util->message( 'Now see if the NID-based output is correct ...' );

	my $expected_output = t_SRT_Verbose->expected_model_nid_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	is( $actual_output, $expected_output, "verify serialization of objects (NID)" );

	t_SRT_Util->message( 'Now see if the SID-long-based output is correct ...' );

	my $expected_output2 = t_SRT_Verbose->expected_model_sid_long_xml_output();
	my $actual_output2 = $model->get_all_properties_as_xml_str( 1 );
	is( $actual_output2, $expected_output2, "verify serialization of objects (SID long)" );

	t_SRT_Util->message( 'Now see if the SID-short-based output is correct ...' );

	my $expected_output3 = t_SRT_Verbose->expected_model_sid_short_xml_output();
	my $actual_output3 = $model->get_all_properties_as_xml_str( 1, 1 );
	is( $actual_output3, $expected_output3, "verify serialization of objects (SID short)" );
};
$@ and fail( "TESTS ABORTED: ".t_SRT_Util->error_to_string( $@ ) );

1;
