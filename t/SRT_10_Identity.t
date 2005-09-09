#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;

plan( 'tests' => 91 );

use lib 't/lib';
use t_SRT_Util;
use SQL::Routine;

t_SRT_Util->message( 'Test that we can identify when objects have storage in common.' );

t_SRT_Util->message( 'First create some initial Containers and Nodes.' );

my $contA1 = SQL::Routine->new_container();
isa_ok( $contA1, 'SQL::Routine::Container', 
    'contA1 = SQL::Routine.new_container() ret CI obj' );
my $nodeA1 = SQL::Routine->new_node( $contA1, 'scalar_data_type', 1 );
isa_ok( $nodeA1, 'SQL::Routine::Node', 
    'nodeA1 = SQL::Routine.new_node( contA1, \'scalar_data_type\', 1 ) ret NI obj' );
$nodeA1->set_attribute( 'si_name', 'foo' );
pass( 'nodeA1.set_attribute( \'si_name\', \'foo\' )' );
my $nodeA2 = SQL::Routine->new_node( $contA1, 'scalar_data_type_opt', 2 );
isa_ok( $nodeA2, 'SQL::Routine::Node', 
    'nodeA2 = SQL::Routine.new_node( contA1, \'scalar_data_type_opt\', 2 ) ret NI obj' );
$nodeA1->add_child_node( $nodeA2 );
pass( 'nodeA1.add_child_node( nodeA2 )' );
$nodeA2->set_attribute( 'si_value', 'bar' );
pass( 'nodeA2.set_attribute( \'si_name\', \'bar\' )' );

t_SRT_Util->message( 'Now a sanity check; "=" assignment results in 2 refs to same objects.' );

my $contB1 = $contA1;
is( $contB1, $contA1, 
    'following "contB1 = contA1", both vars hold same Container interface' );
my $nodeB1 = $nodeA1;
is( $nodeB1, $nodeA1, 
    'following "nodeB1 = nodeA1", both vars hold same Node interface' );

t_SRT_Util->message( 'Now a sanity check; obj.new_[c|n]*() gives diff interface and Storage objects.' );

my $contC1 = $contA1->new_container();
isa_ok( $contC1, 'SQL::Routine::Container', 
    'contC1 = contA1.new_container() ret CI obj' );
my $nodeC1 = $nodeA1->new_node( $contA1, 'scalar_data_type_opt', 3 );
isa_ok( $nodeC1, 'SQL::Routine::Node', 
    'nodeC1 = nodeA1.new_node( contA1, \'scalar_data_type_opt\', 3 ) ret NI obj' );
isnt( $contC1, $contA1, 
    'following "contC1 = contA1.new_container()", both vars hold diff Container interfaces' );
isnt( $nodeC1, $nodeA1, 
    'following "nodeC1 = nodeA1.new_node( ... )", both vars hold diff Node interfaces' );
isnt( $contC1->get_self_id(), $contA1->get_self_id(), 
    'both "contC1.get_self_id() and contA1.get_self_id()" hold diff ContainerStorages' );
isnt( $nodeC1->get_self_id(), $nodeA1->get_self_id(), 
    'both "nodeC1.get_self_id() and nodeA1.get_self_id()" hold diff NodeStorages' );

t_SRT_Util->message( 'Now confirm that obj.new_interface() gives diff interface but same Storage objects.' );

my $contD1 = $contA1->new_interface();
isa_ok( $contD1, 'SQL::Routine::Container', 
    'contD1 = contA1.new_interface() ret CI obj' );
my $nodeD1 = $nodeA1->new_interface();
isa_ok( $nodeD1, 'SQL::Routine::Node', 
    'nodeD1 = nodeA1.new_interface() ret NI obj' );
isnt( $contD1, $contA1, 
    'following "contD1 = contA1.new_interface()", both vars hold diff Container interfaces' );
isnt( $nodeD1, $nodeA1, 
    'following "nodeD1 = nodeA1.new_interface()", both vars hold diff Node interfaces' );
is( $contD1->get_self_id(), $contA1->get_self_id(), 
    'both "contD1.get_self_id() and contA1.get_self_id()" hold same ContainerStorage' );
is( $nodeD1->get_self_id(), $nodeA1->get_self_id(), 
    'both "nodeD1.get_self_id() and nodeA1.get_self_id()" hold same NodeStorage' );
isnt( $nodeD1->get_container(), $nodeA1->get_container(), 
    'both "nodeD1.get_container() and nodeA1.get_container()" hold diff Container interfaces' );
is( $nodeD1->get_container()->get_self_id(), $nodeA1->get_container()->get_self_id(), 
    'both "nodeD1.get_container().get_self_id() and nodeA1.get_container().get_self_id()" hold same ContainerStorage' );
is( $nodeA1->get_container(), $contA1, 
    'both "nodeA1.get_container() and contA1" hold same Container interface' );
isnt( $nodeD1->get_container(), $contD1, 
    'both "nodeD1.get_container() and contD1" hold diff Container interfaces' );
is( $nodeD1->get_container()->get_self_id(), $contD1->get_self_id(), 
    'both "nodeD1.get_container().get_self_id() and contD1.get_self_id()" hold same ContainerStorage' );

t_SRT_Util->message( 'Now confirm that C.get_child_nodes() returns new NI with the same CI.' );

my $nodeE1 = $contA1->get_child_nodes()->[0];
isa_ok( $nodeE1, 'SQL::Routine::Node', 
    'nodeE1 = contA1.get_child_nodes().[0] ret NI obj' );
isnt( $nodeE1, $nodeA1,
    'both nodeE1 and nodeA1 hold diff Node interfaces' );
is( $nodeE1->get_self_id(), $nodeA1->get_self_id(),
    'both nodeE1.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeE1->get_container(), $nodeA1->get_container(),
    'both nodeE1.get_container() and nodeA1.get_container() hold same Container interface' );
my $nodeE1b = $contA1->get_child_nodes()->[0];
isa_ok( $nodeE1b, 'SQL::Routine::Node', 
    'nodeE1b = contA1.get_child_nodes().[0] (a second identical invocation) ret NI obj' );
isnt( $nodeE1b, $nodeA1,
    'both nodeE1b and nodeA1 hold diff Node interfaces' );
is( $nodeE1b->get_self_id(), $nodeA1->get_self_id(),
    'both nodeE1b.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeE1b->get_container(), $nodeA1->get_container(),
    'both nodeE1b.get_container() and nodeA1.get_container() hold same Container interface' );
isnt( $nodeE1b, $nodeE1,
    'both nodeE1b and nodeE1 hold diff Node interfaces' );
is( $nodeE1b->get_self_id(), $nodeE1->get_self_id(),
    'both nodeE1b.get_self_id() and nodeE1.get_self_id() hold same Node interface' );
is( $nodeE1b->get_container(), $nodeE1->get_container(),
    'both nodeE1b.get_container() and nodeE1.get_container() hold same Container interface' );

t_SRT_Util->message( 'Now confirm that N.get_child_nodes() returns new NI with the same CI.' );

my $nodeE2 = $nodeE1->get_child_nodes()->[0];
isa_ok( $nodeE2, 'SQL::Routine::Node', 
    'nodeE2 = nodeE1.get_child_nodes().[0] ret NI obj' );
isnt( $nodeE2, $nodeA2,
    'both nodeE2 and nodeA2 hold diff Node interfaces' );
is( $nodeE2->get_self_id(), $nodeA2->get_self_id(),
    'both nodeE2.get_self_id() and nodeA2.get_self_id() hold same Node interface' );
is( $nodeE2->get_container(), $nodeA2->get_container(),
    'both nodeE2.get_container() and nodeA2.get_container() hold same Container interface' );
my $nodeE2b = $nodeE1->get_child_nodes()->[0];
isa_ok( $nodeE2b, 'SQL::Routine::Node', 
    'nodeE2b = nodeE1.get_child_nodes().[0] (a second identical invocation) ret NI obj' );
isnt( $nodeE2b, $nodeA2,
    'both nodeE2b and nodeA2 hold diff Node interfaces' );
is( $nodeE2b->get_self_id(), $nodeA2->get_self_id(),
    'both nodeE2b.get_self_id() and nodeA2.get_self_id() hold same Node interface' );
is( $nodeE2b->get_container(), $nodeA2->get_container(),
    'both nodeE2b.get_container() and nodeA2.get_container() hold same Container interface' );
isnt( $nodeE2b, $nodeE2,
    'both nodeE2b and nodeE2 hold diff Node interfaces' );
is( $nodeE2b->get_self_id(), $nodeE2->get_self_id(),
    'both nodeE2b.get_self_id() and nodeE2.get_self_id() hold same Node interface' );
is( $nodeE2b->get_container(), $nodeE2->get_container(),
    'both nodeE2b.get_container() and nodeE2.get_container() hold same Container interface' );

t_SRT_Util->message( 'Now confirm that C.find_node_by_id() returns new NI with the same CI.' );

my $nodeF1 = $contA1->find_node_by_id( 1 );
isa_ok( $nodeF1, 'SQL::Routine::Node', 
    'nodeF1 = contA1.find_node_by_id( 1 ) ret NI obj' );
isnt( $nodeF1, $nodeA1,
    'both nodeF1 and nodeA1 hold diff Node interfaces' );
is( $nodeF1->get_self_id(), $nodeA1->get_self_id(),
    'both nodeF1.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeF1->get_container(), $nodeA1->get_container(),
    'both nodeF1.get_container() and nodeA1.get_container() hold same Container interface' );
my $nodeF1b = $contA1->find_node_by_id( 1 );
isa_ok( $nodeF1b, 'SQL::Routine::Node', 
    'nodeF1b = contA1.find_node_by_id( 1 ) (a second identical invocation) ret NI obj' );
isnt( $nodeF1b, $nodeA1,
    'both nodeF1b and nodeA1 hold diff Node interfaces' );
is( $nodeF1b->get_self_id(), $nodeA1->get_self_id(),
    'both nodeF1b.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeF1b->get_container(), $nodeA1->get_container(),
    'both nodeF1b.get_container() and nodeA1.get_container() hold same Container interface' );
isnt( $nodeF1b, $nodeF1,
    'both nodeF1b and nodeF1 hold diff Node interfaces' );
is( $nodeF1b->get_self_id(), $nodeF1->get_self_id(),
    'both nodeF1b.get_self_id() and nodeF1.get_self_id() hold same Node interface' );
is( $nodeF1b->get_container(), $nodeF1->get_container(),
    'both nodeF1b.get_container() and nodeF1.get_container() hold same Container interface' );

t_SRT_Util->message( 'Now confirm that C.find_child_node_by_surrogate_id() returns new NI with the same CI.' );

my $nodeG1 = $contA1->find_child_node_by_surrogate_id( 'foo' );
isa_ok( $nodeG1, 'SQL::Routine::Node', 
    'nodeG1 = contA1.find_child_node_by_surrogate_id( \'foo\' ) ret NI obj' );
isnt( $nodeG1, $nodeA1,
    'both nodeG1 and nodeA1 hold diff Node interfaces' );
is( $nodeG1->get_self_id(), $nodeA1->get_self_id(),
    'both nodeG1.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeG1->get_container(), $nodeA1->get_container(),
    'both nodeG1.get_container() and nodeA1.get_container() hold same Container interface' );
my $nodeG1b = $contA1->find_child_node_by_surrogate_id( 'foo' );
isa_ok( $nodeG1b, 'SQL::Routine::Node', 
    'nodeG1b = contA1.find_child_node_by_surrogate_id( \'foo\' ) (a second identical invocation) ret NI obj' );
isnt( $nodeG1b, $nodeA1,
    'both nodeG1b and nodeA1 hold diff Node interfaces' );
is( $nodeG1b->get_self_id(), $nodeA1->get_self_id(),
    'both nodeG1b.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeG1b->get_container(), $nodeA1->get_container(),
    'both nodeG1b.get_container() and nodeA1.get_container() hold same Container interface' );
isnt( $nodeG1b, $nodeG1,
    'both nodeG1b and nodeG1 hold diff Node interfaces' );
is( $nodeG1b->get_self_id(), $nodeG1->get_self_id(),
    'both nodeG1b.get_self_id() and nodeG1.get_self_id() hold same Node interface' );
is( $nodeG1b->get_container(), $nodeG1->get_container(),
    'both nodeG1b.get_container() and nodeG1.get_container() hold same Container interface' );

t_SRT_Util->message( 'Now confirm that N.find_child_node_by_surrogate_id() returns new NI with the same CI.' );

my $nodeG2 = $nodeA1->find_child_node_by_surrogate_id( 'bar' );
isa_ok( $nodeG2, 'SQL::Routine::Node', 
    'nodeG2 = nodeA1.find_child_node_by_surrogate_id( \'bar\' ) ret NI obj' );
isnt( $nodeG2, $nodeA2,
    'both nodeG2 and nodeA2 hold diff Node interfaces' );
is( $nodeG2->get_self_id(), $nodeA2->get_self_id(),
    'both nodeG2.get_self_id() and nodeA2.get_self_id() hold same Node interface' );
is( $nodeG2->get_container(), $nodeA2->get_container(),
    'both nodeG2.get_container() and nodeA2.get_container() hold same Container interface' );
my $nodeG2b = $nodeA1->find_child_node_by_surrogate_id( 'bar' );
isa_ok( $nodeG2b, 'SQL::Routine::Node', 
    'nodeG2b = nodeA1.find_child_node_by_surrogate_id( \'bar\' ) (a second identical invocation) ret NI obj' );
isnt( $nodeG2b, $nodeA2,
    'both nodeG2b and nodeA2 hold diff Node interfaces' );
is( $nodeG2b->get_self_id(), $nodeA2->get_self_id(),
    'both nodeG2b.get_self_id() and nodeA2.get_self_id() hold same Node interface' );
is( $nodeG2b->get_container(), $nodeA2->get_container(),
    'both nodeG2b.get_container() and nodeA2.get_container() hold same Container interface' );
isnt( $nodeG2b, $nodeG2,
    'both nodeG2b and nodeG2 hold diff Node interfaces' );
is( $nodeG2b->get_self_id(), $nodeG2->get_self_id(),
    'both nodeG2b.get_self_id() and nodeG2.get_self_id() hold same Node interface' );
is( $nodeG2b->get_container(), $nodeG2->get_container(),
    'both nodeG2b.get_container() and nodeG2.get_container() hold same Container interface' );

t_SRT_Util->message( 'Now confirm that N.get_primary_parent_attribute() returns new NI with the same CI.' );

my $nodeH1 = $nodeA2->get_primary_parent_attribute();
isa_ok( $nodeH1, 'SQL::Routine::Node', 
    'nodeH1 = nodeA2.get_primary_parent_attribute() ret NI obj' );
isnt( $nodeH1, $nodeA1,
    'both nodeH1 and nodeA1 hold diff Node interfaces' );
is( $nodeH1->get_self_id(), $nodeA1->get_self_id(),
    'both nodeH1.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeH1->get_container(), $nodeA1->get_container(),
    'both nodeH1.get_container() and nodeA1.get_container() hold same Container interface' );
my $nodeH1b = $nodeA2->get_primary_parent_attribute();
isa_ok( $nodeH1b, 'SQL::Routine::Node', 
    'nodeH1b = nodeA2.get_primary_parent_attribute() (a second identical invocation) ret NI obj' );
isnt( $nodeH1b, $nodeA1,
    'both nodeH1b and nodeA1 hold diff Node interfaces' );
is( $nodeH1b->get_self_id(), $nodeA1->get_self_id(),
    'both nodeH1b.get_self_id() and nodeA1.get_self_id() hold same Node interface' );
is( $nodeH1b->get_container(), $nodeA1->get_container(),
    'both nodeH1b.get_container() and nodeA1.get_container() hold same Container interface' );
isnt( $nodeH1b, $nodeH1,
    'both nodeH1b and nodeH1 hold diff Node interfaces' );
is( $nodeH1b->get_self_id(), $nodeH1->get_self_id(),
    'both nodeH1b.get_self_id() and nodeH1.get_self_id() hold same Node interface' );
is( $nodeH1b->get_container(), $nodeH1->get_container(),
    'both nodeH1b.get_container() and nodeH1.get_container() hold same Container interface' );

t_SRT_Util->message( 'TODO: Now confirm that N.set_primary_parent_attribute() accepts same S, rejects diff S.' );

t_SRT_Util->message( 'TODO: Now confirm that N.get_surrogate_id_attribute() returns new NIs with the same CIs.' );

t_SRT_Util->message( 'TODO: Now confirm that N.set_surrogate_id_attribute() accepts same S, rejects diff S.' );

t_SRT_Util->message( 'TODO: Now confirm that N.get_attribute() returns new NIs with the same CIs.' );

t_SRT_Util->message( 'TODO: Now confirm that N.set_attribute() accepts same S, rejects diff S.' );

t_SRT_Util->message( 'TODO: Now confirm that N.get_attributes() returns new NIs with the same CIs.' );

t_SRT_Util->message( 'TODO: Now confirm that N.set_attributes() accepts same S, rejects diff S.' );

t_SRT_Util->message( 'TODO: Now confirm that N.get_referencing_nodes() returns new NIs with the same CIs.' );

t_SRT_Util->message( 'TODO: Now confirm that N.find_node_by_surrogate_id() returns new NIs with the same CIs.' );

t_SRT_Util->message( 'TODO: Now confirm that N.get_relative_surrogate_id() returns new NIs with the same CIs.' );

1;
