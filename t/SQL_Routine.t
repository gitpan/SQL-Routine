#!perl

use 5.008001; use utf8; use strict; use warnings;

BEGIN { $| = 1; print "1..11\n"; }

######################################################################
# First ensure the modules to test will compile, are correct versions:

use lib 't/lib';
use t_SRT_Circular;
use t_SRT_Verbose;
use t_SRT_Terse;
use t_SRT_Abstract;
use SQL::Routine '0.54';
use SQL::Routine::L::en '0.24';

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
		return( ref($message) ? "internal error: can't find user text for a message: ".
			$message->as_string()." ".$translator->as_string() : $message );
	}
	return( $user_text );
}

######################################################################
# Now perform the actual tests:

message( "START TESTING SQL::Routine - t_SRT_Circular" );
message( "  Test that circular reference creation can be blocked." );

######################################################################

eval {
	my ($test1_passed, $test2_passed) = 
		t_SRT_Circular->test_circular_ref_prevention( 'SQL::Routine' );
	result( $test1_passed, "prevent creation of circular refs - parent is child" );
	result( $test2_passed, "prevent creation of circular refs - parent is self" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - t_SRT_Circular" );
message( "START TESTING SQL::Routine - t_SRT_Verbose" );
message( "  Test model construction using verbose standard interface." );

######################################################################

eval {
	message( "First populate some objects ..." );

	my $model = t_SRT_Verbose->create_and_populate_model( 'SQL::Routine' );
	result( ref($model) eq 'SQL::Routine::Container', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output = t_SRT_Verbose->expected_model_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects" );

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
	message( "First populate some objects ..." );

	my $model = t_SRT_Terse->create_and_populate_model( 'SQL::Routine' );
	result( ref($model) eq 'SQL::Routine::Container', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output = t_SRT_Terse->expected_model_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects" );

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
	message( "First populate some objects ..." );

	my $model = t_SRT_Abstract->create_and_populate_model( 'SQL::Routine' );
	result( ref($model) eq 'SQL::Routine::Container', "creation of all objects" );

	message( "Now see if the output is correct ..." );

	my $expected_output = t_SRT_Abstract->expected_model_xml_output();
	my $actual_output = $model->get_all_properties_as_xml_str();
	result( $actual_output eq $expected_output, "verify serialization of objects" );

	message( "Now destroy the objects ..." );

	$model->destroy();
	result( (keys %{$model}) eq '0', "destruction of all objects" );
};
$@ and result( 0, "TESTS ABORTED: ".error_to_string( $@ ) );

######################################################################

message( "DONE TESTING SQL::Routine - t_SRT_Abstract" );

######################################################################

1;
