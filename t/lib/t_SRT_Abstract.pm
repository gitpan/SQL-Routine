# This module is used when testing SQL::Routine.
# These tests check that a model can be built using the abstract wrapper 
# interface without errors, and serializes to the correct output.
# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SRT_Abstract;
use strict;
use warnings;

######################################################################

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();
	$model->auto_assert_deferrable_constraints( 1 );
	$model->auto_set_node_ids( 1 );
	$model->use_abstract_interface( 1 );

	##### NEXT SET CATALOG ELEMENT-TYPE DETAILS #####

	$model->build_child_node_trees( [ map { { 'NODE_TYPE' => 'scalar_data_type', 'ATTRS' => $_ } } (
		{ 'name' => 'bin1k' , 'base_type' => 'STR_BIT', 'max_octets' =>  1_000, },
		{ 'name' => 'bin32k', 'base_type' => 'STR_BIT', 'max_octets' => 32_000, },
		{ 'name' => 'str4'  , 'base_type' => 'STR_CHAR', 'max_chars' =>  4, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 'uc_latin' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'name' => 'str10' , 'base_type' => 'STR_CHAR', 'max_chars' => 10, 'store_fixed' => 1, 
			'char_enc' => 'ASCII', 'trim_white' => 1, 
			'pad_char' => ' ', 'trim_pad' => 1, },
		{ 'name' => 'str30' , 'base_type' => 'STR_CHAR', 'max_chars' =>    30, 
			'char_enc' => 'ASCII', 'trim_white' => 1, },
		{ 'name' => 'str2k' , 'base_type' => 'STR_CHAR', 'max_chars' => 2_000, 'char_enc' => 'UTF8', },
		{ 'name' => 'byte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, },
		{ 'name' => 'short', 'base_type' => 'NUM_INT', 'num_precision' =>  5, },
		{ 'name' => 'int'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, },
		{ 'name' => 'long' , 'base_type' => 'NUM_INT', 'num_precision' => 19, },
		{ 'name' => 'ubyte' , 'base_type' => 'NUM_INT', 'num_precision' =>  3, 'num_unsigned' => 1, },
		{ 'name' => 'ushort', 'base_type' => 'NUM_INT', 'num_precision' =>  5, 'num_unsigned' => 1, },
		{ 'name' => 'uint'  , 'base_type' => 'NUM_INT', 'num_precision' => 10, 'num_unsigned' => 1, },
		{ 'name' => 'ulong' , 'base_type' => 'NUM_INT', 'num_precision' => 19, 'num_unsigned' => 1, },
		{ 'name' => 'float' , 'base_type' => 'NUM_APR', 'num_octets' => 4, },
		{ 'name' => 'double', 'base_type' => 'NUM_APR', 'num_octets' => 8, },
		{ 'name' => 'dec10p2', 'base_type' => 'NUM_EXA', 'num_precision' =>  10, 'num_scale' => 2, },
		{ 'name' => 'dec255' , 'base_type' => 'NUM_EXA', 'num_precision' => 255, },
		{ 'name' => 'boolean', 'base_type' => 'BOOLEAN', },
		{ 'name' => 'datetime', 'base_type' => 'DATM_FULL', 'calendar' => 'ABS', },
		{ 'name' => 'dtchines', 'base_type' => 'DATM_FULL', 'calendar' => 'CHI', },
		{ 'name' => 'sex'   , 'base_type' => 'STR_CHAR', 'max_chars' =>     1, 'char_enc' => 'ASCII', },
		{ 'name' => 'str20' , 'base_type' => 'STR_CHAR', 'max_chars' =>    20, 'char_enc' => 'ASCII', },
		{ 'name' => 'str100', 'base_type' => 'STR_CHAR', 'max_chars' =>   100, 'char_enc' => 'ASCII', },
		{ 'name' => 'str250', 'base_type' => 'STR_CHAR', 'max_chars' =>   250, 'char_enc' => 'ASCII', },
		{ 'name' => 'entitynm', 'base_type' => 'STR_CHAR', 'max_chars' =>  30, 'char_enc' => 'ASCII', },
		{ 'name' => 'generic' , 'base_type' => 'STR_CHAR', 'max_chars' => 250, 'char_enc' => 'ASCII', },
	) ] );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'person_id'   , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'alternate_id', 'scalar_data_type' => 'str20' , },
			{ 'name' => 'name'        , 'scalar_data_type' => 'str100', },
			{ 'name' => 'sex'         , 'scalar_data_type' => 'sex'   , },
			{ 'name' => 'father_id'   , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'mother_id'   , 'scalar_data_type' => 'int'   , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'person_with_parents', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'self_id'    , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'self_name'  , 'scalar_data_type' => 'str100', },
			{ 'name' => 'father_id'  , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'father_name', 'scalar_data_type' => 'str100', },
			{ 'name' => 'mother_id'  , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'mother_name', 'scalar_data_type' => 'str100', },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'      , 'scalar_data_type' => 'int'    , },
			{ 'name' => 'login_name'   , 'scalar_data_type' => 'str20'  , },
			{ 'name' => 'login_pass'   , 'scalar_data_type' => 'str20'  , },
			{ 'name' => 'private_name' , 'scalar_data_type' => 'str100' , },
			{ 'name' => 'private_email', 'scalar_data_type' => 'str100' , },
			{ 'name' => 'may_login'    , 'scalar_data_type' => 'boolean', },
			{ 'name' => 'max_sessions' , 'scalar_data_type' => 'byte'   , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'     , 'scalar_data_type' => 'int'   , },
			{ 'name' => 'public_name' , 'scalar_data_type' => 'str250', },
			{ 'name' => 'public_email', 'scalar_data_type' => 'str250', },
			{ 'name' => 'web_url'     , 'scalar_data_type' => 'str250', },
			{ 'name' => 'contact_net' , 'scalar_data_type' => 'str250', },
			{ 'name' => 'contact_phy' , 'scalar_data_type' => 'str250', },
			{ 'name' => 'bio'         , 'scalar_data_type' => 'str250', },
			{ 'name' => 'plan'        , 'scalar_data_type' => 'str250', },
			{ 'name' => 'comments'    , 'scalar_data_type' => 'str250', },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'user', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'      , 'scalar_data_type' => 'int'    , },
			{ 'name' => 'login_name'   , 'scalar_data_type' => 'str20'  , },
			{ 'name' => 'login_pass'   , 'scalar_data_type' => 'str20'  , },
			{ 'name' => 'private_name' , 'scalar_data_type' => 'str100' , },
			{ 'name' => 'private_email', 'scalar_data_type' => 'str100' , },
			{ 'name' => 'may_login'    , 'scalar_data_type' => 'boolean', },
			{ 'name' => 'max_sessions' , 'scalar_data_type' => 'byte'   , },
			{ 'name' => 'public_name'  , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'public_email' , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'web_url'      , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'contact_net'  , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'contact_phy'  , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'bio'          , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'plan'         , 'scalar_data_type' => 'str250' , },
			{ 'name' => 'comments'     , 'scalar_data_type' => 'str250' , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'user_id'   , 'scalar_data_type' => 'int'     , },
			{ 'name' => 'pref_name' , 'scalar_data_type' => 'entitynm', },
			{ 'name' => 'pref_value', 'scalar_data_type' => 'generic' , },
		) ),
	] } );

	$model->build_child_node_tree( { 'NODE_TYPE' => 'row_data_type', 
			'ATTRS' => { 'name' => 'user_theme', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'row_data_type_field', 'ATTRS' => $_ } } (
			{ 'name' => 'theme_name' , 'scalar_data_type' => 'generic', },
			{ 'name' => 'theme_count', 'scalar_data_type' => 'int'    , },
		) ),
	] } );

	##### NEXT SET APPLICATION ELEMENT-TYPE DETAILS #####

	# ... TODO ...

	##### NEXT SET CATALOG BLUEPRINT-TYPE DETAILS #####

	my $catalog = $model->build_child_node_tree( 
		{ 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'id' => 1, 'name' => 'The Catalog Blueprint' }, 
		'CHILDREN' => [ { 'NODE_TYPE' => 'owner', 'ATTRS' => { 'id' =>  1, } } ] } ); 

	my $schema = $catalog->build_child_node_tree( { 'NODE_TYPE' => 'schema', 
		'ATTRS' => { 'id' => 1, 'name' => 'gene', 'owner' => 1, } } ); 

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'person', 'row_data_type' => 'person', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'row_field' => 'person_id', 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'row_field' => 'name'     , 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'        , 'index_type' => 'UNIQUE', }, 'person_id'    ], 
			[ { 'name' => 'ak_alternate_id', 'index_type' => 'UNIQUE', }, 'alternate_id' ], 
			[ { 'name' => 'fk_father', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'field' => 'father_id', 'f_field' => 'person_id' } ], 
			[ { 'name' => 'fk_mother', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, 
				{ 'field' => 'mother_id', 'f_field' => 'person_id' } ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'person_vw', 'view_type' => 'ALIAS', 'row_data_type' => 'person', 'may_write' => 1 }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'person', 'match_table' => 'person', }, },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'person_with_parents', 'view_type' => 'JOINED', 'row_data_type' => 'person_with_parents', 'may_write' => 0, }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
			'CHILDREN' => [ map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw( person_id name father_id mother_id ) ] 
		} } qw( self ) ),
		( map { { 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => $_, 'match_table' => 'person', }, 
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
#					'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 'srchw_fa', }, },
			] },
			{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'LIKE', }, 'CHILDREN' => [ 
				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
					'cont_type' => 'SCALAR', 'valf_src_field' => ['name','mother'], }, },
#				{ 'NODE_TYPE' => 'view_expr', 'ATTRS' => { 
#					'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 'srchw_mo', }, },
			] },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_auth', 'row_data_type' => 'user_auth', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'row_field' => 'user_id'      , 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, },
			{ 'row_field' => 'login_name'   , 'mandatory' => 1, },
			{ 'row_field' => 'login_pass'   , 'mandatory' => 1, },
			{ 'row_field' => 'private_name' , 'mandatory' => 1, },
			{ 'row_field' => 'private_email', 'mandatory' => 1, },
			{ 'row_field' => 'may_login'    , 'mandatory' => 1, },
			{ 'row_field' => 'max_sessions' , 'mandatory' => 1, 'default_val' => 3, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'         , 'index_type' => 'UNIQUE', }, 'user_id'       ],
			[ { 'name' => 'ak_login_name'   , 'index_type' => 'UNIQUE', }, 'login_name'    ],
			[ { 'name' => 'ak_private_email', 'index_type' => 'UNIQUE', }, 'private_email' ],
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_profile', 'row_data_type' => 'user_profile', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'row_field' => 'user_id'    , 'mandatory' => 1, },
			{ 'row_field' => 'public_name', 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 
				'CHILDREN' => { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_->[1] } } } (
			[ { 'name' => 'primary'       , 'index_type' => 'UNIQUE', }, 'user_id'     ],
			[ { 'name' => 'ak_public_name', 'index_type' => 'UNIQUE', }, 'public_name' ],
			[ { 'name' => 'fk_user', 'index_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				{ 'field' => 'user_id', 'f_field' => 'user_id' } ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'user', 'view_type' => 'JOINED', 'row_data_type' => 'user', 'may_write' => 1, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_auth', 
				'match_table' => 'user_auth', }, 'CHILDREN' => [ 
			( map { { 'NODE_TYPE' => 'view_src_field', 'ATTRS' => $_ } } qw(
				user_id login_name login_pass private_name private_email may_login max_sessions
			) ),
		] },
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_profile', 
				'match_table' => 'user_profile', }, 'CHILDREN' => [ 
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
#				'cont_type' => 'SCALAR', 'valf_p_routine_arg' => 'curr_uid', }, },
		] },
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'table', 
			'ATTRS' => { 'name' => 'user_pref', 'row_data_type' => 'user_pref', }, 'CHILDREN' => [ 
		( map { { 'NODE_TYPE' => 'table_field', 'ATTRS' => $_ } } (
			{ 'row_field' => 'user_id'  , 'mandatory' => 1, },
			{ 'row_field' => 'pref_name', 'mandatory' => 1, },
		) ),
		( map { { 'NODE_TYPE' => 'table_index', 'ATTRS' => $_->[0], 'CHILDREN' => [ 
				map { { 'NODE_TYPE' => 'table_index_field', 'ATTRS' => $_ } } @{$_->[1]}
				] } } (
			[ { 'name' => 'primary', 'index_type' => 'UNIQUE', }, [ 'user_id', 'pref_name', ], ], 
			[ { 'name' => 'fk_user', 'index_type' => 'FOREIGN', 'f_table' => 'user_auth', }, 
				[ { 'field' => 'user_id', 'f_field' => 'user_id' }, ], ], 
		) ),
	] } );

	$schema->build_child_node_tree( { 'NODE_TYPE' => 'view', 
			'ATTRS' => { 'name' => 'user_theme', 'view_type' => 'JOINED', 'row_data_type' => 'user_theme', 'may_write' => 0, }, 'CHILDREN' => [ 
		{ 'NODE_TYPE' => 'view_src', 'ATTRS' => { 'name' => 'user_pref', 'match_table' => 'user_pref', }, 
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
		<scalar_data_type id="22" name="sex" base_type="STR_CHAR" max_chars="1" char_enc="ASCII" />
		<scalar_data_type id="23" name="str20" base_type="STR_CHAR" max_chars="20" char_enc="ASCII" />
		<scalar_data_type id="24" name="str100" base_type="STR_CHAR" max_chars="100" char_enc="ASCII" />
		<scalar_data_type id="25" name="str250" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<scalar_data_type id="26" name="entitynm" base_type="STR_CHAR" max_chars="30" char_enc="ASCII" />
		<scalar_data_type id="27" name="generic" base_type="STR_CHAR" max_chars="250" char_enc="ASCII" />
		<row_data_type id="1" name="person">
			<row_data_type_field id="1" pp_row_data_type="1" name="person_id" scalar_data_type="9" />
			<row_data_type_field id="2" pp_row_data_type="1" name="alternate_id" scalar_data_type="23" />
			<row_data_type_field id="3" pp_row_data_type="1" name="name" scalar_data_type="24" />
			<row_data_type_field id="4" pp_row_data_type="1" name="sex" scalar_data_type="22" />
			<row_data_type_field id="5" pp_row_data_type="1" name="father_id" scalar_data_type="9" />
			<row_data_type_field id="6" pp_row_data_type="1" name="mother_id" scalar_data_type="9" />
		</row_data_type>
		<row_data_type id="2" name="person_with_parents">
			<row_data_type_field id="7" pp_row_data_type="2" name="self_id" scalar_data_type="9" />
			<row_data_type_field id="8" pp_row_data_type="2" name="self_name" scalar_data_type="24" />
			<row_data_type_field id="9" pp_row_data_type="2" name="father_id" scalar_data_type="9" />
			<row_data_type_field id="10" pp_row_data_type="2" name="father_name" scalar_data_type="24" />
			<row_data_type_field id="11" pp_row_data_type="2" name="mother_id" scalar_data_type="9" />
			<row_data_type_field id="12" pp_row_data_type="2" name="mother_name" scalar_data_type="24" />
		</row_data_type>
		<row_data_type id="3" name="user_auth">
			<row_data_type_field id="13" pp_row_data_type="3" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="14" pp_row_data_type="3" name="login_name" scalar_data_type="23" />
			<row_data_type_field id="15" pp_row_data_type="3" name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="16" pp_row_data_type="3" name="private_name" scalar_data_type="24" />
			<row_data_type_field id="17" pp_row_data_type="3" name="private_email" scalar_data_type="24" />
			<row_data_type_field id="18" pp_row_data_type="3" name="may_login" scalar_data_type="19" />
			<row_data_type_field id="19" pp_row_data_type="3" name="max_sessions" scalar_data_type="7" />
		</row_data_type>
		<row_data_type id="4" name="user_profile">
			<row_data_type_field id="20" pp_row_data_type="4" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="21" pp_row_data_type="4" name="public_name" scalar_data_type="25" />
			<row_data_type_field id="22" pp_row_data_type="4" name="public_email" scalar_data_type="25" />
			<row_data_type_field id="23" pp_row_data_type="4" name="web_url" scalar_data_type="25" />
			<row_data_type_field id="24" pp_row_data_type="4" name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="25" pp_row_data_type="4" name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="26" pp_row_data_type="4" name="bio" scalar_data_type="25" />
			<row_data_type_field id="27" pp_row_data_type="4" name="plan" scalar_data_type="25" />
			<row_data_type_field id="28" pp_row_data_type="4" name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="5" name="user">
			<row_data_type_field id="29" pp_row_data_type="5" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="30" pp_row_data_type="5" name="login_name" scalar_data_type="23" />
			<row_data_type_field id="31" pp_row_data_type="5" name="login_pass" scalar_data_type="23" />
			<row_data_type_field id="32" pp_row_data_type="5" name="private_name" scalar_data_type="24" />
			<row_data_type_field id="33" pp_row_data_type="5" name="private_email" scalar_data_type="24" />
			<row_data_type_field id="34" pp_row_data_type="5" name="may_login" scalar_data_type="19" />
			<row_data_type_field id="35" pp_row_data_type="5" name="max_sessions" scalar_data_type="7" />
			<row_data_type_field id="36" pp_row_data_type="5" name="public_name" scalar_data_type="25" />
			<row_data_type_field id="37" pp_row_data_type="5" name="public_email" scalar_data_type="25" />
			<row_data_type_field id="38" pp_row_data_type="5" name="web_url" scalar_data_type="25" />
			<row_data_type_field id="39" pp_row_data_type="5" name="contact_net" scalar_data_type="25" />
			<row_data_type_field id="40" pp_row_data_type="5" name="contact_phy" scalar_data_type="25" />
			<row_data_type_field id="41" pp_row_data_type="5" name="bio" scalar_data_type="25" />
			<row_data_type_field id="42" pp_row_data_type="5" name="plan" scalar_data_type="25" />
			<row_data_type_field id="43" pp_row_data_type="5" name="comments" scalar_data_type="25" />
		</row_data_type>
		<row_data_type id="6" name="user_pref">
			<row_data_type_field id="44" pp_row_data_type="6" name="user_id" scalar_data_type="9" />
			<row_data_type_field id="45" pp_row_data_type="6" name="pref_name" scalar_data_type="26" />
			<row_data_type_field id="46" pp_row_data_type="6" name="pref_value" scalar_data_type="27" />
		</row_data_type>
		<row_data_type id="7" name="user_theme">
			<row_data_type_field id="47" pp_row_data_type="7" name="theme_name" scalar_data_type="27" />
			<row_data_type_field id="48" pp_row_data_type="7" name="theme_count" scalar_data_type="9" />
		</row_data_type>
	</elements>
	<blueprints>
		<catalog id="1" name="The Catalog Blueprint">
			<owner id="1" pp_catalog="1" />
			<schema id="1" pp_catalog="1" name="gene" owner="1">
				<table id="1" pp_schema="1" name="person" row_data_type="1">
					<table_field id="1" pp_table="1" row_field="1" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="2" pp_table="1" row_field="3" mandatory="1" />
					<table_index id="1" pp_table="1" name="primary" index_type="UNIQUE">
						<table_index_field id="1" pp_table_index="1" field="1" />
					</table_index>
					<table_index id="2" pp_table="1" name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="2" pp_table_index="2" field="2" />
					</table_index>
					<table_index id="3" pp_table="1" name="fk_father" index_type="FOREIGN" f_table="1">
						<table_index_field id="3" pp_table_index="3" field="5" f_field="1" />
					</table_index>
					<table_index id="4" pp_table="1" name="fk_mother" index_type="FOREIGN" f_table="1">
						<table_index_field id="4" pp_table_index="4" field="6" f_field="1" />
					</table_index>
				</table>
				<view id="1" pp_schema="1" name="person_vw" view_type="ALIAS" row_data_type="1" may_write="1">
					<view_src id="1" pp_view="1" name="person" match_table="1" />
				</view>
				<view id="2" pp_schema="1" name="person_with_parents" view_type="JOINED" row_data_type="2" may_write="0">
					<view_src id="2" pp_view="2" name="self" match_table="1">
						<view_src_field id="1" pp_src="2" match_field="1" />
						<view_src_field id="2" pp_src="2" match_field="3" />
						<view_src_field id="3" pp_src="2" match_field="5" />
						<view_src_field id="4" pp_src="2" match_field="6" />
					</view_src>
					<view_src id="3" pp_view="2" name="father" match_table="1">
						<view_src_field id="5" pp_src="3" match_field="1" />
						<view_src_field id="6" pp_src="3" match_field="3" />
					</view_src>
					<view_src id="4" pp_view="2" name="mother" match_table="1">
						<view_src_field id="7" pp_src="4" match_field="1" />
						<view_src_field id="8" pp_src="4" match_field="3" />
					</view_src>
					<view_join id="1" pp_view="2" lhs_src="2" rhs_src="3" join_op="LEFT">
						<view_join_field id="1" pp_join="1" lhs_src_field="3" rhs_src_field="5" />
					</view_join>
					<view_join id="2" pp_view="2" lhs_src="2" rhs_src="4" join_op="LEFT">
						<view_join_field id="2" pp_join="2" lhs_src_field="4" rhs_src_field="7" />
					</view_join>
					<view_expr id="1" pp_view="2" view_part="RESULT" set_result_field="7" cont_type="SCALAR" valf_src_field="1" />
					<view_expr id="2" pp_view="2" view_part="RESULT" set_result_field="8" cont_type="SCALAR" valf_src_field="2" />
					<view_expr id="3" pp_view="2" view_part="RESULT" set_result_field="9" cont_type="SCALAR" valf_src_field="5" />
					<view_expr id="4" pp_view="2" view_part="RESULT" set_result_field="10" cont_type="SCALAR" valf_src_field="6" />
					<view_expr id="5" pp_view="2" view_part="RESULT" set_result_field="11" cont_type="SCALAR" valf_src_field="7" />
					<view_expr id="6" pp_view="2" view_part="RESULT" set_result_field="12" cont_type="SCALAR" valf_src_field="8" />
					<view_expr id="7" pp_view="2" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="AND">
						<view_expr id="8" pp_expr="7" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="9" pp_expr="8" cont_type="SCALAR" valf_src_field="6" />
						</view_expr>
						<view_expr id="10" pp_expr="7" cont_type="SCALAR" valf_call_sroutine="LIKE">
							<view_expr id="11" pp_expr="10" cont_type="SCALAR" valf_src_field="8" />
						</view_expr>
					</view_expr>
				</view>
				<table id="2" pp_schema="1" name="user_auth" row_data_type="3">
					<table_field id="3" pp_table="2" row_field="13" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="4" pp_table="2" row_field="14" mandatory="1" />
					<table_field id="5" pp_table="2" row_field="15" mandatory="1" />
					<table_field id="6" pp_table="2" row_field="16" mandatory="1" />
					<table_field id="7" pp_table="2" row_field="17" mandatory="1" />
					<table_field id="8" pp_table="2" row_field="18" mandatory="1" />
					<table_field id="9" pp_table="2" row_field="19" mandatory="1" default_val="3" />
					<table_index id="5" pp_table="2" name="primary" index_type="UNIQUE">
						<table_index_field id="5" pp_table_index="5" field="13" />
					</table_index>
					<table_index id="6" pp_table="2" name="ak_login_name" index_type="UNIQUE">
						<table_index_field id="6" pp_table_index="6" field="14" />
					</table_index>
					<table_index id="7" pp_table="2" name="ak_private_email" index_type="UNIQUE">
						<table_index_field id="7" pp_table_index="7" field="17" />
					</table_index>
				</table>
				<table id="3" pp_schema="1" name="user_profile" row_data_type="4">
					<table_field id="10" pp_table="3" row_field="20" mandatory="1" />
					<table_field id="11" pp_table="3" row_field="21" mandatory="1" />
					<table_index id="8" pp_table="3" name="primary" index_type="UNIQUE">
						<table_index_field id="8" pp_table_index="8" field="20" />
					</table_index>
					<table_index id="9" pp_table="3" name="ak_public_name" index_type="UNIQUE">
						<table_index_field id="9" pp_table_index="9" field="21" />
					</table_index>
					<table_index id="10" pp_table="3" name="fk_user" index_type="FOREIGN" f_table="2">
						<table_index_field id="10" pp_table_index="10" field="20" f_field="13" />
					</table_index>
				</table>
				<view id="3" pp_schema="1" name="user" view_type="JOINED" row_data_type="5" may_write="1">
					<view_src id="5" pp_view="3" name="user_auth" match_table="2">
						<view_src_field id="9" pp_src="5" match_field="13" />
						<view_src_field id="10" pp_src="5" match_field="14" />
						<view_src_field id="11" pp_src="5" match_field="15" />
						<view_src_field id="12" pp_src="5" match_field="16" />
						<view_src_field id="13" pp_src="5" match_field="17" />
						<view_src_field id="14" pp_src="5" match_field="18" />
						<view_src_field id="15" pp_src="5" match_field="19" />
					</view_src>
					<view_src id="6" pp_view="3" name="user_profile" match_table="3">
						<view_src_field id="16" pp_src="6" match_field="20" />
						<view_src_field id="17" pp_src="6" match_field="21" />
						<view_src_field id="18" pp_src="6" match_field="22" />
						<view_src_field id="19" pp_src="6" match_field="23" />
						<view_src_field id="20" pp_src="6" match_field="24" />
						<view_src_field id="21" pp_src="6" match_field="25" />
						<view_src_field id="22" pp_src="6" match_field="26" />
						<view_src_field id="23" pp_src="6" match_field="27" />
						<view_src_field id="24" pp_src="6" match_field="28" />
					</view_src>
					<view_join id="3" pp_view="3" lhs_src="5" rhs_src="6" join_op="LEFT">
						<view_join_field id="3" pp_join="3" lhs_src_field="9" rhs_src_field="16" />
					</view_join>
					<view_expr id="12" pp_view="3" view_part="RESULT" set_result_field="29" cont_type="SCALAR" valf_src_field="9" />
					<view_expr id="13" pp_view="3" view_part="RESULT" set_result_field="30" cont_type="SCALAR" valf_src_field="10" />
					<view_expr id="14" pp_view="3" view_part="RESULT" set_result_field="31" cont_type="SCALAR" valf_src_field="11" />
					<view_expr id="15" pp_view="3" view_part="RESULT" set_result_field="32" cont_type="SCALAR" valf_src_field="12" />
					<view_expr id="16" pp_view="3" view_part="RESULT" set_result_field="33" cont_type="SCALAR" valf_src_field="13" />
					<view_expr id="17" pp_view="3" view_part="RESULT" set_result_field="34" cont_type="SCALAR" valf_src_field="14" />
					<view_expr id="18" pp_view="3" view_part="RESULT" set_result_field="35" cont_type="SCALAR" valf_src_field="15" />
					<view_expr id="19" pp_view="3" view_part="RESULT" set_result_field="36" cont_type="SCALAR" valf_src_field="17" />
					<view_expr id="20" pp_view="3" view_part="RESULT" set_result_field="37" cont_type="SCALAR" valf_src_field="18" />
					<view_expr id="21" pp_view="3" view_part="RESULT" set_result_field="38" cont_type="SCALAR" valf_src_field="19" />
					<view_expr id="22" pp_view="3" view_part="RESULT" set_result_field="39" cont_type="SCALAR" valf_src_field="20" />
					<view_expr id="23" pp_view="3" view_part="RESULT" set_result_field="40" cont_type="SCALAR" valf_src_field="21" />
					<view_expr id="24" pp_view="3" view_part="RESULT" set_result_field="41" cont_type="SCALAR" valf_src_field="22" />
					<view_expr id="25" pp_view="3" view_part="RESULT" set_result_field="42" cont_type="SCALAR" valf_src_field="23" />
					<view_expr id="26" pp_view="3" view_part="RESULT" set_result_field="43" cont_type="SCALAR" valf_src_field="24" />
					<view_expr id="27" pp_view="3" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="28" pp_expr="27" cont_type="SCALAR" valf_src_field="9" />
					</view_expr>
				</view>
				<table id="4" pp_schema="1" name="user_pref" row_data_type="6">
					<table_field id="12" pp_table="4" row_field="44" mandatory="1" />
					<table_field id="13" pp_table="4" row_field="45" mandatory="1" />
					<table_index id="11" pp_table="4" name="primary" index_type="UNIQUE">
						<table_index_field id="11" pp_table_index="11" field="44" />
						<table_index_field id="12" pp_table_index="11" field="45" />
					</table_index>
					<table_index id="12" pp_table="4" name="fk_user" index_type="FOREIGN" f_table="2">
						<table_index_field id="13" pp_table_index="12" field="44" f_field="13" />
					</table_index>
				</table>
				<view id="4" pp_schema="1" name="user_theme" view_type="JOINED" row_data_type="7" may_write="0">
					<view_src id="7" pp_view="4" name="user_pref" match_table="4">
						<view_src_field id="25" pp_src="7" match_field="45" />
						<view_src_field id="26" pp_src="7" match_field="46" />
					</view_src>
					<view_expr id="29" pp_view="4" view_part="RESULT" set_result_field="47" cont_type="SCALAR" valf_src_field="26" />
					<view_expr id="30" pp_view="4" view_part="RESULT" set_result_field="48" cont_type="SCALAR" valf_call_sroutine="COUNT">
						<view_expr id="31" pp_expr="30" cont_type="SCALAR" valf_src_field="26" />
					</view_expr>
					<view_expr id="32" pp_view="4" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="33" pp_expr="32" cont_type="SCALAR" valf_src_field="25" />
						<view_expr id="34" pp_expr="32" cont_type="SCALAR" valf_literal="theme" scalar_data_type="5" />
					</view_expr>
					<view_expr id="35" pp_view="4" view_part="GROUP" cont_type="SCALAR" valf_src_field="26" />
					<view_expr id="36" pp_view="4" view_part="HAVING" cont_type="SCALAR" valf_call_sroutine="GT">
						<view_expr id="37" pp_expr="36" cont_type="SCALAR" valf_call_sroutine="COUNT" />
						<view_expr id="38" pp_expr="36" cont_type="SCALAR" valf_literal="1" scalar_data_type="9" />
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
