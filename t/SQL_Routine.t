#!perl

use 5.008001; use utf8; use strict; use warnings;

BEGIN { $| = 1; print "1..20\n"; }

######################################################################
# First ensure the modules to test will compile, are correct versions:

use lib 't/lib';
use t_SRT_Verbose;
use t_SRT_Terse;
use t_SRT_Abstract;
use SQL::Routine '0.56';
use SQL::Routine::L::en '0.26';

######################################################################
# Here are some utility methods:

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

my $test_num = 0;

sub result {
	my ($worked, $detail) = @_;
	$test_num++;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");
	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub error_to_string {
	my ($message) = @_;
	my $translator = Locale::KeyedText->new_translator( ['SQL::Routine::L::'], ['en'] );
	my $user_text = $translator->translate_message( $message );
	unless( $user_text ) {
		return ref($message) ? "internal error: can't find user text for a message: ".
			$message->as_string()." ".$translator->as_string() : $message;
	}
	return $user_text;
}

######################################################################
# Now perform the actual tests:

message( "START TESTING SQL::Routine - Circular Ref Prevention" );
message( "  Test that circular reference creation can be blocked." );

######################################################################

eval {
	my $model = SQL::Routine->new_container();
	$model->auto_set_node_ids( 1 );

	my $vw1 = $model->build_node( 'view', 'foo' );
	my $vw2 = $vw1->build_child_node( 'view', 'bar' );
	my $vw3 = $vw2->build_child_node( 'view', 'bz' );

	my $test1_passed = 0;
	eval {
		$vw2->set_primary_parent_attribute( $vw3 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF' ) {
				$test1_passed = 1;
			}
		}
		$test1_passed or die $exception;
	}
	result( $test1_passed, "prevent creation of circular refs - parent is child" );

	my $test2_passed = 0;
	eval {
		$vw2->set_primary_parent_attribute( $vw2 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF' ) {
				$test2_passed = 1;
			}
		}
		$test2_passed or die $exception;
	}
	result( $test2_passed, "prevent creation of circular refs - parent is self" );

	$model->destroy();
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - Circular Ref Prevention" );
message( "START TESTING SQL::Routine - t_SRT_Verbose" );
message( "  Test model construction using verbose standard interface." );

######################################################################

eval {
	message( "First create the Container object that will be populated ..." );

	my $model = SQL::Routine->new_container();
	result( ref($model) eq 'SQL::Routine::Container', "creation of Container object" );

	message( "Now create a set of Nodes in the Container ..." );

	t_SRT_Verbose->populate_model( $model );
	result( 1, "creation of Node objects" );

	message( "Now see if deferrable constraints are valid ..." );

	$model->assert_deferrable_constraints();
	result( 1, "assert all deferrable constraints" );

	message( "Now see if the NID-based output is correct ..." );

	my $expected_output = t_SRT_Verbose->expected_model_nid_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects (NID)" );

	message( "Now see if the SID-based output is correct ..." );

	my $expected_output2 = t_SRT_Verbose->expected_model_sid_xml_output();
	my $actual_output2 = $model->get_all_properties_as_xml_str( 1 );
	result( $actual_output2 eq $expected_output2, "verify serialization of objects (SID)" );

	message( "Now destroy the objects ..." );

	$model->destroy();
	result( (keys %{$model}) eq '0', "destruction of all objects" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - t_SRT_Verbose" );
message( "START TESTING SQL::Routine - t_SRT_Terse" );
message( "  Test model construction using terse wrapper interface." );

######################################################################

eval {
	message( "First create the Container object that will be populated ..." );

	my $model = SQL::Routine->new_container();
	result( ref($model) eq 'SQL::Routine::Container', "creation of Container object" );

	message( "Now create a set of Nodes in the Container ..." );

	$model->auto_assert_deferrable_constraints( 1 ); # also done here to help with debugging
	t_SRT_Terse->populate_model( $model );
	result( 1, "creation of Node objects" );

	message( "Now see if deferrable constraints are valid ..." );

	$model->assert_deferrable_constraints();
	result( 1, "assert all deferrable constraints" );

	message( "Now see if the NID-based output is correct ..." );

	my $expected_output = t_SRT_Terse->expected_model_nid_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects (NID)" );

	message( "Now see if the SID-based output is correct ..." );

	my $expected_output2 = t_SRT_Terse->expected_model_sid_xml_output();
	my $actual_output2 = $model->get_all_properties_as_xml_str( 1 );
	result( $actual_output2 eq $expected_output2, "verify serialization of objects (SID)" );

	message( "Now destroy the objects ..." );

	$model->destroy();
	result( (keys %{$model}) eq '0', "destruction of all objects" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - t_SRT_Terse" );
message( "START TESTING SQL::Routine - t_SRT_Abstract" );
message( "  Test model construction using abstract wrapper interface." );

######################################################################

eval {
	message( "First create the Container object that will be populated ..." );

	my $model = SQL::Routine->new_container();
	result( ref($model) eq 'SQL::Routine::Container', "creation of Container object" );

	message( "Now create a set of Nodes in the Container ..." );

	$model->auto_assert_deferrable_constraints( 1 ); # also done here to help with debugging
	$model->auto_set_node_ids( 1 );
	$model->may_match_surrogate_node_ids( 1 );
	t_SRT_Abstract->populate_model( $model );
	result( 1, "creation of Node objects" );

	message( "Now see if deferrable constraints are valid ..." );

	$model->assert_deferrable_constraints();
	result( 1, "assert all deferrable constraints" );

	message( "Now see if the NID-based output is correct ..." );

	my $expected_output = t_SRT_Abstract->expected_model_nid_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects (NID)" );

	message( "Now see if the SID-based output is correct ..." );

	my $expected_output2 = t_SRT_Abstract->expected_model_sid_xml_output();
	my $actual_output2 = $model->get_all_properties_as_xml_str( 1 );
	result( $actual_output2 eq $expected_output2, "verify serialization of objects (SID)" );

	message( "Now destroy the objects ..." );

	$model->destroy();
	result( (keys %{$model}) eq '0', "destruction of all objects" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - t_SRT_Abstract" );

######################################################################

1;
