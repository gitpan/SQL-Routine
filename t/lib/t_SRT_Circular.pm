#!perl

use 5.008001; use utf8; use strict; use warnings;

# This module is used when testing SQL::Routine.
# These tests check that circular reference creation can be blocked.

package # hide this class name from PAUSE indexer
t_SRT_Circular;

######################################################################

sub test_circular_ref_prevention {
	my (undef, $class) = @_;

	my $model = $class->new_container();
	$model->auto_set_node_ids( 1 );

	my $vw1 = $model->build_node( 'view', 'foo' );
	my $vw2 = $vw1->build_child_node( 'view', 'bar' );
	my $vw3 = $vw2->build_child_node( 'view', 'bz' );

	my $test1_passed = 0;
	my $test2_passed = 0;
	eval {
		$vw2->set_primary_parent_attribute( $vw3 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF' ) {
				$test1_passed = 1;
			}
		}
	}
	eval {
		$vw2->set_primary_parent_attribute( $vw2 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF' ) {
				$test2_passed = 1;
			}
		}
	}

	$model->destroy();

	return( $test1_passed, $test2_passed );
}

######################################################################

1;
