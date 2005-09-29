#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;

plan( 'tests' => 2 );

use lib 't/lib';
use t_SRT_Util;
use SQL::Routine;

t_SRT_Util->message( 'Test that circular reference creation is always blocked.' );

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
    if (my $exception = $@) {
        if (ref $exception and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' )) {
            if ($exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF') {
                $test1_passed = 1;
            }
        }
        die $exception
            if !$test1_passed;
    }
    ok( $test1_passed, 'prevent creation of circular refs - parent is child' );

    my $test2_passed = 0;
    eval {
        $vw2->set_primary_parent_attribute( $vw2 );
    };
    if (my $exception = $@) {
        if (ref $exception and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' )) {
            if ($exception->get_message_key() eq 'SRT_N_SET_PP_AT_CIRC_REF') {
                $test2_passed = 1;
            }
        }
        die $exception
            if !$test2_passed;
    }
    ok( $test2_passed, 'prevent creation of circular refs - parent is self' );
};
$@ and fail( 'TESTS ABORTED: ' . t_SRT_Util->error_to_string( $@ ) );

1;
