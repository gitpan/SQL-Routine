# This module is used when testing SQL::Routine.
# These tests check that circular reference creation can be blocked.

package # hide this class name from PAUSE indexer
t_SRT_Circular;
use strict;
use warnings;

######################################################################

sub make_a_node {
	my ($node_type, $model) = @_;
	my $node = $model->new_node( $node_type );
	$node->set_node_id( $model->get_next_free_node_id( $node_type ) );
	$node->put_in_container( $model );
	return( $node );
}

sub make_a_child_node {
	my ($node_type, $pp_node, $pp_attr) = @_;
	my $container = $pp_node->get_container();
	my $node = $pp_node->new_node( $node_type );
	$node->set_node_id( $container->get_next_free_node_id( $node_type ) );
	$node->put_in_container( $container );
	$node->set_node_ref_attribute( $pp_attr, $pp_node );
	$node->set_pp_node_attribute_name( $pp_attr );
	return( $node );
}

######################################################################

sub test_circular_ref_prevention {
	my (undef, $class) = @_;
	my $model = $class->new_container();

	my $catalog_bp = make_a_node( 'catalog', $model );
	$catalog_bp->set_literal_attribute( 'si_name', 'The Catalog Blueprint' );
	my $owner = make_a_child_node( 'owner', $catalog_bp, 'pp_catalog' );
	my $schema = make_a_child_node( 'schema', $catalog_bp, 'pp_catalog' );
	$schema->set_literal_attribute( 'si_name', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	my $vw1 = make_a_child_node( 'view', $schema, 'pp_schema' );
	$vw1->set_literal_attribute( 'si_name', 'foo' );
	$vw1->set_enumerated_attribute( 'view_type', 'UPDATE' );

	my $vw2 = make_a_child_node( 'view', $vw1, 'pp_view' );
	$vw2->set_literal_attribute( 'si_name', 'bar' );
	$vw2->set_enumerated_attribute( 'view_type', 'UPDATE' );

	my $vw3 = make_a_child_node( 'view', $vw2, 'pp_view' );
	$vw3->set_literal_attribute( 'si_name', 'bz' );
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
