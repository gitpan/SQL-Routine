# This module is used when testing SQL::Routine.
# These tests check that a model can be built using the terse wrapper 
# interface without errors, and serializes to the correct output.
# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SRT_Terse;
use strict;
use warnings;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();
	$model->auto_assert_deferrable_constraints( 1 );

	##### NEXT SET CATALOG ELEMENT-TYPE DETAILS #####

	$model->build_child_node_trees( [ map { { 'NODE_TYPE' => 'scalar_data_type', 'ATTRS' => $_ } } (
		{ 'id' =>  1, 'name' => 'bin1k' , 'base_type' => 'STR_BIT', 'max_octets' =>  1_000, },
		{ 'id' =>  2, 'name' => 'bin32k', 'base_type' => 'STR_BIT', 'max_octets' => 32_000, },
		{ 'id' =>  3, 'name' => 'str4'  , 'base_type' => 'STR_CHAR', 'max_chars' =>     4, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 'uc_latin' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'id' =>  4, 'name' => 'str10' , 'base_type' => 'STR_CHAR', 'max_chars' =>    10, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'id' =>  5, 'name' => 'str30' , 'base_type' => 'STR_CHAR', 'max_chars' =>    30, 
			'char_enc' => 'ASCII', 'trim_white' => 1, },
		{ 'id' =>  6, 'name' => 'str2k' , 'base_type' => 'STR_CHAR', 'max_chars' => 2_000, 'char_enc' => 'UTF8', },
		{ 'id' =>  7, 'name' => 'byte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, },
		{ 'id' =>  8, 'name' => 'short', 'base_type' => 'NUM_INT', 'num_precision' =>  5, },
		{ 'id' =>  9, 'name' => 'int'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, },
		{ 'id' => 10, 'name' => 'long' , 'base_type' => 'NUM_INT', 'num_precision' => 19, },
		{ 'id' => 11, 'name' => 'ubyte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, 'num_unsigned' => 1, },
		{ 'id' => 12, 'name' => 'ushort', 'base_type' => 'NUM_INT', 'num_precision' =>  5, 'num_unsigned' => 1, },
		{ 'id' => 13, 'name' => 'uint'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, 'num_unsigned' => 1, },
		{ 'id' => 14, 'name' => 'ulong' , 'base_type' => 'NUM_INT', 'num_precision' => 19, 'num_unsigned' => 1, },
		{ 'id' => 15, 'name' => 'float' , 'base_type' => 'NUM_APR', 'num_octets' => 4, },
		{ 'id' => 16, 'name' => 'double', 'base_type' => 'NUM_APR', 'num_octets' => 8, },
		{ 'id' => 17, 'name' => 'dec10p2', 'base_type' => 'NUM_EXA', 'num_precision' =>  10, 'num_scale' => 2, },
		{ 'id' => 18, 'name' => 'dec255' , 'base_type' => 'NUM_EXA', 'num_precision' => 255, },
		{ 'id' => 19, 'name' => 'boolean', 'base_type' => 'BOOLEAN', },
		{ 'id' => 20, 'name' => 'datetime', 'base_type' => 'DATM_FULL', 'calendar' => 'ABS', },
		{ 'id' => 21, 'name' => 'dtchines', 'base_type' => 'DATM_FULL', 'calendar' => 'CHI', },
		{ 'id' => 22, 'name' => 'sex'   , 'base_type' => 'STR_CHAR', 'max_chars' =>     1, 'char_enc' => 'ASCII', },
		{ 'id' => 23, 'name' => 'str20' , 'base_type' => 'STR_CHAR', 'max_chars' =>    20, 'char_enc' => 'ASCII', },
		{ 'id' => 24, 'name' => 'str100', 'base_type' => 'STR_CHAR', 'max_chars' =>   100, 'char_enc' => 'ASCII', },
		{ 'id' => 25, 'name' => 'str250', 'base_type' => 'STR_CHAR', 'max_chars' =>   250, 'char_enc' => 'ASCII', },
		{ 'id' => 26, 'name' => 'entitynm', 'base_type' => 'STR_CHAR', 'max_chars' =>  30, 'char_enc' => 'ASCII', },
		{ 'id' => 27, 'name' => 'generic' , 'base_type' => 'STR_CHAR', 'max_chars' => 250, 'char_enc' => 'ASCII', },
	) ] );

	my $sex = $model->get_node( 'scalar_data_type', '22' );
	$sex->build_child_node_trees( [ map { { 'NODE_TYPE' => 'scalar_data_type_opt', 'ATTRS' => $_ } } (
		{ 'id' =>  1, 'value' => 'M', },
		{ 'id' =>  2, 'value' => 'F', },
	) ] );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 4, 'name' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 20, 'name' => 'person_id'   , 'scalar_data_type' =>  9, },
			{ 'id' => 21, 'name' => 'alternate_id', 'scalar_data_type' => 23, },
			{ 'id' => 22, 'name' => 'name'        , 'scalar_data_type' => 24, },
			{ 'id' => 23, 'name' => 'sex'         , 'scalar_data_type' => 22, },
			{ 'id' => 24, 'name' => 'father_id'   , 'scalar_data_type' =>  9, },
			{ 'id' => 25, 'name' => 'mother_id'   , 'scalar_data_type' =>  9, },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 102, 'name' => 'person_with_parents', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 116, 'name' => 'self_id'    , 'scalar_data_type' =>  9, },
			{ 'id' => 117, 'name' => 'self_name'  , 'scalar_data_type' => 24, },
			{ 'id' => 118, 'name' => 'father_id'  , 'scalar_data_type' =>  9, },
			{ 'id' => 119, 'name' => 'father_name', 'scalar_data_type' => 24, },
			{ 'id' => 120, 'name' => 'mother_id'  , 'scalar_data_type' =>  9, },
			{ 'id' => 121, 'name' => 'mother_name', 'scalar_data_type' => 24, },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 1, 'name' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 1, 'name' => 'user_id'      , 'scalar_data_type' =>  9, },
			{ 'id' => 2, 'name' => 'login_name'   , 'scalar_data_type' => 23, },
			{ 'id' => 3, 'name' => 'login_pass'   , 'scalar_data_type' => 23, },
			{ 'id' => 4, 'name' => 'private_name' , 'scalar_data_type' => 24, },
			{ 'id' => 5, 'name' => 'private_email', 'scalar_data_type' => 24, },
			{ 'id' => 6, 'name' => 'may_login'    , 'scalar_data_type' => 19, },
			{ 'id' => 7, 'name' => 'max_sessions' , 'scalar_data_type' =>  7, },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 2, 'name' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' =>  8, 'name' => 'user_id'     , 'scalar_data_type' =>  9, },
			{ 'id' =>  9, 'name' => 'public_name' , 'scalar_data_type' => 25, },
			{ 'id' => 10, 'name' => 'public_email', 'scalar_data_type' => 25, },
			{ 'id' => 11, 'name' => 'web_url'     , 'scalar_data_type' => 25, },
			{ 'id' => 12, 'name' => 'contact_net' , 'scalar_data_type' => 25, },
			{ 'id' => 13, 'name' => 'contact_phy' , 'scalar_data_type' => 25, },
			{ 'id' => 14, 'name' => 'bio'         , 'scalar_data_type' => 25, },
			{ 'id' => 15, 'name' => 'plan'        , 'scalar_data_type' => 25, },
			{ 'id' => 16, 'name' => 'comments'    , 'scalar_data_type' => 25, },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 101, 'name' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 101, 'name' => 'user_id'      , 'scalar_data_type' =>  9, },
			{ 'id' => 102, 'name' => 'login_name'   , 'scalar_data_type' => 23, },
			{ 'id' => 103, 'name' => 'login_pass'   , 'scalar_data_type' => 23, },
			{ 'id' => 104, 'name' => 'private_name' , 'scalar_data_type' => 24, },
			{ 'id' => 105, 'name' => 'private_email', 'scalar_data_type' => 24, },
			{ 'id' => 106, 'name' => 'may_login'    , 'scalar_data_type' => 19, },
			{ 'id' => 107, 'name' => 'max_sessions' , 'scalar_data_type' =>  7, },
			{ 'id' => 108, 'name' => 'public_name'  , 'scalar_data_type' => 25, },
			{ 'id' => 109, 'name' => 'public_email' , 'scalar_data_type' => 25, },
			{ 'id' => 110, 'name' => 'web_url'      , 'scalar_data_type' => 25, },
			{ 'id' => 111, 'name' => 'contact_net'  , 'scalar_data_type' => 25, },
			{ 'id' => 112, 'name' => 'contact_phy'  , 'scalar_data_type' => 25, },
			{ 'id' => 113, 'name' => 'bio'          , 'scalar_data_type' => 25, },
			{ 'id' => 114, 'name' => 'plan'         , 'scalar_data_type' => 25, },
			{ 'id' => 115, 'name' => 'comments'     , 'scalar_data_type' => 25, },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 3, 'name' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 17, 'name' => 'user_id'   , 'scalar_data_type' =>  9, },
			{ 'id' => 18, 'name' => 'pref_name' , 'scalar_data_type' => 26, },
			{ 'id' => 19, 'name' => 'pref_value', 'scalar_data_type' => 27, },
		) ),
	] } );

	##### NEXT SET APPLICATION ELEMENT-TYPE DETAILS #####

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'id' => 103, 'name' => 'user_theme',  }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'id' => 122, 'name' => 'theme_name' , 'scalar_data_type' => 27, },
			{ 'id' => 123, 'name' => 'theme_count', 'scalar_data_type' =>  9, },
		) ),
	] } );

	##### NEXT SET CATALOG BLUEPRINT-TYPE DETAILS #####

	my $catalog = $model->build_child_node_tree( 
		{ 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'id' => 1, 'name' => 'The Catalog Blueprint' }, 
		'CHILDREN' => [ { 'NODE_TYPE' => 'owner', 'ATTRS' => { 'id' =>  1, } } ] } ); 

	my $schema = $catalog->build_child_node_tree( { 'NODE_TYPE' => 'schema', 
		'ATTRS' => { 'id' => 1, 'name' => 'gene', 'owner' => 1, } } ); 

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 4, 'name' => 'person', 'row_data_type' => 4, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'id' => 20, 'row_field' => 20, 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'id' => 22, 'row_field' => 22, 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'id' =>  9, 'name' => 'primary'        , 'index_type' => 'UNIQUE', }, 
				{ 'id' => 10, 'field' => 20, }, ], 
			[ { 'id' => 10, 'name' => 'ak_alternate_id', 'index_type' => 'UNIQUE', }, 
				{ 'id' => 11, 'field' => 21, }, ], 
			[ { 'id' => 11, 'name' => 'fk_father', 'index_type' => 'FOREIGN', 'f_table' => 4, }, 
				{ 'id' => 12, 'field' => 24, 'f_field' => 20 }, ], 
			[ { 'id' => 12, 'name' => 'fk_mother', 'index_type' => 'FOREIGN', 'f_table' => 4, }, 
				{ 'id' => 13, 'field' => 25, 'f_field' => 20 }, ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 2, 
			'name' => 'person_with_parents', 'view_type' => 'JOINED', 'row_data_type' => 102, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 3, 'name' => 'self'  , 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 17, 'match_field' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 18, 'match_field' => 22, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 25, 'match_field' => 24, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 26, 'match_field' => 25, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 4, 'name' => 'father', 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 19, 'match_field' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 20, 'match_field' => 22, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 5, 'name' => 'mother', 
				'match_table' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 21, 'match_field' => 20, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 22, 'match_field' => 22, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_field', 'ATTRS' => $_ } } (
			{ 'id' => 16, 'row_field' => 116, 'src_field' => 17, },
			{ 'id' => 17, 'row_field' => 117, 'src_field' => 18, },
			{ 'id' => 18, 'row_field' => 118, 'src_field' => 19, },
			{ 'id' => 19, 'row_field' => 119, 'src_field' => 20, },
			{ 'id' => 20, 'row_field' => 120, 'src_field' => 21, },
			{ 'id' => 21, 'row_field' => 121, 'src_field' => 22, },
		) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 2, 'lhs_src' => 3, 
				'rhs_src' => 4, 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'id' => 2, 'lhs_src_field' => 25, 'rhs_src_field' => 19, } },
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 3, 'lhs_src' => 3, 
				'rhs_src' => 5, 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'id' => 3, 'lhs_src_field' => 26, 'rhs_src_field' => 21, } },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 1, 'name' => 'user_auth', 'row_data_type' => 1, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'id' => 1, 'row_field' => 1, 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'id' => 2, 'row_field' => 2, 'mandatory' => 1, },
			{ 'id' => 3, 'row_field' => 3, 'mandatory' => 1, },
			{ 'id' => 4, 'row_field' => 4, 'mandatory' => 1, },
			{ 'id' => 5, 'row_field' => 5, 'mandatory' => 1, },
			{ 'id' => 6, 'row_field' => 6, 'mandatory' => 1, },
			{ 'id' => 7, 'row_field' => 7, 'mandatory' => 1, 'default_val' => 3, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 1, 'name' => 'primary'         , 'index_type' => 'UNIQUE', }, 
				{ 'id' => 1, 'field' => 1, }, ], 
			[ { 'id' => 2, 'name' => 'ak_login_name'   , 'index_type' => 'UNIQUE', }, 
				{ 'id' => 2, 'field' => 2, }, ], 
			[ { 'id' => 3, 'name' => 'ak_private_email', 'index_type' => 'UNIQUE', }, 
				{ 'id' => 3, 'field' => 5, }, ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 2, 'name' => 'user_profile', 'row_data_type' => 2, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'id' =>  8, 'row_field' => 8, 'mandatory' => 1, },
			{ 'id' =>  9, 'row_field' => 9, 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'id' => 4, 'name' => 'primary'       , 'index_type' => 'UNIQUE', }, 
				{ 'id' => 4, 'field' => 8, }, ], 
			[ { 'id' => 5, 'name' => 'ak_public_name', 'index_type' => 'UNIQUE', }, 
				{ 'id' => 5, 'field' => 9, }, ], 
			[ { 'id' => 6, 'name' => 'fk_user'       , 'index_type' => 'FOREIGN', 'f_table' => 1, }, 
				{ 'id' => 6, 'field' => 8, 'f_field' => 1 }, ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 1, 
			'name' => 'user', 'view_type' => 'JOINED', 'row_data_type' => 101, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 1, 'name' => 'user_auth', 
				'match_table' => 1, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  1, 'match_field' =>  1, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  2, 'match_field' =>  2, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  3, 'match_field' =>  3, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  4, 'match_field' =>  4, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  5, 'match_field' =>  5, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  6, 'match_field' =>  6, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  7, 'match_field' =>  7, }, },
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 2, 'name' => 'user_profile', 
				'match_table' => 2, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  8, 'match_field' =>  8, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' =>  9, 'match_field' =>  9, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 10, 'match_field' => 10, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 11, 'match_field' => 11, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 12, 'match_field' => 12, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 13, 'match_field' => 13, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 14, 'match_field' => 14, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 15, 'match_field' => 15, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 16, 'match_field' => 16, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_field', 'ATTRS' => $_ } } (
			{ 'id' =>  1, 'row_field' => 101, 'src_field' =>  1, },
			{ 'id' =>  2, 'row_field' => 102, 'src_field' =>  2, },
			{ 'id' =>  3, 'row_field' => 103, 'src_field' =>  3, },
			{ 'id' =>  4, 'row_field' => 104, 'src_field' =>  4, },
			{ 'id' =>  5, 'row_field' => 105, 'src_field' =>  5, },
			{ 'id' =>  6, 'row_field' => 106, 'src_field' =>  6, },
			{ 'id' =>  7, 'row_field' => 107, 'src_field' =>  7, },
			{ 'id' =>  8, 'row_field' => 108, 'src_field' =>  9, },
			{ 'id' =>  9, 'row_field' => 109, 'src_field' => 10, },
			{ 'id' => 10, 'row_field' => 110, 'src_field' => 11, },
			{ 'id' => 11, 'row_field' => 111, 'src_field' => 12, },
			{ 'id' => 12, 'row_field' => 112, 'src_field' => 13, },
			{ 'id' => 13, 'row_field' => 113, 'src_field' => 14, },
			{ 'id' => 14, 'row_field' => 114, 'src_field' => 15, },
			{ 'id' => 15, 'row_field' => 115, 'src_field' => 16, },
		) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'id' => 1, 'lhs_src' => 1, 
				'rhs_src' => 2, 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'id' => 1, 'lhs_src_field' => 1, 'rhs_src_field' => 8, } },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'id' => 3, 'name' => 'user_pref', 'row_data_type' => 3, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'id' => 17, 'row_field' => 17, 'mandatory' => 1, },
			{ 'id' => 18, 'row_field' => 18, 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'id' => 7, 'name' => 'primary', 'index_type' => 'UNIQUE', },
				[ { 'id' => 7, 'field' => 17, }, 
				{ 'id' => 8, 'field' => 18, }, ],
			], 
			[ { 'id' => 8, 'name' => 'fk_user', 'index_type' => 'FOREIGN', 'f_table' => 1, }, 
				[ { 'id' => 9, 'field' => 17, 'f_field' => 1 }, ],
			], 
		) ),
	] } );

	##### NEXT SET APPLICATION BLUEPRINT-TYPE DETAILS #####

	my $application = $model->build_child_node_tree( { 'NODE_TYPE' => 'application', 
		'ATTRS' => { 'id' => 1, 'name' => 'My App', }, } ); 

	$application->build_child_node_tree( { 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 3, 
			'name' => 'user_theme', 'view_type' => 'JOINED', 'row_data_type' => 103, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 6, 'name' => 'user_pref', 
			'match_table' => 3, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 23, 'match_field' => 18, }, },
			{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 24, 'match_field' => 19, }, },
		] },
		( map { { 'NODE_TYPE' => 'view_field', 'ATTRS' => $_ } } (
			{ 'id' => 22, 'row_field' => 122, },
			{ 'id' => 23, 'row_field' => 123, },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'id' => 42, 'set_result_field' => 22, 'cont_type' => 'SCALAR', 'valf_src_field' => 24, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'id' => 43, 'set_result_field' => 23, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'COUNT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 44, 'cont_type' => 'SCALAR', 'valf_src_field' => 24, }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'id' => 11, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 12, 'cont_type' => 'SCALAR', 'valf_src_field' => 23, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 13, 'cont_type' => 'SCALAR', 'scalar_data_type' => 5, 'valf_literal' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'GROUP', 
			'id' => 14, 'cont_type' => 'SCALAR', 'valf_src_field' => 24, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'HAVING', 
				'id' => 15, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'GT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 16, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'COUNT', }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'id' => 17, 'cont_type' => 'SCALAR', 'scalar_data_type' => 9, 'valf_literal' => '1', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
			'id' => 55, 'cont_type' => 'SCALAR', 'valf_result_field' => 23, }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
			'id' => 56, 'cont_type' => 'SCALAR', 'valf_result_field' => 22, }, },
	] } );

	$application->build_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 1, 'routine_type' => 'FUNCTION', 'name' => 'get_user', 
			'return_cont_type' => 'CURSOR', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 1, 'name' => 'curr_uid', 
			'cont_type' => 'SCALAR', 'scalar_data_type' => 9, }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 5, 'name' => 'get_user', 
				'view_type' => 'JOINED', 'row_data_type' => 101, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 8, 'name' => 'm', 'match_view' => 1, }, 
					'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 30, 'match_field' => 101, }, },
				{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 31, 'match_field' => 102, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 1, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'EQ', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 2, 'cont_type' => 'SCALAR', 'valf_src_field' => 30, }, },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'id' => 3, 'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 1, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 51, 'cont_type' => 'SCALAR', 'valf_src_field' => 31, }, },
		] },
		{ 'NODE_TYPE' => 'routine_stmt', 'ATTRS' => { 'id' => 1, 'call_sroutine' => 'CURSOR_OPEN' }, },
	] } );

	$application->build_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 2, 'routine_type' => 'FUNCTION', 'name' => 'get_pwp', 
			'return_cont_type' => 'CURSOR', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 2, 'name' => 'srchw_fa', 'cont_type' => 'SCALAR', 'scalar_data_type' => 5, }, },
		{ 'NODE_TYPE' => 'routine_arg', 'ATTRS' => { 'id' => 3, 'name' => 'srchw_mo', 'cont_type' => 'SCALAR', 'scalar_data_type' => 5, }, },
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 6, 'name' => 'get_pwp', 
				'view_type' => 'JOINED', 'row_data_type' => 102, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 9, 'name' => 'm', 'match_view' => 2, }, 
					'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 27, 'match_field' => 117, }, },
				{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 28, 'match_field' => 119, }, },
				{ 'NODE_TYPE' => 'view_src_field', 'ATTRS' => { 'id' => 29, 'match_field' => 121, }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
					'id' => 4, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'AND', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 5, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 6, 'cont_type' => 'SCALAR', 'valf_src_field' => 28, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 7, 'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 2, }, },
				] },
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 8, 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'LIKE', }, 'CHILDREN' => [ 
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 9, 'cont_type' => 'SCALAR', 'valf_src_field' => 29, }, },
					{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
						'id' => 10, 'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 3, }, },
				] },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 52, 'cont_type' => 'SCALAR', 'valf_src_field' => 27, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 53, 'cont_type' => 'SCALAR', 'valf_src_field' => 28, }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'ORDER', 
				'id' => 54, 'cont_type' => 'SCALAR', 'valf_src_field' => 29, }, },
		] },
		{ 'NODE_TYPE' => 'routine_stmt', 'ATTRS' => { 'id' => 2, 'call_sroutine' => 'CURSOR_OPEN' }, },
	] } );

	$application->build_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 3, 'routine_type' => 'FUNCTION', 'name' => 'get_theme', 
			'return_cont_type' => 'CURSOR', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 7, 'name' => 'get_theme', 
				'view_type' => 'ALIAS', 'row_data_type' => 103, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 10, 'name' => 'm', 'match_view' => 3, }, },
		] },
		{ 'NODE_TYPE' => 'routine_stmt', 'ATTRS' => { 'id' => 3, 'call_sroutine' => 'CURSOR_OPEN' }, },
	] } );

	$application->build_child_node_tree( { 'NODE_TYPE' => 'routine', 
			'ATTRS' => { 'id' => 4, 'routine_type' => 'FUNCTION', 'name' => 'get_person', 
			'return_cont_type' => 'CURSOR', }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view', 'ATTRS' => { 'id' => 4, 'name' => 'get_person', 
				'view_type' => 'ALIAS', 'row_data_type' => 4, }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'id' => 7, 'name' => 'person', 'match_table' => 4, }, },
		] },
		{ 'NODE_TYPE' => 'routine_stmt', 'ATTRS' => { 'id' => 4, 'call_sroutine' => 'CURSOR_OPEN' }, },
	] } );

	##### NEXT SET PRODUCT-TYPE DETAILS #####

	# ... TODO ...

	##### NEXT SET INSTANCE-TYPE DETAILS #####

	# ... TODO ...

	##### END OF DETAILS SETTING #####

	# Now check that we didn't omit something important:
	$model->assert_deferrable_constraints();

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<elements>
		<scalar_data_type id="1" name="bin1k" base_type="STR_BIT" max_octets="1000" />
		<scalar_data_type id="2" name="bin32k" base_type="STR_BIT" max_octets="32000" />
		<scalar_data_type id="3" name="str4" base_type="STR_CHAR" max_chars="4" store_fixed="1" char_enc="ASCII" trim_white="1" uc_latin="1" pad_char=" " trim_pad="1" />
		<scalar_data_type id="4" name="str10" base_type="STR_CHAR" max_chars="10" store_fixed="1" char_enc="ASCII" trim_white="1" pad_char=" " trim_pad="1" />
		<scalar_data_type id="5" name="str30" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" trim_white="1" />
		<scalar_data_type id="6" name="str2k" base_type="STR_CHAR" max_chars="2000" char_enc="UTF8" />
		<scalar_data_type id="7" name="byte" base_type="NUM_INT" num_precision="3" />
		<scalar_data_type id="8" name="short" base_type="NUM_INT" num_precision="5" />
		<scalar_data_type id="9" name="int" base_type="NUM_INT" num_precision="10" />
		<scalar_data_type id="10" name="long" base_type="NUM_INT" num_precision="19" />
		<scalar_data_type id="11" name="ubyte" base_type="NUM_INT" num_precision="3" num_unsigned="1" />
		<scalar_data_type id="12" name="ushort" base_type="NUM_INT" num_precision="5" num_unsigned="1" />
		<scalar_data_type id="13" name="uint" base_type="NUM_INT" num_precision="10" num_unsigned="1" />
		<scalar_data_type id="14" name="ulong" base_type="NUM_INT" num_precision="19" num_unsigned="1" />
		<scalar_data_type id="15" name="float" base_type="NUM_APR" num_octets="4" />
		<scalar_data_type id="16" name="double" base_type="NUM_APR" num_octets="8" />
		<scalar_data_type id="17" name="dec10p2" base_type="NUM_EXA" num_precision="10" num_scale="2" />
		<scalar_data_type id="18" name="dec255" base_type="NUM_EXA" num_precision="255" />
		<scalar_data_type id="19" name="boolean" base_type="BOOLEAN" />
		<scalar_data_type id="20" name="datetime" base_type="DATM_FULL" calendar="ABS" />
		<scalar_data_type id="21" name="dtchines" base_type="DATM_FULL" calendar="CHI" />
		<scalar_data_type id="22" name="sex" base_type="STR_CHAR" max_chars="1" char_enc="ASCII">
			<scalar_data_type_opt id="1" pp_scalar_data_type="22" value="M" />
			<scalar_data_type_opt id="2" pp_scalar_data_type="22" value="F" />
		</scalar_data_type>
		<scalar_data_type id="23" name="str20" base_type="STR_CHAR" max_chars="20" char_enc="ASCII" />
		<scalar_data_type id="24" name="str100" base_type="STR_CHAR" max_chars="100" char_enc="ASCII" />
		<scalar_data_type id="25" name="str250" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<scalar_data_type id="26" name="entitynm" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" />
		<scalar_data_type id="27" name="generic" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<row_data_type id="4" name="person">
			<row_data_type_field id="20" pp_row_data_type="4" name="person_id" scalar_data_type="9" />
			<row_data_type_field id="21" pp_row_data_type="4" name="alternate_id" scalar_data_type="23" />
			<row_data_type_field id="22" pp_row_data_type="4" name="name" scalar_data_type="24" />
			<row_data_type_field id="23" pp_row_data_type="4" name="sex" scalar_data_type="22" />
			<row_data_type_field id="24" pp_row_data_type="4" name="father_id" scalar_data_type="9" />
			<row_data_type_field id="25" pp_row_data_type="4" name="mother_id" scalar_data_type="9" />
		</row_data_type>
		<row_data_type id="102" name="person_with_parents">
			<row_data_type_field id="116" pp_row_data_type="102" name="self_id" scalar_data_type="9" />
			<row_data_type_field id="117" pp_row_data_type="102" name="self_name" scalar_data_type="24" />
			<row_data_type_field id="118" pp_row_data_type="102" name="father_id" scalar_data_type="9" />
			<row_data_type_field id="119" pp_row_data_type="102" name="father_name" scalar_data_type="24" />
			<row_data_type_field id="120" pp_row_data_type="102" name="mother_id" scalar_data_type="9" />
			<row_data_type_field id="121" pp_row_data_type="102" name="mother_name" scalar_data_type="24" />
		</row_data_type>
		<row_data_type id="1" name="user_auth">
			<row_data_type_field id="1" pp_row_data_type="1" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="2" pp_row_data_type="1" name="login_name" scalar_data_type="23" />
			<row_data_type_field id="3" pp_row_data_type="1" name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="4" pp_row_data_type="1" name="private_name" scalar_data_type="24" />
			<row_data_type_field id="5" pp_row_data_type="1" name="private_email" scalar_data_type="24" />
			<row_data_type_field id="6" pp_row_data_type="1" name="may_login" scalar_data_type="19" />
			<row_data_type_field id="7" pp_row_data_type="1" name="max_sessions" scalar_data_type="7" />
		</row_data_type>
		<row_data_type id="2" name="user_profile">
			<row_data_type_field id="8" pp_row_data_type="2" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="9" pp_row_data_type="2" name="public_name" scalar_data_type="25" />
			<row_data_type_field id="10" pp_row_data_type="2" name="public_email" scalar_data_type="25" />
			<row_data_type_field id="11" pp_row_data_type="2" name="web_url" scalar_data_type="25" />
			<row_data_type_field id="12" pp_row_data_type="2" name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="13" pp_row_data_type="2" name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="14" pp_row_data_type="2" name="bio" scalar_data_type="25" />
			<row_data_type_field id="15" pp_row_data_type="2" name="plan" scalar_data_type="25" />
			<row_data_type_field id="16" pp_row_data_type="2" name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="101" name="user">
			<row_data_type_field id="101" pp_row_data_type="101" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="102" pp_row_data_type="101" name="login_name" scalar_data_type="23" />
			<row_data_type_field id="103" pp_row_data_type="101" name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="104" pp_row_data_type="101" name="private_name" scalar_data_type="24" />
			<row_data_type_field id="105" pp_row_data_type="101" name="private_email" scalar_data_type="24" />
			<row_data_type_field id="106" pp_row_data_type="101" name="may_login" scalar_data_type="19" />
			<row_data_type_field id="107" pp_row_data_type="101" name="max_sessions" scalar_data_type="7" />
			<row_data_type_field id="108" pp_row_data_type="101" name="public_name" scalar_data_type="25" />
			<row_data_type_field id="109" pp_row_data_type="101" name="public_email" scalar_data_type="25" />
			<row_data_type_field id="110" pp_row_data_type="101" name="web_url" scalar_data_type="25" />
			<row_data_type_field id="111" pp_row_data_type="101" name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="112" pp_row_data_type="101" name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="113" pp_row_data_type="101" name="bio" scalar_data_type="25" />
			<row_data_type_field id="114" pp_row_data_type="101" name="plan" scalar_data_type="25" />
			<row_data_type_field id="115" pp_row_data_type="101" name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="3" name="user_pref">
			<row_data_type_field id="17" pp_row_data_type="3" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="18" pp_row_data_type="3" name="pref_name" scalar_data_type="26" />
			<row_data_type_field id="19" pp_row_data_type="3" name="pref_value" scalar_data_type="27" />
		</row_data_type>
		<row_data_type id="103" name="user_theme">
			<row_data_type_field id="122" pp_row_data_type="103" name="theme_name" scalar_data_type="27" />
			<row_data_type_field id="123" pp_row_data_type="103" name="theme_count" scalar_data_type="9" />
		</row_data_type>
	</elements>
	<blueprints>
		<catalog id="1" name="The Catalog Blueprint">
			<owner id="1" pp_catalog="1" />
			<schema id="1" pp_catalog="1" name="gene" owner="1">
				<table id="4" pp_schema="1" name="person" row_data_type="4">
					<table_field id="20" pp_table="4" row_field="20" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="22" pp_table="4" row_field="22" mandatory="1" />
					<table_index id="9" pp_table="4" name="primary" index_type="UNIQUE">
						<table_index_field id="10" pp_table_index="9" field="20" />
					</table_index>
					<table_index id="10" pp_table="4" name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="11" pp_table_index="10" field="21" />
					</table_index>
					<table_index id="11" pp_table="4" name="fk_father" index_type="FOREIGN" f_table="4">
						<table_index_field id="12" pp_table_index="11" field="24" f_field="20" />
					</table_index>
					<table_index id="12" pp_table="4" name="fk_mother" index_type="FOREIGN" f_table="4">
						<table_index_field id="13" pp_table_index="12" field="25" f_field="20" />
					</table_index>
				</table>
				<view id="2" pp_schema="1" name="person_with_parents" view_type="JOINED" row_data_type="102">
					<view_src id="3" pp_view="2" name="self" match_table="4">
						<view_src_field id="17" pp_src="3" match_field="20" />
						<view_src_field id="18" pp_src="3" match_field="22" />
						<view_src_field id="25" pp_src="3" match_field="24" />
						<view_src_field id="26" pp_src="3" match_field="25" />
					</view_src>
					<view_src id="4" pp_view="2" name="father" match_table="4">
						<view_src_field id="19" pp_src="4" match_field="20" />
						<view_src_field id="20" pp_src="4" match_field="22" />
					</view_src>
					<view_src id="5" pp_view="2" name="mother" match_table="4">
						<view_src_field id="21" pp_src="5" match_field="20" />
						<view_src_field id="22" pp_src="5" match_field="22" />
					</view_src>
					<view_field id="16" pp_view="2" row_field="116" src_field="17" />
					<view_field id="17" pp_view="2" row_field="117" src_field="18" />
					<view_field id="18" pp_view="2" row_field="118" src_field="19" />
					<view_field id="19" pp_view="2" row_field="119" src_field="20" />
					<view_field id="20" pp_view="2" row_field="120" src_field="21" />
					<view_field id="21" pp_view="2" row_field="121" src_field="22" />
					<view_join id="2" pp_view="2" lhs_src="3" rhs_src="4" join_op="LEFT">
						<view_join_field id="2" pp_join="2" lhs_src_field="25" rhs_src_field="19" />
					</view_join>
					<view_join id="3" pp_view="2" lhs_src="3" rhs_src="5" join_op="LEFT">
						<view_join_field id="3" pp_join="3" lhs_src_field="26" rhs_src_field="21" />
					</view_join>
				</view>
				<table id="1" pp_schema="1" name="user_auth" row_data_type="1">
					<table_field id="1" pp_table="1" row_field="1" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="2" pp_table="1" row_field="2" mandatory="1" />
					<table_field id="3" pp_table="1" row_field="3" mandatory="1" />
					<table_field id="4" pp_table="1" row_field="4" mandatory="1" />
					<table_field id="5" pp_table="1" row_field="5" mandatory="1" />
					<table_field id="6" pp_table="1" row_field="6" mandatory="1" />
					<table_field id="7" pp_table="1" row_field="7" mandatory="1" default_val="3" />
					<table_index id="1" pp_table="1" name="primary" index_type="UNIQUE">
						<table_index_field id="1" pp_table_index="1" field="1" />
					</table_index>
					<table_index id="2" pp_table="1" name="ak_login_name" index_type="UNIQUE">
						<table_index_field id="2" pp_table_index="2" field="2" />
					</table_index>
					<table_index id="3" pp_table="1" name="ak_private_email" index_type="UNIQUE">
						<table_index_field id="3" pp_table_index="3" field="5" />
					</table_index>
				</table>
				<table id="2" pp_schema="1" name="user_profile" row_data_type="2">
					<table_field id="8" pp_table="2" row_field="8" mandatory="1" />
					<table_field id="9" pp_table="2" row_field="9" mandatory="1" />
					<table_index id="4" pp_table="2" name="primary" index_type="UNIQUE">
						<table_index_field id="4" pp_table_index="4" field="8" />
					</table_index>
					<table_index id="5" pp_table="2" name="ak_public_name" index_type="UNIQUE">
						<table_index_field id="5" pp_table_index="5" field="9" />
					</table_index>
					<table_index id="6" pp_table="2" name="fk_user" index_type="FOREIGN" f_table="1">
						<table_index_field id="6" pp_table_index="6" field="8" f_field="1" />
					</table_index>
				</table>
				<view id="1" pp_schema="1" name="user" view_type="JOINED" row_data_type="101">
					<view_src id="1" pp_view="1" name="user_auth" match_table="1">
						<view_src_field id="1" pp_src="1" match_field="1" />
						<view_src_field id="2" pp_src="1" match_field="2" />
						<view_src_field id="3" pp_src="1" match_field="3" />
						<view_src_field id="4" pp_src="1" match_field="4" />
						<view_src_field id="5" pp_src="1" match_field="5" />
						<view_src_field id="6" pp_src="1" match_field="6" />
						<view_src_field id="7" pp_src="1" match_field="7" />
					</view_src>
					<view_src id="2" pp_view="1" name="user_profile" match_table="2">
						<view_src_field id="8" pp_src="2" match_field="8" />
						<view_src_field id="9" pp_src="2" match_field="9" />
						<view_src_field id="10" pp_src="2" match_field="10" />
						<view_src_field id="11" pp_src="2" match_field="11" />
						<view_src_field id="12" pp_src="2" match_field="12" />
						<view_src_field id="13" pp_src="2" match_field="13" />
						<view_src_field id="14" pp_src="2" match_field="14" />
						<view_src_field id="15" pp_src="2" match_field="15" />
						<view_src_field id="16" pp_src="2" match_field="16" />
					</view_src>
					<view_field id="1" pp_view="1" row_field="101" src_field="1" />
					<view_field id="2" pp_view="1" row_field="102" src_field="2" />
					<view_field id="3" pp_view="1" row_field="103" src_field="3" />
					<view_field id="4" pp_view="1" row_field="104" src_field="4" />
					<view_field id="5" pp_view="1" row_field="105" src_field="5" />
					<view_field id="6" pp_view="1" row_field="106" src_field="6" />
					<view_field id="7" pp_view="1" row_field="107" src_field="7" />
					<view_field id="8" pp_view="1" row_field="108" src_field="9" />
					<view_field id="9" pp_view="1" row_field="109" src_field="10" />
					<view_field id="10" pp_view="1" row_field="110" src_field="11" />
					<view_field id="11" pp_view="1" row_field="111" src_field="12" />
					<view_field id="12" pp_view="1" row_field="112" src_field="13" />
					<view_field id="13" pp_view="1" row_field="113" src_field="14" />
					<view_field id="14" pp_view="1" row_field="114" src_field="15" />
					<view_field id="15" pp_view="1" row_field="115" src_field="16" />
					<view_join id="1" pp_view="1" lhs_src="1" rhs_src="2" join_op="LEFT">
						<view_join_field id="1" pp_join="1" lhs_src_field="1" rhs_src_field="8" />
					</view_join>
				</view>
				<table id="3" pp_schema="1" name="user_pref" row_data_type="3">
					<table_field id="17" pp_table="3" row_field="17" mandatory="1" />
					<table_field id="18" pp_table="3" row_field="18" mandatory="1" />
					<table_index id="7" pp_table="3" name="primary" index_type="UNIQUE">
						<table_index_field id="7" pp_table_index="7" field="17" />
						<table_index_field id="8" pp_table_index="7" field="18" />
					</table_index>
					<table_index id="8" pp_table="3" name="fk_user" index_type="FOREIGN" f_table="1">
						<table_index_field id="9" pp_table_index="8" field="17" f_field="1" />
					</table_index>
				</table>
			</schema>
		</catalog>
		<application id="1" name="My App">
			<view id="3" pp_application="1" name="user_theme" view_type="JOINED" row_data_type="103">
				<view_src id="6" pp_view="3" name="user_pref" match_table="3">
					<view_src_field id="23" pp_src="6" match_field="18" />
					<view_src_field id="24" pp_src="6" match_field="19" />
				</view_src>
				<view_field id="22" pp_view="3" row_field="122" />
				<view_field id="23" pp_view="3" row_field="123" />
				<view_expr id="42" pp_view="3" view_part="RESULT" set_result_field="22" cont_type="SCALAR" valf_src_field="24" />
				<view_expr id="43" pp_view="3" view_part="RESULT" set_result_field="23" cont_type="SCALAR" valf_call_sroutine="COUNT">
					<view_expr id="44" pp_expr="43" cont_type="SCALAR" valf_src_field="24" />
				</view_expr>
				<view_expr id="11" pp_view="3" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
					<view_expr id="12" pp_expr="11" cont_type="SCALAR" valf_src_field="23" />
					<view_expr id="13" pp_expr="11" cont_type="SCALAR" valf_literal="theme" scalar_data_type="5" />
				</view_expr>
				<view_expr id="14" pp_view="3" view_part="GROUP" cont_type="SCALAR" valf_src_field="24" />
				<view_expr id="15" pp_view="3" view_part="HAVING" cont_type="SCALAR" valf_call_sroutine="GT">
					<view_expr id="16" pp_expr="15" cont_type="SCALAR" valf_call_sroutine="COUNT" />
					<view_expr id="17" pp_expr="15" cont_type="SCALAR" valf_literal="1" scalar_data_type="9" />
				</view_expr>
				<view_expr id="55" pp_view="3" view_part="ORDER" cont_type="SCALAR" valf_result_field="23" />
				<view_expr id="56" pp_view="3" view_part="ORDER" cont_type="SCALAR" valf_result_field="22" />
			</view>
			<routine id="1" pp_application="1" name="get_user" routine_type="FUNCTION" return_cont_type="CURSOR">
				<routine_arg id="1" pp_routine="1" name="curr_uid" cont_type="SCALAR" scalar_data_type="9" />
				<view id="5" pp_routine="1" name="get_user" view_type="JOINED" row_data_type="101">
					<view_src id="8" pp_view="5" name="m" match_view="1">
						<view_src_field id="30" pp_src="8" match_field="101" />
						<view_src_field id="31" pp_src="8" match_field="102" />
					</view_src>
					<view_expr id="1" pp_view="5" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="2" pp_expr="1" cont_type="SCALAR" valf_src_field="30" />
						<view_expr id="3" pp_expr="1" cont_type="SCALAR" valf_p_routine_arg="1" />
					</view_expr>
					<view_expr id="51" pp_view="5" view_part="ORDER" cont_type="SCALAR" valf_src_field="31" />
				</view>
				<routine_stmt id="1" pp_routine="1" call_sroutine="CURSOR_OPEN" />
			</routine>
			<routine id="2" pp_application="1" name="get_pwp" routine_type="FUNCTION" return_cont_type="CURSOR">
				<routine_arg id="2" pp_routine="2" name="srchw_fa" cont_type="SCALAR" scalar_data_type="5" />
				<routine_arg id="3" pp_routine="2" name="srchw_mo" cont_type="SCALAR" scalar_data_type="5" />
				<view id="6" pp_routine="2" name="get_pwp" view_type="JOINED" row_data_type="102">
					<view_src id="9" pp_view="6" name="m" match_view="2">
						<view_src_field id="27" pp_src="9" match_field="117" />
						<view_src_field id="28" pp_src="9" match_field="119" />
						<view_src_field id="29" pp_src="9" match_field="121" />
					</view_src>
					<view_expr id="4" pp_view="6" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="AND">
						<view_expr id="5" pp_expr="4" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="6" pp_expr="5" cont_type="SCALAR" valf_src_field="28" />
							<view_expr id="7" pp_expr="5" cont_type="SCALAR" valf_p_routine_arg="2" />
						</view_expr>
						<view_expr id="8" pp_expr="4" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="9" pp_expr="8" cont_type="SCALAR" valf_src_field="29" />
							<view_expr id="10" pp_expr="8" cont_type="SCALAR" valf_p_routine_arg="3" />
						</view_expr>
					</view_expr>
					<view_expr id="52" pp_view="6" view_part="ORDER" cont_type="SCALAR" valf_src_field="27" />
					<view_expr id="53" pp_view="6" view_part="ORDER" cont_type="SCALAR" valf_src_field="28" />
					<view_expr id="54" pp_view="6" view_part="ORDER" cont_type="SCALAR" valf_src_field="29" />
				</view>
				<routine_stmt id="2" pp_routine="2" call_sroutine="CURSOR_OPEN" />
			</routine>
			<routine id="3" pp_application="1" name="get_theme" routine_type="FUNCTION" return_cont_type="CURSOR">
				<view id="7" pp_routine="3" name="get_theme" view_type="ALIAS" row_data_type="103">
					<view_src id="10" pp_view="7" name="m" match_view="3" />
				</view>
				<routine_stmt id="3" pp_routine="3" call_sroutine="CURSOR_OPEN" />
			</routine>
			<routine id="4" pp_application="1" name="get_person" routine_type="FUNCTION" return_cont_type="CURSOR">
				<view id="4" pp_routine="4" name="get_person" view_type="ALIAS" row_data_type="4">
					<view_src id="7" pp_view="4" name="person" match_table="4" />
				</view>
				<routine_stmt id="4" pp_routine="4" call_sroutine="CURSOR_OPEN" />
			</routine>
		</application>
	</blueprints>
	<tools />
	<sites />
	<circumventions />
</root>
'
	);
}

######################################################################

1;
