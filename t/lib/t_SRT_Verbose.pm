# This module is used when testing SQL::Routine.
# These tests check that a model can be built using the verbose standard 
# interface without errors, and serializes to the correct output.
# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SRT_Verbose;
use strict;
use warnings;

######################################################################

sub make_a_node {
	my ($node_type, $model) = @_;
	my $node = $model->new_node( $node_type );
	$node->set_node_id( $model->get_next_free_node_id() );
	$node->put_in_container( $model );
	return( $node );
}

sub make_a_child_node {
	my ($node_type, $pp_node, $pp_attr) = @_;
	my $container = $pp_node->get_container();
	my $node = $pp_node->new_node( $node_type );
	$node->set_node_id( $container->get_next_free_node_id() );
	$node->put_in_container( $container );
	$node->set_node_ref_attribute( $pp_attr, $pp_node );
	$node->set_pp_node_attribute_name( $pp_attr );
	return( $node );
}

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();

	##### NEXT SET CATALOG ELEMENT-TYPE DETAILS #####

	# Create user-defined scalar data type that our database record primary keys are:
	my $sdt_entity_id = make_a_node( 'scalar_data_type', $model );
	$sdt_entity_id->set_literal_attribute( 'si_name', 'entity_id' );
	$sdt_entity_id->set_enumerated_attribute( 'base_type', 'NUM_INT' );
	$sdt_entity_id->set_literal_attribute( 'num_precision', 9 );

	# Create user-defined scalar data type that our person names are:
	my $sdt_pers_name = make_a_node( 'scalar_data_type', $model );
	$sdt_pers_name->set_literal_attribute( 'si_name', 'person_name' );
	$sdt_pers_name->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	$sdt_pers_name->set_literal_attribute( 'max_chars', 100 );
	$sdt_pers_name->set_enumerated_attribute( 'char_enc', 'UTF8' );

	# Create u-d row data type that describes the columns of the table that holds our data:
	my $rdt_person = make_a_node( 'row_data_type', $model );
	$rdt_person->set_literal_attribute( 'si_name', 'person' );

	# Define the 'person id' field/column of that row/table:
	my $rdtf_person_id = make_a_child_node( 'row_data_type_field', $rdt_person, 'pp_row_data_type' );
	$rdtf_person_id->set_literal_attribute( 'si_name', 'person_id' );
	$rdtf_person_id->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );

	# Define the 'person name' field/column of that row/table:
	my $rdtf_person_name = make_a_child_node( 'row_data_type_field', $rdt_person, 'pp_row_data_type' );
	$rdtf_person_name->set_literal_attribute( 'si_name', 'name' );
	$rdtf_person_name->set_node_ref_attribute( 'scalar_data_type', $sdt_pers_name );

	# Define the 'father' field/column of that row/table:
	my $rdtf_father_id = make_a_child_node( 'row_data_type_field', $rdt_person, 'pp_row_data_type' );
	$rdtf_father_id->set_literal_attribute( 'si_name', 'father_id' );
	$rdtf_father_id->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );

	# Define the 'mother field/column of that row/table:
	my $rdtf_mother_id = make_a_child_node( 'row_data_type_field', $rdt_person, 'pp_row_data_type' );
	$rdtf_mother_id->set_literal_attribute( 'si_name', 'mother_id' );
	$rdtf_mother_id->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );

	##### NEXT SET APPLICATION ELEMENT-TYPE DETAILS #####

	# Create user-defined data type for generic boolean literals:
	my $sdt_boolean = make_a_node( 'scalar_data_type', $model );
	$sdt_boolean->set_literal_attribute( 'si_name', 'boolean' );
	$sdt_boolean->set_enumerated_attribute( 'base_type', 'BOOLEAN' );

	# Create user-defined data type for generic login-name and password literals:
	my $sdt_loginauth = make_a_node( 'scalar_data_type', $model );
	$sdt_loginauth->set_literal_attribute( 'si_name', 'loginauth' );
	$sdt_loginauth->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	$sdt_loginauth->set_literal_attribute( 'max_chars', 20 );
	$sdt_loginauth->set_enumerated_attribute( 'char_enc', 'UTF8' );

	##### NEXT SET CATALOG BLUEPRINT-TYPE DETAILS #####

	# Describe the database catalog blueprint that we will store our data in:
	my $catalog_bp = make_a_node( 'catalog', $model );
	$catalog_bp->set_literal_attribute( 'si_name', 'The Catalog Blueprint' );

	# Define the unrealized database user that owns our primary schema:
	my $owner = make_a_child_node( 'owner', $catalog_bp, 'pp_catalog' );

	# Define the primary schema that holds our data:
	my $schema = make_a_child_node( 'schema', $catalog_bp, 'pp_catalog' );
	$schema->set_literal_attribute( 'si_name', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	# Create u-d row domain that describes the columns of the table that holds our data:
	my $dom_person = make_a_child_node( 'row_domain', $schema, 'pp_schema' );
	$dom_person->set_literal_attribute( 'si_name', 'person_type' );
	$dom_person->set_node_ref_attribute( 'data_type', $rdt_person );

	# Define the table that holds our data:
	my $tb_person = make_a_child_node( 'table', $schema, 'pp_schema' );
	$tb_person->set_literal_attribute( 'si_name', 'person' );
	$tb_person->set_node_ref_attribute( 'row_domain', $dom_person );

	# Add more attributes to the 'person id' column of that table:
	my $tbf_person_id = make_a_child_node( 'table_field', $tb_person, 'pp_table' );
	$tbf_person_id->set_node_ref_attribute( 'si_row_field', $rdtf_person_id );
	$tbf_person_id->set_literal_attribute( 'mandatory', 1 );
	$tbf_person_id->set_literal_attribute( 'default_val', 1 );
	$tbf_person_id->set_literal_attribute( 'auto_inc', 1 );

	# Add more attributes to the 'person name' column of that table:
	my $tbf_person_name = make_a_child_node( 'table_field', $tb_person, 'pp_table' );
	$tbf_person_name->set_node_ref_attribute( 'si_row_field', $rdtf_person_name );
	$tbf_person_name->set_literal_attribute( 'mandatory', 1 );

	# Define the table primary key constraint on person.person_id:
	my $ipk_person = make_a_child_node( 'table_index', $tb_person, 'pp_table' );
	$ipk_person->set_literal_attribute( 'si_name', 'primary' );
	$ipk_person->set_enumerated_attribute( 'index_type', 'UNIQUE' );
	my $icpk_person = make_a_child_node( 'table_index_field', $ipk_person, 'pp_table_index' );
	$icpk_person->set_node_ref_attribute( 'si_field', $rdtf_person_id );

	# Define a table foreign key constraint on person.father_id to person.person_id:
	my $ifk_father = make_a_child_node( 'table_index', $tb_person, 'pp_table' );
	$ifk_father->set_literal_attribute( 'si_name', 'fk_father' );
	$ifk_father->set_enumerated_attribute( 'index_type', 'FOREIGN' );
	$ifk_father->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_father = make_a_child_node( 'table_index_field', $ifk_father, 'pp_table_index' );
	$icfk_father->set_node_ref_attribute( 'si_field', $rdtf_father_id );
	$icfk_father->set_node_ref_attribute( 'f_field', $rdtf_person_id );

	# Define a table foreign key constraint on person.mother_id to person.person_id:
	my $ifk_mother = make_a_child_node( 'table_index', $tb_person, 'pp_table' );
	$ifk_mother->set_literal_attribute( 'si_name', 'fk_mother' );
	$ifk_mother->set_enumerated_attribute( 'index_type', 'FOREIGN' );
	$ifk_mother->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_mother = make_a_child_node( 'table_index_field', $ifk_mother, 'pp_table_index' );
	$icfk_mother->set_node_ref_attribute( 'si_field', $rdtf_mother_id );
	$icfk_mother->set_node_ref_attribute( 'f_field', $rdtf_person_id );

	##### NEXT SET APPLICATION BLUEPRINT-TYPE DETAILS #####

	# Describe a utility application for managing our database schema:
	my $setup_app = make_a_node( 'application', $model );
	$setup_app->set_literal_attribute( 'si_name', 'Setup' );

	# Describe the data link that the utility app will use to talk to the database:
	my $setup_app_cl = make_a_child_node( 'catalog_link', $setup_app, 'pp_application' );
	$setup_app_cl->set_literal_attribute( 'si_name', 'admin_link' );
	$setup_app_cl->set_node_ref_attribute( 'target', $catalog_bp );

	# Describe a routine for setting up a database with our schema:
	my $rt_install = make_a_child_node( 'routine', $setup_app, 'pp_application' );
	$rt_install->set_literal_attribute( 'si_name', 'install_app_schema' );
	$rt_install->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rts_install = make_a_child_node( 'routine_stmt', $rt_install, 'pp_routine' );
	$rts_install->set_enumerated_attribute( 'call_sroutine', 'CATALOG_CREATE' );
	my $rte_install_a1 = make_a_child_node( 'routine_expr', $rts_install, 'pp_stmt' );
	$rte_install_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LINK_BP' );
	$rte_install_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_install_a1->set_node_ref_attribute( 'actn_catalog_link', $setup_app_cl );
	my $rte_install_a2 = make_a_child_node( 'routine_expr', $rts_install, 'pp_stmt' );
	$rte_install_a2->set_enumerated_attribute( 'call_sroutine_arg', 'RECURSIVE' );
	$rte_install_a2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_install_a2->set_literal_attribute( 'valf_literal', 1 );
	$rte_install_a2->set_node_ref_attribute( 'scalar_data_type', $sdt_boolean );

	# Describe a routine for tearing down a database with our schema:
	my $rt_remove = make_a_child_node( 'routine', $setup_app, 'pp_application' );
	$rt_remove->set_literal_attribute( 'si_name', 'remove_app_schema' );
	$rt_remove->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rts_remove = make_a_child_node( 'routine_stmt', $rt_remove, 'pp_routine' );
	$rts_remove->set_enumerated_attribute( 'call_sroutine', 'CATALOG_DELETE' );
	my $rte_remove_a1 = make_a_child_node( 'routine_expr', $rts_remove, 'pp_stmt' );
	$rte_remove_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LINK_BP' );
	$rte_remove_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_remove_a1->set_node_ref_attribute( 'actn_catalog_link', $setup_app_cl );

	# Describe a 'normal' application for viewing and editing database records:
	my $editor_app = make_a_node( 'application', $model );
	$editor_app->set_literal_attribute( 'si_name', 'People Watcher' );

	# Describe the data link that the normal app will use to talk to the database:
	my $editor_app_cl = make_a_child_node( 'catalog_link', $editor_app, 'pp_application' );
	$editor_app_cl->set_literal_attribute( 'si_name', 'editor_link' );
	$editor_app_cl->set_node_ref_attribute( 'target', $catalog_bp );

	# Describe a routine that makes a new database connection context, returning it for later use:
	my $rt_declare = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_declare->set_literal_attribute( 'si_name', 'declare_db_conn' );
	$rt_declare->set_enumerated_attribute( 'routine_type', 'FUNCTION' );
	$rt_declare->set_enumerated_attribute( 'return_cont_type', 'CONN' );
	my $rtv_declare_conn_cx = make_a_child_node( 'routine_var', $rt_declare, 'pp_routine' );
	$rtv_declare_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtv_declare_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtv_declare_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rts_declare_return = make_a_child_node( 'routine_stmt', $rt_declare, 'pp_routine' );
	$rts_declare_return->set_enumerated_attribute( 'call_sroutine', 'RETURN' );
	my $rte_declare_return_a1 = make_a_child_node( 'routine_expr', $rts_declare_return, 'pp_stmt' );
	$rte_declare_return_a1->set_enumerated_attribute( 'call_sroutine_arg', 'RETURN_VALUE' );
	$rte_declare_return_a1->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_declare_return_a1->set_node_ref_attribute( 'valf_p_routine_var', $rtv_declare_conn_cx );

	# Describe a routine that opens a database connection context:
	my $rt_open = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_open->set_literal_attribute( 'si_name', 'open_db_conn' );
	$rt_open->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_open_conn_cx = make_a_child_node( 'routine_context', $rt_open, 'pp_routine' );
	$rtc_open_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_open_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_open_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_open_user = make_a_child_node( 'routine_arg', $rt_open, 'pp_routine' );
	$rta_open_user->set_literal_attribute( 'si_name', 'login_name' );
	$rta_open_user->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_open_user->set_node_ref_attribute( 'scalar_data_type', $sdt_loginauth );
	my $rta_open_pass = make_a_child_node( 'routine_arg', $rt_open, 'pp_routine' );
	$rta_open_pass->set_literal_attribute( 'si_name', 'login_pass' );
	$rta_open_pass->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_open_pass->set_node_ref_attribute( 'scalar_data_type', $sdt_loginauth );
	my $rts_open_c = make_a_child_node( 'routine_stmt', $rt_open, 'pp_routine' );
	$rts_open_c->set_enumerated_attribute( 'call_sroutine', 'CATALOG_OPEN' );
	my $rte_open_c_cx = make_a_child_node( 'routine_expr', $rts_open_c, 'pp_stmt' );
	$rte_open_c_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_open_c_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_open_c_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_open_conn_cx );
	my $rte_open_c_a1 = make_a_child_node( 'routine_expr', $rts_open_c, 'pp_stmt' );
	$rte_open_c_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LOGIN_NAME' );
	$rte_open_c_a1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_open_c_a1->set_node_ref_attribute( 'valf_p_routine_arg', $rta_open_user );
	my $rte_open_c_a2 = make_a_child_node( 'routine_expr', $rts_open_c, 'pp_stmt' );
	$rte_open_c_a2->set_enumerated_attribute( 'call_sroutine_arg', 'LOGIN_PASS' );
	$rte_open_c_a2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_open_c_a2->set_node_ref_attribute( 'valf_p_routine_arg', $rta_open_pass );

	# Describe a routine that closes a database connection context:
	my $rt_close = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_close->set_literal_attribute( 'si_name', 'close_db_conn' );
	$rt_close->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_close_conn_cx = make_a_child_node( 'routine_context', $rt_close, 'pp_routine' );
	$rtc_close_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_close_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_close_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rts_close_c = make_a_child_node( 'routine_stmt', $rt_close, 'pp_routine' );
	$rts_close_c->set_enumerated_attribute( 'call_sroutine', 'CATALOG_CLOSE' );
	my $rte_close_c_cx = make_a_child_node( 'routine_expr', $rts_close_c, 'pp_stmt' );
	$rte_close_c_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_close_c_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_close_c_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_close_conn_cx );

	# Describe a routine that fetches and returns all records in the 'person' table:
	my $rt_fetchall = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_fetchall->set_literal_attribute( 'si_name', 'fetch_all_persons' );
	$rt_fetchall->set_enumerated_attribute( 'routine_type', 'FUNCTION' );
	$rt_fetchall->set_enumerated_attribute( 'return_cont_type', 'RW_ARY' );
	$rt_fetchall->set_node_ref_attribute( 'return_row_domain', $dom_person );
	my $rtc_fet_conn_cx = make_a_child_node( 'routine_context', $rt_fetchall, 'pp_routine' );
	$rtc_fet_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_fet_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_fet_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rtv_person_ary = make_a_child_node( 'routine_var', $rt_fetchall, 'pp_routine' );
	$rtv_person_ary->set_literal_attribute( 'si_name', 'person_ary' );
	$rtv_person_ary->set_enumerated_attribute( 'cont_type', 'RW_ARY' );
	$rtv_person_ary->set_node_ref_attribute( 'row_domain', $dom_person );
	my $vw_fetchall = make_a_child_node( 'view', $rt_fetchall, 'pp_routine' );
	$vw_fetchall->set_literal_attribute( 'si_name', 'fetch_all_persons' );
	$vw_fetchall->set_enumerated_attribute( 'view_type', 'ALIAS' );
	$vw_fetchall->set_node_ref_attribute( 'row_domain', $dom_person );
	$vw_fetchall->set_node_ref_attribute( 'set_p_routine_var', $rtv_person_ary );
	my $vws_fetchall = make_a_child_node( 'view_src', $vw_fetchall, 'pp_view' );
	$vws_fetchall->set_literal_attribute( 'si_name', 'person' );
	$vws_fetchall->set_node_ref_attribute( 'match_table', $tb_person );
	my $rts_select = make_a_child_node( 'routine_stmt', $rt_fetchall, 'pp_routine' );
	$rts_select->set_enumerated_attribute( 'call_sroutine', 'SELECT' );
	my $rte_select_cx = make_a_child_node( 'routine_expr', $rts_select, 'pp_stmt' );
	$rte_select_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_select_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_select_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_fet_conn_cx );
	my $rte_select_defn = make_a_child_node( 'routine_expr', $rts_select, 'pp_stmt' );
	$rte_select_defn->set_enumerated_attribute( 'call_sroutine_arg', 'SELECT_DEFN' );
	$rte_select_defn->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_select_defn->set_node_ref_attribute( 'actn_view', $vw_fetchall );
	my $rts_fet_return = make_a_child_node( 'routine_stmt', $rt_fetchall, 'pp_routine' );
	$rts_fet_return->set_enumerated_attribute( 'call_sroutine', 'RETURN' );
	my $rte_fet_return_a1 = make_a_child_node( 'routine_expr', $rts_fet_return, 'pp_stmt' );
	$rte_fet_return_a1->set_enumerated_attribute( 'call_sroutine_arg', 'RETURN_VALUE' );
	$rte_fet_return_a1->set_enumerated_attribute( 'cont_type', 'RW_ARY' );
	$rte_fet_return_a1->set_node_ref_attribute( 'valf_p_routine_var', $rtv_person_ary );

	# Describe a routine that inserts a record into the 'person' table:
	my $rt_insertone = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_insertone->set_literal_attribute( 'si_name', 'insert_a_person' );
	$rt_insertone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_ins_conn_cx = make_a_child_node( 'routine_context', $rt_insertone, 'pp_routine' );
	$rtc_ins_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_ins_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_ins_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_person = make_a_child_node( 'routine_arg', $rt_insertone, 'pp_routine' );
	$rta_person->set_literal_attribute( 'si_name', 'person' );
	$rta_person->set_enumerated_attribute( 'cont_type', 'ROW' );
	$rta_person->set_node_ref_attribute( 'row_domain', $dom_person );
	my $vw_insertone = make_a_child_node( 'view', $rt_insertone, 'pp_routine' );
	$vw_insertone->set_literal_attribute( 'si_name', 'insert_a_person' );
	$vw_insertone->set_enumerated_attribute( 'view_type', 'INSERT' );
	$vw_insertone->set_node_ref_attribute( 'row_domain', $dom_person );
	$vw_insertone->set_node_ref_attribute( 'ins_p_routine_arg', $rta_person );
	my $vws_ins_pers = make_a_child_node( 'view_src', $vw_insertone, 'pp_view' );
	$vws_ins_pers->set_literal_attribute( 'si_name', 'person' );
	$vws_ins_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $rts_insert = make_a_child_node( 'routine_stmt', $rt_insertone, 'pp_routine' );
	$rts_insert->set_enumerated_attribute( 'call_sroutine', 'INSERT' );
	my $rte_insert_cx = make_a_child_node( 'routine_expr', $rts_insert, 'pp_stmt' );
	$rte_insert_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_insert_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_insert_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_ins_conn_cx );
	my $rte_insert_defn = make_a_child_node( 'routine_expr', $rts_insert, 'pp_stmt' );
	$rte_insert_defn->set_enumerated_attribute( 'call_sroutine_arg', 'INSERT_DEFN' );
	$rte_insert_defn->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_insert_defn->set_node_ref_attribute( 'actn_view', $vw_insertone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	# Describe a routine that updates a record in the 'person' table:
	my $rt_updateone = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_updateone->set_literal_attribute( 'si_name', 'update_a_person' );
	$rt_updateone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_upd_conn_cx = make_a_child_node( 'routine_context', $rt_updateone, 'pp_routine' );
	$rtc_upd_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_upd_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_upd_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_upd_pid = make_a_child_node( 'routine_arg', $rt_updateone, 'pp_routine' );
	$rta_upd_pid->set_literal_attribute( 'si_name', 'arg_person_id' );
	$rta_upd_pid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_pid->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );
	my $rta_upd_pnm = make_a_child_node( 'routine_arg', $rt_updateone, 'pp_routine' );
	$rta_upd_pnm->set_literal_attribute( 'si_name', 'arg_person_name' );
	$rta_upd_pnm->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_pnm->set_node_ref_attribute( 'scalar_data_type', $sdt_pers_name );
	my $rta_upd_fid = make_a_child_node( 'routine_arg', $rt_updateone, 'pp_routine' );
	$rta_upd_fid->set_literal_attribute( 'si_name', 'arg_father_id' );
	$rta_upd_fid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_fid->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );
	my $rta_upd_mid = make_a_child_node( 'routine_arg', $rt_updateone, 'pp_routine' );
	$rta_upd_mid->set_literal_attribute( 'si_name', 'arg_mother_id' );
	$rta_upd_mid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_mid->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );
	my $vw_updateone = make_a_child_node( 'view', $rt_updateone, 'pp_routine' );
	$vw_updateone->set_literal_attribute( 'si_name', 'update_a_person' );
	$vw_updateone->set_enumerated_attribute( 'view_type', 'UPDATE' );
	my $vws_upd_pers = make_a_child_node( 'view_src', $vw_updateone, 'pp_view' );
	$vws_upd_pers->set_literal_attribute( 'si_name', 'person' );
	$vws_upd_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $vwsc_upd_pid = make_a_child_node( 'view_src_field', $vws_upd_pers, 'pp_src' );
	$vwsc_upd_pid->set_node_ref_attribute( 'si_match_field', $rdtf_person_id );
	my $vwsc_upd_pnm = make_a_child_node( 'view_src_field', $vws_upd_pers, 'pp_src' );
	$vwsc_upd_pnm->set_node_ref_attribute( 'si_match_field', $rdtf_person_name );
	my $vwsc_upd_fid = make_a_child_node( 'view_src_field', $vws_upd_pers, 'pp_src' );
	$vwsc_upd_fid->set_node_ref_attribute( 'si_match_field', $rdtf_father_id );
	my $vwsc_upd_mid = make_a_child_node( 'view_src_field', $vws_upd_pers, 'pp_src' );
	$vwsc_upd_mid->set_node_ref_attribute( 'si_match_field', $rdtf_mother_id );
	my $vwe_upd_set1 = make_a_child_node( 'view_expr', $vw_updateone, 'pp_view' );
	$vwe_upd_set1->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set1->set_node_ref_attribute( 'set_src_field', $vwsc_upd_pnm );
	$vwe_upd_set1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set1->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_pnm );
	my $vwe_upd_set2 = make_a_child_node( 'view_expr', $vw_updateone, 'pp_view' );
	$vwe_upd_set2->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set2->set_node_ref_attribute( 'set_src_field', $vwsc_upd_fid );
	$vwe_upd_set2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set2->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_fid );
	my $vwe_upd_set3 = make_a_child_node( 'view_expr', $vw_updateone, 'pp_view' );
	$vwe_upd_set3->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set3->set_node_ref_attribute( 'set_src_field', $vwsc_upd_mid );
	$vwe_upd_set3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_mid );
	my $vwe_upd_w1 = make_a_child_node( 'view_expr', $vw_updateone, 'pp_view' );
	$vwe_upd_w1->set_enumerated_attribute( 'view_part', 'WHERE' );
	$vwe_upd_w1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w1->set_enumerated_attribute( 'valf_call_sroutine', 'EQ' );
	my $vwe_upd_w2 = make_a_child_node( 'view_expr', $vwe_upd_w1, 'pp_expr' );
	$vwe_upd_w2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w2->set_node_ref_attribute( 'valf_src_field', $vwsc_upd_pid );
	my $vwe_upd_w3 = make_a_child_node( 'view_expr', $vwe_upd_w1, 'pp_expr' );
	$vwe_upd_w3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_pid );
	my $rts_update = make_a_child_node( 'routine_stmt', $rt_updateone, 'pp_routine' );
	$rts_update->set_enumerated_attribute( 'call_sroutine', 'UPDATE' );
	my $rte_update_cx = make_a_child_node( 'routine_expr', $rts_update, 'pp_stmt' );
	$rte_update_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_update_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_update_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_upd_conn_cx );
	my $rte_update_defn = make_a_child_node( 'routine_expr', $rts_update, 'pp_stmt' );
	$rte_update_defn->set_enumerated_attribute( 'call_sroutine_arg', 'UPDATE_DEFN' );
	$rte_update_defn->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_update_defn->set_node_ref_attribute( 'actn_view', $vw_updateone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	# Describe a routine that deletes a record from the 'person' table:
	my $rt_deleteone = make_a_child_node( 'routine', $editor_app, 'pp_application' );
	$rt_deleteone->set_literal_attribute( 'si_name', 'delete_a_person' );
	$rt_deleteone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_del_conn_cx = make_a_child_node( 'routine_context', $rt_deleteone, 'pp_routine' );
	$rtc_del_conn_cx->set_literal_attribute( 'si_name', 'conn_cx' );
	$rtc_del_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_del_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_del_pid = make_a_child_node( 'routine_arg', $rt_deleteone, 'pp_routine' );
	$rta_del_pid->set_literal_attribute( 'si_name', 'arg_person_id' );
	$rta_del_pid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_del_pid->set_node_ref_attribute( 'scalar_data_type', $sdt_entity_id );
	my $vw_deleteone = make_a_child_node( 'view', $rt_deleteone, 'pp_routine' );
	$vw_deleteone->set_literal_attribute( 'si_name', 'delete_a_person' );
	$vw_deleteone->set_enumerated_attribute( 'view_type', 'DELETE' );
	my $vws_del_pers = make_a_child_node( 'view_src', $vw_deleteone, 'pp_view' );
	$vws_del_pers->set_literal_attribute( 'si_name', 'person' );
	$vws_del_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $vwsc_del_pid = make_a_child_node( 'view_src_field', $vws_del_pers, 'pp_src' );
	$vwsc_del_pid->set_node_ref_attribute( 'si_match_field', $rdtf_person_id );
	my $vwe_del_w1 = make_a_child_node( 'view_expr', $vw_deleteone, 'pp_view' );
	$vwe_del_w1->set_enumerated_attribute( 'view_part', 'WHERE' );
	$vwe_del_w1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w1->set_enumerated_attribute( 'valf_call_sroutine', 'EQ' );
	my $vwe_del_w2 = make_a_child_node( 'view_expr', $vwe_del_w1, 'pp_expr' );
	$vwe_del_w2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w2->set_node_ref_attribute( 'valf_src_field', $vwsc_del_pid );
	my $vwe_del_w3 = make_a_child_node( 'view_expr', $vwe_del_w1, 'pp_expr' );
	$vwe_del_w3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_del_pid );
	my $rts_delete = make_a_child_node( 'routine_stmt', $rt_deleteone, 'pp_routine' );
	$rts_delete->set_enumerated_attribute( 'call_sroutine', 'DELETE' );
	my $rte_delete_cx = make_a_child_node( 'routine_expr', $rts_delete, 'pp_stmt' );
	$rte_delete_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_delete_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_delete_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_del_conn_cx );
	my $rte_delete_defn = make_a_child_node( 'routine_expr', $rts_delete, 'pp_stmt' );
	$rte_delete_defn->set_enumerated_attribute( 'call_sroutine_arg', 'DELETE_DEFN' );
	$rte_delete_defn->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_delete_defn->set_node_ref_attribute( 'actn_view', $vw_deleteone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	##### NEXT SET PRODUCT-TYPE DETAILS #####

	# Indicate one database product we will be using:
	my $dsp_sqlite = make_a_node( 'data_storage_product', $model );
	$dsp_sqlite->set_literal_attribute( 'si_name', 'SQLite v2.8.12' );
	$dsp_sqlite->set_literal_attribute( 'product_code', 'SQLite_2_8_12' );
	$dsp_sqlite->set_literal_attribute( 'is_file_based', 1 );

	# Indicate another database product we will be using:
	my $dsp_oracle = make_a_node( 'data_storage_product', $model );
	$dsp_oracle->set_literal_attribute( 'si_name', 'Oracle v9i' );
	$dsp_oracle->set_literal_attribute( 'product_code', 'Oracle_9_i' );
	$dsp_oracle->set_literal_attribute( 'is_network_svc', 1 );

	# Indicate the data link product we will be using:
	my $dlp_odbc = make_a_node( 'data_link_product', $model );
	$dlp_odbc->set_literal_attribute( 'si_name', 'Microsoft ODBC' );
	$dlp_odbc->set_literal_attribute( 'product_code', 'ODBC' );

	##### NEXT SET 'TEST' INSTANCE-TYPE DETAILS #####

	# Define the database catalog instance that our testers will log-in to:
	my $test_db = make_a_node( 'catalog_instance', $model );
	$test_db->set_literal_attribute( 'si_name', 'test' );
	$test_db->set_node_ref_attribute( 'product', $dsp_sqlite );
	$test_db->set_node_ref_attribute( 'blueprint', $catalog_bp );

	# Define the database user that owns the testing db schema:
	my $ownerI1 = make_a_child_node( 'user', $test_db, 'pp_catalog' );
	$ownerI1->set_literal_attribute( 'si_name', 'ronsealy' );
	$ownerI1->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI1->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI1->set_literal_attribute( 'password', 'K34dsD' );

	# Define a 'normal' database user that will work with the testing database:
	my $tester = make_a_child_node( 'user', $test_db, 'pp_catalog' );
	$tester->set_literal_attribute( 'si_name', 'joesmith' );
	$tester->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$tester->set_literal_attribute( 'password', 'fdsKJ4' );

	# Define a utility app instance that testers will demonstrate with:
	my $test_setup_app = make_a_node( 'application_instance', $model );
	$test_setup_app->set_node_ref_attribute( 'blueprint', $setup_app );
	$test_setup_app->set_literal_attribute( 'si_name', 'test Setup' );
	# Describe the data link instance that the utility app will use to talk to the test database:
	my $test_setup_app_cl = make_a_child_node( 'catalog_link_instance', $test_setup_app, 'pp_application' );
	$test_setup_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$test_setup_app_cl->set_node_ref_attribute( 'blueprint', $setup_app_cl );
	$test_setup_app_cl->set_node_ref_attribute( 'target', $test_db );
	$test_setup_app_cl->set_literal_attribute( 'local_dsn', 'test' );

	# Define a normal app instance that testers will demonstrate with:
	my $test_editor_app = make_a_node( 'application_instance', $model );
	$test_editor_app->set_node_ref_attribute( 'blueprint', $editor_app );
	$test_editor_app->set_literal_attribute( 'si_name', 'test People Watcher' );
	# Describe the data link instance that the normal app will use to talk to the test database:
	my $test_editor_app_cl = make_a_child_node( 'catalog_link_instance', $test_editor_app, 'pp_application' );
	$test_editor_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$test_editor_app_cl->set_node_ref_attribute( 'blueprint', $editor_app_cl );
	$test_editor_app_cl->set_node_ref_attribute( 'target', $test_db );
	$test_editor_app_cl->set_literal_attribute( 'local_dsn', 'test' );

	##### NEXT SET 'DEMO' INSTANCE-TYPE DETAILS #####

	# Define the database catalog instance that marketers will demonstrate with:
	my $demo_db = make_a_node( 'catalog_instance', $model );
	$demo_db->set_node_ref_attribute( 'product', $dsp_oracle );
	$demo_db->set_node_ref_attribute( 'blueprint', $catalog_bp );
	$demo_db->set_literal_attribute( 'si_name', 'demo' );

	# Define the database user that owns the demo db schema:
	my $ownerI2 = make_a_child_node( 'user', $demo_db, 'pp_catalog' );
	$ownerI2->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI2->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI2->set_literal_attribute( 'si_name', 'florence' );
	$ownerI2->set_literal_attribute( 'password', '0sfs8G' );

	# Define a 'normal' user that will work with the demo db:
	my $marketer = make_a_child_node( 'user', $demo_db, 'pp_catalog' );
	$marketer->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$marketer->set_literal_attribute( 'si_name', 'thainuff' );
	$marketer->set_literal_attribute( 'password', '9340sd' );

	# Define a utility app instance that marketers will demonstrate with:
	my $demo_setup_app = make_a_node( 'application_instance', $model );
	$demo_setup_app->set_literal_attribute( 'si_name', 'demo Setup' );
	$demo_setup_app->set_node_ref_attribute( 'blueprint', $setup_app );
	# Describe the data link instance that the utility app will use to talk to the demo database:
	my $demo_setup_app_cl = make_a_child_node( 'catalog_link_instance', $demo_setup_app, 'pp_application' );
	$demo_setup_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$demo_setup_app_cl->set_node_ref_attribute( 'blueprint', $setup_app_cl );
	$demo_setup_app_cl->set_node_ref_attribute( 'target', $demo_db );
	$demo_setup_app_cl->set_literal_attribute( 'local_dsn', 'demo' );

	# Define a normal app instance that marketers will demonstrate with:
	my $demo_editor_app = make_a_node( 'application_instance', $model );
	$demo_editor_app->set_literal_attribute( 'si_name', 'demo People Watcher' );
	$demo_editor_app->set_node_ref_attribute( 'blueprint', $editor_app );
	# Describe the data link instance that the normal app will use to talk to the demo database:
	my $demo_editor_app_cl = make_a_child_node( 'catalog_link_instance', $demo_editor_app, 'pp_application' );
	$demo_editor_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$demo_editor_app_cl->set_node_ref_attribute( 'blueprint', $editor_app_cl );
	$demo_editor_app_cl->set_node_ref_attribute( 'target', $demo_db );
	$demo_editor_app_cl->set_literal_attribute( 'local_dsn', 'demo' );

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
		<scalar_data_type id="1" si_name="entity_id" base_type="NUM_INT" num_precision="9" />
		<scalar_data_type id="2" si_name="person_name" base_type="STR_CHAR" max_chars="100" char_enc="UTF8" />
		<row_data_type id="3" si_name="person">
			<row_data_type_field id="4" pp_row_data_type="3" si_name="person_id" scalar_data_type="1" />
			<row_data_type_field id="5" pp_row_data_type="3" si_name="name" scalar_data_type="2" />
			<row_data_type_field id="6" pp_row_data_type="3" si_name="father_id" scalar_data_type="1" />
			<row_data_type_field id="7" pp_row_data_type="3" si_name="mother_id" scalar_data_type="1" />
		</row_data_type>
		<scalar_data_type id="8" si_name="boolean" base_type="BOOLEAN" />
		<scalar_data_type id="9" si_name="loginauth" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
	</elements>
	<blueprints>
		<catalog id="10" si_name="The Catalog Blueprint">
			<owner id="11" pp_catalog="10" />
			<schema id="12" pp_catalog="10" si_name="gene" owner="11">
				<row_domain id="13" pp_schema="12" si_name="person_type" data_type="3" />
				<table id="14" pp_schema="12" si_name="person" row_domain="13">
					<table_field id="15" pp_table="14" si_row_field="4" mandatory="1" default_val="1" auto_inc="1" />
					<table_field id="16" pp_table="14" si_row_field="5" mandatory="1" />
					<table_index id="17" pp_table="14" si_name="primary" index_type="UNIQUE">
						<table_index_field id="18" pp_table_index="17" si_field="4" />
					</table_index>
					<table_index id="19" pp_table="14" si_name="fk_father" index_type="FOREIGN" f_table="14">
						<table_index_field id="20" pp_table_index="19" si_field="6" f_field="4" />
					</table_index>
					<table_index id="21" pp_table="14" si_name="fk_mother" index_type="FOREIGN" f_table="14">
						<table_index_field id="22" pp_table_index="21" si_field="7" f_field="4" />
					</table_index>
				</table>
			</schema>
		</catalog>
		<application id="23" si_name="Setup">
			<catalog_link id="24" pp_application="23" si_name="admin_link" target="10" />
			<routine id="25" pp_application="23" si_name="install_app_schema" routine_type="PROCEDURE">
				<routine_stmt id="26" pp_routine="25" call_sroutine="CATALOG_CREATE">
					<routine_expr id="27" pp_stmt="26" call_sroutine_arg="LINK_BP" cont_type="SRT_NODE" actn_catalog_link="24" />
					<routine_expr id="28" pp_stmt="26" call_sroutine_arg="RECURSIVE" cont_type="SCALAR" valf_literal="1" scalar_data_type="8" />
				</routine_stmt>
			</routine>
			<routine id="29" pp_application="23" si_name="remove_app_schema" routine_type="PROCEDURE">
				<routine_stmt id="30" pp_routine="29" call_sroutine="CATALOG_DELETE">
					<routine_expr id="31" pp_stmt="30" call_sroutine_arg="LINK_BP" cont_type="SRT_NODE" actn_catalog_link="24" />
				</routine_stmt>
			</routine>
		</application>
		<application id="32" si_name="People Watcher">
			<catalog_link id="33" pp_application="32" si_name="editor_link" target="10" />
			<routine id="34" pp_application="32" si_name="declare_db_conn" routine_type="FUNCTION" return_cont_type="CONN">
				<routine_var id="35" pp_routine="34" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_stmt id="36" pp_routine="34" call_sroutine="RETURN">
					<routine_expr id="37" pp_stmt="36" call_sroutine_arg="RETURN_VALUE" cont_type="CONN" valf_p_routine_var="35" />
				</routine_stmt>
			</routine>
			<routine id="38" pp_application="32" si_name="open_db_conn" routine_type="PROCEDURE">
				<routine_context id="39" pp_routine="38" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_arg id="40" pp_routine="38" si_name="login_name" cont_type="SCALAR" scalar_data_type="9" />
				<routine_arg id="41" pp_routine="38" si_name="login_pass" cont_type="SCALAR" scalar_data_type="9" />
				<routine_stmt id="42" pp_routine="38" call_sroutine="CATALOG_OPEN">
					<routine_expr id="43" pp_stmt="42" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="39" />
					<routine_expr id="44" pp_stmt="42" call_sroutine_arg="LOGIN_NAME" cont_type="SCALAR" valf_p_routine_arg="40" />
					<routine_expr id="45" pp_stmt="42" call_sroutine_arg="LOGIN_PASS" cont_type="SCALAR" valf_p_routine_arg="41" />
				</routine_stmt>
			</routine>
			<routine id="46" pp_application="32" si_name="close_db_conn" routine_type="PROCEDURE">
				<routine_context id="47" pp_routine="46" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_stmt id="48" pp_routine="46" call_sroutine="CATALOG_CLOSE">
					<routine_expr id="49" pp_stmt="48" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="47" />
				</routine_stmt>
			</routine>
			<routine id="50" pp_application="32" si_name="fetch_all_persons" routine_type="FUNCTION" return_cont_type="RW_ARY" return_row_domain="13">
				<routine_context id="51" pp_routine="50" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_var id="52" pp_routine="50" si_name="person_ary" cont_type="RW_ARY" row_domain="13" />
				<view id="53" pp_routine="50" si_name="fetch_all_persons" view_type="ALIAS" row_domain="13" set_p_routine_var="52">
					<view_src id="54" pp_view="53" si_name="person" match_table="14" />
				</view>
				<routine_stmt id="55" pp_routine="50" call_sroutine="SELECT">
					<routine_expr id="56" pp_stmt="55" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="51" />
					<routine_expr id="57" pp_stmt="55" call_sroutine_arg="SELECT_DEFN" cont_type="SRT_NODE" actn_view="53" />
				</routine_stmt>
				<routine_stmt id="58" pp_routine="50" call_sroutine="RETURN">
					<routine_expr id="59" pp_stmt="58" call_sroutine_arg="RETURN_VALUE" cont_type="RW_ARY" valf_p_routine_var="52" />
				</routine_stmt>
			</routine>
			<routine id="60" pp_application="32" si_name="insert_a_person" routine_type="PROCEDURE">
				<routine_context id="61" pp_routine="60" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_arg id="62" pp_routine="60" si_name="person" cont_type="ROW" row_domain="13" />
				<view id="63" pp_routine="60" si_name="insert_a_person" view_type="INSERT" row_domain="13" ins_p_routine_arg="62">
					<view_src id="64" pp_view="63" si_name="person" match_table="14" />
				</view>
				<routine_stmt id="65" pp_routine="60" call_sroutine="INSERT">
					<routine_expr id="66" pp_stmt="65" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="61" />
					<routine_expr id="67" pp_stmt="65" call_sroutine_arg="INSERT_DEFN" cont_type="SRT_NODE" actn_view="63" />
				</routine_stmt>
			</routine>
			<routine id="68" pp_application="32" si_name="update_a_person" routine_type="PROCEDURE">
				<routine_context id="69" pp_routine="68" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_arg id="70" pp_routine="68" si_name="arg_person_id" cont_type="SCALAR" scalar_data_type="1" />
				<routine_arg id="71" pp_routine="68" si_name="arg_person_name" cont_type="SCALAR" scalar_data_type="2" />
				<routine_arg id="72" pp_routine="68" si_name="arg_father_id" cont_type="SCALAR" scalar_data_type="1" />
				<routine_arg id="73" pp_routine="68" si_name="arg_mother_id" cont_type="SCALAR" scalar_data_type="1" />
				<view id="74" pp_routine="68" si_name="update_a_person" view_type="UPDATE">
					<view_src id="75" pp_view="74" si_name="person" match_table="14">
						<view_src_field id="76" pp_src="75" si_match_field="4" />
						<view_src_field id="77" pp_src="75" si_match_field="5" />
						<view_src_field id="78" pp_src="75" si_match_field="6" />
						<view_src_field id="79" pp_src="75" si_match_field="7" />
					</view_src>
					<view_expr id="80" pp_view="74" view_part="SET" set_src_field="77" cont_type="SCALAR" valf_p_routine_arg="71" />
					<view_expr id="81" pp_view="74" view_part="SET" set_src_field="78" cont_type="SCALAR" valf_p_routine_arg="72" />
					<view_expr id="82" pp_view="74" view_part="SET" set_src_field="79" cont_type="SCALAR" valf_p_routine_arg="73" />
					<view_expr id="83" pp_view="74" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="84" pp_expr="83" cont_type="SCALAR" valf_src_field="76" />
						<view_expr id="85" pp_expr="83" cont_type="SCALAR" valf_p_routine_arg="70" />
					</view_expr>
				</view>
				<routine_stmt id="86" pp_routine="68" call_sroutine="UPDATE">
					<routine_expr id="87" pp_stmt="86" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="69" />
					<routine_expr id="88" pp_stmt="86" call_sroutine_arg="UPDATE_DEFN" cont_type="SRT_NODE" actn_view="74" />
				</routine_stmt>
			</routine>
			<routine id="89" pp_application="32" si_name="delete_a_person" routine_type="PROCEDURE">
				<routine_context id="90" pp_routine="89" si_name="conn_cx" cont_type="CONN" conn_link="33" />
				<routine_arg id="91" pp_routine="89" si_name="arg_person_id" cont_type="SCALAR" scalar_data_type="1" />
				<view id="92" pp_routine="89" si_name="delete_a_person" view_type="DELETE">
					<view_src id="93" pp_view="92" si_name="person" match_table="14">
						<view_src_field id="94" pp_src="93" si_match_field="4" />
					</view_src>
					<view_expr id="95" pp_view="92" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="96" pp_expr="95" cont_type="SCALAR" valf_src_field="94" />
						<view_expr id="97" pp_expr="95" cont_type="SCALAR" valf_p_routine_arg="91" />
					</view_expr>
				</view>
				<routine_stmt id="98" pp_routine="89" call_sroutine="DELETE">
					<routine_expr id="99" pp_stmt="98" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="90" />
					<routine_expr id="100" pp_stmt="98" call_sroutine_arg="DELETE_DEFN" cont_type="SRT_NODE" actn_view="92" />
				</routine_stmt>
			</routine>
		</application>
	</blueprints>
	<tools>
		<data_storage_product id="101" si_name="SQLite v2.8.12" product_code="SQLite_2_8_12" is_file_based="1" />
		<data_storage_product id="102" si_name="Oracle v9i" product_code="Oracle_9_i" is_network_svc="1" />
		<data_link_product id="103" si_name="Microsoft ODBC" product_code="ODBC" />
	</tools>
	<sites>
		<catalog_instance id="104" si_name="test" blueprint="10" product="101">
			<user id="105" pp_catalog="104" si_name="ronsealy" user_type="SCHEMA_OWNER" match_owner="11" password="K34dsD" />
			<user id="106" pp_catalog="104" si_name="joesmith" user_type="DATA_EDITOR" password="fdsKJ4" />
		</catalog_instance>
		<application_instance id="107" si_name="test Setup" blueprint="23">
			<catalog_link_instance id="108" pp_application="107" blueprint="24" product="103" target="104" local_dsn="test" />
		</application_instance>
		<application_instance id="109" si_name="test People Watcher" blueprint="32">
			<catalog_link_instance id="110" pp_application="109" blueprint="33" product="103" target="104" local_dsn="test" />
		</application_instance>
		<catalog_instance id="111" si_name="demo" blueprint="10" product="102">
			<user id="112" pp_catalog="111" si_name="florence" user_type="SCHEMA_OWNER" match_owner="11" password="0sfs8G" />
			<user id="113" pp_catalog="111" si_name="thainuff" user_type="DATA_EDITOR" password="9340sd" />
		</catalog_instance>
		<application_instance id="114" si_name="demo Setup" blueprint="23">
			<catalog_link_instance id="115" pp_application="114" blueprint="24" product="103" target="111" local_dsn="demo" />
		</application_instance>
		<application_instance id="116" si_name="demo People Watcher" blueprint="32">
			<catalog_link_instance id="117" pp_application="116" blueprint="33" product="103" target="111" local_dsn="demo" />
		</application_instance>
	</sites>
	<circumventions />
</root>
'
	);
}

######################################################################

1;
