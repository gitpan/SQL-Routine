# This module contains sample input and output data which is used to test 
# SQL::Routine, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SQL_Routine;
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
	$node->set_parent_node_attribute_name( $pp_attr );
	return( $node );
}

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new_container();

	##### NEXT SET CATALOG BLUEPRINT-TYPE DETAILS #####

	# Describe the database catalog blueprint that we will store our data in:
	my $catalog_bp = make_a_node( 'catalog', $model );
	$catalog_bp->set_literal_attribute( 'name', 'The Catalog Blueprint' );

	# Define the unrealized database user that owns our primary schema:
	my $owner = make_a_child_node( 'owner', $catalog_bp, 'catalog' );

	# Define the primary schema that holds our data:
	my $schema = make_a_child_node( 'schema', $catalog_bp, 'catalog' );
	$schema->set_literal_attribute( 'name', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	# Create user-defined data type domain that our database record primary keys are:
	my $dom_entity_id = make_a_child_node( 'domain', $schema, 'schema' );
	$dom_entity_id->set_literal_attribute( 'name', 'entity_id' );
	$dom_entity_id->set_enumerated_attribute( 'base_type', 'NUM_INT' );
	$dom_entity_id->set_literal_attribute( 'num_precision', 9 );

	# Create user-defined data type domain that our person names are:
	my $dom_pers_name = make_a_child_node( 'domain', $schema, 'schema' );
	$dom_pers_name->set_literal_attribute( 'name', 'person_name' );
	$dom_pers_name->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	$dom_pers_name->set_literal_attribute( 'max_chars', 100 );
	$dom_pers_name->set_enumerated_attribute( 'char_enc', 'UTF8' );

	# Define the table that holds our data:
	my $tb_person = make_a_child_node( 'table', $schema, 'schema' );
	$tb_person->set_literal_attribute( 'name', 'person' );

	# Define the 'person id' column of that table:
	my $tbc_person_id = make_a_child_node( 'table_col', $tb_person, 'table' );
	$tbc_person_id->set_literal_attribute( 'name', 'person_id' );
	$tbc_person_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_person_id->set_literal_attribute( 'mandatory', 1 );
	$tbc_person_id->set_literal_attribute( 'default_val', 1 );
	$tbc_person_id->set_literal_attribute( 'auto_inc', 1 );

	# Define the 'person name' column of that table:
	my $tbc_person_name = make_a_child_node( 'table_col', $tb_person, 'table' );
	$tbc_person_name->set_literal_attribute( 'name', 'name' );
	$tbc_person_name->set_node_ref_attribute( 'domain', $dom_pers_name );
	$tbc_person_name->set_literal_attribute( 'mandatory', 1 );

	# Define the 'father' column of that table:
	my $tbc_father_id = make_a_child_node( 'table_col', $tb_person, 'table' );
	$tbc_father_id->set_literal_attribute( 'name', 'father_id' );
	$tbc_father_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_father_id->set_literal_attribute( 'mandatory', 0 );

	# Define the 'mother column of that table:
	my $tbc_mother_id = make_a_child_node( 'table_col', $tb_person, 'table' );
	$tbc_mother_id->set_literal_attribute( 'name', 'mother_id' );
	$tbc_mother_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_mother_id->set_literal_attribute( 'mandatory', 0 );

	# Define the table primary key constraint on person.person_id:
	my $ipk_person = make_a_child_node( 'table_ind', $tb_person, 'table' );
	$ipk_person->set_literal_attribute( 'name', 'primary' );
	$ipk_person->set_enumerated_attribute( 'ind_type', 'UNIQUE' );
	my $icpk_person = make_a_child_node( 'table_ind_col', $ipk_person, 'table_ind' );
	$icpk_person->set_node_ref_attribute( 'table_col', $tbc_person_id );

	# Define a table foreign key constraint on person.father_id to person.person_id:
	my $ifk_father = make_a_child_node( 'table_ind', $tb_person, 'table' );
	$ifk_father->set_literal_attribute( 'name', 'fk_father' );
	$ifk_father->set_enumerated_attribute( 'ind_type', 'FOREIGN' );
	$ifk_father->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_father = make_a_child_node( 'table_ind_col', $ifk_father, 'table_ind' );
	$icfk_father->set_node_ref_attribute( 'table_col', $tbc_father_id );
	$icfk_father->set_node_ref_attribute( 'f_table_col', $tbc_person_id );

	# Define a table foreign key constraint on person.mother_id to person.person_id:
	my $ifk_mother = make_a_child_node( 'table_ind', $tb_person, 'table' );
	$ifk_mother->set_literal_attribute( 'name', 'fk_mother' );
	$ifk_mother->set_enumerated_attribute( 'ind_type', 'FOREIGN' );
	$ifk_mother->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_mother = make_a_child_node( 'table_ind_col', $ifk_mother, 'table_ind' );
	$icfk_mother->set_node_ref_attribute( 'table_col', $tbc_mother_id );
	$icfk_mother->set_node_ref_attribute( 'f_table_col', $tbc_person_id );

	##### NEXT SET APPLICATION BLUEPRINT-TYPE DETAILS #####

	# Describe a utility application for managing our database schema:
	my $setup_app = make_a_node( 'application', $model );
	$setup_app->set_literal_attribute( 'name', 'Setup' );

	# Describe the data link that the utility app will use to talk to the database:
	my $setup_app_cl = make_a_child_node( 'catalog_link', $setup_app, 'application' );
	$setup_app_cl->set_literal_attribute( 'name', 'admin_link' );
	$setup_app_cl->set_node_ref_attribute( 'target', $catalog_bp );

	# Need this domain def for generic boolean literals:
	my $dom_boolean = make_a_child_node( 'domain', $setup_app, 'application' );
	$dom_boolean->set_literal_attribute( 'name', 'boolean' );
	$dom_boolean->set_enumerated_attribute( 'base_type', 'BOOLEAN' );

	# Describe a routine for setting up a database with our schema:
	my $rt_install = make_a_child_node( 'routine', $setup_app, 'application' );
	$rt_install->set_literal_attribute( 'name', 'install_app_schema' );
	$rt_install->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rts_install = make_a_child_node( 'routine_stmt', $rt_install, 'routine' );
	$rts_install->set_enumerated_attribute( 'call_sroutine', 'CATALOG_CREATE' );
	my $rte_install_a1 = make_a_child_node( 'routine_expr', $rts_install, 'p_stmt' );
	$rte_install_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LINK_BP' );
	$rte_install_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_install_a1->set_node_ref_attribute( 'actn_catalog_link', $setup_app_cl );
	my $rte_install_a2 = make_a_child_node( 'routine_expr', $rts_install, 'p_stmt' );
	$rte_install_a2->set_enumerated_attribute( 'call_sroutine_arg', 'RECURSIVE' );
	$rte_install_a2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_install_a2->set_literal_attribute( 'valf_literal', 1 );
	$rte_install_a2->set_node_ref_attribute( 'domain', $dom_boolean );

	# Describe a routine for tearing down a database with our schema:
	my $rt_remove = make_a_child_node( 'routine', $setup_app, 'application' );
	$rt_remove->set_literal_attribute( 'name', 'remove_app_schema' );
	$rt_remove->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rts_remove = make_a_child_node( 'routine_stmt', $rt_remove, 'routine' );
	$rts_remove->set_enumerated_attribute( 'call_sroutine', 'CATALOG_DELETE' );
	my $rte_remove_a1 = make_a_child_node( 'routine_expr', $rts_remove, 'p_stmt' );
	$rte_remove_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LINK_BP' );
	$rte_remove_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_remove_a1->set_node_ref_attribute( 'actn_catalog_link', $setup_app_cl );

	# Describe a 'normal' application for viewing and editing database records:
	my $editor_app = make_a_node( 'application', $model );
	$editor_app->set_literal_attribute( 'name', 'People Watcher' );

	# Describe the data link that the normal app will use to talk to the database:
	my $editor_app_cl = make_a_child_node( 'catalog_link', $editor_app, 'application' );
	$editor_app_cl->set_literal_attribute( 'name', 'editor_link' );
	$editor_app_cl->set_node_ref_attribute( 'target', $catalog_bp );

	# Need this domain def for generic login-name and password literals:
	my $dom_loginauth = make_a_child_node( 'domain', $editor_app, 'application' );
	$dom_loginauth->set_literal_attribute( 'name', 'loginauth' );
	$dom_loginauth->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	$dom_loginauth->set_literal_attribute( 'max_chars', 20 );
	$dom_loginauth->set_enumerated_attribute( 'char_enc', 'UTF8' );

	# Describe a routine that makes a new database connection context, returning it for later use:
	my $rt_declare = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_declare->set_literal_attribute( 'name', 'declare_db_conn' );
	$rt_declare->set_enumerated_attribute( 'routine_type', 'FUNCTION' );
	$rt_declare->set_enumerated_attribute( 'return_cont_type', 'CONN' );
	my $rtv_declare_conn_cx = make_a_child_node( 'routine_var', $rt_declare, 'routine' );
	$rtv_declare_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtv_declare_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtv_declare_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rts_declare_return = make_a_child_node( 'routine_stmt', $rt_declare, 'routine' );
	$rts_declare_return->set_enumerated_attribute( 'call_sroutine', 'RETURN' );
	my $rte_declare_return_a1 = make_a_child_node( 'routine_expr', $rts_declare_return, 'p_stmt' );
	$rte_declare_return_a1->set_enumerated_attribute( 'call_sroutine_arg', 'RETURN_VALUE' );
	$rte_declare_return_a1->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_declare_return_a1->set_node_ref_attribute( 'valf_p_routine_var', $rtv_declare_conn_cx );

	# Describe a routine that opens a database connection context:
	my $rt_open = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_open->set_literal_attribute( 'name', 'open_db_conn' );
	$rt_open->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_open_conn_cx = make_a_child_node( 'routine_context', $rt_open, 'routine' );
	$rtc_open_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_open_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_open_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_open_user = make_a_child_node( 'routine_arg', $rt_open, 'routine' );
	$rta_open_user->set_literal_attribute( 'name', 'login_name' );
	$rta_open_user->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_open_user->set_node_ref_attribute( 'domain', $dom_loginauth );
	my $rta_open_pass = make_a_child_node( 'routine_arg', $rt_open, 'routine' );
	$rta_open_pass->set_literal_attribute( 'name', 'login_pass' );
	$rta_open_pass->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_open_pass->set_node_ref_attribute( 'domain', $dom_loginauth );
	my $rts_open_c = make_a_child_node( 'routine_stmt', $rt_open, 'routine' );
	$rts_open_c->set_enumerated_attribute( 'call_sroutine', 'CATALOG_OPEN' );
	my $rte_open_c_cx = make_a_child_node( 'routine_expr', $rts_open_c, 'p_stmt' );
	$rte_open_c_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_open_c_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_open_c_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_open_conn_cx );
	my $rte_open_c_a1 = make_a_child_node( 'routine_expr', $rts_open_c, 'p_stmt' );
	$rte_open_c_a1->set_enumerated_attribute( 'call_sroutine_arg', 'LOGIN_NAME' );
	$rte_open_c_a1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_open_c_a1->set_node_ref_attribute( 'valf_p_routine_arg', $rta_open_user );
	my $rte_open_c_a2 = make_a_child_node( 'routine_expr', $rts_open_c, 'p_stmt' );
	$rte_open_c_a2->set_enumerated_attribute( 'call_sroutine_arg', 'LOGIN_PASS' );
	$rte_open_c_a2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rte_open_c_a2->set_node_ref_attribute( 'valf_p_routine_arg', $rta_open_pass );

	# Describe a routine that closes a database connection context:
	my $rt_close = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_close->set_literal_attribute( 'name', 'close_db_conn' );
	$rt_close->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_close_conn_cx = make_a_child_node( 'routine_context', $rt_close, 'routine' );
	$rtc_close_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_close_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_close_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rts_close_c = make_a_child_node( 'routine_stmt', $rt_close, 'routine' );
	$rts_close_c->set_enumerated_attribute( 'call_sroutine', 'CATALOG_CLOSE' );
	my $rte_close_c_cx = make_a_child_node( 'routine_expr', $rts_close_c, 'p_stmt' );
	$rte_close_c_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_close_c_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_close_c_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_close_conn_cx );

	# Describe a routine that returns a cursor to fetch all records in the 'person' table:
	my $rt_fetchall = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_fetchall->set_literal_attribute( 'name', 'fetch_all_persons' );
	$rt_fetchall->set_enumerated_attribute( 'routine_type', 'FUNCTION' );
	$rt_fetchall->set_enumerated_attribute( 'return_cont_type', 'CURSOR' );
	my $rtc_fet_conn_cx = make_a_child_node( 'routine_context', $rt_fetchall, 'routine' );
	$rtc_fet_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_fet_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_fet_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $vw_fetchall = make_a_child_node( 'view', $rt_fetchall, 'routine' );
	$vw_fetchall->set_literal_attribute( 'name', 'fetch_all_persons' );
	$vw_fetchall->set_enumerated_attribute( 'view_type', 'MATCH' );
	$vw_fetchall->set_literal_attribute( 'match_all_cols', 1 );
	my $vw_fetchall_s1 = make_a_child_node( 'view_src', $vw_fetchall, 'view' );
	$vw_fetchall_s1->set_literal_attribute( 'name', 'person' );
	$vw_fetchall_s1->set_node_ref_attribute( 'match_table', $tb_person );
	my $rtv_fet_cursor_cx = make_a_child_node( 'routine_var', $rt_fetchall, 'routine' );
	$rtv_fet_cursor_cx->set_literal_attribute( 'name', 'cursor_cx' );
	$rtv_fet_cursor_cx->set_enumerated_attribute( 'cont_type', 'CURSOR' );
	$rtv_fet_cursor_cx->set_node_ref_attribute( 'curs_view', $vw_fetchall );
	my $rts_fet_open_c = make_a_child_node( 'routine_stmt', $rt_fetchall, 'routine' );
	$rts_fet_open_c->set_enumerated_attribute( 'call_sroutine', 'CURSOR_OPEN' );
	my $rte_fet_open_c_cx = make_a_child_node( 'routine_expr', $rts_fet_open_c, 'p_stmt' );
	$rte_fet_open_c_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CURSOR_CX' );
	$rte_fet_open_c_cx->set_enumerated_attribute( 'cont_type', 'CURSOR' );
	$rte_fet_open_c_cx->set_node_ref_attribute( 'valf_p_routine_var', $rtv_fet_cursor_cx );
	my $rts_fet_return = make_a_child_node( 'routine_stmt', $rt_fetchall, 'routine' );
	$rts_fet_return->set_enumerated_attribute( 'call_sroutine', 'RETURN' );
	my $rte_fet_return_a1 = make_a_child_node( 'routine_expr', $rts_fet_return, 'p_stmt' );
	$rte_fet_return_a1->set_enumerated_attribute( 'call_sroutine_arg', 'RETURN_VALUE' );
	$rte_fet_return_a1->set_enumerated_attribute( 'cont_type', 'CURSOR' );
	$rte_fet_return_a1->set_node_ref_attribute( 'valf_p_routine_var', $rtv_fet_cursor_cx );
	# ... The calling code would then fetch whatever rows they want and then close the cursor

	# Describe a routine that inserts a record into the 'person' table:
	my $rt_insertone = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_insertone->set_literal_attribute( 'name', 'insert_a_person' );
	$rt_insertone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_ins_conn_cx = make_a_child_node( 'routine_context', $rt_insertone, 'routine' );
	$rtc_ins_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_ins_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_ins_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_ins_pid = make_a_child_node( 'routine_arg', $rt_insertone, 'routine' );
	$rta_ins_pid->set_literal_attribute( 'name', 'arg_person_id' );
	$rta_ins_pid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_ins_pid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $rta_ins_pnm = make_a_child_node( 'routine_arg', $rt_insertone, 'routine' );
	$rta_ins_pnm->set_literal_attribute( 'name', 'arg_person_name' );
	$rta_ins_pnm->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_ins_pnm->set_node_ref_attribute( 'domain', $dom_pers_name );
	my $rta_ins_fid = make_a_child_node( 'routine_arg', $rt_insertone, 'routine' );
	$rta_ins_fid->set_literal_attribute( 'name', 'arg_father_id' );
	$rta_ins_fid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_ins_fid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $rta_ins_mid = make_a_child_node( 'routine_arg', $rt_insertone, 'routine' );
	$rta_ins_mid->set_literal_attribute( 'name', 'arg_mother_id' );
	$rta_ins_mid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_ins_mid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $vw_insertone = make_a_child_node( 'view', $rt_insertone, 'routine' );
	$vw_insertone->set_literal_attribute( 'name', 'insert_a_person' );
	$vw_insertone->set_enumerated_attribute( 'view_type', 'MATCH' );
	my $vws_ins_pers = make_a_child_node( 'view_src', $vw_insertone, 'view' );
	$vws_ins_pers->set_literal_attribute( 'name', 'person' );
	$vws_ins_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $vwsc_ins_pid = make_a_child_node( 'view_src_col', $vws_ins_pers, 'src' );
	$vwsc_ins_pid->set_node_ref_attribute( 'match_table_col', $tbc_person_id );
	my $vwsc_ins_pnm = make_a_child_node( 'view_src_col', $vws_ins_pers, 'src' );
	$vwsc_ins_pnm->set_node_ref_attribute( 'match_table_col', $tbc_person_name );
	my $vwsc_ins_fid = make_a_child_node( 'view_src_col', $vws_ins_pers, 'src' );
	$vwsc_ins_fid->set_node_ref_attribute( 'match_table_col', $tbc_father_id );
	my $vwsc_ins_mid = make_a_child_node( 'view_src_col', $vws_ins_pers, 'src' );
	$vwsc_ins_mid->set_node_ref_attribute( 'match_table_col', $tbc_mother_id );
	my $vwe_ins_set0 = make_a_child_node( 'view_expr', $vw_insertone, 'view' );
	$vwe_ins_set0->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_ins_set0->set_node_ref_attribute( 'set_src_col', $vwsc_ins_pid );
	$vwe_ins_set0->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_ins_set0->set_node_ref_attribute( 'valf_p_routine_arg', $rta_ins_pid );
	my $vwe_ins_set1 = make_a_child_node( 'view_expr', $vw_insertone, 'view' );
	$vwe_ins_set1->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_ins_set1->set_node_ref_attribute( 'set_src_col', $vwsc_ins_pnm );
	$vwe_ins_set1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_ins_set1->set_node_ref_attribute( 'valf_p_routine_arg', $rta_ins_pnm );
	my $vwe_ins_set2 = make_a_child_node( 'view_expr', $vw_insertone, 'view' );
	$vwe_ins_set2->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_ins_set2->set_node_ref_attribute( 'set_src_col', $vwsc_ins_fid );
	$vwe_ins_set2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_ins_set2->set_node_ref_attribute( 'valf_p_routine_arg', $rta_ins_fid );
	my $vwe_ins_set3 = make_a_child_node( 'view_expr', $vw_insertone, 'view' );
	$vwe_ins_set3->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_ins_set3->set_node_ref_attribute( 'set_src_col', $vwsc_ins_mid );
	$vwe_ins_set3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_ins_set3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_ins_mid );
	my $rts_insert = make_a_child_node( 'routine_stmt', $rt_insertone, 'routine' );
	$rts_insert->set_enumerated_attribute( 'call_sroutine', 'INSERT' );
	my $rte_insert_cx = make_a_child_node( 'routine_expr', $rts_insert, 'p_stmt' );
	$rte_insert_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_insert_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_insert_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_ins_conn_cx );
	my $rte_insert_a1 = make_a_child_node( 'routine_expr', $rts_insert, 'p_stmt' );
	$rte_insert_a1->set_enumerated_attribute( 'call_sroutine_arg', 'INSERT_DEFN' );
	$rte_insert_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_insert_a1->set_node_ref_attribute( 'actn_view', $vw_insertone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	# Describe a routine that updates a record in the 'person' table:
	my $rt_updateone = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_updateone->set_literal_attribute( 'name', 'update_a_person' );
	$rt_updateone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_upd_conn_cx = make_a_child_node( 'routine_context', $rt_updateone, 'routine' );
	$rtc_upd_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_upd_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_upd_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_upd_pid = make_a_child_node( 'routine_arg', $rt_updateone, 'routine' );
	$rta_upd_pid->set_literal_attribute( 'name', 'arg_person_id' );
	$rta_upd_pid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_pid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $rta_upd_pnm = make_a_child_node( 'routine_arg', $rt_updateone, 'routine' );
	$rta_upd_pnm->set_literal_attribute( 'name', 'arg_person_name' );
	$rta_upd_pnm->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_pnm->set_node_ref_attribute( 'domain', $dom_pers_name );
	my $rta_upd_fid = make_a_child_node( 'routine_arg', $rt_updateone, 'routine' );
	$rta_upd_fid->set_literal_attribute( 'name', 'arg_father_id' );
	$rta_upd_fid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_fid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $rta_upd_mid = make_a_child_node( 'routine_arg', $rt_updateone, 'routine' );
	$rta_upd_mid->set_literal_attribute( 'name', 'arg_mother_id' );
	$rta_upd_mid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_upd_mid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $vw_updateone = make_a_child_node( 'view', $rt_updateone, 'routine' );
	$vw_updateone->set_literal_attribute( 'name', 'update_a_person' );
	$vw_updateone->set_enumerated_attribute( 'view_type', 'MATCH' );
	my $vws_upd_pers = make_a_child_node( 'view_src', $vw_updateone, 'view' );
	$vws_upd_pers->set_literal_attribute( 'name', 'person' );
	$vws_upd_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $vwsc_upd_pid = make_a_child_node( 'view_src_col', $vws_upd_pers, 'src' );
	$vwsc_upd_pid->set_node_ref_attribute( 'match_table_col', $tbc_person_id );
	my $vwsc_upd_pnm = make_a_child_node( 'view_src_col', $vws_upd_pers, 'src' );
	$vwsc_upd_pnm->set_node_ref_attribute( 'match_table_col', $tbc_person_name );
	my $vwsc_upd_fid = make_a_child_node( 'view_src_col', $vws_upd_pers, 'src' );
	$vwsc_upd_fid->set_node_ref_attribute( 'match_table_col', $tbc_father_id );
	my $vwsc_upd_mid = make_a_child_node( 'view_src_col', $vws_upd_pers, 'src' );
	$vwsc_upd_mid->set_node_ref_attribute( 'match_table_col', $tbc_mother_id );
	my $vwe_upd_set1 = make_a_child_node( 'view_expr', $vw_updateone, 'view' );
	$vwe_upd_set1->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set1->set_node_ref_attribute( 'set_src_col', $vwsc_upd_pnm );
	$vwe_upd_set1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set1->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_pnm );
	my $vwe_upd_set2 = make_a_child_node( 'view_expr', $vw_updateone, 'view' );
	$vwe_upd_set2->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set2->set_node_ref_attribute( 'set_src_col', $vwsc_upd_fid );
	$vwe_upd_set2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set2->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_fid );
	my $vwe_upd_set3 = make_a_child_node( 'view_expr', $vw_updateone, 'view' );
	$vwe_upd_set3->set_enumerated_attribute( 'view_part', 'SET' );
	$vwe_upd_set3->set_node_ref_attribute( 'set_src_col', $vwsc_upd_mid );
	$vwe_upd_set3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_set3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_mid );
	my $vwe_upd_w1 = make_a_child_node( 'view_expr', $vw_updateone, 'view' );
	$vwe_upd_w1->set_enumerated_attribute( 'view_part', 'WHERE' );
	$vwe_upd_w1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w1->set_enumerated_attribute( 'valf_call_sroutine', 'EQ' );
	my $vwe_upd_w2 = make_a_child_node( 'view_expr', $vwe_upd_w1, 'p_expr' );
	$vwe_upd_w2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w2->set_node_ref_attribute( 'valf_src_col', $vwsc_upd_pid );
	my $vwe_upd_w3 = make_a_child_node( 'view_expr', $vwe_upd_w1, 'p_expr' );
	$vwe_upd_w3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_upd_w3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_upd_pid );
	my $rts_update = make_a_child_node( 'routine_stmt', $rt_updateone, 'routine' );
	$rts_update->set_enumerated_attribute( 'call_sroutine', 'UPDATE' );
	my $rte_update_cx = make_a_child_node( 'routine_expr', $rts_update, 'p_stmt' );
	$rte_update_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_update_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_update_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_upd_conn_cx );
	my $rte_update_a1 = make_a_child_node( 'routine_expr', $rts_update, 'p_stmt' );
	$rte_update_a1->set_enumerated_attribute( 'call_sroutine_arg', 'UPDATE_DEFN' );
	$rte_update_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_update_a1->set_node_ref_attribute( 'actn_view', $vw_updateone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	# Describe a routine that deletes a record from the 'person' table:
	my $rt_deleteone = make_a_child_node( 'routine', $editor_app, 'application' );
	$rt_deleteone->set_literal_attribute( 'name', 'delete_a_person' );
	$rt_deleteone->set_enumerated_attribute( 'routine_type', 'PROCEDURE' );
	my $rtc_del_conn_cx = make_a_child_node( 'routine_context', $rt_deleteone, 'routine' );
	$rtc_del_conn_cx->set_literal_attribute( 'name', 'conn_cx' );
	$rtc_del_conn_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rtc_del_conn_cx->set_node_ref_attribute( 'conn_link', $editor_app_cl );
	my $rta_del_pid = make_a_child_node( 'routine_arg', $rt_deleteone, 'routine' );
	$rta_del_pid->set_literal_attribute( 'name', 'arg_person_id' );
	$rta_del_pid->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$rta_del_pid->set_node_ref_attribute( 'domain', $dom_entity_id );
	my $vw_deleteone = make_a_child_node( 'view', $rt_deleteone, 'routine' );
	$vw_deleteone->set_literal_attribute( 'name', 'delete_a_person' );
	$vw_deleteone->set_enumerated_attribute( 'view_type', 'MATCH' );
	my $vws_del_pers = make_a_child_node( 'view_src', $vw_deleteone, 'view' );
	$vws_del_pers->set_literal_attribute( 'name', 'person' );
	$vws_del_pers->set_node_ref_attribute( 'match_table', $tb_person );
	my $vwsc_del_pid = make_a_child_node( 'view_src_col', $vws_del_pers, 'src' );
	$vwsc_del_pid->set_node_ref_attribute( 'match_table_col', $tbc_person_id );
	my $vwe_del_w1 = make_a_child_node( 'view_expr', $vw_deleteone, 'view' );
	$vwe_del_w1->set_enumerated_attribute( 'view_part', 'WHERE' );
	$vwe_del_w1->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w1->set_enumerated_attribute( 'valf_call_sroutine', 'EQ' );
	my $vwe_del_w2 = make_a_child_node( 'view_expr', $vwe_del_w1, 'p_expr' );
	$vwe_del_w2->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w2->set_node_ref_attribute( 'valf_src_col', $vwsc_del_pid );
	my $vwe_del_w3 = make_a_child_node( 'view_expr', $vwe_del_w1, 'p_expr' );
	$vwe_del_w3->set_enumerated_attribute( 'cont_type', 'SCALAR' );
	$vwe_del_w3->set_node_ref_attribute( 'valf_p_routine_arg', $rta_del_pid );
	my $rts_delete = make_a_child_node( 'routine_stmt', $rt_deleteone, 'routine' );
	$rts_delete->set_enumerated_attribute( 'call_sroutine', 'DELETE' );
	my $rte_delete_cx = make_a_child_node( 'routine_expr', $rts_delete, 'p_stmt' );
	$rte_delete_cx->set_enumerated_attribute( 'call_sroutine_cxt', 'CONN_CX' );
	$rte_delete_cx->set_enumerated_attribute( 'cont_type', 'CONN' );
	$rte_delete_cx->set_node_ref_attribute( 'valf_p_routine_cxt', $rtc_del_conn_cx );
	my $rte_delete_a1 = make_a_child_node( 'routine_expr', $rts_delete, 'p_stmt' );
	$rte_delete_a1->set_enumerated_attribute( 'call_sroutine_arg', 'DELETE_DEFN' );
	$rte_delete_a1->set_enumerated_attribute( 'cont_type', 'SRT_NODE' );
	$rte_delete_a1->set_node_ref_attribute( 'actn_view', $vw_deleteone );
	# ... Currently, nothing is returned, though a count of affected rows could be later

	##### NEXT SET PRODUCT-TYPE DETAILS #####

	# Indicate one database product we will be using:
	my $dsp_sqlite = make_a_node( 'data_storage_product', $model );
	$dsp_sqlite->set_literal_attribute( 'name', 'SQLite v2.8.12' );
	$dsp_sqlite->set_literal_attribute( 'product_code', 'SQLite_2_8_12' );
	$dsp_sqlite->set_literal_attribute( 'is_file_based', 1 );

	# Indicate another database product we will be using:
	my $dsp_oracle = make_a_node( 'data_storage_product', $model );
	$dsp_oracle->set_literal_attribute( 'name', 'Oracle v9i' );
	$dsp_oracle->set_literal_attribute( 'product_code', 'Oracle_9_i' );
	$dsp_oracle->set_literal_attribute( 'is_network_svc', 1 );

	# Indicate the data link product we will be using:
	my $dlp_odbc = make_a_node( 'data_link_product', $model );
	$dlp_odbc->set_literal_attribute( 'name', 'Microsoft ODBC' );
	$dlp_odbc->set_literal_attribute( 'product_code', 'ODBC' );

	##### NEXT SET 'TEST' INSTANCE-TYPE DETAILS #####

	# Define the database catalog instance that our testers will log-in to:
	my $test_db = make_a_node( 'catalog_instance', $model );
	$test_db->set_literal_attribute( 'name', 'test' );
	$test_db->set_node_ref_attribute( 'product', $dsp_sqlite );
	$test_db->set_node_ref_attribute( 'blueprint', $catalog_bp );

	# Define the database user that owns the testing db schema:
	my $ownerI1 = make_a_child_node( 'user', $test_db, 'catalog' );
	$ownerI1->set_literal_attribute( 'name', 'ronsealy' );
	$ownerI1->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI1->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI1->set_literal_attribute( 'password', 'K34dsD' );

	# Define a 'normal' database user that will work with the testing database:
	my $tester = make_a_child_node( 'user', $test_db, 'catalog' );
	$tester->set_literal_attribute( 'name', 'joesmith' );
	$tester->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$tester->set_literal_attribute( 'password', 'fdsKJ4' );

	# Define a utility app instance that testers will demonstrate with:
	my $test_setup_app = make_a_node( 'application_instance', $model );
	$test_setup_app->set_node_ref_attribute( 'blueprint', $setup_app );
	$test_setup_app->set_literal_attribute( 'name', 'test Setup' );
	# Describe the data link instance that the utility app will use to talk to the test database:
	my $test_setup_app_cl = make_a_child_node( 'catalog_link_instance', $test_setup_app, 'application' );
	$test_setup_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$test_setup_app_cl->set_node_ref_attribute( 'unrealized', $setup_app_cl );
	$test_setup_app_cl->set_node_ref_attribute( 'target', $test_db );
	$test_setup_app_cl->set_literal_attribute( 'local_dsn', 'test' );

	# Define a normal app instance that testers will demonstrate with:
	my $test_editor_app = make_a_node( 'application_instance', $model );
	$test_editor_app->set_node_ref_attribute( 'blueprint', $editor_app );
	$test_editor_app->set_literal_attribute( 'name', 'test People Watcher' );
	# Describe the data link instance that the normal app will use to talk to the test database:
	my $test_editor_app_cl = make_a_child_node( 'catalog_link_instance', $test_editor_app, 'application' );
	$test_editor_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$test_editor_app_cl->set_node_ref_attribute( 'unrealized', $editor_app_cl );
	$test_editor_app_cl->set_node_ref_attribute( 'target', $test_db );
	$test_editor_app_cl->set_literal_attribute( 'local_dsn', 'test' );

	##### NEXT SET 'DEMO' INSTANCE-TYPE DETAILS #####

	# Define the database catalog instance that marketers will demonstrate with:
	my $demo_db = make_a_node( 'catalog_instance', $model );
	$demo_db->set_node_ref_attribute( 'product', $dsp_oracle );
	$demo_db->set_node_ref_attribute( 'blueprint', $catalog_bp );
	$demo_db->set_literal_attribute( 'name', 'demo' );

	# Define the database user that owns the demo db schema:
	my $ownerI2 = make_a_child_node( 'user', $demo_db, 'catalog' );
	$ownerI2->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI2->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI2->set_literal_attribute( 'name', 'florence' );
	$ownerI2->set_literal_attribute( 'password', '0sfs8G' );

	# Define a 'normal' user that will work with the demo db:
	my $marketer = make_a_child_node( 'user', $demo_db, 'catalog' );
	$marketer->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$marketer->set_literal_attribute( 'name', 'thainuff' );
	$marketer->set_literal_attribute( 'password', '9340sd' );

	# Define a utility app instance that marketers will demonstrate with:
	my $demo_setup_app = make_a_node( 'application_instance', $model );
	$demo_setup_app->set_literal_attribute( 'name', 'demo Setup' );
	$demo_setup_app->set_node_ref_attribute( 'blueprint', $setup_app );
	# Describe the data link instance that the utility app will use to talk to the demo database:
	my $demo_setup_app_cl = make_a_child_node( 'catalog_link_instance', $demo_setup_app, 'application' );
	$demo_setup_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$demo_setup_app_cl->set_node_ref_attribute( 'unrealized', $setup_app_cl );
	$demo_setup_app_cl->set_node_ref_attribute( 'target', $demo_db );
	$demo_setup_app_cl->set_literal_attribute( 'local_dsn', 'demo' );

	# Define a normal app instance that marketers will demonstrate with:
	my $demo_editor_app = make_a_node( 'application_instance', $model );
	$demo_editor_app->set_literal_attribute( 'name', 'demo People Watcher' );
	$demo_editor_app->set_node_ref_attribute( 'blueprint', $editor_app );
	# Describe the data link instance that the normal app will use to talk to the demo database:
	my $demo_editor_app_cl = make_a_child_node( 'catalog_link_instance', $demo_editor_app, 'application' );
	$demo_editor_app_cl->set_node_ref_attribute( 'product', $dlp_odbc );
	$demo_editor_app_cl->set_node_ref_attribute( 'unrealized', $editor_app_cl );
	$demo_editor_app_cl->set_node_ref_attribute( 'target', $demo_db );
	$demo_editor_app_cl->set_literal_attribute( 'local_dsn', 'demo' );

	# ... we are still missing a bunch of things in this example ...

	##### END OF DETAILS SETTING #####

	# Now check that we didn't omit something important:
	$model->assert_deferrable_constraints();

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<blueprints>
		<catalog id="1" name="The Catalog Blueprint">
			<owner id="1" catalog="1" />
			<schema id="1" catalog="1" name="gene" owner="1">
				<domain id="1" schema="1" name="entity_id" base_type="NUM_INT" num_precision="9" />
				<domain id="2" schema="1" name="person_name" base_type="STR_CHAR" max_chars="100" char_enc="UTF8" />
				<table id="1" schema="1" name="person">
					<table_col id="1" table="1" name="person_id" domain="1" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="2" table="1" name="name" domain="2" mandatory="1" />
					<table_col id="3" table="1" name="father_id" domain="1" mandatory="0" />
					<table_col id="4" table="1" name="mother_id" domain="1" mandatory="0" />
					<table_ind id="1" table="1" name="primary" ind_type="UNIQUE">
						<table_ind_col id="1" table_ind="1" table_col="1" />
					</table_ind>
					<table_ind id="2" table="1" name="fk_father" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="2" table_ind="2" table_col="3" f_table_col="1" />
					</table_ind>
					<table_ind id="3" table="1" name="fk_mother" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="3" table_ind="3" table_col="4" f_table_col="1" />
					</table_ind>
				</table>
			</schema>
		</catalog>
		<application id="1" name="Setup">
			<catalog_link id="1" application="1" name="admin_link" target="1" />
			<domain id="3" application="1" name="boolean" base_type="BOOLEAN" />
			<routine id="1" application="1" name="install_app_schema" routine_type="PROCEDURE">
				<routine_stmt id="1" routine="1" call_sroutine="CATALOG_CREATE">
					<routine_expr id="1" p_stmt="1" call_sroutine_arg="LINK_BP" cont_type="SRT_NODE" actn_catalog_link="1" />
					<routine_expr id="2" p_stmt="1" call_sroutine_arg="RECURSIVE" cont_type="SCALAR" valf_literal="1" domain="3" />
				</routine_stmt>
			</routine>
			<routine id="2" application="1" name="remove_app_schema" routine_type="PROCEDURE">
				<routine_stmt id="2" routine="2" call_sroutine="CATALOG_DELETE">
					<routine_expr id="3" p_stmt="2" call_sroutine_arg="LINK_BP" cont_type="SRT_NODE" actn_catalog_link="1" />
				</routine_stmt>
			</routine>
		</application>
		<application id="2" name="People Watcher">
			<catalog_link id="2" application="2" name="editor_link" target="1" />
			<domain id="4" application="2" name="loginauth" base_type="STR_CHAR" max_chars="20" char_enc="UTF8" />
			<routine id="3" application="2" name="declare_db_conn" routine_type="FUNCTION" return_cont_type="CONN">
				<routine_var id="1" routine="3" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_stmt id="3" routine="3" call_sroutine="RETURN">
					<routine_expr id="4" p_stmt="3" call_sroutine_arg="RETURN_VALUE" cont_type="CONN" valf_p_routine_var="1" />
				</routine_stmt>
			</routine>
			<routine id="4" application="2" name="open_db_conn" routine_type="PROCEDURE">
				<routine_context id="1" routine="4" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_arg id="1" routine="4" name="login_name" cont_type="SCALAR" domain="4" />
				<routine_arg id="2" routine="4" name="login_pass" cont_type="SCALAR" domain="4" />
				<routine_stmt id="4" routine="4" call_sroutine="CATALOG_OPEN">
					<routine_expr id="5" p_stmt="4" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="1" />
					<routine_expr id="6" p_stmt="4" call_sroutine_arg="LOGIN_NAME" cont_type="SCALAR" valf_p_routine_arg="1" />
					<routine_expr id="7" p_stmt="4" call_sroutine_arg="LOGIN_PASS" cont_type="SCALAR" valf_p_routine_arg="2" />
				</routine_stmt>
			</routine>
			<routine id="5" application="2" name="close_db_conn" routine_type="PROCEDURE">
				<routine_context id="2" routine="5" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_stmt id="5" routine="5" call_sroutine="CATALOG_CLOSE">
					<routine_expr id="8" p_stmt="5" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="2" />
				</routine_stmt>
			</routine>
			<routine id="6" application="2" name="fetch_all_persons" routine_type="FUNCTION" return_cont_type="CURSOR">
				<routine_context id="3" routine="6" name="conn_cx" cont_type="CONN" conn_link="2" />
				<view id="1" routine="6" name="fetch_all_persons" view_type="MATCH" match_all_cols="1">
					<view_src id="1" view="1" name="person" match_table="1" />
				</view>
				<routine_var id="2" routine="6" name="cursor_cx" cont_type="CURSOR" curs_view="1" />
				<routine_stmt id="6" routine="6" call_sroutine="CURSOR_OPEN">
					<routine_expr id="9" p_stmt="6" call_sroutine_cxt="CURSOR_CX" cont_type="CURSOR" valf_p_routine_var="2" />
				</routine_stmt>
				<routine_stmt id="7" routine="6" call_sroutine="RETURN">
					<routine_expr id="10" p_stmt="7" call_sroutine_arg="RETURN_VALUE" cont_type="CURSOR" valf_p_routine_var="2" />
				</routine_stmt>
			</routine>
			<routine id="7" application="2" name="insert_a_person" routine_type="PROCEDURE">
				<routine_context id="4" routine="7" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_arg id="3" routine="7" name="arg_person_id" cont_type="SCALAR" domain="1" />
				<routine_arg id="4" routine="7" name="arg_person_name" cont_type="SCALAR" domain="2" />
				<routine_arg id="5" routine="7" name="arg_father_id" cont_type="SCALAR" domain="1" />
				<routine_arg id="6" routine="7" name="arg_mother_id" cont_type="SCALAR" domain="1" />
				<view id="2" routine="7" name="insert_a_person" view_type="MATCH">
					<view_src id="2" view="2" name="person" match_table="1">
						<view_src_col id="1" src="2" match_table_col="1" />
						<view_src_col id="2" src="2" match_table_col="2" />
						<view_src_col id="3" src="2" match_table_col="3" />
						<view_src_col id="4" src="2" match_table_col="4" />
					</view_src>
					<view_expr id="1" view="2" view_part="SET" set_src_col="1" cont_type="SCALAR" valf_p_routine_arg="3" />
					<view_expr id="2" view="2" view_part="SET" set_src_col="2" cont_type="SCALAR" valf_p_routine_arg="4" />
					<view_expr id="3" view="2" view_part="SET" set_src_col="3" cont_type="SCALAR" valf_p_routine_arg="5" />
					<view_expr id="4" view="2" view_part="SET" set_src_col="4" cont_type="SCALAR" valf_p_routine_arg="6" />
				</view>
				<routine_stmt id="8" routine="7" call_sroutine="INSERT">
					<routine_expr id="11" p_stmt="8" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="4" />
					<routine_expr id="12" p_stmt="8" call_sroutine_arg="INSERT_DEFN" cont_type="SRT_NODE" actn_view="2" />
				</routine_stmt>
			</routine>
			<routine id="8" application="2" name="update_a_person" routine_type="PROCEDURE">
				<routine_context id="5" routine="8" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_arg id="7" routine="8" name="arg_person_id" cont_type="SCALAR" domain="1" />
				<routine_arg id="8" routine="8" name="arg_person_name" cont_type="SCALAR" domain="2" />
				<routine_arg id="9" routine="8" name="arg_father_id" cont_type="SCALAR" domain="1" />
				<routine_arg id="10" routine="8" name="arg_mother_id" cont_type="SCALAR" domain="1" />
				<view id="3" routine="8" name="update_a_person" view_type="MATCH">
					<view_src id="3" view="3" name="person" match_table="1">
						<view_src_col id="5" src="3" match_table_col="1" />
						<view_src_col id="6" src="3" match_table_col="2" />
						<view_src_col id="7" src="3" match_table_col="3" />
						<view_src_col id="8" src="3" match_table_col="4" />
					</view_src>
					<view_expr id="5" view="3" view_part="SET" set_src_col="6" cont_type="SCALAR" valf_p_routine_arg="8" />
					<view_expr id="6" view="3" view_part="SET" set_src_col="7" cont_type="SCALAR" valf_p_routine_arg="9" />
					<view_expr id="7" view="3" view_part="SET" set_src_col="8" cont_type="SCALAR" valf_p_routine_arg="10" />
					<view_expr id="8" view="3" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="9" p_expr="8" cont_type="SCALAR" valf_src_col="5" />
						<view_expr id="10" p_expr="8" cont_type="SCALAR" valf_p_routine_arg="7" />
					</view_expr>
				</view>
				<routine_stmt id="9" routine="8" call_sroutine="UPDATE">
					<routine_expr id="13" p_stmt="9" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="5" />
					<routine_expr id="14" p_stmt="9" call_sroutine_arg="UPDATE_DEFN" cont_type="SRT_NODE" actn_view="3" />
				</routine_stmt>
			</routine>
			<routine id="9" application="2" name="delete_a_person" routine_type="PROCEDURE">
				<routine_context id="6" routine="9" name="conn_cx" cont_type="CONN" conn_link="2" />
				<routine_arg id="11" routine="9" name="arg_person_id" cont_type="SCALAR" domain="1" />
				<view id="4" routine="9" name="delete_a_person" view_type="MATCH">
					<view_src id="4" view="4" name="person" match_table="1">
						<view_src_col id="9" src="4" match_table_col="1" />
					</view_src>
					<view_expr id="11" view="4" view_part="WHERE" cont_type="SCALAR" valf_call_sroutine="EQ">
						<view_expr id="12" p_expr="11" cont_type="SCALAR" valf_src_col="9" />
						<view_expr id="13" p_expr="11" cont_type="SCALAR" valf_p_routine_arg="11" />
					</view_expr>
				</view>
				<routine_stmt id="10" routine="9" call_sroutine="DELETE">
					<routine_expr id="15" p_stmt="10" call_sroutine_cxt="CONN_CX" cont_type="CONN" valf_p_routine_cxt="6" />
					<routine_expr id="16" p_stmt="10" call_sroutine_arg="DELETE_DEFN" cont_type="SRT_NODE" actn_view="4" />
				</routine_stmt>
			</routine>
		</application>
	</blueprints>
	<tools>
		<data_storage_product id="1" name="SQLite v2.8.12" product_code="SQLite_2_8_12" is_file_based="1" />
		<data_storage_product id="2" name="Oracle v9i" product_code="Oracle_9_i" is_network_svc="1" />
		<data_link_product id="1" name="Microsoft ODBC" product_code="ODBC" />
	</tools>
	<sites>
		<catalog_instance id="1" name="test" product="1" blueprint="1">
			<user id="1" catalog="1" name="ronsealy" user_type="SCHEMA_OWNER" match_owner="1" password="K34dsD" />
			<user id="2" catalog="1" name="joesmith" user_type="DATA_EDITOR" password="fdsKJ4" />
		</catalog_instance>
		<application_instance id="1" name="test Setup" blueprint="1">
			<catalog_link_instance id="1" application="1" product="1" unrealized="1" target="1" local_dsn="test" />
		</application_instance>
		<application_instance id="2" name="test People Watcher" blueprint="2">
			<catalog_link_instance id="2" application="2" product="1" unrealized="2" target="1" local_dsn="test" />
		</application_instance>
		<catalog_instance id="2" name="demo" product="2" blueprint="1">
			<user id="3" catalog="2" name="florence" user_type="SCHEMA_OWNER" match_owner="1" password="0sfs8G" />
			<user id="4" catalog="2" name="thainuff" user_type="DATA_EDITOR" password="9340sd" />
		</catalog_instance>
		<application_instance id="3" name="demo Setup" blueprint="1">
			<catalog_link_instance id="3" application="3" product="1" unrealized="1" target="2" local_dsn="demo" />
		</application_instance>
		<application_instance id="4" name="demo People Watcher" blueprint="2">
			<catalog_link_instance id="4" application="4" product="1" unrealized="2" target="2" local_dsn="demo" />
		</application_instance>
	</sites>
	<circumventions />
</root>
'
	);
}

######################################################################

sub test_circular_ref_prevention {
	my (undef, $class) = @_;
	my $model = $class->new_container();

	my $catalog_bp = make_a_node( 'catalog', $model );
	$catalog_bp->set_literal_attribute( 'name', 'The Catalog Blueprint' );
	my $owner = make_a_child_node( 'owner', $catalog_bp, 'catalog' );
	my $schema = make_a_child_node( 'schema', $catalog_bp, 'catalog' );
	$schema->set_literal_attribute( 'name', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	my $vw1 = make_a_child_node( 'view', $schema, 'schema' );
	$vw1->set_literal_attribute( 'name', 'foo' );
	$vw1->set_enumerated_attribute( 'view_type', 'COMPOUND' );
	$vw1->set_enumerated_attribute( 'compound_op', 'UNION' );

	my $vw2 = make_a_child_node( 'view', $vw1, 'p_view' );
	$vw2->set_literal_attribute( 'name', 'bar' );
	$vw2->set_enumerated_attribute( 'view_type', 'SINGLE' );

	my $vw3 = make_a_child_node( 'view', $vw2, 'p_view' );
	$vw3->set_literal_attribute( 'name', 'bz' );
	$vw3->set_enumerated_attribute( 'view_type', 'SINGLE' );

	my $test1_passed = 0;
	my $test2_passed = 0;
	eval {
		$vw2->set_node_ref_attribute( 'p_view', $vw3 );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_NREF_AT_CIRC_REF' ) {
				$test1_passed = 1;
			}
		}
	}
	eval {
		$vw3->clear_parent_node_attribute_name();
		$vw2->set_node_ref_attribute( 'p_view', $vw3 );
		$vw3->set_parent_node_attribute_name( 'p_view' );
	};
	if( my $exception = $@ ) {
		if( ref($exception) and UNIVERSAL::isa( $exception, 'Locale::KeyedText::Message' ) ) {
			if( $exception->get_message_key() eq 'SRT_N_SET_P_NODE_ATNM_CIRC_REF' ) {
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
