# This module is used when testing SQL::Routine.
# These tests check that circular reference creation can be blocked.

package # hide this class name from PAUSE indexer
t_SRT_Circular;
use strict;
use warnings;

######################################################################

sub test_circular_ref_prevention {
	my (undef, $class) = @_;
	my $model = $class->new_container();
	$model->auto_set_node_ids( 1 );

	my $catalog_bp = $model->build_child_node( 'catalog', 'The Catalog Blueprint' );
	my $owner = $catalog_bp->build_child_node( 'owner' );
	my $schema = $catalog_bp->build_child_node( 'schema', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	my $vw1 = $schema->build_child_node( 'view', 'foo' );
	$vw1->set_enumerated_attribute( 'view_type', 'UPDATE' );

	my $vw2 = $vw1->build_child_node( 'view', 'bar' );
	$vw2->set_enumerated_attribute( 'view_type', 'UPDATE' );

	my $vw3 = $vw2->build_child_node( 'view', 'bz' );
	$vw3->set_enumerated_attribute( 'view_type', 'UPDATE' );

	my $test1_passed = 0;
	my $test2_passed = 0;
	eval {
		$vw2->set_node_ref_attribute( 'pp_view', $vw3 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_NREF_AT_CIRC_REF' ) {
				$test1_passed = 1;
			}
		}
	}
	eval {
		$vw3->clear_pp_node_attribute_name();
		$vw2->set_node_ref_attribute( 'pp_view', $vw3 );
		$vw3->set_pp_node_attribute_name( 'pp_view' );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_PP_NODE_ATNM_CIRC_REF' ) {
				$test2_passed = 1;
			}
		}
	}

	$model->assert_deferrable_constraints();
	$model->destroy();

	return( $test1_passed, $test2_passed );
}

######################################################################

1;
