#!perl
use 5.008001; use utf8; use strict; use warnings;

# This module is used when testing SQL::Routine.
# These tests check that a model can be built using the SYNOPSIS code in 
# Routine.pm without errors, and serializes to the correct output.
# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SRT_Synopsis;

######################################################################

sub populate_model {
	my (undef, $model) = @_;

	# This defines 4 scalar/column/field data types (1 number, 2 char strings, 1 enumerated value type) 
	# and 2 row/table data types; the former are atomic and the latter are composite.
	# The former can describe individual columns of a base table (table) or viewed table (view), 
	# while the latter can describe an entire table or view.
	# Any of these can describe a 'domain' schema object or a stored procedure's variable's data type.
	# See also the 'person' and 'person_with_parents' table+view defs further below; these data types help describe them.
	$model->build_child_node_trees( [
		[ 'scalar_data_type', { 'si_name' => 'entity_id'  , 'base_type' => 'NUM_INT' , 'num_precision' => 9, }, ],
		[ 'scalar_data_type', { 'si_name' => 'alt_id'     , 'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8', }, ],
		[ 'scalar_data_type', { 'si_name' => 'person_name', 'base_type' => 'STR_CHAR', 'max_chars' => 100, 'char_enc' => 'UTF8', }, ],
		[ 'scalar_data_type', { 'si_name' => 'person_sex' , 'base_type' => 'STR_CHAR', 'max_chars' => 1, 'char_enc' => 'UTF8', }, [
			[ 'scalar_data_type_opt', 'M', ],
			[ 'scalar_data_type_opt', 'F', ],
		], ],
		[ 'row_data_type', 'person', [
			[ 'row_data_type_field', { 'si_name' => 'person_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
			[ 'row_data_type_field', { 'si_name' => 'alternate_id', 'scalar_data_type' => 'alt_id'     , }, ],
			[ 'row_data_type_field', { 'si_name' => 'name'        , 'scalar_data_type' => 'person_name', }, ],
			[ 'row_data_type_field', { 'si_name' => 'sex'         , 'scalar_data_type' => 'person_sex' , }, ],
			[ 'row_data_type_field', { 'si_name' => 'father_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
			[ 'row_data_type_field', { 'si_name' => 'mother_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
		], ],
		[ 'row_data_type', 'person_with_parents', [
			[ 'row_data_type_field', { 'si_name' => 'self_id'    , 'scalar_data_type' => 'entity_id'  , }, ],
			[ 'row_data_type_field', { 'si_name' => 'self_name'  , 'scalar_data_type' => 'person_name', }, ],
			[ 'row_data_type_field', { 'si_name' => 'father_id'  , 'scalar_data_type' => 'entity_id'  , }, ],
			[ 'row_data_type_field', { 'si_name' => 'father_name', 'scalar_data_type' => 'person_name', }, ],
			[ 'row_data_type_field', { 'si_name' => 'mother_id'  , 'scalar_data_type' => 'entity_id'  , }, ],
			[ 'row_data_type_field', { 'si_name' => 'mother_name', 'scalar_data_type' => 'person_name', }, ],
		], ],
	] );

	# This defines the blueprint of a database catalog that contains a single schema and a single virtual user which owns the schema.
	my $catalog_bp = $model->build_child_node_tree( 'catalog', 'Gene Database', [
		[ 'owner', 'Lord of the Root', ],
		[ 'schema', { 'si_name' => 'Gene Schema', 'owner' => 'Lord of the Root', }, ],
	] );
	my $schema = $catalog_bp->find_child_node_by_surrogate_id( 'Gene Schema' );

	# This defines a base table (table) schema object that lives in the aforementioned database catalog. 
	# It contains 6 columns, including a not-null primary key (having a trivial sequence generator to give it 
	# default values), another not-null field, a surrogate key, and 2 self-referencing foreign keys.
	# Each row represents a single 'person', for each storing up to 2 unique identifiers, name, sex, and the parents' unique ids.
	my $tb_person = $schema->build_child_node_tree( 'table', { 'si_name' => 'person', 'row_data_type' => 'person', }, [
		[ 'table_field', { 'si_row_field' => 'person_id', 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, }, ],
		[ 'table_field', { 'si_row_field' => 'name'     , 'mandatory' => 1, }, ],
		[ 'table_index', { 'si_name' => 'primary' , 'index_type' => 'UNIQUE', }, [
			[ 'table_index_field', 'person_id', ], 
		], ],
		[ 'table_index', { 'si_name' => 'ak_alternate_id', 'index_type' => 'UNIQUE', }, [
			[ 'table_index_field', 'alternate_id', ], 
		], ],
		[ 'table_index', { 'si_name' => 'fk_father', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, [
			[ 'table_index_field', { 'si_field' => 'father_id', 'f_field' => 'person_id' } ],
		], ],
		[ 'table_index', { 'si_name' => 'fk_mother', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, [
			[ 'table_index_field', { 'si_field' => 'mother_id', 'f_field' => 'person_id' } ],
		], ],
	] );

	# This defines a viewed table (view) schema object that lives in the aforementioned database catalog. 
	# It left-outer-joins the 'person' table to itself twice and returns 2 columns from each constituent, for 6 total.
	# Each row gives the unique id and name each for 3 people, a given person and that person's 2 parents.
	my $vw_pwp = $schema->build_child_node_tree( 'view', { 'si_name' => 'person_with_parents', 
			'view_type' => 'JOINED', 'row_data_type' => 'person_with_parents', }, [
		( map { [ 'view_src', { 'si_name' => $_, 'match' => 'person', }, [
			map { [ 'view_src_field', $_, ], } ( 'person_id', 'name', 'father_id', 'mother_id', ),
		], ], } ('self') ),
		( map { [ 'view_src', { 'si_name' => $_, 'match' => 'person', }, [
			map { [ 'view_src_field', $_, ], } ( 'person_id', 'name', ),
		], ], } ( 'father', 'mother', ) ),
		[ 'view_field', { 'si_row_field' => 'self_id'    , 'src_field' => ['person_id','self'  ], }, ],
		[ 'view_field', { 'si_row_field' => 'self_name'  , 'src_field' => ['name'     ,'self'  ], }, ],
		[ 'view_field', { 'si_row_field' => 'father_id'  , 'src_field' => ['person_id','father'], }, ],
		[ 'view_field', { 'si_row_field' => 'father_name', 'src_field' => ['name'     ,'father'], }, ],
		[ 'view_field', { 'si_row_field' => 'mother_id'  , 'src_field' => ['person_id','mother'], }, ],
		[ 'view_field', { 'si_row_field' => 'mother_name', 'src_field' => ['name'     ,'mother'], }, ],
		[ 'view_join', { 'lhs_src' => 'self', 'rhs_src' => 'father', 'join_op' => 'LEFT', }, [
			[ 'view_join_field', { 'lhs_src_field' => 'father_id', 'rhs_src_field' => 'person_id' } ],
		], ],
		[ 'view_join', { 'lhs_src' => 'self', 'rhs_src' => 'mother', 'join_op' => 'LEFT', }, [
			[ 'view_join_field', { 'lhs_src_field' => 'mother_id', 'rhs_src_field' => 'person_id' } ],
		], ],
	] );

	# This defines the blueprint of an application that has a single virtual connection descriptor to the above database.
	my $application_bp = $model->build_child_node_tree( 'application', 'Gene App', [
		[ 'catalog_link', { 'si_name' => 'editor_link', 'target' => $catalog_bp, }, ],
	] );

	# This defines another scalar data type, which is used by some routines that follow below.
	my $sdt_login_auth = $model->build_child_node( 'scalar_data_type', { 'si_name' => 'login_auth', 
		'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8', } );

	# This defines an application-side routine/function that connects to the 'Gene Database', fetches all 
	# the records from the 'person_with_parents' view, disconnects the database, and returns the fetched records.
	# It takes run-time arguments for a user login name and password that are used when connecting.
	my $rt_fetch_pwp = $application_bp->build_child_node_tree( 'routine', { 'si_name' => 'fetch_pwp', 
			'routine_type' => 'FUNCTION', 'return_cont_type' => 'RW_ARY', 'return_row_data_type' => 'person_with_parents', }, [
		[ 'routine_arg', { 'si_name' => 'login_name', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_login_auth }, ],
		[ 'routine_arg', { 'si_name' => 'login_pass', 'cont_type' => 'SCALAR', 'scalar_data_type' => $sdt_login_auth }, ],
		[ 'routine_var', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'editor_link', }, ],
		[ 'routine_stmt', { 'call_sroutine' => 'CATALOG_OPEN', }, [
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item', 'conn_cx', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_NAME', 'cont_type' => 'SCALAR', 'valf_p_routine_item', 'login_name', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_PASS', 'cont_type' => 'SCALAR', 'valf_p_routine_item', 'login_pass', }, ],
		], ],
		[ 'routine_var', { 'si_name' => 'pwp_ary', 'cont_type' => 'RW_ARY', 'row_data_type' => 'person_with_parents', }, ],
		[ 'routine_stmt', { 'call_sroutine' => 'SELECT', }, [
			[ 'view', { 'si_name' => 'query_pwp', 'view_type' => 'ALIAS', 'row_data_type' => 'person_with_parents', }, [
				[ 'view_src', { 'si_name' => 's', 'match' => $vw_pwp, }, ],
			], ],
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'SELECT_DEFN', 'cont_type' => 'SRT_NODE', 'act_on' => 'query_pwp', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'INTO', 'query_dest' => 'pwp_ary', 'cont_type' => 'RW_ARY', }, ],
		], ],
		[ 'routine_stmt', { 'call_sroutine' => 'CATALOG_CLOSE', }, [
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item', 'conn_cx', }, ],
		], ],
		[ 'routine_stmt', { 'call_sroutine' => 'RETURN', }, [
			[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 'cont_type' => 'RW_ARY', 'valf_p_routine_item' => 'pwp_ary', }, ],
		], ],
	] );

	# This defines an application-side routine/procedure that inserts a set of records, given in an argument, 
	# into the 'person' table.  It takes an already opened db connection handle to operate through as a 
	# 'context' argument (which would represent the invocant if this routine was wrapped in an object-oriented interface).
	my $rt_add_people = $application_bp->build_child_node_tree( 'routine', { 'si_name' => 'add_people', 'routine_type' => 'PROCEDURE', }, [
		[ 'routine_context', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'editor_link', }, ],
		[ 'routine_arg', { 'si_name' => 'person_ary', 'cont_type' => 'RW_ARY', 'row_data_type' => 'person', }, ],
		[ 'routine_stmt', { 'call_sroutine' => 'INSERT', }, [
			[ 'view', { 'si_name' => 'insert_people', 'view_type' => 'INSERT', 'row_data_type' => 'person', 'ins_p_routine_item' => 'person_ary', }, [
				[ 'view_src', { 'si_name' => 's', 'match' => $tb_person, }, ],
			], ],
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'INSERT_DEFN', 'cont_type' => 'SRT_NODE', 'act_on' => 'insert_people', }, ],
		], ],
	] );

	# This defines an application-side routine/function that fetches one record 
	# from the 'person' table which matches its argument.
	my $rt_get_person = $application_bp->build_child_node_tree( 'routine', { 'si_name' => 'get_person', 
			'routine_type' => 'FUNCTION', 'return_cont_type' => 'ROW', 'return_row_data_type' => 'person', }, [
		[ 'routine_context', { 'si_name' => 'conn_cx', 'cont_type' => 'CONN', 'conn_link' => 'editor_link', }, ],
		[ 'routine_arg', { 'si_name' => 'arg_person_id', 'cont_type' => 'SCALAR', 'scalar_data_type' => 'entity_id', }, ],
		[ 'routine_var', { 'si_name' => 'person_row', 'cont_type' => 'ROW', 'row_data_type' => 'person', }, ],
		[ 'routine_stmt', { 'call_sroutine' => 'SELECT', }, [
			[ 'view', { 'si_name' => 'query_person', 'view_type' => 'JOINED', 'row_data_type' => 'person', }, [
				[ 'view_src', { 'si_name' => 's', 'match' => $tb_person, }, [
					[ 'view_src_field', 'person_id', ],
				], ],
				[ 'view_expr', { 'view_part' => 'WHERE', 'cont_type' => 'SCALAR', 'valf_call_sroutine' => 'EQ', }, [
					[ 'view_expr', { 'call_sroutine_arg' => 'LHS', 'cont_type' => 'SCALAR', 'valf_src_field' => 'person_id', }, ],
					[ 'view_expr', { 'call_sroutine_arg' => 'RHS', 'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'arg_person_id', }, ],
				], ],
			], ],
			[ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'SELECT_DEFN', 'cont_type' => 'SRT_NODE', 'act_on' => 'query_person', }, ],
			[ 'routine_expr', { 'call_sroutine_arg' => 'INTO', 'query_dest' => 'person_row', 'cont_type' => 'RW_ARY', }, ],
		], ],
		[ 'routine_stmt', { 'call_sroutine' => 'RETURN', }, [
			[ 'routine_expr', { 'call_sroutine_arg' => 'RETURN_VALUE', 'cont_type' => 'ROW', 'valf_p_routine_item' => 'person_row', }, ],
		], ],
	] );

	# This defines 6 database engine descriptors and 2 database bridge descriptors that we may be using.
	# These details can help external code determine such things as what string-SQL flavors should be 
	# generated from the model, as well as which database features can be used natively or have to be emulated.
	# The 'si_name' has no meaning to code and is for users; the other attribute values should have meaning to said external code.
	$model->build_child_node_trees( [
		[ 'data_storage_product', { 'si_name' => 'SQLite v3.2'  , 'product_code' => 'SQLite_3_2'  , 'is_file_based'  => 1, }, ],
		[ 'data_storage_product', { 'si_name' => 'MySQL v5.0'   , 'product_code' => 'MySQL_5_0'   , 'is_network_svc' => 1, }, ],
		[ 'data_storage_product', { 'si_name' => 'PostgreSQL v8', 'product_code' => 'PostgreSQL_8', 'is_network_svc' => 1, }, ],
		[ 'data_storage_product', { 'si_name' => 'Oracle v10g'  , 'product_code' => 'Oracle_10_g' , 'is_network_svc' => 1, }, ],
		[ 'data_storage_product', { 'si_name' => 'Sybase'       , 'product_code' => 'Sybase'      , 'is_network_svc' => 1, }, ],
		[ 'data_storage_product', { 'si_name' => 'CSV'          , 'product_code' => 'CSV'         , 'is_file_based'  => 1, }, ],
		[ 'data_link_product', { 'si_name' => 'Microsoft ODBC v3', 'product_code' => 'ODBC_3', }, ],
		[ 'data_link_product', { 'si_name' => 'Oracle OCI*8', 'product_code' => 'OCI_8', }, ],
		[ 'data_link_product', { 'si_name' => 'Generic Rosetta Engine', 'product_code' => 'Rosetta::Engine::Generic', }, ],
	] );

	# This defines one concrete instance each of the database catalog and an application using it.
	# This concrete database instance includes two concrete user definitions, one that can owns 
	# the schema and one that can only edit data.  The concrete application instance includes 
	# a concrete connection descriptor going to this concrete database instance.
	# Note that 'user' descriptions are only stored in a SQL::Routine model when that model is being used to create 
	# database catalogs and/or create or modify database users; otherwise 'user' should not be kept for security sake.
	$model->build_child_node_trees( [
		[ 'catalog_instance', { 'si_name' => 'test', 'blueprint' => $catalog_bp, 'product' => 'PostgreSQL v8', }, [
			[ 'user', { 'si_name' => 'ronsealy', 'user_type' => 'SCHEMA_OWNER', 'match_owner' => 'Lord of the Root', 'password' => 'K34dsD', }, ],
			[ 'user', { 'si_name' => 'joesmith', 'user_type' => 'DATA_EDITOR', 'password' => 'fdsKJ4', }, ],
		], ],
		[ 'application_instance', { 'si_name' => 'test app', 'blueprint' => $application_bp, }, [
			[ 'catalog_link_instance', { 'blueprint' => 'editor_link', 'product' => 'Microsoft ODBC v3', 'target' => 'test', 'local_dsn' => 'keep_it', }, ],
		], ],
	] );


	# This defines another concrete instance each of the database catalog and an application using it.
	$model->build_child_node_trees( [
		[ 'catalog_instance', { 'si_name' => 'production', 'blueprint' => $catalog_bp, 'product' => 'Oracle v10g', }, [
			[ 'user', { 'si_name' => 'florence', 'user_type' => 'SCHEMA_OWNER', 'match_owner' => 'Lord of the Root', 'password' => '0sfs8G', }, ],
			[ 'user', { 'si_name' => 'thainuff', 'user_type' => 'DATA_EDITOR', 'password' => '9340sd', }, ],
		], ],
		[ 'application_instance', { 'si_name' => 'production app', 'blueprint' => $application_bp, }, [
			[ 'catalog_link_instance', { 'blueprint' => 'editor_link', 'product' => 'Oracle OCI*8', 'target' => 'production', 'local_dsn' => 'ship_it', }, ],
		], ],
	] );

	# This defines a third concrete instance each of the database catalog and an application using it.
	$model->build_child_node_trees( [
		[ 'catalog_instance', { 'si_name' => 'laptop demo', 'blueprint' => $catalog_bp, 'product' => 'SQLite v3.2', 'file_path' => 'Move It', }, ],
		[ 'application_instance', { 'si_name' => 'laptop demo app', 'blueprint' => $application_bp, }, [
			[ 'catalog_link_instance', { 'blueprint' => 'editor_link', 'product' => 'Generic Rosetta Engine', 'target' => 'laptop demo', }, ],
		], ],
	] );
}

######################################################################

sub expected_model_nid_xml_output {
	return
'<?xml version="1.0" encoding="UTF-8"?>
<root>
	<elements>
		<scalar_data_type id="1" si_name="entity_id" base_type="NUM_INT" num_precision="9" />
		<scalar_data_type id="2" si_name="alt_id" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
		<scalar_data_type id="3" si_name="person_name" base_type="STR_CHAR" max_chars="100" char_enc="UTF8" />
		<scalar_data_type id="4" si_name="person_sex" base_type="STR_CHAR" max_chars="1" char_enc="UTF8">
			<scalar_data_type_opt id="5" si_value="M" />
			<scalar_data_type_opt id="6" si_value="F" />
		</scalar_data_type>
		<row_data_type id="7" si_name="person">
			<row_data_type_field id="8" si_name="person_id" scalar_data_type="1" />
			<row_data_type_field id="9" si_name="alternate_id" scalar_data_type="2" />
			<row_data_type_field id="10" si_name="name" scalar_data_type="3" />
			<row_data_type_field id="11" si_name="sex" scalar_data_type="4" />
			<row_data_type_field id="12" si_name="father_id" scalar_data_type="1" />
			<row_data_type_field id="13" si_name="mother_id" scalar_data_type="1" />
		</row_data_type>
		<row_data_type id="14" si_name="person_with_parents">
			<row_data_type_field id="15" si_name="self_id" scalar_data_type="1" />
			<row_data_type_field id="16" si_name="self_name" scalar_data_type="3" />
			<row_data_type_field id="17" si_name="father_id" scalar_data_type="1" />
			<row_data_type_field id="18" si_name="father_name" scalar_data_type="3" />
			<row_data_type_field id="19" si_name="mother_id" scalar_data_type="1" />
			<row_data_type_field id="20" si_name="mother_name" scalar_data_type="3" />
		</row_data_type>
		<scalar_data_type id="59" si_name="login_auth" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
	</elements>
	<blueprints>
		<catalog id="21" si_name="Gene Database">
			<owner id="22" si_name="Lord of the Root" />
			<schema id="23" si_name="Gene Schema" owner="22">
				<table id="24" si_name="person" row_data_type="7">
					<table_field id="25" si_row_field="8" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="26" si_row_field="10" mandatory="1" />
					<table_index id="27" si_name="primary" index_type="UNIQUE">
						<table_index_field id="28" si_field="8" />
					</table_index>
					<table_index id="29" si_name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="30" si_field="9" />
					</table_index>
					<table_index id="31" si_name="fk_father" index_type="FOREIGN" f_table="24">
						<table_index_field id="32" si_field="12" f_field="8" />
					</table_index>
					<table_index id="33" si_name="fk_mother" index_type="FOREIGN" f_table="24">
						<table_index_field id="34" si_field="13" f_field="8" />
					</table_index>
				</table>
				<view id="35" si_name="person_with_parents" view_type="JOINED" row_data_type="14">
					<view_src id="36" si_name="self" match="24">
						<view_src_field id="37" si_match_field="8" />
						<view_src_field id="38" si_match_field="10" />
						<view_src_field id="39" si_match_field="12" />
						<view_src_field id="40" si_match_field="13" />
					</view_src>
					<view_src id="41" si_name="father" match="24">
						<view_src_field id="42" si_match_field="8" />
						<view_src_field id="43" si_match_field="10" />
					</view_src>
					<view_src id="44" si_name="mother" match="24">
						<view_src_field id="45" si_match_field="8" />
						<view_src_field id="46" si_match_field="10" />
					</view_src>
					<view_field id="47" si_row_field="15" src_field="37" />
					<view_field id="48" si_row_field="16" src_field="38" />
					<view_field id="49" si_row_field="17" src_field="42" />
					<view_field id="50" si_row_field="18" src_field="43" />
					<view_field id="51" si_row_field="19" src_field="45" />
					<view_field id="52" si_row_field="20" src_field="46" />
					<view_join id="53" lhs_src="36" rhs_src="41" join_op="LEFT">
						<view_join_field id="54" lhs_src_field="39" rhs_src_field="42" />
					</view_join>
					<view_join id="55" lhs_src="36" rhs_src="44" join_op="LEFT">
						<view_join_field id="56" lhs_src_field="40" rhs_src_field="45" />
					</view_join>
				</view>
			</schema>
		</catalog>
		<application id="57" si_name="Gene App">
			<catalog_link id="58" si_name="editor_link" target="21" />
			<routine id="60" si_name="fetch_pwp" routine_type="FUNCTION" return_cont_type="RW_ARY" return_row_data_type="14">
				<routine_arg id="61" si_name="login_name" cont_type="SCALAR" scalar_data_type="59" />
				<routine_arg id="62" si_name="login_pass" cont_type="SCALAR" scalar_data_type="59" />
				<routine_var id="63" si_name="conn_cx" cont_type="CONN" conn_link="58" />
				<routine_stmt id="64" call_sroutine="CATALOG_OPEN">
					<routine_expr id="65" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="63" />
					<routine_expr id="66" call_sroutine_arg="LOGIN_NAME" cont_type="SCALAR" valf_p_routine_item="61" />
					<routine_expr id="67" call_sroutine_arg="LOGIN_PASS" cont_type="SCALAR" valf_p_routine_item="62" />
				</routine_stmt>
				<routine_var id="68" si_name="pwp_ary" cont_type="RW_ARY" row_data_type="14" />
				<routine_stmt id="69" call_sroutine="SELECT">
					<view id="70" si_name="query_pwp" view_type="ALIAS" row_data_type="14">
						<view_src id="71" si_name="s" match="35" />
					</view>
					<routine_expr id="72" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="63" />
					<routine_expr id="73" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="70" />
					<routine_expr id="74" call_sroutine_arg="INTO" query_dest="68" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="75" call_sroutine="CATALOG_CLOSE">
					<routine_expr id="76" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="63" />
				</routine_stmt>
				<routine_stmt id="77" call_sroutine="RETURN">
					<routine_expr id="78" call_sroutine_arg="RETURN_VALUE" cont_type="RW_ARY" valf_p_routine_item="68" />
				</routine_stmt>
			</routine>
			<routine id="79" si_name="add_people" routine_type="PROCEDURE">
				<routine_context id="80" si_name="conn_cx" cont_type="CONN" conn_link="58" />
				<routine_arg id="81" si_name="person_ary" cont_type="RW_ARY" row_data_type="7" />
				<routine_stmt id="82" call_sroutine="INSERT">
					<view id="83" si_name="insert_people" view_type="INSERT" row_data_type="7" ins_p_routine_item="81">
						<view_src id="84" si_name="s" match="24" />
					</view>
					<routine_expr id="85" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="80" />
					<routine_expr id="86" call_sroutine_arg="INSERT_DEFN" cont_type="SRT_NODE" act_on="83" />
				</routine_stmt>
			</routine>
			<routine id="87" si_name="get_person" routine_type="FUNCTION" return_cont_type="ROW" return_row_data_type="7">
				<routine_context id="88" si_name="conn_cx" cont_type="CONN" conn_link="58" />
				<routine_arg id="89" si_name="arg_person_id" cont_type="SCALAR" scalar_data_type="1" />
				<routine_var id="90" si_name="person_row" cont_type="ROW" row_data_type="7" />
				<routine_stmt id="91" call_sroutine="SELECT">
					<view id="92" si_name="query_person" view_type="JOINED" row_data_type="7">
						<view_src id="93" si_name="s" match="24">
							<view_src_field id="94" si_match_field="8" />
						</view_src>
						<view_expr id="95" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
							<view_expr id="96" call_sroutine_arg="LHS" cont_type="SCALAR" valf_src_field="94" />
							<view_expr id="97" call_sroutine_arg="RHS" cont_type="SCALAR" valf_p_routine_item="89" />
						</view_expr>
					</view>
					<routine_expr id="98" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="88" />
					<routine_expr id="99" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="92" />
					<routine_expr id="100" call_sroutine_arg="INTO" query_dest="90" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="101" call_sroutine="RETURN">
					<routine_expr id="102" call_sroutine_arg="RETURN_VALUE" cont_type="ROW" valf_p_routine_item="90" />
				</routine_stmt>
			</routine>
		</application>
	</blueprints>
	<tools>
		<data_storage_product id="103" si_name="SQLite v3.2" product_code="SQLite_3_2" is_file_based="1" />
		<data_storage_product id="104" si_name="MySQL v5.0" product_code="MySQL_5_0" is_network_svc="1" />
		<data_storage_product id="105" si_name="PostgreSQL v8" product_code="PostgreSQL_8" is_network_svc="1" />
		<data_storage_product id="106" si_name="Oracle v10g" product_code="Oracle_10_g" is_network_svc="1" />
		<data_storage_product id="107" si_name="Sybase" product_code="Sybase" is_network_svc="1" />
		<data_storage_product id="108" si_name="CSV" product_code="CSV" is_file_based="1" />
		<data_link_product id="109" si_name="Microsoft ODBC v3" product_code="ODBC_3" />
		<data_link_product id="110" si_name="Oracle OCI*8" product_code="OCI_8" />
		<data_link_product id="111" si_name="Generic Rosetta Engine" product_code="Rosetta::Engine::Generic" />
	</tools>
	<sites>
		<catalog_instance id="112" si_name="test" blueprint="21" product="105">
			<user id="113" si_name="ronsealy" user_type="SCHEMA_OWNER" match_owner="22" password="K34dsD" />
			<user id="114" si_name="joesmith" user_type="DATA_EDITOR" password="fdsKJ4" />
		</catalog_instance>
		<application_instance id="115" si_name="test app" blueprint="57">
			<catalog_link_instance id="116" blueprint="58" product="109" target="112" local_dsn="keep_it" />
		</application_instance>
		<catalog_instance id="117" si_name="production" blueprint="21" product="106">
			<user id="118" si_name="florence" user_type="SCHEMA_OWNER" match_owner="22" password="0sfs8G" />
			<user id="119" si_name="thainuff" user_type="DATA_EDITOR" password="9340sd" />
		</catalog_instance>
		<application_instance id="120" si_name="production app" blueprint="57">
			<catalog_link_instance id="121" blueprint="58" product="110" target="117" local_dsn="ship_it" />
		</application_instance>
		<catalog_instance id="122" si_name="laptop demo" blueprint="21" product="103" file_path="Move It" />
		<application_instance id="123" si_name="laptop demo app" blueprint="57">
			<catalog_link_instance id="124" blueprint="58" product="111" target="122" />
		</application_instance>
	</sites>
	<circumventions />
</root>
'
	;
}

######################################################################

sub expected_model_sid_long_xml_output {
	return
'<?xml version="1.0" encoding="UTF-8"?>
<root>
	<elements>
		<scalar_data_type id="1" si_name="entity_id" base_type="NUM_INT" num_precision="9" />
		<scalar_data_type id="2" si_name="alt_id" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
		<scalar_data_type id="3" si_name="person_name" base_type="STR_CHAR" max_chars="100" char_enc="UTF8" />
		<scalar_data_type id="4" si_name="person_sex" base_type="STR_CHAR" max_chars="1" char_enc="UTF8">
			<scalar_data_type_opt id="5" si_value="M" />
			<scalar_data_type_opt id="6" si_value="F" />
		</scalar_data_type>
		<row_data_type id="7" si_name="person">
			<row_data_type_field id="8" si_name="person_id" scalar_data_type="entity_id" />
			<row_data_type_field id="9" si_name="alternate_id" scalar_data_type="alt_id" />
			<row_data_type_field id="10" si_name="name" scalar_data_type="person_name" />
			<row_data_type_field id="11" si_name="sex" scalar_data_type="person_sex" />
			<row_data_type_field id="12" si_name="father_id" scalar_data_type="entity_id" />
			<row_data_type_field id="13" si_name="mother_id" scalar_data_type="entity_id" />
		</row_data_type>
		<row_data_type id="14" si_name="person_with_parents">
			<row_data_type_field id="15" si_name="self_id" scalar_data_type="entity_id" />
			<row_data_type_field id="16" si_name="self_name" scalar_data_type="person_name" />
			<row_data_type_field id="17" si_name="father_id" scalar_data_type="entity_id" />
			<row_data_type_field id="18" si_name="father_name" scalar_data_type="person_name" />
			<row_data_type_field id="19" si_name="mother_id" scalar_data_type="entity_id" />
			<row_data_type_field id="20" si_name="mother_name" scalar_data_type="person_name" />
		</row_data_type>
		<scalar_data_type id="59" si_name="login_auth" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
	</elements>
	<blueprints>
		<catalog id="21" si_name="Gene Database">
			<owner id="22" si_name="Lord of the Root" />
			<schema id="23" si_name="Gene Schema" owner="Lord of the Root">
				<table id="24" si_name="person" row_data_type="person">
					<table_field id="25" si_row_field="person_id" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="26" si_row_field="name" mandatory="1" />
					<table_index id="27" si_name="primary" index_type="UNIQUE">
						<table_index_field id="28" si_field="person_id" />
					</table_index>
					<table_index id="29" si_name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="30" si_field="alternate_id" />
					</table_index>
					<table_index id="31" si_name="fk_father" index_type="FOREIGN" f_table="person">
						<table_index_field id="32" si_field="father_id" f_field="person_id" />
					</table_index>
					<table_index id="33" si_name="fk_mother" index_type="FOREIGN" f_table="person">
						<table_index_field id="34" si_field="mother_id" f_field="person_id" />
					</table_index>
				</table>
				<view id="35" si_name="person_with_parents" view_type="JOINED" row_data_type="person_with_parents">
					<view_src id="36" si_name="self" match="person">
						<view_src_field id="37" si_match_field="person_id" />
						<view_src_field id="38" si_match_field="name" />
						<view_src_field id="39" si_match_field="father_id" />
						<view_src_field id="40" si_match_field="mother_id" />
					</view_src>
					<view_src id="41" si_name="father" match="person">
						<view_src_field id="42" si_match_field="person_id" />
						<view_src_field id="43" si_match_field="name" />
					</view_src>
					<view_src id="44" si_name="mother" match="person">
						<view_src_field id="45" si_match_field="person_id" />
						<view_src_field id="46" si_match_field="name" />
					</view_src>
					<view_field id="47" si_row_field="self_id" src_field="[person_id,self]" />
					<view_field id="48" si_row_field="self_name" src_field="[name,self]" />
					<view_field id="49" si_row_field="father_id" src_field="[person_id,father]" />
					<view_field id="50" si_row_field="father_name" src_field="[name,father]" />
					<view_field id="51" si_row_field="mother_id" src_field="[person_id,mother]" />
					<view_field id="52" si_row_field="mother_name" src_field="[name,mother]" />
					<view_join id="53" lhs_src="self" rhs_src="father" join_op="LEFT">
						<view_join_field id="54" lhs_src_field="father_id" rhs_src_field="person_id" />
					</view_join>
					<view_join id="55" lhs_src="self" rhs_src="mother" join_op="LEFT">
						<view_join_field id="56" lhs_src_field="mother_id" rhs_src_field="person_id" />
					</view_join>
				</view>
			</schema>
		</catalog>
		<application id="57" si_name="Gene App">
			<catalog_link id="58" si_name="editor_link" target="Gene Database" />
			<routine id="60" si_name="fetch_pwp" routine_type="FUNCTION" return_cont_type="RW_ARY" return_row_data_type="person_with_parents">
				<routine_arg id="61" si_name="login_name" cont_type="SCALAR" scalar_data_type="login_auth" />
				<routine_arg id="62" si_name="login_pass" cont_type="SCALAR" scalar_data_type="login_auth" />
				<routine_var id="63" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_stmt id="64" call_sroutine="CATALOG_OPEN">
					<routine_expr id="65" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="66" call_sroutine_arg="LOGIN_NAME" cont_type="SCALAR" valf_p_routine_item="login_name" />
					<routine_expr id="67" call_sroutine_arg="LOGIN_PASS" cont_type="SCALAR" valf_p_routine_item="login_pass" />
				</routine_stmt>
				<routine_var id="68" si_name="pwp_ary" cont_type="RW_ARY" row_data_type="person_with_parents" />
				<routine_stmt id="69" call_sroutine="SELECT">
					<view id="70" si_name="query_pwp" view_type="ALIAS" row_data_type="person_with_parents">
						<view_src id="71" si_name="s" match="[person_with_parents,Gene Schema,Gene Database]" />
					</view>
					<routine_expr id="72" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="73" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="query_pwp" />
					<routine_expr id="74" call_sroutine_arg="INTO" query_dest="pwp_ary" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="75" call_sroutine="CATALOG_CLOSE">
					<routine_expr id="76" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
				</routine_stmt>
				<routine_stmt id="77" call_sroutine="RETURN">
					<routine_expr id="78" call_sroutine_arg="RETURN_VALUE" cont_type="RW_ARY" valf_p_routine_item="pwp_ary" />
				</routine_stmt>
			</routine>
			<routine id="79" si_name="add_people" routine_type="PROCEDURE">
				<routine_context id="80" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_arg id="81" si_name="person_ary" cont_type="RW_ARY" row_data_type="person" />
				<routine_stmt id="82" call_sroutine="INSERT">
					<view id="83" si_name="insert_people" view_type="INSERT" row_data_type="person" ins_p_routine_item="person_ary">
						<view_src id="84" si_name="s" match="[person,Gene Schema,Gene Database]" />
					</view>
					<routine_expr id="85" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="86" call_sroutine_arg="INSERT_DEFN" cont_type="SRT_NODE" act_on="insert_people" />
				</routine_stmt>
			</routine>
			<routine id="87" si_name="get_person" routine_type="FUNCTION" return_cont_type="ROW" return_row_data_type="person">
				<routine_context id="88" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_arg id="89" si_name="arg_person_id" cont_type="SCALAR" scalar_data_type="entity_id" />
				<routine_var id="90" si_name="person_row" cont_type="ROW" row_data_type="person" />
				<routine_stmt id="91" call_sroutine="SELECT">
					<view id="92" si_name="query_person" view_type="JOINED" row_data_type="person">
						<view_src id="93" si_name="s" match="[person,Gene Schema,Gene Database]">
							<view_src_field id="94" si_match_field="person_id" />
						</view_src>
						<view_expr id="95" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
							<view_expr id="96" call_sroutine_arg="LHS" cont_type="SCALAR" valf_src_field="[person_id,s]" />
							<view_expr id="97" call_sroutine_arg="RHS" cont_type="SCALAR" valf_p_routine_item="arg_person_id" />
						</view_expr>
					</view>
					<routine_expr id="98" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="99" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="query_person" />
					<routine_expr id="100" call_sroutine_arg="INTO" query_dest="person_row" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="101" call_sroutine="RETURN">
					<routine_expr id="102" call_sroutine_arg="RETURN_VALUE" cont_type="ROW" valf_p_routine_item="person_row" />
				</routine_stmt>
			</routine>
		</application>
	</blueprints>
	<tools>
		<data_storage_product id="103" si_name="SQLite v3.2" product_code="SQLite_3_2" is_file_based="1" />
		<data_storage_product id="104" si_name="MySQL v5.0" product_code="MySQL_5_0" is_network_svc="1" />
		<data_storage_product id="105" si_name="PostgreSQL v8" product_code="PostgreSQL_8" is_network_svc="1" />
		<data_storage_product id="106" si_name="Oracle v10g" product_code="Oracle_10_g" is_network_svc="1" />
		<data_storage_product id="107" si_name="Sybase" product_code="Sybase" is_network_svc="1" />
		<data_storage_product id="108" si_name="CSV" product_code="CSV" is_file_based="1" />
		<data_link_product id="109" si_name="Microsoft ODBC v3" product_code="ODBC_3" />
		<data_link_product id="110" si_name="Oracle OCI*8" product_code="OCI_8" />
		<data_link_product id="111" si_name="Generic Rosetta Engine" product_code="Rosetta::Engine::Generic" />
	</tools>
	<sites>
		<catalog_instance id="112" si_name="test" blueprint="Gene Database" product="PostgreSQL v8">
			<user id="113" si_name="ronsealy" user_type="SCHEMA_OWNER" match_owner="Lord of the Root" password="K34dsD" />
			<user id="114" si_name="joesmith" user_type="DATA_EDITOR" password="fdsKJ4" />
		</catalog_instance>
		<application_instance id="115" si_name="test app" blueprint="Gene App">
			<catalog_link_instance id="116" blueprint="editor_link" product="Microsoft ODBC v3" target="test" local_dsn="keep_it" />
		</application_instance>
		<catalog_instance id="117" si_name="production" blueprint="Gene Database" product="Oracle v10g">
			<user id="118" si_name="florence" user_type="SCHEMA_OWNER" match_owner="Lord of the Root" password="0sfs8G" />
			<user id="119" si_name="thainuff" user_type="DATA_EDITOR" password="9340sd" />
		</catalog_instance>
		<application_instance id="120" si_name="production app" blueprint="Gene App">
			<catalog_link_instance id="121" blueprint="editor_link" product="Oracle OCI*8" target="production" local_dsn="ship_it" />
		</application_instance>
		<catalog_instance id="122" si_name="laptop demo" blueprint="Gene Database" product="SQLite v3.2" file_path="Move It" />
		<application_instance id="123" si_name="laptop demo app" blueprint="Gene App">
			<catalog_link_instance id="124" blueprint="editor_link" product="Generic Rosetta Engine" target="laptop demo" />
		</application_instance>
	</sites>
	<circumventions />
</root>
'
	;
}

######################################################################

sub expected_model_sid_short_xml_output {
	return
'<?xml version="1.0" encoding="UTF-8"?>
<root>
	<elements>
		<scalar_data_type id="1" si_name="entity_id" base_type="NUM_INT" num_precision="9" />
		<scalar_data_type id="2" si_name="alt_id" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
		<scalar_data_type id="3" si_name="person_name" base_type="STR_CHAR" max_chars="100" char_enc="UTF8" />
		<scalar_data_type id="4" si_name="person_sex" base_type="STR_CHAR" max_chars="1" char_enc="UTF8">
			<scalar_data_type_opt id="5" si_value="M" />
			<scalar_data_type_opt id="6" si_value="F" />
		</scalar_data_type>
		<row_data_type id="7" si_name="person">
			<row_data_type_field id="8" si_name="person_id" scalar_data_type="entity_id" />
			<row_data_type_field id="9" si_name="alternate_id" scalar_data_type="alt_id" />
			<row_data_type_field id="10" si_name="name" scalar_data_type="person_name" />
			<row_data_type_field id="11" si_name="sex" scalar_data_type="person_sex" />
			<row_data_type_field id="12" si_name="father_id" scalar_data_type="entity_id" />
			<row_data_type_field id="13" si_name="mother_id" scalar_data_type="entity_id" />
		</row_data_type>
		<row_data_type id="14" si_name="person_with_parents">
			<row_data_type_field id="15" si_name="self_id" scalar_data_type="entity_id" />
			<row_data_type_field id="16" si_name="self_name" scalar_data_type="person_name" />
			<row_data_type_field id="17" si_name="father_id" scalar_data_type="entity_id" />
			<row_data_type_field id="18" si_name="father_name" scalar_data_type="person_name" />
			<row_data_type_field id="19" si_name="mother_id" scalar_data_type="entity_id" />
			<row_data_type_field id="20" si_name="mother_name" scalar_data_type="person_name" />
		</row_data_type>
		<scalar_data_type id="59" si_name="login_auth" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
	</elements>
	<blueprints>
		<catalog id="21" si_name="Gene Database">
			<owner id="22" si_name="Lord of the Root" />
			<schema id="23" si_name="Gene Schema" owner="Lord of the Root">
				<table id="24" si_name="person" row_data_type="person">
					<table_field id="25" si_row_field="person_id" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="26" si_row_field="name" mandatory="1" />
					<table_index id="27" si_name="primary" index_type="UNIQUE">
						<table_index_field id="28" si_field="person_id" />
					</table_index>
					<table_index id="29" si_name="ak_alternate_id" index_type="UNIQUE">
						<table_index_field id="30" si_field="alternate_id" />
					</table_index>
					<table_index id="31" si_name="fk_father" index_type="FOREIGN" f_table="person">
						<table_index_field id="32" si_field="father_id" f_field="person_id" />
					</table_index>
					<table_index id="33" si_name="fk_mother" index_type="FOREIGN" f_table="person">
						<table_index_field id="34" si_field="mother_id" f_field="person_id" />
					</table_index>
				</table>
				<view id="35" si_name="person_with_parents" view_type="JOINED" row_data_type="person_with_parents">
					<view_src id="36" si_name="self" match="person">
						<view_src_field id="37" si_match_field="person_id" />
						<view_src_field id="38" si_match_field="name" />
						<view_src_field id="39" si_match_field="father_id" />
						<view_src_field id="40" si_match_field="mother_id" />
					</view_src>
					<view_src id="41" si_name="father" match="person">
						<view_src_field id="42" si_match_field="person_id" />
						<view_src_field id="43" si_match_field="name" />
					</view_src>
					<view_src id="44" si_name="mother" match="person">
						<view_src_field id="45" si_match_field="person_id" />
						<view_src_field id="46" si_match_field="name" />
					</view_src>
					<view_field id="47" si_row_field="self_id" src_field="[person_id,self]" />
					<view_field id="48" si_row_field="self_name" src_field="[name,self]" />
					<view_field id="49" si_row_field="father_id" src_field="[person_id,father]" />
					<view_field id="50" si_row_field="father_name" src_field="[name,father]" />
					<view_field id="51" si_row_field="mother_id" src_field="[person_id,mother]" />
					<view_field id="52" si_row_field="mother_name" src_field="[name,mother]" />
					<view_join id="53" lhs_src="self" rhs_src="father" join_op="LEFT">
						<view_join_field id="54" lhs_src_field="father_id" rhs_src_field="person_id" />
					</view_join>
					<view_join id="55" lhs_src="self" rhs_src="mother" join_op="LEFT">
						<view_join_field id="56" lhs_src_field="mother_id" rhs_src_field="person_id" />
					</view_join>
				</view>
			</schema>
		</catalog>
		<application id="57" si_name="Gene App">
			<catalog_link id="58" si_name="editor_link" target="Gene Database" />
			<routine id="60" si_name="fetch_pwp" routine_type="FUNCTION" return_cont_type="RW_ARY" return_row_data_type="person_with_parents">
				<routine_arg id="61" si_name="login_name" cont_type="SCALAR" scalar_data_type="login_auth" />
				<routine_arg id="62" si_name="login_pass" cont_type="SCALAR" scalar_data_type="login_auth" />
				<routine_var id="63" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_stmt id="64" call_sroutine="CATALOG_OPEN">
					<routine_expr id="65" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="66" call_sroutine_arg="LOGIN_NAME" cont_type="SCALAR" valf_p_routine_item="login_name" />
					<routine_expr id="67" call_sroutine_arg="LOGIN_PASS" cont_type="SCALAR" valf_p_routine_item="login_pass" />
				</routine_stmt>
				<routine_var id="68" si_name="pwp_ary" cont_type="RW_ARY" row_data_type="person_with_parents" />
				<routine_stmt id="69" call_sroutine="SELECT">
					<view id="70" si_name="query_pwp" view_type="ALIAS" row_data_type="person_with_parents">
						<view_src id="71" si_name="s" match="person_with_parents" />
					</view>
					<routine_expr id="72" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="73" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="query_pwp" />
					<routine_expr id="74" call_sroutine_arg="INTO" query_dest="pwp_ary" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="75" call_sroutine="CATALOG_CLOSE">
					<routine_expr id="76" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
				</routine_stmt>
				<routine_stmt id="77" call_sroutine="RETURN">
					<routine_expr id="78" call_sroutine_arg="RETURN_VALUE" cont_type="RW_ARY" valf_p_routine_item="pwp_ary" />
				</routine_stmt>
			</routine>
			<routine id="79" si_name="add_people" routine_type="PROCEDURE">
				<routine_context id="80" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_arg id="81" si_name="person_ary" cont_type="RW_ARY" row_data_type="person" />
				<routine_stmt id="82" call_sroutine="INSERT">
					<view id="83" si_name="insert_people" view_type="INSERT" row_data_type="person" ins_p_routine_item="person_ary">
						<view_src id="84" si_name="s" match="person" />
					</view>
					<routine_expr id="85" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="86" call_sroutine_arg="INSERT_DEFN" cont_type="SRT_NODE" act_on="insert_people" />
				</routine_stmt>
			</routine>
			<routine id="87" si_name="get_person" routine_type="FUNCTION" return_cont_type="ROW" return_row_data_type="person">
				<routine_context id="88" si_name="conn_cx" cont_type="CONN" conn_link="editor_link" />
				<routine_arg id="89" si_name="arg_person_id" cont_type="SCALAR" scalar_data_type="entity_id" />
				<routine_var id="90" si_name="person_row" cont_type="ROW" row_data_type="person" />
				<routine_stmt id="91" call_sroutine="SELECT">
					<view id="92" si_name="query_person" view_type="JOINED" row_data_type="person">
						<view_src id="93" si_name="s" match="person">
							<view_src_field id="94" si_match_field="person_id" />
						</view_src>
						<view_expr id="95" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
							<view_expr id="96" call_sroutine_arg="LHS" cont_type="SCALAR" valf_src_field="person_id" />
							<view_expr id="97" call_sroutine_arg="RHS" cont_type="SCALAR" valf_p_routine_item="arg_person_id" />
						</view_expr>
					</view>
					<routine_expr id="98" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_item="conn_cx" />
					<routine_expr id="99" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" act_on="query_person" />
					<routine_expr id="100" call_sroutine_arg="INTO" query_dest="person_row" cont_type="RW_ARY" />
				</routine_stmt>
				<routine_stmt id="101" call_sroutine="RETURN">
					<routine_expr id="102" call_sroutine_arg="RETURN_VALUE" cont_type="ROW" valf_p_routine_item="person_row" />
				</routine_stmt>
			</routine>
		</application>
	</blueprints>
	<tools>
		<data_storage_product id="103" si_name="SQLite v3.2" product_code="SQLite_3_2" is_file_based="1" />
		<data_storage_product id="104" si_name="MySQL v5.0" product_code="MySQL_5_0" is_network_svc="1" />
		<data_storage_product id="105" si_name="PostgreSQL v8" product_code="PostgreSQL_8" is_network_svc="1" />
		<data_storage_product id="106" si_name="Oracle v10g" product_code="Oracle_10_g" is_network_svc="1" />
		<data_storage_product id="107" si_name="Sybase" product_code="Sybase" is_network_svc="1" />
		<data_storage_product id="108" si_name="CSV" product_code="CSV" is_file_based="1" />
		<data_link_product id="109" si_name="Microsoft ODBC v3" product_code="ODBC_3" />
		<data_link_product id="110" si_name="Oracle OCI*8" product_code="OCI_8" />
		<data_link_product id="111" si_name="Generic Rosetta Engine" product_code="Rosetta::Engine::Generic" />
	</tools>
	<sites>
		<catalog_instance id="112" si_name="test" blueprint="Gene Database" product="PostgreSQL v8">
			<user id="113" si_name="ronsealy" user_type="SCHEMA_OWNER" match_owner="Lord of the Root" password="K34dsD" />
			<user id="114" si_name="joesmith" user_type="DATA_EDITOR" password="fdsKJ4" />
		</catalog_instance>
		<application_instance id="115" si_name="test app" blueprint="Gene App">
			<catalog_link_instance id="116" blueprint="editor_link" product="Microsoft ODBC v3" target="test" local_dsn="keep_it" />
		</application_instance>
		<catalog_instance id="117" si_name="production" blueprint="Gene Database" product="Oracle v10g">
			<user id="118" si_name="florence" user_type="SCHEMA_OWNER" match_owner="Lord of the Root" password="0sfs8G" />
			<user id="119" si_name="thainuff" user_type="DATA_EDITOR" password="9340sd" />
		</catalog_instance>
		<application_instance id="120" si_name="production app" blueprint="Gene App">
			<catalog_link_instance id="121" blueprint="editor_link" product="Oracle OCI*8" target="production" local_dsn="ship_it" />
		</application_instance>
		<catalog_instance id="122" si_name="laptop demo" blueprint="Gene Database" product="SQLite v3.2" file_path="Move It" />
		<application_instance id="123" si_name="laptop demo app" blueprint="Gene App">
			<catalog_link_instance id="124" blueprint="editor_link" product="Generic Rosetta Engine" target="laptop demo" />
		</application_instance>
	</sites>
	<circumventions />
</root>
'
	;
}

######################################################################

1;
