#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 15 );

use lib 't/lib';
use t_SRT_Util;
use t_SRT_Terse;
use SQL::Routine;
use SQL::Routine::L::en;

t_SRT_Util->message( 'Test that SRT models can be easily cloned.' );

eval {
	my $model = SQL::Routine->new_container();
	t_SRT_Terse->populate_model( $model );
	my $props_nid = $model->get_all_properties();
	my $props_sidL = $model->get_all_properties( 1 );
	my $props_sidS = $model->get_all_properties( 1, 1 );

	t_SRT_Util->message( 'NID: First build populated Container object from an original model\'s NID dump...' );

	my $nid_model = SQL::Routine->build_container( $props_nid, 1 );
	isa_ok( $nid_model, 'SQL::Routine::Container', "building Container and Nodes" );

	t_SRT_Util->message( 'NID: Now see if deferrable constraints are valid ...' );

	$nid_model->assert_deferrable_constraints();
	pass( "assert all deferrable constraints" );

	t_SRT_Util->message( 'NID: Now see if the NID-based output is correct ...' );

	my $nid_expected_output = t_SRT_Terse->expected_model_nid_xml_output();
	my $nid_actual_output = $nid_model->get_all_properties_as_xml_str();
	is( $nid_actual_output, $nid_expected_output, "verify serialization of objects (NID)" );

	t_SRT_Util->message( 'NID: Now see if the SID-long-based output is correct ...' );

	my $nid_expected_output2 = t_SRT_Terse->expected_model_sid_long_xml_output();
	my $nid_actual_output2 = $nid_model->get_all_properties_as_xml_str( 1 );
	is( $nid_actual_output2, $nid_expected_output2, "verify serialization of objects (SID long)" );

	t_SRT_Util->message( 'NID: Now see if the SID-short-based output is correct ...' );

	my $nid_expected_output3 = t_SRT_Terse->expected_model_sid_short_xml_output();
	my $nid_actual_output3 = $nid_model->get_all_properties_as_xml_str( 1, 1 );
	is( $nid_actual_output3, $nid_expected_output3, "verify serialization of objects (SID short)" );

	t_SRT_Util->message( 'SID-L: First build populated Container object from an original model\'s SID-long dump...' );

	my $sidL_model = SQL::Routine->build_container( $props_sidL, 1, undef, 1 );
	isa_ok( $sidL_model, 'SQL::Routine::Container', "building Container and Nodes" );

	t_SRT_Util->message( 'SID-L: Now see if deferrable constraints are valid ...' );

	$sidL_model->assert_deferrable_constraints();
	pass( "assert all deferrable constraints" );

	t_SRT_Util->message( 'SID-L: Now see if the NID-based output is correct ...' );

	my $sidL_expected_output = t_SRT_Terse->expected_model_nid_xml_output();
	my $sidL_actual_output = $sidL_model->get_all_properties_as_xml_str();
	is( $sidL_actual_output, $sidL_expected_output, "verify serialization of objects (NID)" );

	t_SRT_Util->message( 'SID-L: Now see if the SID-long-based output is correct ...' );

	my $sidL_expected_output2 = t_SRT_Terse->expected_model_sid_long_xml_output();
	my $sidL_actual_output2 = $sidL_model->get_all_properties_as_xml_str( 1 );
	is( $sidL_actual_output2, $sidL_expected_output2, "verify serialization of objects (SID long)" );

	t_SRT_Util->message( 'SID-L: Now see if the SID-short-based output is correct ...' );

	my $sidL_expected_output3 = t_SRT_Terse->expected_model_sid_short_xml_output();
	my $sidL_actual_output3 = $sidL_model->get_all_properties_as_xml_str( 1, 1 );
	is( $sidL_actual_output3, $sidL_expected_output3, "verify serialization of objects (SID short)" );

	t_SRT_Util->message( 'SID-S: First build populated Container object from an original model\'s SID-long dump...' );

	my $sidS_model = SQL::Routine->build_container( $props_sidS, 1, undef, 1 );
	isa_ok( $sidS_model, 'SQL::Routine::Container', "building Container and Nodes" );

	t_SRT_Util->message( 'SID-S: Now see if deferrable constraints are valid ...' );

	$sidS_model->assert_deferrable_constraints();
	pass( "assert all deferrable constraints" );

	t_SRT_Util->message( 'SID-S: Now see if the NID-based output is correct ...' );

	my $sidS_expected_output = t_SRT_Terse->expected_model_nid_xml_output();
	my $sidS_actual_output = $sidS_model->get_all_properties_as_xml_str();
	is( $sidS_actual_output, $sidS_expected_output, "verify serialization of objects (NID)" );

	t_SRT_Util->message( 'SID-S: Now see if the SID-long-based output is correct ...' );

	my $sidS_expected_output2 = t_SRT_Terse->expected_model_sid_long_xml_output();
	my $sidS_actual_output2 = $sidS_model->get_all_properties_as_xml_str( 1 );
	is( $sidS_actual_output2, $sidS_expected_output2, "verify serialization of objects (SID long)" );

	t_SRT_Util->message( 'SID-S: Now see if the SID-short-based output is correct ...' );

	my $sidS_expected_output3 = t_SRT_Terse->expected_model_sid_short_xml_output();
	my $sidS_actual_output3 = $sidS_model->get_all_properties_as_xml_str( 1, 1 );
	is( $sidS_actual_output3, $sidS_expected_output3, "verify serialization of objects (SID short)" );
};
$@ and fail( "TESTS ABORTED: ".t_SRT_Util->error_to_string( $@ ) );

1;
