#!perl

use 5.008001; use utf8; use strict; use warnings;

# This module is used when testing SQL::Routine.
# These tests check that a model can be built using the abstract wrapper 
# interface without errors, and serializes to the correct output.
# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SRT_Abstract;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();
	$model->auto_assert_deferrable_constraints( 1 );
	$model->auto_set_node_ids( 1 );
	$model->may_match_surrogate_node_ids( 1 );

	##### NEXT SET CATALOG ELEMENT-TYPE DETAILS #####

	$model->build_child_node_trees( [ map { { 'NODE_TYPE' => 'scalar_data_type', 'ATTRS' => $_ } } (
		{ 'si_name' => 'bin1k' , 'base_type' => 'STR_BIT', 'max_octets' =>  1_000, },
		{ 'si_name' => 'bin32k', 'base_type' => 'STR_BIT', 'max_octets' => 32_000, },
		{ 'si_name' => 'str4'  , 'base_type' => 'STR_CHAR', 'max_chars' =>  4, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 'uc_latin' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'si_name' => 'str10' , 'base_type' => 'STR_CHAR', 'max_chars' => 10, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'si_name' => 'str30' , 'base_type' => 'STR_CHAR', 'max_chars' =>    30, 
			'char_enc' => 'ASCII', 'trim_white' => 1, },
		{ 'si_name' => 'str2k' , 'base_type' => 'STR_CHAR', 'max_chars' => 2_000, 'char_enc' => 'UTF8', },
		{ 'si_name' => 'byte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, },
		{ 'si_name' => 'short', 'base_type' => 'NUM_INT', 'num_precision' =>  5, },
		{ 'si_name' => 'int'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, },
		{ 'si_name' => 'long' , 'base_type' => 'NUM_INT', 'num_precision' => 19, },
		{ 'si_name' => 'ubyte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, 'num_unsigned' => 1, },
		{ 'si_name' => 'ushort', 'base_type' => 'NUM_INT', 'num_precision' =>  5, 'num_unsigned' => 1, },
		{ 'si_name' => 'uint'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, 'num_unsigned' => 1, },
		{ 'si_name' => 'ulong' , 'base_type' => 'NUM_INT', 'num_precision' => 19, 'num_unsigned' => 1, },
		{ 'si_name' => 'float' , 'base_type' => 'NUM_APR', 'num_octets' => 4, },
		{ 'si_name' => 'double', 'base_type' => 'NUM_APR', 'num_octets' => 8, },
		{ 'si_name' => 'dec10p2', 'base_type' => 'NUM_EXA', 'num_precision' =>  10, 'num_scale' => 2, },
		{ 'si_name' => 'dec255' , 'base_type' => 'NUM_EXA', 'num_precision' => 255, },
		{ 'si_name' => 'boolean', 'base_type' => 'BOOLEAN', },
		{ 'si_name' => 'datetime', 'base_type' => 'DATM_FULL', 'calendar' => 'ABS', },
		{ 'si_name' => 'dtchines', 'base_type' => 'DATM_FULL', 'calendar' => 'CHI', },
		{ 'si_name' => 'sex'   , 'base_type' => 'STR_CHAR', 'max_chars' =>     1, 'char_enc' => 'ASCII', },
		{ 'si_name' => 'str20' , 'base_type' => 'STR_CHAR', 'max_chars' =>    20, 'char_enc' => 'ASCII', },
		{ 'si_name' => 'str100', 'base_type' => 'STR_CHAR', 'max_chars' =>   100, 'char_enc' => 'ASCII', },
		{ 'si_name' => 'str250', 'base_type' => 'STR_CHAR', 'max_chars' =>   250, 'char_enc' => 'ASCII', },
		{ 'si_name' => 'entitynm', 'base_type' => 'STR_CHAR', 'max_chars' =>  30, 'char_enc' => 'ASCII', },
		{ 'si_name' => 'generic' , 'base_type' => 'STR_CHAR', 'max_chars' => 250, 'char_enc' => 'ASCII', },
	) ] );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'person_id'   , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'alternate_id', 'scalar_data_type' => 'str20' , },
			{ 'si_name' => 'name'        , 'scalar_data_type' => 'str100', },
			{ 'si_name' => 'sex'         , 'scalar_data_type' => 'sex'   , },
			{ 'si_name' => 'father_id'   , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'mother_id'   , 'scalar_data_type' => 'int'   , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'person_with_parents', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'self_id'    , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'self_name'  , 'scalar_data_type' => 'str100', },
			{ 'si_name' => 'father_id'  , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'father_name', 'scalar_data_type' => 'str100', },
			{ 'si_name' => 'mother_id'  , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'mother_name', 'scalar_data_type' => 'str100', },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'user_id'      , 'scalar_data_type' => 'int'    , },
			{ 'si_name' => 'login_name'   , 'scalar_data_type' => 'str20'  , },
			{ 'si_name' => 'login_pass'   , 'scalar_data_type' => 'str20'  , },
			{ 'si_name' => 'private_name' , 'scalar_data_type' => 'str100' , },
			{ 'si_name' => 'private_email', 'scalar_data_type' => 'str100' , },
			{ 'si_name' => 'may_login'    , 'scalar_data_type' => 'boolean', },
			{ 'si_name' => 'max_sessions' , 'scalar_data_type' => 'byte'   , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'user_id'     , 'scalar_data_type' => 'int'   , },
			{ 'si_name' => 'public_name' , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'public_email', 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'web_url'     , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'contact_net' , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'contact_phy' , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'bio'         , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'plan'        , 'scalar_data_type' => 'str250', },
			{ 'si_name' => 'comments'    , 'scalar_data_type' => 'str250', },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'user_id'      , 'scalar_data_type' => 'int'    , },
			{ 'si_name' => 'login_name'   , 'scalar_data_type' => 'str20'  , },
			{ 'si_name' => 'login_pass'   , 'scalar_data_type' => 'str20'  , },
			{ 'si_name' => 'private_name' , 'scalar_data_type' => 'str100' , },
			{ 'si_name' => 'private_email', 'scalar_data_type' => 'str100' , },
			{ 'si_name' => 'may_login'    , 'scalar_data_type' => 'boolean', },
			{ 'si_name' => 'max_sessions' , 'scalar_data_type' => 'byte'   , },
			{ 'si_name' => 'public_name'  , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'public_email' , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'web_url'      , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'contact_net'  , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'contact_phy'  , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'bio'          , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'plan'         , 'scalar_data_type' => 'str250' , },
			{ 'si_name' => 'comments'     , 'scalar_data_type' => 'str250' , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'user_id'   , 'scalar_data_type' => 'int'     , },
			{ 'si_name' => 'pref_name' , 'scalar_data_type' => 'entitynm', },
			{ 'si_name' => 'pref_value', 'scalar_data_type' => 'generic' , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'si_name' => 'user_theme', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'si_name' => 'theme_name' , 'scalar_data_type' => 'generic', },
			{ 'si_name' => 'theme_count', 'scalar_data_type' => 'int'    , },
		) ),
	] } );

	##### NEXT SET APPLICATION ELEMENT-TYPE DETAILS #####

	# ... TODO ...

	##### NEXT SET CATALOG BLUEPRINT-TYPE DETAILS #####

	my $catalog = $model->build_child_node_tree( 
		{ 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'si_name' => 'The Catalog Blueprint' }, 
		'CHILDREN' => [ { 'NODE_TYPE' => 'owner', 'ATTRS' => { 'si_name' => 'Gene\'s Owner' } } ] } ); 

	my $schema = $catalog->build_child_node_tree( { 'NODE_TYPE' => 'schema', 
		'ATTRS' => { 'si_name' => 'gene', 'owner' => 'Gene\'s Owner', } } ); 

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'si_name' => 'person', 'row_data_type' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'si_row_field' => 'person_id', 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'si_row_field' => 'name'     , 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'si_name' => 'primary'        , 'index_type' => 'UNIQUE', }, 'person_id'    ], 
			[ { 'si_name' => 'ak_alternate_id', 'index_type' => 'UNIQUE', }, 'alternate_id' ], 
			[ { 'si_name' => 'fk_father', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'si_field' => 'father_id', 'f_field' => 'person_id' } ], 
			[ { 'si_name' => 'fk_mother', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'si_field' => 'mother_id', 'f_field' => 'person_id' } ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'si_name' => 'person_vw', 'view_type' => 'ALIAS', 'row_data_type' => 'person', 'may_write' => 1 }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => 'person', 'match' => 'person', }, },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'si_name' => 'person_with_parents', 'view_type' => 'JOINED', 'row_data_type' => 'person_with_parents', 'may_write' => 0, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => $_, 'match' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw( person_id name father_id mother_id ) ] 
		} } qw( self ) ),
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => $_, 'match' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw( person_id name ) ] 
		} } qw( father mother ) ),
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'father', 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'lhs_src_field' => 'father_id', 
				'rhs_src_field' => 'person_id',  } },
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'self', 
				'rhs_src' => 'mother', 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'lhs_src_field' => 'mother_id', 
				'rhs_src_field' => 'person_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
			{ 'view_part' => 'RESULT', 'set_result_field' => 'self_id'    , 'cont_type' => 'SCALAR', 'valf_src_field' => ['person_id','self'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'self_name'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['name'     ,'self'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'father_id'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['person_id','father'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'father_name', 'cont_type' => 'SCALAR', 'valf_src_field' => ['name'     ,'father'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'mother_id'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['person_id','mother'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'mother_name', 'cont_type' => 'SCALAR', 'valf_src_field' => ['name'     ,'mother'], },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'AND', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'LIKE', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_src_field' => ['name','father'], }, },
#				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
#					'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'srchw_fa', }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'LIKE', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_src_field' => ['name','mother'], }, },
#				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
#					'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'srchw_mo', }, },
			] },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'si_name' => 'user_auth', 'row_data_type' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'si_row_field' => 'user_id'      , 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'si_row_field' => 'login_name'   , 'mandatory' => 1, },
			{ 'si_row_field' => 'login_pass'   , 'mandatory' => 1, },
			{ 'si_row_field' => 'private_name' , 'mandatory' => 1, },
			{ 'si_row_field' => 'private_email', 'mandatory' => 1, },
			{ 'si_row_field' => 'may_login'    , 'mandatory' => 1, },
			{ 'si_row_field' => 'max_sessions' , 'mandatory' => 1, 'default_val' => 3, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'si_name' => 'primary'         , 'index_type' => 'UNIQUE', }, 'user_id'       ],
			[ { 'si_name' => 'ak_login_name'   , 'index_type' => 'UNIQUE', }, 'login_name'    ],
			[ { 'si_name' => 'ak_private_email', 'index_type' => 'UNIQUE', }, 'private_email' ],
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'si_name' => 'user_profile', 'row_data_type' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'si_row_field' => 'user_id'    , 'mandatory' => 1, },
			{ 'si_row_field' => 'public_name', 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'si_name' => 'primary'       , 'index_type' => 'UNIQUE', }, 'user_id'     ],
			[ { 'si_name' => 'ak_public_name', 'index_type' => 'UNIQUE', }, 'public_name' ],
			[ { 'si_name' => 'fk_user', 'index_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				{ 'si_field' => 'user_id', 'f_field' => 'user_id' } ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'si_name' => 'user', 'view_type' => 'JOINED', 'row_data_type' => 'user', 'may_write' => 1, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => 'user_auth', 
				'match' => 'user_auth', }, 'CHILDREN' => [ 
			( map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw(
				user_id login_name login_pass private_name private_email may_login max_sessions
			) ),
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => 'user_profile', 
				'match' => 'user_profile', }, 'CHILDREN' => [ 
			( map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw(
				user_id public_name public_email web_url contact_net contact_phy bio plan comments
			) ),
		] },
		{ 'NODE_TYPE' => 'view_join', 'ATTRS' => { 'lhs_src' => 'user_auth', 
				'rhs_src' => 'user_profile', 'join_op' => 'LEFT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_join_field', 'ATTRS' => { 'lhs_src_field' => 'user_id', 
				'rhs_src_field' => 'user_id',  } },
		] },
		( map { { 'NODE_TYPE' => 'view_expr', 'ATTRS' => $_ } } (
			{ 'view_part' => 'RESULT', 'set_result_field' => 'user_id'      , 'cont_type' => 'SCALAR', 'valf_src_field' => ['user_id'      ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'login_name'   , 'cont_type' => 'SCALAR', 'valf_src_field' => ['login_name'   ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'login_pass'   , 'cont_type' => 'SCALAR', 'valf_src_field' => ['login_pass'   ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'private_name' , 'cont_type' => 'SCALAR', 'valf_src_field' => ['private_name' ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'private_email', 'cont_type' => 'SCALAR', 'valf_src_field' => ['private_email','user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'may_login'    , 'cont_type' => 'SCALAR', 'valf_src_field' => ['may_login'    ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'max_sessions' , 'cont_type' => 'SCALAR', 'valf_src_field' => ['max_sessions' ,'user_auth'   ], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'public_name'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['public_name'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'public_email' , 'cont_type' => 'SCALAR', 'valf_src_field' => ['public_email' ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'web_url'      , 'cont_type' => 'SCALAR', 'valf_src_field' => ['web_url'      ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'contact_net'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['contact_net'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'contact_phy'  , 'cont_type' => 'SCALAR', 'valf_src_field' => ['contact_phy'  ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'bio'          , 'cont_type' => 'SCALAR', 'valf_src_field' => ['bio'          ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'plan'         , 'cont_type' => 'SCALAR', 'valf_src_field' => ['plan'         ,'user_profile'], },
			{ 'view_part' => 'RESULT', 'set_result_field' => 'comments'     , 'cont_type' => 'SCALAR', 'valf_src_field' => ['comments'     ,'user_profile'], },
		) ),
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'valf_src_field' => ['user_id','user_auth'], }, },
#			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
#				'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'curr_uid', }, },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'si_name' => 'user_pref', 'row_data_type' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'si_row_field' => 'user_id'  , 'mandatory' => 1, },
			{ 'si_row_field' => 'pref_name', 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'si_name' => 'primary', 'index_type' => 'UNIQUE', }, [ 'user_id', 'pref_name', ], ], 
			[ { 'si_name' => 'fk_user', 'index_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				[ { 'si_field' => 'user_id', 'f_field' => 'user_id' }, ], ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'si_name' => 'user_theme', 'view_type' => 'JOINED', 'row_data_type' => 'user_theme', 'may_write' => 0, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'si_name' => 'user_pref', 'match' => 'user_pref', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw( pref_name pref_value ) ] 
		},
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
			'set_result_field' => 'theme_name', 'cont_type' => 'SCALAR', 'valf_src_field' => ['pref_value','user_pref'], }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'RESULT', 
				'set_result_field' => 'theme_count', 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'COUNT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'valf_src_field' => ['pref_value','user_pref'], }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'WHERE', 
				'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'EQ', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'valf_src_field' => ['pref_name','user_pref'], }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'scalar_data_type' => 'str30', 'valf_literal' => 'theme', }, },
		] },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'GROUP', 
			'cont_type' => 'SCALAR', 'valf_src_field' => ['pref_value','user_pref'], }, },
		{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 'view_part' => 'HAVING', 
				'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'GT', }, 'CHILDREN' => [ 
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'COUNT', }, },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
				'cont_type' => 'SCALAR', 'scalar_data_type' => 'int', 'valf_literal' => '1', }, },
		] },
	] } );

	##### NEXT SET APPLICATION BLUEPRINT-TYPE DETAILS #####

	# ... TODO ...

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
'<?xml version="1.0" encoding="UTF-8"?>
<root>
	<elements>
		<scalar_data_type id="1" si_name="bin1k" base_type="STR_BIT" max_octets="1000" />
		<scalar_data_type id="2" si_name="bin32k" base_type="STR_BIT" max_octets="32000" />
		<scalar_data_type id="3" si_name="str4" base_type="STR_CHAR" max_chars="4" store_fixed="1" char_enc="ASCII" trim_white="1" uc_latin="1" pad_char=" " trim_pad="1" />
		<scalar_data_type id="4" si_name="str10" base_type="STR_CHAR" max_chars="10" store_fixed="1" char_enc="ASCII" trim_white="1" pad_char=" " trim_pad="1" />
		<scalar_data_type id="5" si_name="str30" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" trim_white="1" />
		<scalar_data_type id="6" si_name="str2k" base_type="STR_CHAR" max_chars="2000" char_enc="UTF8" />
		<scalar_data_type id="7" si_name="byte" base_type="NUM_INT" num_precision="3" />
		<scalar_data_type id="8" si_name="short" base_type="NUM_INT" num_precision="5" />
		<scalar_data_type id="9" si_name="int" base_type="NUM_INT" num_precision="10" />
		<scalar_data_type id="10" si_name="long" base_type="NUM_INT" num_precision="19" />
		<scalar_data_type id="11" si_name="ubyte" base_type="NUM_INT" num_precision="3" num_unsigned="1" />
		<scalar_data_type id="12" si_name="ushort" base_type="NUM_INT" num_precision="5" num_unsigned="1" />
		<scalar_data_type id="13" si_name="uint" base_type="NUM_INT" num_precision="10" num_unsigned="1" />
		<scalar_data_type id="14" si_name="ulong" base_type="NUM_INT" num_precision="19" num_unsigned="1" />
		<scalar_data_type id="15" si_name="float" base_type="NUM_APR" num_octets="4" />
		<scalar_data_type id="16" si_name="double" base_type="NUM_APR" num_octets="8" />
		<scalar_data_type id="17" si_name="dec10p2" base_type="NUM_EXA" num_precision="10" num_scale="2" />
		<scalar_data_type id="18" si_name="dec255" base_type="NUM_EXA" num_precision="255" />
		<scalar_data_type id="19" si_name="boolean" base_type="BOOLEAN" />
		<scalar_data_type id="20" si_name="datetime" base_type="DATM_FULL" calendar="ABS" />
		<scalar_data_type id="21" si_name="dtchines" base_type="DATM_FULL" calendar="CHI" />
		<scalar_data_type id="22" si_name="sex" base_type="STR_CHAR" max_chars="1" char_enc="ASCII" />
		<scalar_data_type id="23" si_name="str20" base_type="STR_CHAR" max_chars="20" char_enc="ASCII" />
		<scalar_data_type id="24" si_name="str100" base_type="STR_CHAR" max_chars="100" char_enc="ASCII" />
		<scalar_data_type id="25" si_name="str250" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<scalar_data_type id="26" si_name="entitynm" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" />
		<scalar_data_type id="27" si_name="generic" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<row_data_type id="28" si_name="person">
			<row_data_type_field id="29" si_name="person_id" scalar_data_type="9" />
			<row_data_type_field id="30" si_name="alternate_id" scalar_data_type="23" />
			<row_data_type_field id="31" si_name="name" scalar_data_type="24" />
			<row_data_type_field id="32" si_name="sex" scalar_data_type="22" />
			<row_data_type_field id="33" si_name="father_id" scalar_data_type="9" />
			<row_data_type_field id="34" si_name="mother_id" scalar_data_type="9" />
		</row_data_type>
		<row_data_type id="35" si_name="person_with_parents">
			<row_data_type_field id="36" si_name="self_id" scalar_data_type="9" />
			<row_data_type_field id="37" si_name="self_name" scalar_data_type="24" />
			<row_data_type_field id="38" si_name="father_id" scalar_data_type="9" />
			<row_data_type_field id="39" si_name="father_name" scalar_data_type="24" />
			<row_data_type_field id="40" si_name="mother_id" scalar_data_type="9" />
			<row_data_type_field id="41" si_name="mother_name" scalar_data_type="24" />
		</row_data_type>
		<row_data_type id="42" si_name="user_auth">
			<row_data_type_field id="43" si_name="user_id" scalar_data_type="9" />
			<row_data_type_field id="44" si_name="login_name" scalar_data_type="23" />
			<row_data_type_field id="45" si_name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="46" si_name="private_name" scalar_data_type="24" />
			<row_data_type_field id="47" si_name="private_email" scalar_data_type="24" />
			<row_data_type_field id="48" si_name="may_login" scalar_data_type="19" />
			<row_data_type_field id="49" si_name="max_sessions" scalar_data_type="7" />
		</row_data_type>
		<row_data_type id="50" si_name="user_profile">
			<row_data_type_field id="51" si_name="user_id" scalar_data_type="9" />
			<row_data_type_field id="52" si_name="public_name" scalar_data_type="25" />
			<row_data_type_field id="53" si_name="public_email" scalar_data_type="25" />
			<row_data_type_field id="54" si_name="web_url" scalar_data_type="25" />
			<row_data_type_field id="55" si_name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="56" si_name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="57" si_name="bio" scalar_data_type="25" />
			<row_data_type_field id="58" si_name="plan" scalar_data_type="25" />
			<row_data_type_field id="59" si_name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="60" si_name="user">
			<row_data_type_field id="61" si_name="user_id" scalar_data_type="9" />
			<row_data_type_field id="62" si_name="login_name" scalar_data_type="23" />
			<row_data_type_field id="63" si_name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="64" si_name="private_name" scalar_data_type="24" />
			<row_data_type_field id="65" si_name="private_email" scalar_data_type="24" />
			<row_data_type_field id="66" si_name="may_login" scalar_data_type="19" />
			<row_data_type_field id="67" si_name="max_sessions" scalar_data_type="7" />
			<row_data_type_field id="68" si_name="public_name" scalar_data_type="25" />
			<row_data_type_field id="69" si_name="public_email" scalar_data_type="25" />
			<row_data_type_field id="70" si_name="web_url" scalar_data_type="25" />
			<row_data_type_field id="71" si_name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="72" si_name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="73" si_name="bio" scalar_data_type="25" />
			<row_data_type_field id="74" si_name="plan" scalar_data_type="25" />
			<row_data_type_field id="75" si_name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="76" si_name="user_pref">
			<row_data_type_field id="77" si_name="user_id" scalar_data_type="9" />
			<row_data_type_field id="78" si_name="pref_name" scalar_data_type="26" />
			<row_data_type_field id="79" si_name="pref_value" scalar_data_type="27" />
		</row_data_type>
		<row_data_type id="80" si_name="user_theme">
			<row_data_type_field id="81" si_name="theme_name" scalar_data_type="27" />
			<row_data_type_field id="82" si_name="theme_count" scalar_data_type="9" />
		</row_data_type>
	</elements>
	<blueprints>
		<catalog id="83" si_name="The Catalog Blueprint">
			<owner id="84" si_name="Gene\'s Owner" />
			<schema id="85" si_name="gene" owner="84">
				<table id="86" si_name="person" row_data_type="28">
					<table_field id="87" si_row_field="29" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="88" si_row_field="31" mandatory="1" />
					<table_index id="89" si_name="primary" index_type="UNIQUE">
						<table_index_field id="90" si_field="29" />
					</table_index>
					<table_index id="91" si_name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="92" si_field="30" />
					</table_index>
					<table_index id="93" si_name="fk_father" index_type="FOREIGN" f_table="86">
						<table_index_field id="94" si_field="33" f_field="29" />
					</table_index>
					<table_index id="95" si_name="fk_mother" index_type="FOREIGN" f_table="86">
						<table_index_field id="96" si_field="34" f_field="29" />
					</table_index>
				</table>
				<view id="97" si_name="person_vw" view_type="ALIAS" row_data_type="28" may_write="1">
					<view_src id="98" si_name="person" match="86" />
				</view>
				<view id="99" si_name="person_with_parents" view_type="JOINED" row_data_type="35" may_write="0">
					<view_src id="100" si_name="self" match="86">
						<view_src_field id="101" si_match_field="29" />
						<view_src_field id="102" si_match_field="31" />
						<view_src_field id="103" si_match_field="33" />
						<view_src_field id="104" si_match_field="34" />
					</view_src>
					<view_src id="105" si_name="father" match="86">
						<view_src_field id="106" si_match_field="29" />
						<view_src_field id="107" si_match_field="31" />
					</view_src>
					<view_src id="108" si_name="mother" match="86">
						<view_src_field id="109" si_match_field="29" />
						<view_src_field id="110" si_match_field="31" />
					</view_src>
					<view_join id="111" lhs_src="100" rhs_src="105" join_op="LEFT">
						<view_join_field id="112" lhs_src_field="103" rhs_src_field="106" />
					</view_join>
					<view_join id="113" lhs_src="100" rhs_src="108" join_op="LEFT">
						<view_join_field id="114" lhs_src_field="104" rhs_src_field="109" />
					</view_join>
					<view_expr id="115" view_part="RESULT" set_result_field="36" cont_type="SCALAR" valf_src_field="101" />
					<view_expr id="116" view_part="RESULT" set_result_field="37" cont_type="SCALAR" valf_src_field="102" />
					<view_expr id="117" view_part="RESULT" set_result_field="38" cont_type="SCALAR" valf_src_field="106" />
					<view_expr id="118" view_part="RESULT" set_result_field="39" cont_type="SCALAR" valf_src_field="107" />
					<view_expr id="119" view_part="RESULT" set_result_field="40" cont_type="SCALAR" valf_src_field="109" />
					<view_expr id="120" view_part="RESULT" set_result_field="41" cont_type="SCALAR" valf_src_field="110" />
					<view_expr id="121" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="AND">
						<view_expr id="122" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="123" cont_type="SCALAR" valf_src_field="107" />
						</view_expr>
						<view_expr id="124" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="125" cont_type="SCALAR" valf_src_field="110" />
						</view_expr>
					</view_expr>
				</view>
				<table id="126" si_name="user_auth" row_data_type="42">
					<table_field id="127" si_row_field="43" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="128" si_row_field="44" mandatory="1" />
					<table_field id="129" si_row_field="45" mandatory="1" />
					<table_field id="130" si_row_field="46" mandatory="1" />
					<table_field id="131" si_row_field="47" mandatory="1" />
					<table_field id="132" si_row_field="48" mandatory="1" />
					<table_field id="133" si_row_field="49" mandatory="1" default_val="3" />
					<table_index id="134" si_name="primary" index_type="UNIQUE">
						<table_index_field id="135" si_field="43" />
					</table_index>
					<table_index id="136" si_name="ak_login_name" index_type="UNIQUE">
						<table_index_field id="137" si_field="44" />
					</table_index>
					<table_index id="138" si_name="ak_private_email" index_type="UNIQUE">
						<table_index_field id="139" si_field="47" />
					</table_index>
				</table>
				<table id="140" si_name="user_profile" row_data_type="50">
					<table_field id="141" si_row_field="51" mandatory="1" />
					<table_field id="142" si_row_field="52" mandatory="1" />
					<table_index id="143" si_name="primary" index_type="UNIQUE">
						<table_index_field id="144" si_field="51" />
					</table_index>
					<table_index id="145" si_name="ak_public_name" index_type="UNIQUE">
						<table_index_field id="146" si_field="52" />
					</table_index>
					<table_index id="147" si_name="fk_user" index_type="FOREIGN" f_table="126">
						<table_index_field id="148" si_field="51" f_field="43" />
					</table_index>
				</table>
				<view id="149" si_name="user" view_type="JOINED" row_data_type="60" may_write="1">
					<view_src id="150" si_name="user_auth" match="126">
						<view_src_field id="151" si_match_field="43" />
						<view_src_field id="152" si_match_field="44" />
						<view_src_field id="153" si_match_field="45" />
						<view_src_field id="154" si_match_field="46" />
						<view_src_field id="155" si_match_field="47" />
						<view_src_field id="156" si_match_field="48" />
						<view_src_field id="157" si_match_field="49" />
					</view_src>
					<view_src id="158" si_name="user_profile" match="140">
						<view_src_field id="159" si_match_field="51" />
						<view_src_field id="160" si_match_field="52" />
						<view_src_field id="161" si_match_field="53" />
						<view_src_field id="162" si_match_field="54" />
						<view_src_field id="163" si_match_field="55" />
						<view_src_field id="164" si_match_field="56" />
						<view_src_field id="165" si_match_field="57" />
						<view_src_field id="166" si_match_field="58" />
						<view_src_field id="167" si_match_field="59" />
					</view_src>
					<view_join id="168" lhs_src="150" rhs_src="158" join_op="LEFT">
						<view_join_field id="169" lhs_src_field="151" rhs_src_field="159" />
					</view_join>
					<view_expr id="170" view_part="RESULT" set_result_field="61" cont_type="SCALAR" valf_src_field="151" />
					<view_expr id="171" view_part="RESULT" set_result_field="62" cont_type="SCALAR" valf_src_field="152" />
					<view_expr id="172" view_part="RESULT" set_result_field="63" cont_type="SCALAR" valf_src_field="153" />
					<view_expr id="173" view_part="RESULT" set_result_field="64" cont_type="SCALAR" valf_src_field="154" />
					<view_expr id="174" view_part="RESULT" set_result_field="65" cont_type="SCALAR" valf_src_field="155" />
					<view_expr id="175" view_part="RESULT" set_result_field="66" cont_type="SCALAR" valf_src_field="156" />
					<view_expr id="176" view_part="RESULT" set_result_field="67" cont_type="SCALAR" valf_src_field="157" />
					<view_expr id="177" view_part="RESULT" set_result_field="68" cont_type="SCALAR" valf_src_field="160" />
					<view_expr id="178" view_part="RESULT" set_result_field="69" cont_type="SCALAR" valf_src_field="161" />
					<view_expr id="179" view_part="RESULT" set_result_field="70" cont_type="SCALAR" valf_src_field="162" />
					<view_expr id="180" view_part="RESULT" set_result_field="71" cont_type="SCALAR" valf_src_field="163" />
					<view_expr id="181" view_part="RESULT" set_result_field="72" cont_type="SCALAR" valf_src_field="164" />
					<view_expr id="182" view_part="RESULT" set_result_field="73" cont_type="SCALAR" valf_src_field="165" />
					<view_expr id="183" view_part="RESULT" set_result_field="74" cont_type="SCALAR" valf_src_field="166" />
					<view_expr id="184" view_part="RESULT" set_result_field="75" cont_type="SCALAR" valf_src_field="167" />
					<view_expr id="185" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="186" cont_type="SCALAR" valf_src_field="151" />
					</view_expr>
				</view>
				<table id="187" si_name="user_pref" row_data_type="76">
					<table_field id="188" si_row_field="77" mandatory="1" />
					<table_field id="189" si_row_field="78" mandatory="1" />
					<table_index id="190" si_name="primary" index_type="UNIQUE">
						<table_index_field id="191" si_field="77" />
						<table_index_field id="192" si_field="78" />
					</table_index>
					<table_index id="193" si_name="fk_user" index_type="FOREIGN" f_table="126">
						<table_index_field id="194" si_field="77" f_field="43" />
					</table_index>
				</table>
				<view id="195" si_name="user_theme" view_type="JOINED" row_data_type="80" may_write="0">
					<view_src id="196" si_name="user_pref" match="187">
						<view_src_field id="197" si_match_field="78" />
						<view_src_field id="198" si_match_field="79" />
					</view_src>
					<view_expr id="199" view_part="RESULT" set_result_field="81" cont_type="SCALAR" valf_src_field="198" />
					<view_expr id="200" view_part="RESULT" set_result_field="82" cont_type="SCALAR" valf_call_sroutine="COUNT">
						<view_expr id="201" cont_type="SCALAR" valf_src_field="198" />
					</view_expr>
					<view_expr id="202" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="203" cont_type="SCALAR" valf_src_field="197" />
						<view_expr id="204" cont_type="SCALAR" valf_literal="theme" scalar_data_type="5" />
					</view_expr>
					<view_expr id="205" view_part="GROUP" cont_type="SCALAR" valf_src_field="198" />
					<view_expr id="206" view_part="HAVING" cont_type="SCALAR" valf_call_sroutine="GT">
						<view_expr id="207" cont_type="SCALAR" valf_call_sroutine="COUNT" />
						<view_expr id="208" cont_type="SCALAR" valf_literal="1" scalar_data_type="9" />
					</view_expr>
				</view>
			</schema>
		</catalog>
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
