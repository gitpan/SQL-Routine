#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More 0.47;

plan( 'tests' => 17 );

use lib 't/lib';
use t_SRT_Util;
use SQL::Routine;
use SQL::Routine::L::en;

t_SRT_Util->message( 'Test that Containers don\'t allow changes when read-only.' );

eval {
	my $model = SQL::Routine->new_container();
	is( $model->is_read_only(), 0, "brand new Container's RO is false" );

	$model->auto_set_node_ids( 1 );
	pass( "allow auto-set prop change when Container writable (p1)" );
	is( $model->auto_set_node_ids(), 1, "allow auto-set prop change when Container writable (p2)" );
	my $sdt1 = $model->build_node( 'scalar_data_type', 'foo' );
	pass( "allow new Node build when Container writable" );
	$sdt1->set_enumerated_attribute( 'base_type', 'NUM_INT' );
	pass( "allow held Node attr change when Container writable (p1)" );
	is( $sdt1->get_enumerated_attribute( 'base_type' ), 'NUM_INT', "allow held Node attr change when Container writable (p2)" );
	$sdt1->delete_node();
	pass( "allow Node removal when Container writable" );
	SQL::Routine->new_node( $model, 'table_field', 4 );
	pass( "allow Node addition when Container writable" );

	$sdt1 = $model->build_node( 'scalar_data_type', 'foo' );
	$sdt1->set_enumerated_attribute( 'base_type', 'NUM_INT' );
	pass( "allow new identical Node build following first's deletion when Container writable" );

	is( $model->is_read_only( 1 ), 1, "set this Container's RO to true" );

	my $test1_passed = 0;
	eval {
		$model->auto_set_node_ids( 0 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_C_METH_ASS_READ_ONLY' ) {
				$test1_passed = 1;
			}
		}
	}
	ok( $test1_passed, "prevent auto-set prop change when Container read-only (p1)" );
	is( $model->auto_set_node_ids(), 1, "prevent auto-set prop change when Container read-only (p2)" );

	my $test2_passed = 0;
	eval {
		my $sdt2 = $model->build_node( 'scalar_data_type', 'bar' );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_C_METH_ASS_READ_ONLY' ) {
				$test2_passed = 1;
			}
		}
	}
	ok( $test2_passed, "prevent new Node build when Container read-only" );

	my $test3_passed = 0;
	eval {
		$sdt1->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_METH_ASS_READ_ONLY' ) {
				$test3_passed = 1;
			}
		}
	}
	ok( $test3_passed, "prevent held Node attr change when Container read-only (p1)" );
	is( $sdt1->get_enumerated_attribute( 'base_type' ), 'NUM_INT', "prevent held Node attr change when Container read-only (p2)" );

	my $test4_passed = 0;
	eval {
		$sdt1->delete_node();
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_METH_ASS_READ_ONLY' ) {
				$test4_passed = 1;
			}
		}
	}
	ok( $test4_passed, "prevent Node removal when Container read-only" );

	my $test5_passed = 0;
	eval {
		SQL::Routine->new_node( $model, 'table_index', 14 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_METH_ASS_READ_ONLY' ) {
				$test5_passed = 1;
			}
		}
	}
	ok( $test5_passed, "prevent Node addition when Container read-only" );
};
$@ and fail( "TESTS ABORTED: ".t_SRT_Util->error_to_string( $@ ) );

1;
