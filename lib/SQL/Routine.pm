#!perl

use 5.008001; use utf8; use strict; use warnings;

package SQL::Routine;
our $VERSION = '0.56';

use Locale::KeyedText '1.02';

######################################################################

=encoding utf8

=head1 NAME

SQL::Routine - Specify all database tasks with SQL routines

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: 

	Locale::KeyedText 1.02 (for error messages)

=head1 COPYRIGHT AND LICENSE

This file is part of the SQL::Routine library (libSQLRT).

SQL::Routine is Copyright (c) 1999-2005, Darren R. Duncan.  All rights
reserved. Address comments, suggestions, and bug reports to
B<perl@DarrenDuncan.net>, or visit "http://www.DarrenDuncan.net" for more
information.

SQL::Routine is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) version 2 as published by the
Free Software Foundation (http://www.fsf.org/).  You should have received a
copy of the GPL as part of the SQL::Routine distribution, in the file named
"LICENSE"; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA 02111-1307 USA.

Linking SQL::Routine statically or dynamically with other modules is making a
combined work based on SQL::Routine.  Thus, the terms and conditions of the GPL
cover the whole combination.  As a special exception, the copyright holders of
SQL::Routine give you permission to link SQL::Routine with independent modules,
regardless of the license terms of these independent modules, and to copy and
distribute the resulting combined work under terms of your choice, provided
that every copy of the combined work is accompanied by a complete copy of the
source code of SQL::Routine (the version of SQL::Routine used to produce the
combined work), being distributed under the terms of the GPL plus this
exception.  An independent module is a module which is not derived from or
based on SQL::Routine, and which is fully useable when not linked to
SQL::Routine in any form.

Any versions of SQL::Routine that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::Routine is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of SQL::Routine would
appreciate being informed any time you create a modified version of
SQL::Routine that you are willing to distribute, because that is a practical
way of suggesting improvements to the standard version.

=cut

######################################################################
######################################################################

# Names of properties for objects of the SQL::Routine::Container class are declared here:
my $CPROP_AUTO_ASS_DEF_CON = 'auto_ass_def_con'; # boolean - false by def
	# When this flag is true, SQL::Routine's build_*() methods will
	# automatically invoke assert_deferrable_constraints() on the newly created Node,
	# if it is in this Container, prior to returning it.  The use of this method
	# helps isolate bad input bugs faster by flagging them closer to when they were
	# created; it is especially useful with the build*tree() methods.
my $CPROP_AUTO_SET_NIDS = 'auto_set_nids'; # boolean - false by def
	# When this flag is true, SQL::Routine will automatically generate and set a Node Id for 
	# a Node that lacks one as soon as there is an attempt to put that Node in this Container.
	# When this flag is false, a missing Node Id will cause an exception to be raised instead.
my $CPROP_MAY_MATCH_SNIDS = 'may_match_snids'; # boolean - false by def
	# When this flag is true, SQL::Routine will accept a wider range of input values when setting 
	# Node ref attribute values, beyond Node object references and integers representing Node ids to 
	# look up; if other types of values are provided, SQL::Routine will try to look up Nodes based 
	# on other attributes than the Id, usually 'si_name', before giving up on finding a Node to link.
my $CPROP_ALL_NODES = 'all_nodes'; # hash of Node refs; find any Node by its node_id quickly
my $CPROP_PSEUDONODES = 'pseudonodes'; # hash of arrays of Node refs
	# This property is for remembering the insert order of Nodes having hardwired pseudonode parents
my $CPROP_NEXT_FREE_NID = 'next_free_nid'; # uint; next free node id
	# Value is one higher than the highest Node ID that is or was in use by a Node in this Container.
my $CPROP_DEF_CON_TESTED = 'def_con_tested'; # boolean - true by def, false when changes made
	# This property is a status flag which says there have been no changes to the Nodes 
	# in this Container since the last time assert_deferrable_constraints() passed its tests, 
	# and so the current Nodes are still valid.  It is used internally by 
	# assert_deferrable_constraints() to make code faster by avoiding un-necessary 
	# repeated tests from multiple external Container.assert_deferrable_constraints() calls.
	# It is set true on a new empty Container, and set false when any Nodes are moved in 
	# or out of the "well known" state within that Container, or are changed while in that state.
#my $CPROP_CURR_NODE = 'curr_node'; # ref to a Node; used when "streaming" to or from XML
	# I may instead make a new inner class for this, and there can be several of these 
	# per container, such as if multiple streams are working in different areas at once; 
	# any Container property would then just have a list of those active objects, 
	# so they can be killed (return links to Container obj broken) if their Container is destroyed.
# To do: have attribute to indicate an edit in progress 
	# or that there was a failure resulting in inconsistent data;
	# this may be set by a method which partly implements a data change 
	# which is not backed out of, before that function throws an exception;
	# this property may best just be inside the thrown Locale::KeyedText object;
	# OTOH, if users have coarse-grained locks on Containers for threads, we could have a property,
	# since a call to an editing method would check and clear that before the thread releases lock

# Names of properties for objects of the SQL::Routine::Node class are declared here:
	# The C version will have the following comprise fields in a Node struct;
	# all fields will be integers or memory references or enums; none will be strings.
my $NPROP_NODE_TYPE   = 'node_type'; # str (enum) - what type of Node this is, can not change once set
	# The Node type is the only property which absolutely can not change, and is set when object created.
	# (All other Node properties start out undefined or false, and are set separately from object creation.)
	# C version of this will be an enumerated value.
my $NPROP_NODE_ID     = 'node_id'; # uint - unique identifier attribute for this node within container+type
	# Node id must be set when/before Node is put in a container; may lack one when not in container.
	# C version of this will be an unsigned integer.
	# This property corresponds to a Node attribute named 'id'.
my $NPROP_PP_NREF = 'pp_nref'; # Node - special Node attr which points to primary-parent Node (or id reps other Node)
	# C version of this will be either an array or a single struct, to handle pointer vs uint
	# Value can only be actual reference when Node is in a Container, and pointed to must be in same
	# This property is analagous to a non-existing AT_NREFS element whose name is "pp".
	# When converting to XML, this "pp" attribute won't become an XML attr (redundant)
my $NPROP_AT_LITERALS = 'at_literals'; # hash (enum,lit) - attrs of Node which are non-enum, non-id literal values
	# C version of this will be an array (pointer) of Literal structs.
	# We already know what all the attributes can be for each node type, so the size of the array 
	# will be fixed and known in advance, allowing it to be all allocated with one malloc() call.
	# Each attribute struct would be at a specific array index; 
	# C macros/constants will give names to the indices, like with the hash keys for the above.
my $NPROP_AT_ENUMS    = 'at_enums'; # hash (enum,enum) - attrs of Node which are enumerated values
	# C version of this will be an array (pointer) of enumerated values.
my $NPROP_AT_NREFS    = 'at_nrefs'; # hash (enum,Node) - attrs of Node which point to other Nodes (or ids rep other Nodes)
	# C version of this will be either multiple arrays or a single array of structs, to handle pointer vs uint
	# Hash elements can only be actual references when Node is in a Container, and pointed to must be in same
my $NPROP_CONTAINER   = 'container'; # ref to Container this Node lives in
	# C version of this would be a pointer to a Container struct
my $NPROP_PRIM_CHILD_NREFS = 'prim_child_nrefs'; # array - list of refs to other Nodes having actual refs to this one
	# We use this to reciprocate actual refs from the PP_NREF property of other Nodes to us.
	# When converting to XML, only child Nodes linked through PRIM_CHILD_NREFS are rendered.
	# Every Node in this list is guaranteed to appear in this list exactly once.
my $NPROP_LINK_CHILD_NREFS = 'link_child_nrefs'; # array - list of refs to other Nodes having actual refs to this one
	# We use this to reciprocate actual refs from the AT_NREFS property of other Nodes to us.
	# When converting to XML, only child Nodes linked through PRIM_CHILD_NREFS are rendered.
	# C version will be a double-linked list with each element representing a Node struct.
	# Each Node in this list may possibly appear in this list more than once.
	# It is important to ensure that if a Node links to us multiple times (via multiple AT_NREFS) 
	# then we include the other Node in our child list just as many times; eg: 2 here means 2 back; 
	# however, when rendering to XML, we only render a Node once, and not as many times as linked; 
	# it is also possible that we may never be put in this situation from real-world usage.
	# Note that in the above situation, a normalized child list would have the above two links sitting 
	# adjacent to each other; put_in_container() will do this, but subsequent calls to 
	# set_node_ref_attribute() might not.  In the interest of simplicity, any method that wants to 
	# change the order of a child list should also normalize any multiple same-child occurrances.

# These are programmatically recognized enumerations of values that 
# particular Node attributes are allowed to have.  They are given names 
# here so that multiple Node types can make use of the same value lists.  
# Currently only the codes are shown, but attributes may be attached later.
my %ENUMERATED_TYPES = (
	'container_type' => { map { ($_ => 1) } qw(
		ERROR SCALAR ROW SC_ARY RW_ARY CONN CURSOR LIST SRT_NODE SRT_NODE_LIST
	) },
	'exception_type' => { map { ($_ => 1) } qw(
		SRTX_NO_ENVI_LOAD_FAILED SRTX_ENVI_EXEC_FAILED 
		SRTX_NO_CONN_SERVER_ABSENT SRTX_NO_CONN_BAD_AUTH SRTX_NO_CONN_ACTIVE_LOST
	) },
	'standard_routine' => { map { ($_ => 1) } qw(
		CATALOG_LIST CATALOG_INFO CATALOG_VERIFY 
		CATALOG_CREATE CATALOG_DELETE CATALOG_CLONE CATALOG_MOVE
		CATALOG_OPEN 
		CATALOG_CLOSE 
		CATALOG_PING CATALOG_ATTACH CATALOG_DETACH 
		SCHEMA_LIST SCHEMA_INFO SCHEMA_VERIFY
		SCHEMA_CREATE SCHEMA_DELETE SCHEMA_CLONE SCHEMA_UPDATE 
		DOMAIN_LIST DOMAIN_INFO DOMAIN_VERIFY
		DOMAIN_CREATE DOMAIN_DELETE DOMAIN_CLONE DOMAIN_UPDATE
		SEQU_LIST SEQU_INFO SEQU_VERIFY
		SEQU_CREATE SEQU_DELETE SEQU_CLONE SEQU_UPDATE
		TABLE_LIST TABLE_INFO TABLE_VERIFY
		TABLE_CREATE TABLE_DELETE TABLE_CLONE TABLE_UPDATE
		VIEW_LIST VIEW_INFO VIEW_VERIFY
		VIEW_CREATE VIEW_DELETE VIEW_CLONE VIEW_UPDATE
		ROUTINE_LIST ROUTINE_INFO ROUTINE_VERIFY 
		ROUTINE_CREATE ROUTINE_DELETE ROUTINE_CLONE ROUTINE_UPDATE
		USER_LIST USER_INFO USER_VERIFY
		USER_CREATE USER_DELETE USER_CLONE USER_UPDATE USER_GRANT USER_REVOKE
		REC_FETCH 
		REC_VERIFY REC_INSERT REC_UPDATE 
		REC_DELETE REC_REPLACE REC_CLONE REC_LOCK REC_UNLOCK
		RETURN
		CURSOR_OPEN CURSOR_CLOSE CURSOR_FETCH
		SELECT INSERT UPDATE DELETE 
		COMMIT ROLLBACK
		LOCK UNLOCK 
		PLAIN THROW TRY CATCH IF ELSEIF ELSE SWITCH CASE OTHERWISE FOREACH 
		FOR WHILE UNTIL MAP GREP REGEXP 
		LOOP CONDITION LOGIC 
		CAST
		NOT AND OR XOR
		EQ NE LT GT LE GE IS_NULL NOT_NULL COALESCE SWITCH LIKE
		ADD SUB MUL DIV DIVI MOD ROUND ABS POWER LOG
		SCONCAT SLENGTH SINDEX SUBSTR SREPEAT STRIM SPAD SPADL LC UC
		COUNT MIN MAX SUM AVG CONCAT EVERY ANY EXISTS
		GB_SETS GB_RLUP GB_CUBE
	) },
	'standard_routine_context' => { map { ($_ => 1) } qw(
		CONN_CX CURSOR_CX
	) },
	'standard_routine_arg' => { map { ($_ => 1) } qw(
		RECURSIVE LINK_BP SOURCE_LINK_BP DEST_LINK_BP 
		LOGIN_NAME LOGIN_PASS
		RETURN_VALUE
		SELECT_DEFN INSERT_DEFN UPDATE_DEFN DELETE_DEFN
		CAST_TARGET CAST_OPERAND
		FACTOR FACTORS LHS RHS ARG TERMS
		LOOK_IN CASES DEFAULT LOOK_FOR FIXED_LEFT FIXED_RIGHT
		START REMOVE DIVIDEND DIVISOR PLACES OPERAND RADIX EXPONENT
		SOURCE START_POS STR_LEN REPEAT
	) },
	'simple_scalar_type' => { map { ($_ => 1) } qw(
		NUM_INT NUM_EXA NUM_APR STR_BIT STR_CHAR BOOLEAN 
		DATM_FULL DATM_DATE DATM_TIME INTRVL_YM INTRVL_DT 
	) },
	'char_enc_type' => { map { ($_ => 1) } qw(
		UTF8 UTF16 UTF32 ASCII ANSEL EBCDIC
	) },
	'calendar' => { map { ($_ => 1) } qw(
		ABS GRE JUL CHI HEB ISL JPN
	) },
	'privilege_type' => { map { ($_ => 1) } qw(
		ALL SELECT DELETE INSERT UPDATE CONNECT EXECUTE CREATE ALTER DROP 
	) },
	'table_index_type' => { map { ($_ => 1) } qw(
		ATOMIC FULLTEXT UNIQUE FOREIGN UFOREIGN
	) },
	'view_type' => { map { ($_ => 1) } qw(
		ALIAS JOINED GROUPED COMPOUND INSERT UPDATE DELETE
	) },
	'compound_operator' => { map { ($_ => 1) } qw(
		UNION DIFFERENCE INTERSECTION EXCLUSION
	) },
	'join_operator' => { map { ($_ => 1) } qw(
		CROSS INNER LEFT RIGHT FULL
	) },
	'view_part' => { map { ($_ => 1) } qw(
		RESULT SET FROM WHERE GROUP HAVING WINDOW ORDER MAXR SKIPR
	) },
	'routine_type' => { map { ($_ => 1) } qw(
		PACKAGE TRIGGER PROCEDURE FUNCTION BLOCK
	) },
	'basic_trigger_event' => { map { ($_ => 1) } qw(
		BEFR_INS AFTR_INS INST_INS 
		BEFR_UPD AFTR_UPD INST_UPD 
		BEFR_DEL AFTR_DEL INST_DEL
	) },
	'user_type' => { map { ($_ => 1) } qw(
		ROOT SCHEMA_OWNER DATA_EDITOR ANONYMOUS
	) },
);

# Names of hash keys in %NODE_TYPES elements:
my $TPI_AT_SEQUENCE = 'at_sequence'; # Array of all 'attribute' names in canon order
my $TPI_PP_PSEUDONODE = 'pp_pseudonode'; # If set, Nodes of this type have a hard-coded pseudo-parent
my $TPI_PP_NREF     = 'pp_nref'; # An array ref whose values are enums and each matches a single %NODE_TYPES key.
my $TPI_AT_LITERALS = 'at_literals'; # Hash - Keys are attr names a Node can have which have literal values
	# Values are enums and say what literal data type the attribute has, like int or bool or str
my $TPI_AT_ENUMS    = 'at_enums'; # Hash - Keys are attr names a Node can have which are enumerated values
	# Values are enums and match a %ENUMERATED_TYPES key
my $TPI_AT_NREFS    = 'at_nrefs'; # Hash - Keys are attr names a Node can have which are Node Ref/Id values
	# Values are array refs whose values are enums and each matches a single %NODE_TYPES key, 
	# but an empty array matches all Node types.
my $TPI_SI_ATNM     = 'si_atnm'; # The surrogate identifier, distinct under primary parent and always-mandatory
	# Is an array of 4 cstr elements, one for id|lit|enum|nref; 1 elem is valued, other 3 are undef
	# External code can opt specify a Node by the value of this attr-name rather of its Id
	# If set_attributes() is given a non-Hash value, it will resolve to setting either this 'SI' 
	# attribute or the Node's 'id' attribute depending on whether it looks like an 'id' attribute.
my $TPI_WR_ATNM     = 'wr_atnm'; # A wrapper attribute
my $TPI_MA_ATNMS    = 'ma_atnms'; # Array of always-mandatory ('MA') attributes
	# The array contains 3 elements, one each for lit, enum, nref; each inner elem is a MA boolean
my $TPI_MUTEX_ATGPS = 'mutex_atgps'; # Array of groups of mutually exclusive attributes
	# Each array element is an array ref with 5 elements: 1. mutex-name (cstr); 2. lit members (ary); 
	# 3. enum members (ary); 4. nref members (ary); 5. mandatory-flag (boolean).
my $TPI_LOCAL_ATDPS = 'local_atdps'; # Array of attributes depended-on by other attrs in same Nodes
	# Each array element is an array ref with 4 elements: 
	# 1. undef or depended on lit attr name (cstr); 2. undef or depended on enum attr name (cstr); 
	# 3. undef or depended on nref attr name (cstr); 4. an array ref of N elements where 
	# each element is an array ref with 5 elements: 
		# 1. an array ref with 0..N elements that are names of dependent lit attrs; 
		# 2. an array ref with 0..N elements that are names of dependent enum attrs; 
		# 3. an array ref with 0..N elements that are names of dependent nref attrs; 
		# 4. an array ref with 0..N elements that are depended-on values, one of which must 
		# be matched, if depended-on attr is an enum, or which is empty otherwise;
		# 5. mandatory-flag (boolean).
my $TPI_ANCES_ATCORS = 'ances_atcors'; # Hash of Arrays of steps to follow when linking Nodes using SI
	# Each hash key is a Node-ref attr name, each hash value is an array of steps.
my $TPI_REMOTE_ADDR = 'remote_addr'; # Array of ancestor Node type names under which this Node can be remotely addressed
my $TPI_CHILD_QUANTS = 'child_quants'; # Array of quantity limits for child Nodes
	# Each array element is an array ref with 3 elements: 
	# 1. child-node-type (cstr); 2. range-min (uint); 3. range-max (uint)
my $TPI_MUDI_ATGPS  = 'mudi_atgps'; # Array of groups of mutually distinct attributes
	# Each array element is an array ref with 2 elements: 1. mudi-name (cstr); 
	# 2. an array ref of N elements where each element is an array ref with 4 elements:
		# 1. child-node-type (cstr);
		# 2. an array ref with 0..N elements that are names of lit child-node-attrs; 
		# 3. an array ref with 0..N elements that are names of enum child-node-attrs; 
		# 4. an array ref with 0..N elements that are names of nref child-node-attrs.

# Names of special "pseudo-Nodes" that are used in an XML version of this structure.
my $SQLRT_L1_ROOT_PSND = 'root';
my $SQLRT_L2_ELEM_PSND = 'elements';
my $SQLRT_L2_BLPR_PSND = 'blueprints';
my $SQLRT_L2_TOOL_PSND = 'tools';
my $SQLRT_L2_SITE_PSND = 'sites';
my $SQLRT_L2_CIRC_PSND = 'circumventions';
my @L2_PSEUDONODE_LIST = ($SQLRT_L2_ELEM_PSND, $SQLRT_L2_BLPR_PSND, 
	$SQLRT_L2_TOOL_PSND, $SQLRT_L2_SITE_PSND, $SQLRT_L2_CIRC_PSND);
# This hash is used like the subsequent %NODE_TYPES for specific purposes.
my %PSEUDONODE_TYPES = (
	$SQLRT_L1_ROOT_PSND => {
	},
	$SQLRT_L2_ELEM_PSND => {
	},
	$SQLRT_L2_BLPR_PSND => {
		$TPI_CHILD_QUANTS => [
			['application',1,undef],
		],
	},
	$SQLRT_L2_TOOL_PSND => {
	},
	$SQLRT_L2_SITE_PSND => {
		$TPI_CHILD_QUANTS => [
			['application_instance',1,undef],
		],
	},
	$SQLRT_L2_CIRC_PSND => {
	},
);

# These are used with $TPI_ANCES_ATCORS:
my $S = '.';
my $P = '..';
my $R = '...';
my $C = '....';
# These are the allowed Node types, with their allowed attributes and their 
# allowed child Node types.  They are used for method input checking and 
# other related tasks.
my %NODE_TYPES = (
	'scalar_data_type' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name base_type num_precision num_scale num_octets num_unsigned 
			max_octets max_chars store_fixed char_enc trim_white uc_latin lc_latin 
			pad_char trim_pad calendar with_zone range_min range_max 
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_ELEM_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'num_precision' => 'uint',
			'num_scale' => 'uint',
			'num_octets' => 'uint',
			'num_unsigned' => 'bool',
			'max_octets' => 'uint',
			'max_chars' => 'uint',
			'store_fixed' => 'bool',
			'trim_white' => 'bool',
			'uc_latin' => 'bool',
			'lc_latin' => 'bool',
			'pad_char' => 'cstr',
			'trim_pad' => 'bool',
			'with_zone' => 'sint',
			'range_min' => 'misc',
			'range_max' => 'misc',
		},
		$TPI_AT_ENUMS => {
			'base_type' => 'simple_scalar_type',
			'char_enc' => 'char_enc_type',
			'calendar' => 'calendar',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],['base_type'],[]],
		$TPI_MUTEX_ATGPS => [
			['num_size',['num_precision','num_octets'],[],[],0],
		],
		$TPI_LOCAL_ATDPS => [
			[undef,'base_type',undef,[
				[['num_precision'],[],[],['NUM_INT','NUM_EXA','NUM_APR'],0],
				[['num_scale'],[],[],['NUM_EXA','NUM_APR'],0],
				[['num_octets'],[],[],['NUM_INT','NUM_APR'],0],
				[['num_unsigned'],[],[],['NUM_INT','NUM_EXA','NUM_APR'],0],
				[['max_octets'],[],[],['STR_BIT'],1],
				[['max_chars'],[],[],['STR_CHAR'],1],
				[[],['char_enc'],[],['STR_CHAR'],1],
				[['trim_white'],[],[],['STR_CHAR'],0],
				[['uc_latin','lc_latin'],[],[],['STR_CHAR'],0],
				[['pad_char'],[],[],['STR_CHAR'],0],
				[['trim_pad'],[],[],['STR_CHAR'],0],
				[[],['calendar'],[],['DATM_FULL','DATM_DATE'],1],
				[['with_zone'],[],[],['DATM_FULL','DATM_DATE','DATM_TIME'],0],
			]],
			['num_precision',undef,undef,[
				[['num_scale'],[],[],[],0],
			]],
		],
	},
	'scalar_data_type_opt' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_value 
		)],
		$TPI_PP_NREF => ['scalar_data_type'],
		$TPI_AT_LITERALS => {
			'si_value' => 'misc',
		},
		$TPI_SI_ATNM => [undef,'si_value',undef,undef],
	},
	'row_data_type' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_ELEM_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_CHILD_QUANTS => [
			['row_data_type_field',1,undef],
		],
	},
	'row_data_type_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name scalar_data_type
		)],
		$TPI_PP_NREF => ['row_data_type'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'scalar_data_type' => ['scalar_data_type'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['scalar_data_type']],
	},
	'catalog' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name single_schema
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_BLPR_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'single_schema' => 'bool',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
	},
	'application' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name 
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_BLPR_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
	},
	'owner' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name 
		)],
		$TPI_PP_NREF => ['catalog'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
	},
	'catalog_link' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name target
		)],
		$TPI_PP_NREF => ['catalog','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'target' => ['catalog'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['target']],
	},
	'schema' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name owner 
		)],
		$TPI_PP_NREF => ['catalog'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'owner' => ['owner'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['owner']],
	},
	'role' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name
		)],
		$TPI_PP_NREF => ['catalog'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
	},
	'privilege_on' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_priv_on
		)],
		$TPI_PP_NREF => ['role'],
		$TPI_AT_NREFS => {
			'si_priv_on' => ['schema','scalar_domain','row_domain','sequence','table','view','routine'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_priv_on'],
	},
	'privilege_for' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_priv_type
		)],
		$TPI_PP_NREF => ['privilege_on'],
		$TPI_AT_ENUMS => {
			'si_priv_type' => 'privilege_type',
		},
		$TPI_SI_ATNM => [undef,undef,'si_priv_type',undef],
	},
	'scalar_domain' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name data_type
		)],
		$TPI_PP_NREF => ['schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'data_type' => ['scalar_data_type'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['data_type']],
		$TPI_REMOTE_ADDR => ['catalog'],
	},
	'row_domain' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name data_type
		)],
		$TPI_PP_NREF => ['schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'data_type' => ['row_data_type'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'data_type',
		$TPI_MA_ATNMS => [[],[],['data_type']],
		$TPI_REMOTE_ADDR => ['catalog'],
	},
	'sequence' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name increment min_val max_val start_val cycle order 
		)],
		$TPI_PP_NREF => ['schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'increment' => 'sint',
			'min_val' => 'sint',
			'max_val' => 'sint',
			'start_val' => 'sint',
			'cycle' => 'bool',
			'order' => 'bool',
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_REMOTE_ADDR => ['catalog'],
	},
	'table' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name row_data_type
		)],
		$TPI_PP_NREF => ['schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'row_data_type' => ['row_data_type','row_domain'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'row_data_type',
		$TPI_MA_ATNMS => [[],[],['row_data_type']],
		$TPI_REMOTE_ADDR => ['catalog'],
	},
	'table_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_row_field mandatory default_val auto_inc default_seq 
		)],
		$TPI_PP_NREF => ['table'],
		$TPI_AT_LITERALS => {
			'mandatory' => 'bool',
			'default_val' => 'misc',
			'auto_inc' => 'bool',
		},
		$TPI_AT_NREFS => {
			'si_row_field' => ['row_data_type_field'],
			'default_seq' => ['sequence'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_row_field'],
		$TPI_MUTEX_ATGPS => [
			['default',['default_val'],[],['default_seq'],0],
		],
		$TPI_ANCES_ATCORS => {
			'si_row_field' => [$S,$P],
		},
	},
	'table_index' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name index_type f_table 
		)],
		$TPI_PP_NREF => ['table'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_ENUMS => {
			'index_type' => 'table_index_type',
		},
		$TPI_AT_NREFS => {
			'f_table' => ['table'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],['index_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'index_type',undef,[
				[[],[],['f_table'],['FOREIGN','UFOREIGN'],1],
			]],
		],
		$TPI_CHILD_QUANTS => [
			['table_index_field',1,undef],
		],
		$TPI_MUDI_ATGPS => [
			['ak_f_table_field',[
				['table_index_field',[],[],['f_field']],
			]],
		],
	},
	'table_index_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_field f_field 
		)],
		$TPI_PP_NREF => ['table_index'],
		$TPI_AT_NREFS => {
			'si_field' => ['row_data_type_field'],
			'f_field' => ['row_data_type_field'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_field'],
		$TPI_ANCES_ATCORS => {
			'si_field' => [$S,$P,$P],
			'f_field' => [$S,$P,'f_table'],
		},
	},
	'view' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name view_type row_data_type recursive compound_op 
			distinct_rows may_write set_p_routine_item ins_p_routine_item
		)],
		$TPI_PP_NREF => ['view','routine','schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'recursive' => 'bool',
			'distinct_rows' => 'bool',
			'may_write' => 'bool',
		},
		$TPI_AT_ENUMS => {
			'view_type' => 'view_type',
			'compound_op' => 'compound_operator',
		},
		$TPI_AT_NREFS => {
			'row_data_type' => ['row_data_type','row_domain'],
			'set_p_routine_item' => ['routine_arg','routine_var'],
			'ins_p_routine_item' => ['routine_arg','routine_var'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'row_data_type',
		$TPI_MA_ATNMS => [[],['view_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'view_type',undef,[
				[[],[],['row_data_type'],['ALIAS','JOINED','GROUPED','COMPOUND','INSERT'],1],
				[['recursive'],[],[],['JOINED','GROUPED','COMPOUND'],0],
				[[],['compound_op'],[],['COMPOUND'],1],
				[['distinct_rows'],[],[],['JOINED','GROUPED','COMPOUND'],0],
				[['may_write'],[],[],['ALIAS','JOINED','GROUPED','COMPOUND'],0],
				[[],[],['set_p_routine_item'],['ALIAS','JOINED','GROUPED','COMPOUND'],0],
				[[],[],['ins_p_routine_item'],['INSERT'],1],
			]],
		],
		$TPI_REMOTE_ADDR => ['catalog'],
		$TPI_MUDI_ATGPS => [
			['ak_join',[
				['view_join',[],[],['lhs_src','rhs_src']],
			]],
			['ak_join_limit_one',[
				['view_join',[],[],['rhs_src']],
			]],
			['ak_expr_set_result_field',[
				['view_expr',[],[],['set_result_field']],
			]],
			['ak_expr_set_src_field',[
				['view_expr',[],[],['set_src_field']],
			]],
			['ak_expr_call_src_arg',[
				['view_expr',[],[],['call_src_arg']],
			]],
		],
	},
	'view_arg' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name cont_type scalar_data_type row_data_type 
		)],
		$TPI_PP_NREF => ['view'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_ENUMS => {
			'cont_type' => 'container_type',
		},
		$TPI_AT_NREFS => {
			'scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'row_data_type' => ['row_data_type','row_domain'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'row_data_type',
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_MUTEX_ATGPS => [
			['data_type',[],[],['scalar_data_type','row_data_type'],1],
		],
		$TPI_LOCAL_ATDPS => [
			[undef,'cont_type',undef,[
				[[],[],['scalar_data_type'],['SCALAR','SC_ARY'],1],
				[[],[],['row_data_type'],['ROW','RW_ARY'],1],
			]],
		],
	},
	'view_src' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name match catalog_link may_write
		)],
		$TPI_PP_NREF => ['view'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'may_write' => 'bool',
		},
		$TPI_AT_NREFS => {
			'match' => ['table','view','view_arg','routine_arg','routine_var'],
			'catalog_link' => ['catalog_link'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
	},
	'view_src_arg' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_match_view_arg
		)],
		$TPI_PP_NREF => ['view_src'],
		$TPI_AT_NREFS => {
			'si_match_view_arg' => ['view_arg'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_match_view_arg'],
	},
	'view_src_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_match_field
		)],
		$TPI_PP_NREF => ['view_src'],
		$TPI_AT_NREFS => {
			'si_match_field' => ['row_data_type_field'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_match_field'],
		$TPI_ANCES_ATCORS => {
			'si_match_field' => [$S,$P,'match'],
		},
	},
	'view_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_row_field src_field 
		)],
		$TPI_PP_NREF => ['view'],
		$TPI_AT_NREFS => {
			'si_row_field' => ['row_data_type_field'],
			'src_field' => ['view_src_field'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_row_field'],
		$TPI_ANCES_ATCORS => {
			'si_row_field' => [$S,$P],
			'src_field' => [$S,$P,$C],
		},
	},
	'view_join' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp lhs_src rhs_src join_op 
		)],
		$TPI_PP_NREF => ['view'],
		$TPI_AT_ENUMS => {
			'join_op' => 'join_operator',
		},
		$TPI_AT_NREFS => {
			'lhs_src' => ['view_src'],
			'rhs_src' => ['view_src'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],['join_op'],['lhs_src','rhs_src']],
		$TPI_CHILD_QUANTS => [
			['view_join_field',1,undef],
		],
		$TPI_MUDI_ATGPS => [
			['ak_lhs_field',[
				['view_join_field',[],[],['lhs_src_field']],
			]],
			['ak_rhs_field',[
				['view_join_field',[],[],['rhs_src_field']],
			]],
		],
	},
	'view_join_field' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp lhs_src_field rhs_src_field 
		)],
		$TPI_PP_NREF => ['view_join'],
		$TPI_AT_NREFS => {
			'lhs_src_field' => ['view_src_field'],
			'rhs_src_field' => ['view_src_field'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],[],['lhs_src_field','rhs_src_field']],
		$TPI_ANCES_ATCORS => {
			'lhs_src_field' => [$S,$P,'lhs_src'],
			'rhs_src_field' => [$S,$P,'rhs_src'],
		},
	},
	'view_compound_elem' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp operand
		)],
		$TPI_PP_NREF => ['view'],
		$TPI_AT_NREFS => {
			'operand' => ['view_src'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],[],['operand']],
	},
	'view_expr' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp view_part set_result_field set_src_field call_src_arg 
			call_view_arg call_sroutine_cxt call_sroutine_arg call_uroutine_cxt call_uroutine_arg 
			cont_type valf_literal scalar_data_type valf_src_field valf_result_field 
			valf_p_view_arg valf_p_routine_item valf_seq_next 
			valf_call_view valf_call_sroutine valf_call_uroutine catalog_link
		)],
		$TPI_PP_NREF => ['view_expr','view'],
		$TPI_AT_LITERALS => {
			'valf_literal' => 'misc',
		},
		$TPI_AT_ENUMS => {
			'view_part' => 'view_part',
			'call_sroutine_cxt' => 'standard_routine_context',
			'call_sroutine_arg' => 'standard_routine_arg',
			'cont_type' => 'container_type',
			'valf_call_sroutine' => 'standard_routine',
		},
		$TPI_AT_NREFS => {
			'set_result_field' => ['row_data_type_field'],
			'set_src_field' => ['view_src_field'],
			'call_src_arg' => ['view_src_arg'],
			'call_view_arg' => ['view_arg'],
			'call_uroutine_cxt' => ['routine_context'],
			'call_uroutine_arg' => ['routine_arg'],
			'scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'valf_src_field' => ['view_src_field'],
			'valf_result_field' => ['row_data_type_field'],
			'valf_p_view_arg' => ['view_arg'],
			'valf_p_routine_item' => ['routine_context','routine_arg','routine_var'],
			'valf_seq_next' => ['sequence'],
			'valf_call_view' => ['view'],
			'valf_call_uroutine' => ['routine'],
			'catalog_link' => ['catalog_link'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'view_part',undef,[
				[[],[],['set_result_field'],['RESULT'],1],
				[[],[],['set_src_field'],['SET'],1],
				[[],[],['call_src_arg'],['FROM'],1],
			]],
			['valf_literal',undef,undef,[
				[[],[],['scalar_data_type'],[],1],
			]],
			[undef,undef,'valf_call_uroutine',[
				[[],[],['catalog_link'],[],0],
			]],
		],
		$TPI_ANCES_ATCORS => {
			'set_result_field' => [$S,$R,$P],
			'set_src_field' => [$S,$R,$P,$C],
			'call_src_arg' => [$S,$R,$P,$C],
			'call_view_arg' => [$S,$P,'valf_call_view'],
			'call_uroutine_cxt' => [$S,$P,'valf_call_uroutine'],
			'call_uroutine_arg' => [$S,$P,'valf_call_uroutine'],
			'valf_src_field' => [$S,$R,$P,$C],
			'valf_result_field' => [$S,$R,$P],
		},
		$TPI_MUDI_ATGPS => [
			['ak_view_arg',[
				['view_expr',[],[],['call_view_arg']],
			]],
			['ak_sroutine_arg',[
				['view_expr',[],['call_sroutine_cxt'],[]],
				['view_expr',[],['call_sroutine_arg'],[]],
			]],
			['ak_uroutine_arg',[
				['view_expr',[],[],['call_uroutine_cxt']],
				['view_expr',[],[],['call_uroutine_arg']],
			]],
		],
	},
	'routine' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name routine_type return_cont_type 
			return_scalar_data_type return_row_data_type 
			trigger_on trigger_event trigger_per_stmt
		)],
		$TPI_PP_NREF => ['routine','schema','application'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'trigger_per_stmt' => 'bool',
		},
		$TPI_AT_ENUMS => {
			'routine_type' => 'routine_type',
			'return_cont_type' => 'container_type',
			'trigger_event' => 'basic_trigger_event',
		},
		$TPI_AT_NREFS => {
			'return_scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'return_row_data_type' => ['row_data_type','row_domain'],
			'trigger_on' => ['table','view'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],['routine_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'routine_type',undef,[
				[[],['return_cont_type'],[],['FUNCTION'],1],
				[[],[],['trigger_on'],['TRIGGER'],1],
				[[],['trigger_event'],[],['TRIGGER'],1],
				[['trigger_per_stmt'],[],[],['TRIGGER'],1],
			]],
			[undef,'return_cont_type',undef,[
				[[],[],['return_scalar_data_type'],['SCALAR','SC_ARY'],1],
				[[],[],['return_row_data_type'],['ROW','RW_ARY'],1],
			]],
		],
		$TPI_REMOTE_ADDR => ['catalog'],
		$TPI_CHILD_QUANTS => [
			['routine_context',0,1],
			['routine_stmt',1,undef],
		],
	},
	'routine_context' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name cont_type conn_link curs_view 
		)],
		$TPI_PP_NREF => ['routine'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_ENUMS => {
			'cont_type' => 'container_type',
		},
		$TPI_AT_NREFS => {
			'conn_link' => ['catalog_link'],
			'curs_view' => ['view'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_MUTEX_ATGPS => [
			['context',[],[],['conn_link','curs_view'],1],
		],
		$TPI_LOCAL_ATDPS => [
			[undef,'cont_type',undef,[
				[[],[],['conn_link'],['CONN'],1],
				[[],[],['curs_view'],['CURSOR'],1],
			]],
		],
	},
	'routine_arg' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name cont_type scalar_data_type row_data_type
			conn_link curs_view 
		)],
		$TPI_PP_NREF => ['routine'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_ENUMS => {
			'cont_type' => 'container_type',
		},
		$TPI_AT_NREFS => {
			'scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'row_data_type' => ['row_data_type','row_domain'],
			'conn_link' => ['catalog_link'],
			'curs_view' => ['view'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'row_data_type',
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'cont_type',undef,[
				[[],[],['scalar_data_type'],['SCALAR','SC_ARY'],1],
				[[],[],['row_data_type'],['ROW','RW_ARY'],1],
				[[],[],['conn_link'],['CONN'],1],
				[[],[],['curs_view'],['CURSOR'],1],
			]],
		],
	},
	'routine_var' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name cont_type scalar_data_type row_data_type
			init_lit_val is_constant conn_link curs_view curs_for_update 
		)],
		$TPI_PP_NREF => ['routine'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'init_lit_val' => 'misc',
			'is_constant' => 'bool',
			'curs_for_update' => 'bool',
		},
		$TPI_AT_ENUMS => {
			'cont_type' => 'container_type',
		},
		$TPI_AT_NREFS => {
			'scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'row_data_type' => ['row_data_type','row_domain'],
			'conn_link' => ['catalog_link'],
			'curs_view' => ['view'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_WR_ATNM => 'row_data_type',
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'cont_type',undef,[
				[[],[],['scalar_data_type'],['SCALAR','SC_ARY'],1],
				[[],[],['row_data_type'],['ROW','RW_ARY'],1],
				[['init_lit_val'],[],[],['SCALAR'],0],
				[['is_constant'],[],[],['SCALAR'],0],
				[[],[],['conn_link'],['CONN'],1],
				[[],[],['curs_view'],['CURSOR'],1],
				[['curs_for_update'],[],[],['CURSOR'],0],
			]],
		],
	},
	'routine_stmt' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp block_routine assign_dest call_sroutine call_uroutine catalog_link 
		)],
		$TPI_PP_NREF => ['routine'],
		$TPI_AT_ENUMS => {
			'call_sroutine' => 'standard_routine',
		},
		$TPI_AT_NREFS => {
			'block_routine' => ['routine'],
			'assign_dest' => ['routine_context','routine_arg','routine_var'],
			'call_uroutine' => ['routine'],
			'catalog_link' => ['catalog_link'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MUTEX_ATGPS => [
			['stmt_type',[],['call_sroutine'],['block_routine','assign_dest','call_uroutine'],1],
		],
		$TPI_LOCAL_ATDPS => [
			[undef,undef,'call_uroutine',[
				[[],[],['catalog_link'],[],0],
			]],
		],
		$TPI_MUDI_ATGPS => [
			['ak_sroutine_arg',[
				['routine_expr',[],['call_sroutine_cxt'],[]],
				['routine_expr',[],['call_sroutine_arg'],[]],
			]],
			['ak_uroutine_arg',[
				['routine_expr',[],[],['call_uroutine_cxt']],
				['routine_expr',[],[],['call_uroutine_arg']],
			]],
		],
	},
	'routine_expr' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp call_sroutine_cxt call_sroutine_arg call_uroutine_cxt call_uroutine_arg 
			cont_type valf_literal scalar_data_type valf_p_routine_item valf_seq_next 
			valf_call_sroutine valf_call_uroutine catalog_link act_on
		)],
		$TPI_PP_NREF => ['routine_expr','routine_stmt'],
		$TPI_AT_LITERALS => {
			'valf_literal' => 'misc',
		},
		$TPI_AT_ENUMS => {
			'call_sroutine_cxt' => 'standard_routine_context',
			'call_sroutine_arg' => 'standard_routine_arg',
			'cont_type' => 'container_type',
			'valf_call_sroutine' => 'standard_routine',
		},
		$TPI_AT_NREFS => {
			'call_uroutine_cxt' => ['routine_context'],
			'call_uroutine_arg' => ['routine_arg'],
			'scalar_data_type' => ['scalar_data_type','scalar_domain'],
			'valf_p_routine_item' => ['routine_context','routine_arg','routine_var'],
			'valf_seq_next' => ['sequence'],
			'valf_call_uroutine' => ['routine'],
			'catalog_link' => ['catalog_link'],
			'act_on' => ['catalog_link','schema','scalar_domain','row_domain',
				'sequence','table','view','routine','user'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],['cont_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'cont_type',undef,[
				[[],[],['act_on'],['SRT_NODE'],1],
			]],
			['valf_literal',undef,undef,[
				[[],[],['scalar_data_type'],[],1],
			]],
			[undef,undef,'valf_call_uroutine',[
				[[],[],['catalog_link'],[],0],
			]],
		],
		$TPI_ANCES_ATCORS => {
			'call_uroutine_cxt' => [$S,$P,'valf_call_uroutine'],
			'call_uroutine_arg' => [$S,$P,'valf_call_uroutine'],
		},
		$TPI_MUDI_ATGPS => [
			['ak_sroutine_arg',[
				['routine_expr',[],['call_sroutine_cxt'],[]],
				['routine_expr',[],['call_sroutine_arg'],[]],
			]],
			['ak_uroutine_arg',[
				['routine_expr',[],[],['call_uroutine_cxt']],
				['routine_expr',[],[],['call_uroutine_arg']],
			]],
		],
	},
	'data_storage_product' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name product_code is_memory_based is_file_based is_local_proc is_network_svc
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_TOOL_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'product_code' => 'cstr',
			'is_memory_based' => 'bool',
			'is_file_based' => 'bool',
			'is_local_proc' => 'bool',
			'is_network_svc' => 'bool',
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [['si_name','product_code'],[],[]],
		$TPI_MUTEX_ATGPS => [
			['type',['is_memory_based','is_file_based','is_local_proc','is_network_svc'],[],[],1],
		],
	},
	'data_link_product' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name product_code is_proxy
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_TOOL_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'product_code' => 'cstr',
			'is_proxy' => 'bool',
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [['si_name','product_code'],[],[]],
	},
	'catalog_instance' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name blueprint product file_path server_ip server_domain server_port
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_SITE_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'file_path' => 'cstr',
			'server_ip' => 'cstr',
			'server_domain' => 'cstr',
			'server_port' => 'uint',
		},
		$TPI_AT_NREFS => {
			'blueprint' => ['catalog'],
			'product' => ['data_storage_product'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['blueprint','product']],
		$TPI_MUDI_ATGPS => [
			['ak_cat_link_inst',[
				['catalog_link_instance',[],[],['blueprint']],
			]],
		],
	},
	'catalog_instance_opt' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_key value 
		)],
		$TPI_PP_NREF => ['catalog_instance'],
		$TPI_AT_LITERALS => {
			'si_key' => 'cstr',
			'value' => 'misc',
		},
		$TPI_SI_ATNM => [undef,'si_key',undef,undef],
		$TPI_MA_ATNMS => [['value'],[],[]],
	},
	'application_instance' => {
		$TPI_AT_SEQUENCE => [qw( 
			id si_name blueprint 
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_SITE_PSND,
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'blueprint' => ['application'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],[],['blueprint']],
		$TPI_MUDI_ATGPS => [
			['ak_cat_link_inst',[
				['catalog_link_instance',[],[],['blueprint']],
			]],
		],
	},
	'catalog_link_instance' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp blueprint product target local_dsn login_name login_pass
		)],
		$TPI_PP_NREF => ['catalog_link_instance','catalog_instance','application_instance'],
		$TPI_AT_LITERALS => {
			'local_dsn' => 'cstr',
			'login_name' => 'cstr',
			'login_pass' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'blueprint' => ['catalog_link'],
			'product' => ['data_link_product'],
			'target' => ['catalog_instance'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],[],['blueprint','product','target']],
		$TPI_ANCES_ATCORS => {
			'blueprint' => [$S,$P,'blueprint'],
		},
		$TPI_CHILD_QUANTS => [
			['catalog_link_instance',0,1],
		],
	},
	'catalog_link_instance_opt' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_key value 
		)],
		$TPI_PP_NREF => ['catalog_link_instance'],
		$TPI_AT_LITERALS => {
			'si_key' => 'cstr',
			'value' => 'misc',
		},
		$TPI_SI_ATNM => [undef,'si_key',undef,undef],
		$TPI_MA_ATNMS => [['value'],[],[]],
	},
	'user' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_name user_type match_owner password default_schema 
		)],
		$TPI_PP_NREF => ['catalog_instance'],
		$TPI_AT_LITERALS => {
			'si_name' => 'cstr',
			'password' => 'cstr',
		},
		$TPI_AT_ENUMS => {
			'user_type' => 'user_type',
		},
		$TPI_AT_NREFS => {
			'match_owner' => ['owner'],
			'default_schema' => ['schema'],
		},
		$TPI_SI_ATNM => [undef,'si_name',undef,undef],
		$TPI_MA_ATNMS => [[],['user_type'],[]],
		$TPI_LOCAL_ATDPS => [
			[undef,'user_type',undef,[
				[[],[],['match_owner'],['SCHEMA_OWNER'],1],
				[['password'],[],[],['ROOT','SCHEMA_OWNER','DATA_EDITOR'],1],
			]],
		],
		$TPI_ANCES_ATCORS => {
			'match_owner' => [$S,$P,'blueprint'],
			'default_schema' => [$S,$P,'blueprint'],
		},
	},
	'user_role' => {
		$TPI_AT_SEQUENCE => [qw( 
			id pp si_role 
		)],
		$TPI_PP_NREF => ['user'],
		$TPI_AT_NREFS => {
			'si_role' => ['role'],
		},
		$TPI_SI_ATNM => [undef,undef,undef,'si_role'],
		$TPI_ANCES_ATCORS => {
			'si_role' => [$S,$P,$P,'blueprint'],
		},
	},
	'sql_fragment' => {
		$TPI_AT_SEQUENCE => [qw( 
			id attach_to product is_inside is_before is_after fragment
		)],
		$TPI_PP_PSEUDONODE => $SQLRT_L2_CIRC_PSND,
		$TPI_AT_LITERALS => {
			'is_inside' => 'bool',
			'is_before' => 'bool',
			'is_after' => 'bool',
			'fragment' => 'cstr',
		},
		$TPI_AT_NREFS => {
			'attach_to' => [],
			'product' => ['data_storage_product'],
		},
		$TPI_SI_ATNM => ['id',undef,undef,undef],
		$TPI_MA_ATNMS => [[],['attach_to'],[]],
		$TPI_MUTEX_ATGPS => [
			['is_where',['is_inside','is_before','is_after'],[],[],0],
		],
	},
);

# This structure is used as a speed-efficiency measure.  It creates a reverse-index of sorts 
# out of each SI_ATNM that resembles and is used as a simpler version of a MUDI_ATGP.
# It makes the distinct constraint property of surrogate node ids faster to enforce.
# This structure's main hash has a key for each Node type or pseudo-Node type that can have primary-child Nodes; 
# the value for each main hash key is a hash whose keys are the names of Node types that can be primary-children 
# of the aforementioned primary-parent types, and whose values are the SI attribute name of the primary-child Node types.
# Any Node types that can not have primary-child Nodes do not appear in the main structure hash.
my %TYPE_CHILD_SI_ATNMS = ();
while( my ($_node_type, $_type_info) = each %NODE_TYPES ) {
	my $si_atnm = $_type_info->{$TPI_SI_ATNM};
	if( my $pp_psnd = $_type_info->{$TPI_PP_PSEUDONODE} ) {
		$TYPE_CHILD_SI_ATNMS{$pp_psnd} ||= {};
		$TYPE_CHILD_SI_ATNMS{$pp_psnd}->{$_node_type} = $si_atnm;
	} else { # no pseudonode, so must be PP attrs
		foreach my $pp_node_type (@{$_type_info->{$TPI_PP_NREF}}) {
			$TYPE_CHILD_SI_ATNMS{$pp_node_type} ||= {};
			$TYPE_CHILD_SI_ATNMS{$pp_node_type}->{$_node_type} = $si_atnm;
		}
	}
}

# These special hash keys are used by the get_all_properties[/*]() methods, 
# and/or by the build*node*() functions and methods for RAD:
my $NAMED_NODE_TYPE = 'NODE_TYPE'; # str - what type of Node we are
my $NAMED_ATTRS     = 'ATTRS'; # hash - all attributes, including 'id' (and 'pp' if appropriate)
my $NAMED_CHILDREN  = 'CHILDREN'; # array - list of primary-child Node descriptors
my $ATTR_ID         = 'id'; # attribute name to use for the node id
my $ATTR_PP         = 'pp'; # attribute name to use for the node's primary parent nref

######################################################################

sub valid_enumerated_types {
	my ($self, $type) = @_;
	$type and return exists( $ENUMERATED_TYPES{$type} );
	return {map { ($_ => 1) } keys %ENUMERATED_TYPES};
}

sub valid_enumerated_type_values {
	my ($self, $type, $value) = @_;
	$type and (exists( $ENUMERATED_TYPES{$type} ) or return);
	$value and return exists( $ENUMERATED_TYPES{$type}->{$value} );
	return {%{$ENUMERATED_TYPES{$type}}};
}

sub valid_node_types {
	my ($self, $type) = @_;
	$type and return exists( $NODE_TYPES{$type} );
	return {map { ($_ => 1) } keys %NODE_TYPES};
}

sub node_types_with_pseudonode_parents {
	my ($self, $type) = @_;
	if( $type ) {
		exists( $NODE_TYPES{$type} ) or return;
		return $NODE_TYPES{$type}->{$TPI_PP_PSEUDONODE};
	}
	return {map { ($_ => $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE}) } 
		grep { $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE} } keys %NODE_TYPES};
}

sub node_types_with_primary_parent_attributes {
	my ($self, $type) = @_;
	if( $type ) {
		exists( $NODE_TYPES{$type} ) or return;
		exists( $NODE_TYPES{$type}->{$TPI_PP_NREF} ) or return;
		return [@{$NODE_TYPES{$type}->{$TPI_PP_NREF}}];
	}
	return {map { ($_ => [@{$NODE_TYPES{$_}->{$TPI_PP_NREF}}]) } 
		grep { $NODE_TYPES{$_}->{$TPI_PP_NREF} } keys %NODE_TYPES};
}

sub valid_node_type_literal_attributes {
	my ($self, $type, $attr) = @_;
	$type and (exists( $NODE_TYPES{$type} ) or return);
	exists( $NODE_TYPES{$type}->{$TPI_AT_LITERALS} ) or return;
	$attr and return $NODE_TYPES{$type}->{$TPI_AT_LITERALS}->{$attr};
	return {%{$NODE_TYPES{$type}->{$TPI_AT_LITERALS}}};
}

sub valid_node_type_enumerated_attributes {
	my ($self, $type, $attr) = @_;
	$type and (exists( $NODE_TYPES{$type} ) or return);
	exists( $NODE_TYPES{$type}->{$TPI_AT_ENUMS} ) or return;
	$attr and return $NODE_TYPES{$type}->{$TPI_AT_ENUMS}->{$attr};
	return {%{$NODE_TYPES{$type}->{$TPI_AT_ENUMS}}};
}

sub valid_node_type_node_ref_attributes {
	my ($self, $type, $attr) = @_;
	$type and (exists( $NODE_TYPES{$type} ) or return);
	exists( $NODE_TYPES{$type}->{$TPI_AT_NREFS} ) or return;
	my $rh = $NODE_TYPES{$type}->{$TPI_AT_NREFS};
	$attr and return $rh->{$attr} ? [@{$rh->{$attr}}] : undef;
	return {map { ($_ => [@{$rh->{$_}}]) } keys %{$rh}};
}

sub valid_node_type_surrogate_id_attributes {
	my ($self, $type) = @_;
	$type and (exists( $NODE_TYPES{$type} ) or return);
	$type and return (grep { $_ } @{$NODE_TYPES{$type}->{$TPI_SI_ATNM}})[0];
	return {map { ($_ => (grep { $_ } @{$NODE_TYPES{$_}->{$TPI_SI_ATNM}})[0]) } keys %NODE_TYPES};
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _serialize_as_perl {
	my ($self, $node, $pad) = @_;
	$pad ||= '';
	my $padc = "$pad\t\t";
	my $node_type = $node->{$NAMED_NODE_TYPE};
	my $attr_seq = $NODE_TYPES{$node_type}->{$TPI_AT_SEQUENCE};
	my $attrs = $node->{$NAMED_ATTRS};
	return join( '', 
		$pad."{\n",
		$pad."\t'".$NAMED_NODE_TYPE."' => '".$node_type."',\n",
		(scalar(keys %{$attrs}) ? (
			$pad."\t'".$NAMED_ATTRS."' => {\n",
			(map { $pad."\t\t'".$_."' => ".(
					ref($attrs->{$_}) eq 'ARRAY' ? 
						"[".join( ',', map { 
								defined($_) ? "'".$self->_s_a_p_esc($_)."'" : "undef"
							} @{$attrs->{$_}} )."]" : 
						"'".$self->_s_a_p_esc($attrs->{$_})."'"
				).",\n" } grep { defined( $attrs->{$_} ) } @{$attr_seq}),
			$pad."\t},\n",
		) : ''),
		(scalar(@{$node->{$NAMED_CHILDREN}}) ? (
			$pad."\t'".$NAMED_CHILDREN."' => [\n",
			(map { $self->_serialize_as_perl( $_,$padc ) } @{$node->{$NAMED_CHILDREN}}),
			$pad."\t],\n",
		) : ''),
		$pad."},\n",
	);
}

sub _s_a_p_esc {
	my ($self, $text) = @_;
	$text =~ s/\\/\\\\/g;
	$text =~ s/'/\\'/g;
	return $text;
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _serialize_as_xml {
	my ($self, $node, $pad) = @_;
	$pad ||= '';
	my $padc = "$pad\t";
	my $node_type = $node->{$NAMED_NODE_TYPE};
	my $attr_seq = $NODE_TYPES{$node_type}->{$TPI_AT_SEQUENCE};
	my $attrs = $node->{$NAMED_ATTRS};
	return join( '', 
		$pad.'<'.$node_type,
		(map { ' '.$_.'="'.(
				ref($attrs->{$_}) eq 'ARRAY' ? 
					"[".join( ',', map { 
							defined($_) ? $self->_s_a_x_esc($_) : ""
						} @{$attrs->{$_}} )."]" : 
					$self->_s_a_x_esc($attrs->{$_})
			).'"' } grep { defined( $attrs->{$_} ) } @{$attr_seq}),
		(scalar(@{$node->{$NAMED_CHILDREN}}) ? (
			'>'."\n",
			(map { $self->_serialize_as_xml( $_,$padc ) } @{$node->{$NAMED_CHILDREN}}),
			$pad.'</'.$node_type.'>'."\n",
		) : ' />'."\n"),
	);
}

sub _s_a_x_esc {
	my ($self, $text) = @_;
	$text =~ s/&/&amp;/g;
	$text =~ s/\"/&quot;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/</&lt;/g;
	return $text;
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
	my ($self, $error_code, $args) = @_;
	# Throws an exception consisting of an object.  A Container property is not 
	# used to store object so things work properly in multi-threaded environment; 
	# an exception is only supposed to affect the thread that calls it.
	ref($args) eq 'HASH' or $args = {};
	if( ref($self) and UNIVERSAL::isa( $self, 'SQL::Routine::Node' ) ) {
		$args->{'NTYPE'} = $self->{$NPROP_NODE_TYPE};
		$args->{'NID'} = $self->{$NPROP_NODE_ID};
		if( $self->{$NPROP_CONTAINER} ) {
			$args->{'SIDCH'} = $self->get_surrogate_id_chain();
		}
	}
	foreach my $arg_key (keys %{$args}) {
		if( ref($args->{$arg_key}) eq 'ARRAY' ) {
			$args->{$arg_key} = 'PERL_ARRAY:['.join(',',map {$_||''} @{$args->{$arg_key}}).']';
		}
	}
	die Locale::KeyedText->new_message( $error_code, $args );
}

######################################################################
# These are convenience wrapper methods.

sub new_container {
	return SQL::Routine::Container->new();
}

sub new_node {
	return SQL::Routine::Node->new( $_[1] );
}

######################################################################

sub build_lonely_node {
	my ($self, $node_type, $attrs) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS};
	}
	my $node = $self->new_node( $node_type );
	$attrs = $self->_build_node_normalize_attrs( $node, $attrs );
	$node->set_attributes( $attrs );
	return $node;
}

sub _build_node_normalize_attrs {
	my ($self, $node, $attrs) = @_;
	if( ref($attrs) eq 'HASH' ) {
		$attrs = {%{$attrs}}; # copy this, to preserve caller environment
	} elsif( defined($attrs) ) {
		if( $attrs =~ m/^\d+$/ and $attrs > 0 ) { # looks like a node id
			$attrs = { $ATTR_ID => $attrs };
		} else { # does not look like node id
			$attrs = { (grep { $_ } @{$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_SI_ATNM}})[0] => $attrs };
		}
	} else {
		$attrs = {};
	}
	return $attrs;
}

sub build_container {
	my ($self, $list, $auto_assert, $auto_ids, $match_surr_ids) = @_;
	my $container = $self->new_container();
	$auto_assert and $container->auto_assert_deferrable_constraints( 1 );
	$auto_ids and $container->auto_set_node_ids( 1 );
	$match_surr_ids and $container->may_match_surrogate_node_ids( 1 );
	$container->build_child_node_trees( $list );
	return $container;
}

######################################################################
######################################################################

package SQL::Routine::Container;
use base qw( SQL::Routine );

######################################################################

sub new {
	my ($class) = @_;
	my $container = bless( {}, ref($class) || $class );
	$container->{$CPROP_AUTO_ASS_DEF_CON} = 0;
	$container->{$CPROP_AUTO_SET_NIDS} = 0;
	$container->{$CPROP_MAY_MATCH_SNIDS} = 0;
	$container->{$CPROP_ALL_NODES} = {};
	$container->{$CPROP_PSEUDONODES} = { map { ($_ => []) } @L2_PSEUDONODE_LIST };
	$container->{$CPROP_NEXT_FREE_NID} = 1;
	$container->{$CPROP_DEF_CON_TESTED} = 1;
	return $container;
}

######################################################################

sub destroy {
	# Since we probably have circular refs, we must explicitly be destroyed.
	my ($container) = @_;
	foreach my $node (values %{$container->{$CPROP_ALL_NODES}}) {
		%{$node} = ();
	}
	%{$container} = ();
}

######################################################################

sub auto_assert_deferrable_constraints {
	my ($container, $new_value) = @_;
	if( defined( $new_value ) ) {
		$container->{$CPROP_AUTO_ASS_DEF_CON} = $new_value;
	}
	return $container->{$CPROP_AUTO_ASS_DEF_CON};
}

######################################################################

sub auto_set_node_ids {
	my ($container, $new_value) = @_;
	if( defined( $new_value ) ) {
		$container->{$CPROP_AUTO_SET_NIDS} = $new_value;
	}
	return $container->{$CPROP_AUTO_SET_NIDS};
}

######################################################################

sub may_match_surrogate_node_ids {
	my ($container, $new_value) = @_;
	if( defined( $new_value ) ) {
		$container->{$CPROP_MAY_MATCH_SNIDS} = $new_value;
	}
	return $container->{$CPROP_MAY_MATCH_SNIDS};
}

######################################################################

sub get_child_nodes {
	my ($container, $node_type) = @_;
	my $pseudonodes = $container->{$CPROP_PSEUDONODES};
	if( defined( $node_type ) ) {
		unless( $NODE_TYPES{$node_type} ) {
			$container->_throw_error_message( 'SRT_C_GET_CH_NODES_BAD_TYPE', { 'ARGNTYPE' => $node_type } );
		}
		my $pp_pseudonode = $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} or return [];
		return [grep { $_->{$NPROP_NODE_TYPE} eq $node_type } @{$pseudonodes->{$pp_pseudonode}}];
	} else {
		return [map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST];
	}
}

######################################################################

sub find_node_by_id {
	my ($container, $node_id) = @_;
	defined( $node_id ) or $container->_throw_error_message( 'SRT_C_FIND_NODE_BY_ID_NO_ARG_ID' );
	return $container->{$CPROP_ALL_NODES}->{$node_id};
}

######################################################################

sub find_child_node_by_surrogate_id {
	my ($container, $target_attr_value) = @_;
	defined( $target_attr_value ) or $container->_throw_error_message( 'SRT_C_FIND_CH_ND_BY_SID_NO_ARG_VAL' );
	ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
	my ($l2_psn, $chain_first, @chain_rest);
	unless( defined( $target_attr_value->[0] ) ) {
		# The given surrogate id chain starts with [undef,'root',<l2-psn>,<chain-of-node-si>].
		(undef, undef, $l2_psn, $chain_first, @chain_rest) = @{$target_attr_value};
	} else {
		# The given surrogate id chain starts with [<chain-of-node-si>].
		($chain_first, @chain_rest) = @{$target_attr_value};
	}
	my $pseudonodes = $container->{$CPROP_PSEUDONODES};
	my @nodes_to_search;
	if( $l2_psn and grep { $l2_psn eq $_ } @L2_PSEUDONODE_LIST ) {
		# Search only children of a specific pseudo-Node.
		@nodes_to_search = @{$pseudonodes->{$l2_psn}};
	} else {
		# Search children of all pseudo-Nodes.
		@nodes_to_search = map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST;
	}
	foreach my $child (@nodes_to_search) {
		if( my $si_atvl = $child->get_surrogate_id_attribute( 1 ) ) {
			if( $si_atvl eq $chain_first ) {
				return @chain_rest ? $child->find_child_node_by_surrogate_id( \@chain_rest ) : $child;
			}
		}
	}
	return;
}

######################################################################

sub get_next_free_node_id {
	my ($container) = @_;
	return $container->{$CPROP_NEXT_FREE_NID};
}

######################################################################

sub deferrable_constraints_are_tested {
	return $_[0]->{$CPROP_DEF_CON_TESTED};
}

sub assert_deferrable_constraints {
	my ($container) = @_;
	if( $container->{$CPROP_DEF_CON_TESTED} ) {
		return;
	}
	# Test nodes in the same order that they appear in the Node tree.
	foreach my $pseudonode_name (@L2_PSEUDONODE_LIST) {
		SQL::Routine::Node->_assert_child_comp_deferrable_constraints( $pseudonode_name, $container );
		foreach my $child_node (@{$container->{$CPROP_PSEUDONODES}->{$pseudonode_name}}) {
			$container->_assert_deferrable_constraints( $child_node );
		}
	}
	$container->{$CPROP_DEF_CON_TESTED} = 1;
}

sub _assert_deferrable_constraints {
	my ($container, $node) = @_;
	$node->assert_deferrable_constraints();
	foreach my $child_node (@{$node->{$NPROP_PRIM_CHILD_NREFS}}) {
		$container->_assert_deferrable_constraints( $child_node );
	}
}

######################################################################

sub get_all_properties {
	return $_[0]->_get_all_properties( $_[1] );
}

sub _get_all_properties {
	my ($container, $links_as_si) = @_;
	my $pseudonodes = $container->{$CPROP_PSEUDONODES};
	return {
		$NAMED_NODE_TYPE => $SQLRT_L1_ROOT_PSND,
		$NAMED_ATTRS => {},
		$NAMED_CHILDREN => [map { {
			$NAMED_NODE_TYPE => $_,
			$NAMED_ATTRS => {},
			$NAMED_CHILDREN => [map { $_->_get_all_properties( $links_as_si ) } @{$pseudonodes->{$_}}],
		} } @L2_PSEUDONODE_LIST],
	};
}

sub get_all_properties_as_perl_str {
	return $_[0]->_serialize_as_perl( $_[0]->_get_all_properties( $_[1] ) );
}

sub get_all_properties_as_xml_str {
	return '<?xml version="1.0" encoding="UTF-8"?>'."\n".
		$_[0]->_serialize_as_xml( $_[0]->_get_all_properties( $_[1] ) );
}

######################################################################

sub build_node {
	my ($container, $node_type, $attrs) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS};
	}
	return $container->_build_node_is_child_or_not( $node_type, $attrs );
}

sub _build_node_is_child_or_not {
	my ($container, $node_type, $attrs, $pp_node) = @_;
	my $node = $container->new_node( $node_type );
	$attrs = $container->_build_node_normalize_attrs( $node, $attrs );
	if( my $node_id = delete( $attrs->{$ATTR_ID} ) ) {
		$node->set_node_id( $node_id );
	}
	$node->put_in_container( $container );
	my $pp_in_attrs = delete( $attrs->{$ATTR_PP} ); # ensure won't override any $pp_node
	if( $pp_node ) {
		$pp_node->add_child_node( $node );
	} else {
		$pp_in_attrs and $node->set_primary_parent_attribute( $pp_in_attrs );
	}
	$node->set_attributes( $attrs );
	if( $container->{$CPROP_AUTO_ASS_DEF_CON} ) {
		eval {
			$node->assert_deferrable_constraints(); # check that this Node's own attrs are correct
		};
		if( my $exception = $@ ) {
			unless( $exception->get_message_key() eq 'SRT_N_ASDC_CH_N_TOO_FEW_SET' ) {
				die $exception; # don't trap any other types of exceptions
			}
		}
	}
	return $node;
}

sub build_child_node {
	my ($container, $node_type, $attrs) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS};
	}
	if( $node_type eq $SQLRT_L1_ROOT_PSND or grep { $_ eq $node_type } @L2_PSEUDONODE_LIST ) {
		return $container;
	} else { # $node_type is not a valid pseudo-Node
		my $node = $container->_build_node_is_child_or_not( $node_type, $attrs );
		unless( $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} ) {
			$node->take_from_container(); # so the new Node doesn't persist
			$container->_throw_error_message( 'SRT_C_BUILD_CH_ND_NO_PSND', { 'ARGNTYPE' => $node_type } );
		}
		return $node;
	}
}

sub build_child_nodes {
	my ($container, $list) = @_;
	$list or return;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$container->build_child_node( ref($element) eq 'ARRAY' ? @{$element} : $element );
	}
}

sub build_child_node_tree {
	my ($container, $node_type, $attrs, $children) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs, $children) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS, $NAMED_CHILDREN};
	}
	if( $node_type eq $SQLRT_L1_ROOT_PSND or grep { $_ eq $node_type } @L2_PSEUDONODE_LIST ) {
		$container->build_child_node_trees( $children );
		return $container;
	} else { # $node_type is not a valid pseudo-Node
		my $node = $container->build_child_node( $node_type, $attrs );
		$node->build_child_node_trees( $children );
		return $node;
	}
}

sub build_child_node_trees {
	my ($container, $list) = @_;
	$list or return;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$container->build_child_node_tree( ref($element) eq 'ARRAY' ? @{$element} : $element );
	}
}

######################################################################
######################################################################

package SQL::Routine::Node;
use base qw( SQL::Routine );

######################################################################

sub new {
	my ($class, $node_type) = @_;
	my $node = bless( {}, ref($class) || $class );

	defined( $node_type ) or $node->_throw_error_message( 'SRT_N_NEW_NODE_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node_type};
	unless( $type_info ) {
		$node->_throw_error_message( 'SRT_N_NEW_NODE_BAD_TYPE', { 'ARGNTYPE' => $node_type } );
	}

	$node->{$NPROP_NODE_TYPE} = $node_type;
	$node->{$NPROP_NODE_ID} = undef;
	$node->{$NPROP_PP_NREF} = undef;
	$node->{$NPROP_AT_LITERALS} = {};
	$node->{$NPROP_AT_ENUMS} = {};
	$node->{$NPROP_AT_NREFS} = {};
	$node->{$NPROP_CONTAINER} = undef;
	$node->{$NPROP_PRIM_CHILD_NREFS} = [];
	$node->{$NPROP_LINK_CHILD_NREFS} = [];

	return $node;
}

######################################################################

sub delete_node {
	my ($node) = @_;

	if( $node->{$NPROP_CONTAINER} ) {
		$node->_throw_error_message( 'SRT_N_DEL_NODE_IN_CONT' );
	}

	# Ultimately the pure-Perl version of this method is a no-op because once 
	# a Node is not in a Container, there are no references to it by any 
	# SQL::Routine/::* object; it will vanish when external refs go away.
	# This function is a placeholder for the C version, which will require 
	# explicit memory deallocation.
}

######################################################################

sub get_node_type {
	return $_[0]->{$NPROP_NODE_TYPE};
}

######################################################################

sub get_node_id {
	return $_[0]->{$NPROP_NODE_ID};
}

sub clear_node_id {
	my ($node) = @_;
	if( $node->{$NPROP_CONTAINER} ) {
		$node->_throw_error_message( 'SRT_N_CLEAR_NODE_ID_IN_CONT' );
	}
	$node->{$NPROP_NODE_ID} = undef;
}

sub set_node_id {
	my ($node, $new_id) = @_;
	defined( $new_id ) or $node->_throw_error_message( 'SRT_N_SET_NODE_ID_NO_ARGS' );

	unless( $new_id =~ m/^\d+$/ and $new_id > 0 ) {
		$node->_throw_error_message( 'SRT_N_SET_NODE_ID_BAD_ARG', { 'ARG' => $new_id } );
	}

	if( !$node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_NODE_ID} = $new_id;
		return;
	}

	# We would never get here if $node didn't also have a NODE_ID
	my $old_id = $node->{$NPROP_NODE_ID};

	if( $new_id == $old_id ) {
		return; # no-op; new id same as old
	}
	my $rh_cal = $node->{$NPROP_CONTAINER}->{$CPROP_ALL_NODES};

	if( $rh_cal->{$new_id} ) {
		$node->_throw_error_message( 'SRT_N_SET_NODE_ID_DUPL_ID', { 'ARG' => $new_id } );
	}

	# The following seq should leave state consistent or recoverable if the thread dies
	$rh_cal->{$new_id} = $node; # temp reserve new+old
	$node->{$NPROP_NODE_ID} = $new_id; # change self from old to new
	delete( $rh_cal->{$old_id} ); # now only new reserved
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}

	# Now adjust our "next free node id" counter if appropriate
	if( $new_id >= $node->{$NPROP_CONTAINER}->{$CPROP_NEXT_FREE_NID} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_NEXT_FREE_NID} = 1 + $new_id;
	}
}

######################################################################

sub get_primary_parent_attribute {
	my ($node) = @_;
	$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_NREF} or $node->_throw_error_message( 'SRT_N_GET_PP_AT_NO_PP_AT' );
	return $node->_get_primary_parent_attribute();
}

sub _get_primary_parent_attribute {
	my ($node) = @_;
	return $node->{$NPROP_PP_NREF};
}

sub clear_primary_parent_attribute {
	my ($node) = @_;
	$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_NREF} or $node->_throw_error_message( 'SRT_N_CLEAR_PP_AT_NO_PP_AT' );
	$node->_clear_primary_parent_attribute();
}

sub _clear_primary_parent_attribute {
	my ($node) = @_;
	my $pp_node = $node->{$NPROP_PP_NREF} or return; # no-op; attr not set
	if( ref($pp_node) eq ref($node) ) {
		# The attribute value is a Node object, so clear its link back.
		my $siblings = $pp_node->{$NPROP_PRIM_CHILD_NREFS};
		@{$siblings} = grep { $_ ne $node } @{$siblings}; # remove the occurance
	}
	$node->{$NPROP_PP_NREF} = undef; # removes link to primary-parent, if any
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_primary_parent_attribute {
	my ($node, $attr_value) = @_;
	my $exp_node_types = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_NREF} or 
		$node->_throw_error_message( 'SRT_N_SET_PP_AT_NO_PP_AT' );
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_PP_AT_NO_ARG_VAL' );
	$node->_set_primary_parent_attribute( $exp_node_types, $attr_value );
}

sub _set_primary_parent_attribute {
	my ($node, $exp_node_types, $attr_value) = @_;
	$attr_value = $node->_normalize_primary_parent_or_node_ref_attribute_value( 
		'SRT_N_SET_PP_AT', $ATTR_PP, $exp_node_types, $attr_value );

	if( $node->{$NPROP_PP_NREF} and $attr_value eq $node->{$NPROP_PP_NREF} ) {
		return; # no-op; new attribute value same as old
	}

	if( ref($attr_value) eq ref($node) ) {
		# Attempt is to link two Nodes in the same Container; it would be okay, except 
		# that we still have to check for circular primary parent Node references.
		my $pp_node = $attr_value;
		do { # Also make sure we aren't trying to link to ourself.
			if( $pp_node eq $node ) {
				$node->_throw_error_message( 'SRT_N_SET_PP_AT_CIRC_REF' );
			}
		} while( $pp_node = $pp_node->{$NPROP_PP_NREF} );
		# For simplicity, we assume circular refs via Node-ref attrs other than 'pp' are impossible.
	}

	$node->_clear_primary_parent_attribute(); # clears any existing link through this attribute
	$node->{$NPROP_PP_NREF} = $attr_value;
	if( ref($attr_value) eq ref($node) ) {
		# The attribute value is a Node object, so that Node should link back now.
		push( @{$attr_value->{$NPROP_PRIM_CHILD_NREFS}}, $node );
	}
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

######################################################################

sub get_literal_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_GET_LIT_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_GET_LIT_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	return $node->_get_literal_attribute( $attr_name );
}

sub _get_literal_attribute {
	my ($node, $attr_name) = @_;
	return $node->{$NPROP_AT_LITERALS}->{$attr_name};
}

sub get_literal_attributes {
	return {%{$_[0]->{$NPROP_AT_LITERALS}}};
}

sub clear_literal_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_CLEAR_LIT_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_CLEAR_LIT_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	$node->_clear_literal_attribute( $attr_name );
}

sub _clear_literal_attribute {
	my ($node, $attr_name) = @_;
	delete( $node->{$NPROP_AT_LITERALS}->{$attr_name} );
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub clear_literal_attributes {
	my ($node) = @_;
	$node->{$NPROP_AT_LITERALS} = {};
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_literal_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_SET_LIT_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my $exp_lit_type = $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_SET_LIT_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_LIT_AT_NO_ARG_VAL', { 'ATNM' => $attr_name } );
	$node->_set_literal_attribute( $attr_name, $exp_lit_type, $attr_value );
}

sub _set_literal_attribute {
	my ($node, $attr_name, $exp_lit_type, $attr_value) = @_;

	if( ref($attr_value) ) {
		$node->_throw_error_message( 'SRT_N_SET_LIT_AT_INVAL_V_IS_REF', 
			{ 'ATNM' => $attr_name, 'ARG_REF_TYPE' => ref($attr_value) } );
	}

	my $node_type = $node->{$NPROP_NODE_TYPE};

	if( $exp_lit_type eq 'bool' ) {
		unless( $attr_value eq '0' or $attr_value eq '1' ) {
			$node->_throw_error_message( 'SRT_N_SET_LIT_AT_INVAL_V_BOOL', 
				{ 'ATNM' => $attr_name, 'ARG' => $attr_value } );
		}

	} elsif( $exp_lit_type eq 'uint' ) {
		unless( $attr_value =~ m/^\d+$/ and $attr_value > 0 ) {
			$node->_throw_error_message( 'SRT_N_SET_LIT_AT_INVAL_V_UINT', 
				{ 'ATNM' => $attr_name, 'ARG' => $attr_value } );
		}

	} elsif( $exp_lit_type eq 'sint' ) {
		unless( $attr_value =~ m/^-?\d+$/ ) {
			$node->_throw_error_message( 'SRT_N_SET_LIT_AT_INVAL_V_SINT', 
				{ 'ATNM' => $attr_name, 'ARG' => $attr_value } );
		}

	} else {} # $exp_lit_type eq 'cstr' or 'misc'; no change to value needed

	$node->{$NPROP_AT_LITERALS}->{$attr_name} = $attr_value;
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_literal_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SRT_N_SET_LIT_ATS_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SRT_N_SET_LIT_ATS_BAD_ARGS', { 'ARG' => $attrs } );
	}
	foreach my $attr_name (keys %{$attrs}) {
		$node->set_literal_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

######################################################################

sub get_enumerated_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_GET_ENUM_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_GET_ENUM_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	return $node->_get_enumerated_attribute( $attr_name );
}

sub _get_enumerated_attribute {
	my ($node, $attr_name) = @_;
	return $node->{$NPROP_AT_ENUMS}->{$attr_name};
}

sub get_enumerated_attributes {
	return {%{$_[0]->{$NPROP_AT_ENUMS}}};
}

sub clear_enumerated_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_CLEAR_ENUM_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_CLEAR_ENUM_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	$node->_clear_enumerated_attribute( $attr_name );
}

sub _clear_enumerated_attribute {
	my ($node, $attr_name) = @_;
	delete( $node->{$NPROP_AT_ENUMS}->{$attr_name} );
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub clear_enumerated_attributes {
	my ($node) = @_;
	$node->{$NPROP_AT_ENUMS} = {};
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_enumerated_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_SET_ENUM_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my $exp_enum_type = $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_SET_ENUM_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_ENUM_AT_NO_ARG_VAL', { 'ATNM' => $attr_name } );
	$node->_set_enumerated_attribute( $attr_name, $exp_enum_type, $attr_value );
}

sub _set_enumerated_attribute {
	my ($node, $attr_name, $exp_enum_type, $attr_value) = @_;

	unless( $ENUMERATED_TYPES{$exp_enum_type}->{$attr_value} ) {
		$node->_throw_error_message( 'SRT_N_SET_ENUM_AT_INVAL_V', { 'ATNM' => $attr_name, 
			'ENUMTYPE' => $exp_enum_type, 'ARG' => $attr_value } );
	}

	$node->{$NPROP_AT_ENUMS}->{$attr_name} = $attr_value;
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_enumerated_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SRT_N_SET_ENUM_ATS_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SRT_N_SET_ENUM_ATS_BAD_ARGS', { 'ARG' => $attrs } );
	}
	foreach my $attr_name (keys %{$attrs}) {
		$node->set_enumerated_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

######################################################################

sub get_node_ref_attribute {
	my ($node, $attr_name, $get_target_si) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_GET_NREF_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_GET_NREF_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	return $node->_get_node_ref_attribute( $attr_name, $get_target_si );
}

sub _get_node_ref_attribute {
	my ($node, $attr_name, $get_target_si) = @_;
	my $attr_val = $node->{$NPROP_AT_NREFS}->{$attr_name};
	if( $get_target_si and $node->{$NPROP_CONTAINER} and defined($attr_val) ) {
		return $attr_val->get_surrogate_id_attribute( $get_target_si );
	} else {
		return $attr_val;
	}
}

sub get_node_ref_attributes {
	my ($node, $get_target_si) = @_;
	my $at_nrefs = $node->{$NPROP_AT_NREFS};
	if( $get_target_si and $node->{$NPROP_CONTAINER} ) {
		return { map { ( 
				$at_nrefs->{$_}->get_surrogate_id_attribute( $get_target_si )
			) } keys %{$at_nrefs} };
	} else {
		return {%{$at_nrefs}};
	}
}

sub clear_node_ref_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_CLEAR_NREF_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_CLEAR_NREF_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	$node->_clear_node_ref_attribute( $attr_name );
}

sub _clear_node_ref_attribute {
	my ($node, $attr_name) = @_;
	my $attr_value = $node->{$NPROP_AT_NREFS}->{$attr_name} or return; # no-op; attr not set
	if( ref($attr_value) eq ref($node) ) {
		# The attribute value is a Node object, so clear its link back.
		my $ra_children_of_parent = $attr_value->{$NPROP_LINK_CHILD_NREFS};
		foreach my $i (0..$#{$ra_children_of_parent}) {
			if( $ra_children_of_parent->[$i] eq $node ) {
				# remove first instance of $node from it's parent's child list
				splice( @{$ra_children_of_parent}, $i, 1 );
				last;
			}
		}
	}
	delete( $node->{$NPROP_AT_NREFS}->{$attr_name} ); # removes link to link-parent, if any
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub clear_node_ref_attributes {
	my ($node) = @_;
	foreach my $attr_name (sort keys %{$node->{$NPROP_AT_NREFS}}) {
		$node->_clear_node_ref_attribute( $attr_name );
	}
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub set_node_ref_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_SET_NREF_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my $exp_node_types = $type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} or 
		$node->_throw_error_message( 'SRT_N_SET_NREF_AT_INVAL_NM', { 'ATNM' => $attr_name } );
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_NREF_AT_NO_ARG_VAL', { 'ATNM' => $attr_name } );
	$node->_set_node_ref_attribute( $attr_name, $exp_node_types, $attr_value );
}

sub _set_node_ref_attribute {
	my ($node, $attr_name, $exp_node_types, $attr_value) = @_;
	$attr_value = $node->_normalize_primary_parent_or_node_ref_attribute_value( 
		'SRT_N_SET_NREF_AT', $attr_name, $exp_node_types, $attr_value );

	if( $node->{$NPROP_AT_NREFS}->{$attr_name} and $attr_value eq $node->{$NPROP_AT_NREFS}->{$attr_name} ) {
		return; # no-op; new attribute value same as old
	}

	$node->_clear_node_ref_attribute( $attr_name ); # clears any existing link through this attribute
	$node->{$NPROP_AT_NREFS}->{$attr_name} = $attr_value;
	if( ref($attr_value) eq ref($node) ) {
		# The attribute value is a Node object, so that Node should link back now.
		push( @{$attr_value->{$NPROP_LINK_CHILD_NREFS}}, $node );
	}
	if( $node->{$NPROP_CONTAINER} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node was changed.
	}
}

sub _normalize_primary_parent_or_node_ref_attribute_value {
	my ($node, $error_key_pfx, $attr_name, $exp_node_types, $attr_value) = @_;

	if( ref($attr_value) eq ref($node) ) {
		# We were given a Node object for a new attribute value.
		unless( grep { $attr_value->{$NPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
			$node->_throw_error_message( $error_key_pfx.'_WRONG_NODE_TYPE', { 'ATNM' => $attr_name, 
				'EXPNTYPE' => $exp_node_types, 'ARGNTYPE' => $attr_value->{$NPROP_NODE_TYPE} } );
		}
		if( $attr_value->{$NPROP_CONTAINER} and $node->{$NPROP_CONTAINER} ) {
			unless( $attr_value->{$NPROP_CONTAINER} eq $node->{$NPROP_CONTAINER} ) {
				$node->_throw_error_message( $error_key_pfx.'_DIFF_CONT', { 'ATNM' => $attr_name } );
			}
			# If we get here, both Nodes are in the same Container and can link
		} elsif( $attr_value->{$NPROP_CONTAINER} or $node->{$NPROP_CONTAINER} ) {
			$node->_throw_error_message( $error_key_pfx.'_ONE_CONT', { 'ATNM' => $attr_name } );
		} elsif( !$attr_value->{$NPROP_NODE_ID} ) {
			# both Nodes are not in Containers, and $attr_value has no Node Id
			$node->_throw_error_message( $error_key_pfx.'_MISS_NID', { 'ATNM' => $attr_name } );
		} else {
			# both Nodes are not in Containers, and $attr_value has Node Id, so can link
			$attr_value = $attr_value->{$NPROP_NODE_ID};
		} 

	} elsif( $attr_value =~ m/^\d+$/ and $attr_value > 0 ) {
		# We were given a Node Id for a new attribute value.
		if( my $container = $node->{$NPROP_CONTAINER} ) {
			my $searched_attr_value = $container->{$CPROP_ALL_NODES}->{$attr_value};
			unless( $searched_attr_value and grep { $searched_attr_value->{$NPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
				$node->_throw_error_message( $error_key_pfx.'_NONEX_NID', 
					{ 'ATNM' => $attr_name, 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types } );
			}
			$attr_value = $searched_attr_value;
		}

	} else {
		# We were given a Surrogate Node Id for a new attribute value.
		if( $attr_name eq $ATTR_PP ) {
			# This should only be encountered by set_primary_parent_attribute().
			$node->_throw_error_message( 'SRT_N_SET_PP_AT_NO_ALLOW_SID_FOR_PP', { 'ARG' => $attr_value } );
		}
		# These next two should only be encountered by set_node_ref_attribute().
		unless( $node->{$NPROP_CONTAINER} and $node->{$NPROP_CONTAINER}->{$CPROP_MAY_MATCH_SNIDS} ) {
			$node->_throw_error_message( 'SRT_N_SET_NREF_AT_NO_ALLOW_SID', { 'ATNM' => $attr_name, 'ARG' => $attr_value } );
		}
		my $searched_attr_value = $node->find_node_by_surrogate_id( $attr_name, $attr_value );
		unless( $searched_attr_value ) {
			$node->_throw_error_message( 'SRT_N_SET_NREF_AT_NONEX_SID', 
				{ 'ATNM' => $attr_name, 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types } );
		}
		$attr_value = $searched_attr_value;
	}

	return $attr_value;
}

sub set_node_ref_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SRT_N_SET_NREF_ATS_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SRT_N_SET_NREF_ATS_BAD_ARGS', { 'ARG' => $attrs } );
	}
	foreach my $attr_name (sort keys %{$attrs}) {
		$node->set_node_ref_attribute( $attr_name, $attrs->{$attr_name} );
	}
}

######################################################################

sub get_surrogate_id_attribute {
	my ($node, $get_target_si) = @_;
	my ($id, $lit, $enum, $nref) = @{$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_SI_ATNM}};
	$id and return $node->get_node_id();
	$lit and return $node->_get_literal_attribute( $lit );
	$enum and return $node->_get_enumerated_attribute( $enum );
	$nref and return $node->_get_node_ref_attribute( $nref, $get_target_si );
}

sub clear_surrogate_id_attribute {
	my ($node) = @_;
	my ($id, $lit, $enum, $nref) = @{$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_SI_ATNM}};
	$id and return $node->clear_node_id();
	$lit and return $node->_clear_literal_attribute( $lit );
	$enum and return $node->_clear_enumerated_attribute( $enum );
	$nref and return $node->_clear_node_ref_attribute( $nref );
}

sub set_surrogate_id_attribute {
	my ($node, $attr_value) = @_;
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_SI_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my ($id, $lit, $enum, $nref) = @{$type_info->{$TPI_SI_ATNM}};
	$id and return $node->set_node_id( $attr_value );
	$lit and return $node->_set_literal_attribute( $lit, $type_info->{$TPI_AT_LITERALS}->{$lit}, $attr_value );
	$enum and return $node->_set_enumerated_attribute( $enum, $type_info->{$TPI_AT_ENUMS}->{$enum}, $attr_value );
	$nref and return $node->_set_node_ref_attribute( $nref, $type_info->{$TPI_AT_NREFS}->{$nref}, $attr_value );
}

######################################################################

sub get_attribute {
	my ($node, $attr_name, $get_target_si) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_GET_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$attr_name eq $ATTR_ID and return $node->get_node_id();
	$attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NREF} and 
		return $node->_get_primary_parent_attribute();
	$type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} and 
		return $node->_get_literal_attribute( $attr_name );
	$type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} and 
		return $node->_get_enumerated_attribute( $attr_name );
	$type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} and 
		return $node->_get_node_ref_attribute( $attr_name, $get_target_si );
	$node->_throw_error_message( 'SRT_N_GET_AT_INVAL_NM', { 'ATNM' => $attr_name } );
}

sub get_attributes {
	my ($node, $get_target_si) = @_;
	return {
		$ATTR_ID => $node->get_node_id(),
		($NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_NREF} ? 
			($ATTR_PP => $node->_get_primary_parent_attribute()) : ()),
		%{$node->get_literal_attributes()},
		%{$node->get_enumerated_attributes()},
		%{$node->get_node_ref_attributes( $get_target_si )},
	};
}

sub clear_attribute {
	my ($node, $attr_name) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_CLEAR_AT_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	$attr_name eq $ATTR_ID and return $node->clear_node_id();
	$attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NREF} and 
		return $node->_clear_primary_parent_attribute();
	$type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} and 
		return $node->_clear_literal_attribute( $attr_name );
	$type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} and 
		return $node->_clear_enumerated_attribute( $attr_name );
	$type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} and 
		return $node->_clear_node_ref_attribute( $attr_name );
	$node->_throw_error_message( 'SRT_N_CLEAR_AT_INVAL_NM', { 'ATNM' => $attr_name } );
}

sub clear_attributes {
	my ($node) = @_;
	$node->clear_node_id();
	$NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_NREF} and $node->_clear_primary_parent_attribute();
	$node->clear_literal_attributes();
	$node->clear_enumerated_attributes();
	$node->clear_node_ref_attributes();
}

sub set_attribute {
	my ($node, $attr_name, $attr_value) = @_;
	defined( $attr_name ) or $node->_throw_error_message( 'SRT_N_SET_AT_NO_ARGS' );
	defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_AT_NO_ARG_VAL', { 'ATNM' => $attr_name } );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	if( $attr_name eq $ATTR_ID ) {
		return $node->set_node_id( $attr_value );
	}
	if( my $exp_node_types = $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NREF} ) {
		return $node->_set_primary_parent_attribute( $exp_node_types, $attr_value );
	}
	if( my $exp_lit_type = $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} ) {
		return $node->_set_literal_attribute( $attr_name, $exp_lit_type, $attr_value );
	}
	if( my $exp_enum_type = $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} ) {
		return $node->_set_enumerated_attribute( $attr_name, $exp_enum_type, $attr_value );
	}
	if( my $exp_node_types = $type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} ) {
		return $node->_set_node_ref_attribute( $attr_name, $exp_node_types, $attr_value );
	}
	$node->_throw_error_message( 'SRT_N_SET_AT_INVAL_NM', { 'ATNM' => $attr_name } );
}

sub set_attributes {
	my ($node, $attrs) = @_;
	defined( $attrs ) or $node->_throw_error_message( 'SRT_N_SET_ATS_NO_ARGS' );
	unless( ref($attrs) eq 'HASH' ) {
		$node->_throw_error_message( 'SRT_N_SET_ATS_BAD_ARGS', { 'ARG' => $attrs } );
	}
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	foreach my $attr_name (sort keys %{$attrs}) {
		my $attr_value = $attrs->{$attr_name};
		defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_ATS_NO_ARG_ELEM_VAL', { 'ATNM' => $attr_name } );
		if( $attr_name eq $ATTR_ID ) {
			$node->set_node_id( $attr_value );
			next;
		}
		if( my $exp_node_types = $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NREF} ) {
			$node->_set_primary_parent_attribute( $exp_node_types, $attr_value );
			next;
		}
		if( my $exp_lit_type = $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} ) {
			$node->_set_literal_attribute( $attr_name, $exp_lit_type, $attr_value );
			next;
		}
		if( my $exp_enum_type = $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} ) {
			$node->_set_enumerated_attribute( $attr_name, $exp_enum_type, $attr_value );
			next;
		}
		if( my $exp_node_types = $type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$attr_name} ) {
			$node->_set_node_ref_attribute( $attr_name, $exp_node_types, $attr_value );
			next;
		}
		$node->_throw_error_message( 'SRT_N_SET_ATS_INVAL_ELEM_NM', { 'ATNM' => $attr_name } );
	}
}

######################################################################

sub get_container {
	return $_[0]->{$NPROP_CONTAINER};
}

sub put_in_container {
	my ($node, $new_container) = @_;
	defined( $new_container ) or $node->_throw_error_message( 'SRT_N_PI_CONT_NO_ARGS' );

	unless( ref($new_container) and UNIVERSAL::isa( $new_container, 'SQL::Routine::Container' ) ) {
		$node->_throw_error_message( 'SRT_N_PI_CONT_BAD_ARG', { 'ARG' => $new_container } );
	}

	if( $node->{$NPROP_CONTAINER} ) {
		if( $new_container eq $node->{$NPROP_CONTAINER} ) {
			return; # no-op; new container same as old
		}
		$node->_throw_error_message( 'SRT_N_PI_CONT_HAVE_ALREADY' );
	}
	my $node_type = $node->{$NPROP_NODE_TYPE};

	my $node_id = $node->{$NPROP_NODE_ID};
	unless( $node_id ) {
		if( $new_container->{$CPROP_AUTO_SET_NIDS} ) {
			$node_id = $node->{$NPROP_NODE_ID} = $new_container->get_next_free_node_id();
		} else {
			$node->_throw_error_message( 'SRT_N_PI_CONT_NO_NODE_ID' );
		}
	}

	if( $new_container->{$CPROP_ALL_NODES}->{$node_id} ) {
		$node->_throw_error_message( 'SRT_N_PI_CONT_DUPL_ID' );
	}

	# Note: No recursion tests are necessary in put_in_container(); any existing Node 
	# that the newly added Node would link to can not already be the new Node's direct 
	# or indirect child, since Nodes in Containers can't reference Nodes that aren't.

	my $exp_pp_types = $NODE_TYPES{$node_type}->{$TPI_PP_NREF};
	my $exp_at_nrefs_types = $NODE_TYPES{$node_type}->{$TPI_AT_NREFS};
	my $rh_at_nodes_nids = $node->{$NPROP_AT_NREFS}; # all values should be node ids now
	my $rh_can = $new_container->{$CPROP_ALL_NODES};

	my $pp_node = $node->{$NPROP_PP_NREF}; # value should be id number
	if( my $pp_node_id = $pp_node ) {
		my $pp_node_ref = $rh_can->{$pp_node_id};
		unless( $pp_node_ref and grep { $pp_node_ref->{$NPROP_NODE_TYPE} eq $_ } @{$exp_pp_types} ) {
			$node->_throw_error_message( 'SRT_N_PI_CONT_NONEX_AT_NREF', 
				{ 'EXPNTYPE' => $exp_pp_types, 'EXPNID' => $pp_node_id } );
		}
		$pp_node = $pp_node_ref; # change id number to node ref
	}
	my %at_nodes_refs = (); # values put in here will be actual references
	foreach my $at_nodes_atnm (keys %{$rh_at_nodes_nids}) {
		# Note that if $tpi_at_nodes is undefined, expect that this foreach loop will not run
		my $exp_at_nref_types = $exp_at_nrefs_types->{$at_nodes_atnm};
		my $at_nodes_nid = $rh_at_nodes_nids->{$at_nodes_atnm};
		my $at_nodes_ref = $rh_can->{$at_nodes_nid};
		unless( $at_nodes_ref and grep { $at_nodes_ref->{$NPROP_NODE_TYPE} eq $_ } @{$exp_at_nref_types} ) {
			$node->_throw_error_message( 'SRT_N_PI_CONT_NONEX_AT_NREF', 
				{ 'ATNM' => $at_nodes_atnm, 'EXPNTYPE' => $exp_at_nref_types, 'EXPNID' => $at_nodes_nid } );
		}
		$at_nodes_refs{$at_nodes_atnm} = $at_nodes_ref;
	}
	$node->{$NPROP_CONTAINER} = $new_container;
	$node->{$NPROP_PP_NREF} = $pp_node;
	$node->{$NPROP_AT_NREFS} = \%at_nodes_refs;
	$rh_can->{$node_id} = $node;

	# Now get our parent Nodes to link back to us.
	if( my $pp_pseudonode = $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} ) {
		push( @{$new_container->{$CPROP_PSEUDONODES}->{$pp_pseudonode}}, $node );
	} elsif( my $pp_node = $node->{$NPROP_PP_NREF} ) {
		push( @{$pp_node->{$NPROP_PRIM_CHILD_NREFS}}, $node );
	}
	foreach my $attr_value (values %{$node->{$NPROP_AT_NREFS}}) {
		push( @{$attr_value->{$NPROP_LINK_CHILD_NREFS}}, $node );
	}

	# Now adjust our "next free node id" counter if appropriate
	if( $node_id >= $node->{$NPROP_CONTAINER}->{$CPROP_NEXT_FREE_NID} ) {
		$node->{$NPROP_CONTAINER}->{$CPROP_NEXT_FREE_NID} = 1 + $node_id;
	}

	$new_container->{$CPROP_DEF_CON_TESTED} = 0; # A Node has become "Well Known".
}

sub take_from_container {
	my ($node) = @_;
	my $container = $node->{$NPROP_CONTAINER} or return; # no-op; node is already not in a container

	if( @{$node->{$NPROP_PRIM_CHILD_NREFS}} > 0 or @{$node->{$NPROP_LINK_CHILD_NREFS}} > 0 ) {
		$node->_throw_error_message( 'SRT_N_TF_CONT_HAS_CHILD' );
	}

	# Remove our parent Nodes' links back to us.
	my $node_type = $node->{$NPROP_NODE_TYPE};
	if( my $pp_pseudonode = $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} ) {
		my $container = $node->{$NPROP_CONTAINER};
		my $siblings = $container->{$CPROP_PSEUDONODES}->{$pp_pseudonode};
		@{$siblings} = grep { $_ ne $node } @{$siblings}; # remove the occurance
	} elsif( my $pp_node = $node->{$NPROP_PP_NREF} ) {
		my $siblings = $pp_node->{$NPROP_PRIM_CHILD_NREFS};
		@{$siblings} = grep { $_ ne $node } @{$siblings}; # remove the occurance
	}
	foreach my $attr_value (values %{$node->{$NPROP_AT_NREFS}}) {
		my $siblings = $attr_value->{$NPROP_LINK_CHILD_NREFS};
		@{$siblings} = grep { $_ ne $node } @{$siblings}; # remove all occurances
	}

	my $pp_node = $node->{$NPROP_PP_NREF}; # value should be actual ref
	if( $pp_node ) {
		$pp_node = $pp_node->{$NPROP_NODE_ID}; # change node ref to node id number
	}
	my $rh_at_nodes_refs = $node->{$NPROP_AT_NREFS}; # all values should be actual references now
	my %at_nodes_nids = (); # values put in here will be node id numbers
	foreach my $at_nodes_atnm (keys %{$rh_at_nodes_refs}) {
		$at_nodes_nids{$at_nodes_atnm} = $rh_at_nodes_refs->{$at_nodes_atnm}->{$NPROP_NODE_ID};
	}

	delete( $container->{$CPROP_ALL_NODES}->{$node->{$NPROP_NODE_ID}} );
	$node->{$NPROP_AT_NREFS} = \%at_nodes_nids;
	$node->{$NPROP_PP_NREF} = $pp_node;
	$node->{$NPROP_CONTAINER} = undef;

	$container->{$CPROP_DEF_CON_TESTED} = 0; # A "Well Known" Node is gone.
		# Turn on tests because this Node's absence affects *other* Well Known Nodes.
}

######################################################################

sub move_before_sibling {
	my ($node, $sibling, $parent) = @_;
	my $pp_pseudonode = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE};

	# First make sure we have 3 actual Nodes that are all "Well Known" and in the same Container.

	$node->{$NPROP_CONTAINER} or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_NO_CONT' );

	defined( $sibling ) or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_NO_S_ARG' );
	unless( ref($sibling) eq ref($node) ) {
		$node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_BAD_S_ARG', { 'ARG' => $sibling } );
	}
	unless( $sibling->{$NPROP_CONTAINER} and $sibling->{$NPROP_CONTAINER} eq $node->{$NPROP_CONTAINER} ) {
		$node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_S_DIFF_CONT' );
	}

	if( defined( $parent ) ) {
		unless( ref($parent) eq ref($node) ) {
			$node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_BAD_P_ARG', { 'ARG' => $parent } );
		}
		unless( $parent->{$NPROP_CONTAINER} and $parent->{$NPROP_CONTAINER} eq $node->{$NPROP_CONTAINER} ) {
			$node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_P_DIFF_CONT' );
		}
	} else {
		unless( $parent = $node->{$NPROP_PP_NREF} ) {
			$pp_pseudonode or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_NO_P_ARG_OR_PP_OR_PS' );
		}
	}

	# Now get the Node list we're going to search through.

	my $ra_search_list = $parent ? 
		($parent eq $node->{$NPROP_PP_NREF} ? $parent->{$NPROP_PRIM_CHILD_NREFS} : $parent->{$NPROP_LINK_CHILD_NREFS}) : 
		$node->{$NPROP_CONTAINER}->{$CPROP_PSEUDONODES}->{$pp_pseudonode};

	# Now confirm the given Nodes are our parent and sibling.
	# For efficiency we also prepare to reorder the Nodes at the same time.

	my @curr_node_refs = ();
	my @sib_node_refs = ();
	my @refs_before_both = ();
	my @refs_after_both = ();

	my $others_go_before = 1;
	foreach my $child (@{$ra_search_list}) {
		if( $child eq $node ) {
			push( @curr_node_refs, $child );
		} elsif( $child eq $sibling ) {
			push( @sib_node_refs, $child );
			$others_go_before = 0;
		} elsif( $others_go_before ) {
			push( @refs_before_both, $child );
		} else {
			push( @refs_after_both, $child );
		}
	}

	scalar( @curr_node_refs ) or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_P_NOT_P' );
	scalar( @sib_node_refs ) or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_S_NOT_S' );

	# Everything checks out, so now we perform the reordering.

	@{$ra_search_list} = (@refs_before_both, @curr_node_refs, @sib_node_refs, @refs_after_both);
	$node->{$NPROP_CONTAINER}->{$CPROP_DEF_CON_TESTED} = 0; # "Well Known" Node relation chg.
}

######################################################################

sub get_child_nodes {
	my ($node, $node_type) = @_;
	if( defined( $node_type ) ) {
		unless( $NODE_TYPES{$node_type} ) {
			$node->_throw_error_message( 'SRT_N_GET_CH_NODES_BAD_TYPE' );
		}
		return [grep { $_->{$NPROP_NODE_TYPE} eq $node_type } @{$node->{$NPROP_PRIM_CHILD_NREFS}}];
	} else {
		return [@{$node->{$NPROP_PRIM_CHILD_NREFS}}];
	}
}

sub add_child_node {
	my ($node, $new_child) = @_;
	defined( $new_child ) or $node->_throw_error_message( 'SRT_N_ADD_CH_NODE_NO_ARGS' );
	unless( ref($new_child) eq ref($node) ) {
		$node->_throw_error_message( 'SRT_N_ADD_CH_NODE_BAD_ARG', { 'ARG' => $new_child } );
	}
	$new_child->set_primary_parent_attribute( $node ); # will die if not same Container
		# will also die if the change would result in a circular reference
}

sub add_child_nodes {
	my ($node, $list) = @_;
	$list or return;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$node->add_child_node( $element );
	}
}

######################################################################

sub get_referencing_nodes {
	my ($node, $node_type) = @_;
	if( defined( $node_type ) ) {
		unless( $NODE_TYPES{$node_type} ) {
			$node->_throw_error_message( 'SRT_N_GET_REF_NODES_BAD_TYPE' );
		}
		return [grep { $_->{$NPROP_NODE_TYPE} eq $node_type } @{$node->{$NPROP_LINK_CHILD_NREFS}}];
	} else {
		return [@{$node->{$NPROP_LINK_CHILD_NREFS}}];
	}
}

######################################################################

sub get_surrogate_id_chain {
	my ($node) = @_;
	$node->{$NPROP_CONTAINER} or $node->_throw_error_message( 'SRT_N_GET_SID_CHAIN_NOT_IN_CONT' );
	return $node->_get_surrogate_id_chain();
}

sub _get_surrogate_id_chain {
	my ($node) = @_;
	my $si_atvl = $node->get_surrogate_id_attribute( 1 ); # target SI lit/enum is being returned as a string
	if( my $pp_node = $node->{$NPROP_PP_NREF} ) {
		# Current Node has a primary-parent Node; append to its id chain.
		my $elements = $pp_node->_get_surrogate_id_chain();
		push( @{$elements}, $si_atvl );
		return $elements;
	} elsif( my $l2_psnd = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE} ) {
		# Current Node has a primary-parent pseudo-Node; append to its id chain.
		return [undef, $SQLRT_L1_ROOT_PSND, $l2_psnd, $si_atvl];
	} else {
		# Current Node is not linked to the main Node tree yet; indicate this with non-undef first chain element.
		return [$si_atvl];
	}
}

######################################################################

sub find_node_by_surrogate_id {
	my ($node, $self_attr_name, $target_attr_value) = @_;
	$node->{$NPROP_CONTAINER} or $node->_throw_error_message( 'SRT_N_FIND_ND_BY_SID_NOT_IN_CONT' );
	defined( $self_attr_name ) or $node->_throw_error_message( 'SRT_N_FIND_ND_BY_SID_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my $exp_node_types = $type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$self_attr_name} or 
		$node->_throw_error_message( 'SRT_N_FIND_ND_BY_SID_INVAL_NM', { 'ATNM' => $self_attr_name } );
	defined( $target_attr_value ) or $node->_throw_error_message( 
		'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
	ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
	scalar( @{$target_attr_value} ) >= 1 or $node->_throw_error_message( 
		'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
	foreach my $element (@{$target_attr_value}) {
		defined( $element ) or $node->_throw_error_message( 
			'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
	}
	# If we get here, most input checks passed.
	my %exp_p_node_types = map { ($_ => 1) } @{$exp_node_types};
	if( my $search_path = $type_info->{$TPI_ANCES_ATCORS} && $type_info->{$TPI_ANCES_ATCORS}->{$self_attr_name} ) {
		# The value we are searching for must be the child part of a correlated pair.
		return $node->_find_node_by_surrogate_id_using_path( \%exp_p_node_types, $target_attr_value, $search_path );
	}
	# If we get here, the value we are searching for is not the child part of a correlated pair.
	my %remotely_addressable_types = map { ($_ => $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR}) } 
		grep { $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR} } @{$exp_node_types};
	my ($unqualified_value, $qualifier_l1, @rest) = @{$target_attr_value};
	if( $qualifier_l1 ) {
		# An attempt is definitely being made to remotely address a Node.
		scalar( keys %remotely_addressable_types ) >= 1 or $node->_throw_error_message( 
			'SRT_N_FIND_ND_BY_SID_NO_REM_ADDR', { 'ATNM' => $self_attr_name } );
		# If we get here, we are allowed to remotely address a Node.
		return $node->_find_node_by_surrogate_id_remotely( \%remotely_addressable_types, $target_attr_value );
	}
	# If we get here, we are searching with a purely unqualified target SI value.
	# First try to find the target among our ancestors' siblings.
	if( my $result = $node->_find_node_by_surrogate_id_within_layers( \%exp_p_node_types, $unqualified_value ) ) {
		return $result;
	}
	# If we get here, there were no ancestor sibling matches.
	if( scalar( keys %remotely_addressable_types ) >= 1 ) {
		# If we get here, we are allowed to remotely address a Node.
		return $node->_find_node_by_surrogate_id_remotely( \%remotely_addressable_types, $target_attr_value );
	}
	# If we get here, all search attempts failed.
	return;
}

sub _find_node_by_surrogate_id_remotely {
	# Method assumes $exp_p_node_types only contains Node types that can be remotely addressable.
	# Within this method, values of $exp_p_node_types are arrays of expected ancestor types for the keys.
	my ($node, $exp_p_node_types, $target_attr_value) = @_;
	my @search_chain = reverse @{$target_attr_value};
	my %exp_anc_node_types = map { ($_ => 1) } map { @{$_} } values %{$exp_p_node_types};
	# First check if we, ourselves, are a child of an expected ancestor type; 
	# if we are, then we should search beneath our own ancestor first.
	my $self_anc_node = $node;
	while( $self_anc_node and !$exp_anc_node_types{$self_anc_node->{$NPROP_NODE_TYPE}} ) {
		$self_anc_node = $self_anc_node->{$NPROP_PP_NREF};
	}
	if( $self_anc_node ) {
		# Search beneath our own ancestor first.
		my $curr_node = $node;
		do {
			# $curr_node is everything from our parent to and including the remote ancestor.
			$curr_node = $curr_node->{$NPROP_PP_NREF};
			if( my $result = $curr_node->_find_node_by_surrogate_id_remotely_below_here( $exp_p_node_types, \@search_chain ) ) {
				return $result;
			}
		} until( $curr_node eq $self_anc_node );
	}
	# If we get here, we either have no qualified ancestor, or nothing was found when starting beneath it.
	# Now look beneath other allowable ancestors.
	my %psn_roots = map { ($_ => 1) } grep { $_ } map { $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE} } keys %exp_anc_node_types;
	my $pseudonodes = $node->{$NPROP_CONTAINER}->{$CPROP_PSEUDONODES};
	my @anc_nodes = grep { $exp_anc_node_types{$_->{$NPROP_NODE_TYPE}} } 
		map { @{$pseudonodes->{$_}} } grep { $psn_roots{$_} } @L2_PSEUDONODE_LIST;
	foreach my $anc_node (@anc_nodes) {
		if( my $result = $anc_node->_find_node_by_surrogate_id_remotely_below_here( $exp_p_node_types, \@search_chain ) ) {
			return $result;
		}
	}
	# If we get here, nothing was found.
	return;
}

sub _find_node_by_surrogate_id_remotely_below_here {
	# Method assumes $exp_p_node_types only contains Node types that can be remotely addressable.
	my ($node, $exp_p_node_types, $search_chain_in) = @_;
	my @search_chain = @{$search_chain_in};
	scalar( @search_chain ) or return; # no match
	if( my $si_atvl = $node->get_surrogate_id_attribute( 1 ) ) {
		if( $si_atvl eq $search_chain[0] ) {
			# Invocant Node's name matched a chain element.
			my $first = shift( @search_chain ); 
			unless( scalar( @search_chain ) ) {
				# No more Nodes to search along this path; win or lose, we're done here.
				if( $exp_p_node_types->{$node->{$NPROP_NODE_TYPE}} ) {
					return $node;
				} else {
					return;
				}
			}
		}
	}
	# If we get here, there is at least 1 more unmatched search chain element.
	foreach my $child (@{$node->{$NPROP_PRIM_CHILD_NREFS}}) {
		if( $child->{$NPROP_NODE_TYPE} eq $node->{$NPROP_NODE_TYPE} ) {
			next; # It is illegal to remotely match a Node that is a child of its own Node type.
		}
		if( my $result = $child->_find_node_by_surrogate_id_remotely_below_here( $exp_p_node_types, \@search_chain ) ) {
			return $result;
		}
	}
	# If we get here, nothing was found.
	return;
}

sub _find_node_by_surrogate_id_within_layers {
	my ($node, $exp_p_node_types, $target_attr_value) = @_;
	my $pp_node = $node->{$NPROP_PP_NREF};

	# Now determine who our siblings are.

	my @sibling_list = ();
	if( $pp_node ) {
		# We have a normal Node primary-parent, P.
		# Search among all Nodes that have P as their primary-parent Node; these are our siblings.
		@sibling_list = @{$pp_node->{$NPROP_PRIM_CHILD_NREFS}};
	} else {
		# Either we have a pseudo-Node primary-parent, or no parent normal Node is defined for us.
		# Search among all Nodes that have pseudo-Node primary-parents.
		my $pseudonodes = $node->{$NPROP_CONTAINER}->{$CPROP_PSEUDONODES};
		@sibling_list = map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST;
	}

	# Now search among our siblings for a match.

	foreach my $sibling_node (@sibling_list) {
		$exp_p_node_types->{$sibling_node->{$NPROP_NODE_TYPE}} or next;
		if( my $si_atvl = $sibling_node->get_surrogate_id_attribute( 1 ) ) {
			if( $si_atvl eq $target_attr_value ) {
				return $sibling_node;
			}
		}
	}

	# Nothing was found among our siblings.

	if( $pp_node ) {
		# We are not at the tree's root, so move upwards by a generation and try again.
		return $pp_node->_find_node_by_surrogate_id_within_layers( $exp_p_node_types, $target_attr_value );
	} else {
		# There is no further up that we can go, so no match was found.
		return;
	}
}

sub _find_node_by_surrogate_id_using_path {
	my ($node, $exp_p_node_types, $target_attr_value, $search_path) = @_;
	my $curr_node = $node;
	my ($unqualified_value, $qualifier_l1, @rest) = @{$target_attr_value};

	# Now enumerate through the explicit search path elements, updating $curr_node in the process.

	foreach my $path_seg (@{$search_path}) {
		if( $path_seg eq $S ) { # <self> is a no-op, existing for easier-to-read documentation only
			# no-op
		} elsif( $path_seg eq $P ) { # <primary-parent>
			unless( $curr_node = $curr_node->{$NPROP_PP_NREF} ) {
				return; # current Node's primary parent isn't set yet (it should be); get out
			}
		} elsif( $path_seg eq $R ) { # <root-of-kind>
			while( $curr_node->{$NPROP_PP_NREF} and 
					$curr_node->{$NPROP_PP_NREF}->{$NPROP_NODE_TYPE} eq $curr_node->{$NPROP_NODE_TYPE} ) {
				$curr_node = $curr_node->{$NPROP_PP_NREF};
			}
		} elsif( $path_seg eq $C ) { # <primary-child>
			# For simplicity we are assuming the $C is the end of the path; it's grand-child or bust.
			if( defined($qualifier_l1) ) {
				# Given value is qualified; only look within the specified contexts.
				foreach my $child_l1 (@{$curr_node->{$NPROP_PRIM_CHILD_NREFS}}) {
					my $si_atvl = $child_l1->get_surrogate_id_attribute( 1 ) or next;
					$si_atvl eq $qualifier_l1 or next;
					foreach my $child_l2 (@{$child_l1->{$NPROP_PRIM_CHILD_NREFS}}) {
						$exp_p_node_types->{$child_l2->{$NPROP_NODE_TYPE}} or next;
						if( my $si_atvl = $child_l2->get_surrogate_id_attribute( 1 ) ) {
							if( $si_atvl eq $unqualified_value ) {
								return $child_l2;
							}
						}
					}
				}
			} else { # Given value is unqualified; take any one that matches, if only one matches.
				my $matched_count = 0;
				my $matched_node = undef;
				foreach my $grandchild (map { @{$_->{$NPROP_PRIM_CHILD_NREFS}} } @{$curr_node->{$NPROP_PRIM_CHILD_NREFS}}) {
					$exp_p_node_types->{$grandchild->{$NPROP_NODE_TYPE}} or next;
					if( my $si_atvl = $grandchild->get_surrogate_id_attribute( 1 ) ) {
						if( $si_atvl eq $unqualified_value ) {
							$matched_count += 1;
							$matched_node = $grandchild;
						}
					}
				}
				if( $matched_count == 1 ) {
					return $matched_node;
				}
				# If we get here, then either no matches were found, or 2+ were, 
				# so the unqualified identifier can't say which to take.
				# MAYBE TODO: Throw exception to specify that input SI was too ambiguous to match.
			}
			return;
		} else { # <nref-attr>; $path_seg is an attribute name
			unless( $curr_node = $curr_node->{$NPROP_AT_NREFS}->{$path_seg} ) {
				return; # the Node-ref attribute we should follow isn't set yet (it should be); get out
			}
		}
	}

	# We are at the end of the explicit search path, and the start of the implicit path.
	# Now enumerate through any wrapper attributes, if there are any, updating $curr_node in the process.

	while( my $wr_atnm = $NODE_TYPES{$curr_node->{$NPROP_NODE_TYPE}}->{$TPI_WR_ATNM} ) {
		unless( $curr_node = $curr_node->{$NPROP_AT_NREFS}->{$wr_atnm} ) {
			return; # the Node-ref attribute we should follow isn't set yet (it should be); get out
		}
	}

	# We are at the end of the implicit search path.
	# The required Node must be one of $curr_node's children.

	foreach my $child (@{$curr_node->{$NPROP_PRIM_CHILD_NREFS}}) {
		$exp_p_node_types->{$child->{$NPROP_NODE_TYPE}} or next;
		if( my $si_atvl = $child->get_surrogate_id_attribute( 1 ) ) {
			if( $si_atvl eq $unqualified_value ) {
				return $child;
			}
		}
	}

	# Nothing was found, nothing more to search.

	return;
}

######################################################################

sub find_child_node_by_surrogate_id {
	my ($node, $target_attr_value) = @_;
	$node->{$NPROP_CONTAINER} or $node->_throw_error_message( 'SRT_N_FIND_CH_ND_BY_SID_NOT_IN_CONT' );
	defined( $target_attr_value ) or $node->_throw_error_message( 'SRT_N_FIND_CH_ND_BY_SID_NO_ARG_VAL' );
	ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
	if( defined( $target_attr_value->[0] ) ) {
		# The given surrogate id chain is relative to the current Node.
		my $curr_node = $node;
		ELEM: foreach my $chain_element (@{$target_attr_value}) {
			foreach my $child (@{$curr_node->{$NPROP_PRIM_CHILD_NREFS}}) {
				if( my $si_atvl = $child->get_surrogate_id_attribute( 1 ) ) {
					if( $si_atvl eq $chain_element ) {
						$curr_node = $child;
						next ELEM;
					}
				}
			}
			return;
		}
		return $curr_node;
	} else {
		# The given surrogate id chain starts at the root of the current Node's Container.
		return $node->{$NPROP_CONTAINER}->find_child_node_by_surrogate_id( $target_attr_value );
	}
}

######################################################################

sub get_relative_surrogate_id {
	my ($node, $self_attr_name) = @_;
	$node->{$NPROP_CONTAINER} or $node->_throw_error_message( 'SRT_N_GET_REL_SID_NOT_IN_CONT' );
	defined( $self_attr_name ) or $node->_throw_error_message( 'SRT_N_GET_REL_SID_NO_ARGS' );
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};
	my $exp_node_types = $type_info->{$TPI_AT_NREFS} && $type_info->{$TPI_AT_NREFS}->{$self_attr_name} or 
		$node->_throw_error_message( 'SRT_N_GET_REL_SID_INVAL_NM', { 'ATNM' => $self_attr_name } );
	my $attr_value_node = $node->{$NPROP_AT_NREFS}->{$self_attr_name} or return;
	my $attr_value_si_atvl = $attr_value_node->get_surrogate_id_attribute( 1 );
	if( my $search_path = $type_info->{$TPI_ANCES_ATCORS} && $type_info->{$TPI_ANCES_ATCORS}->{$self_attr_name} ) {
		# The value we are outputting is the child part of a correlated pair.
		if( $search_path->[-1] eq $C ) {
			# For simplicity, assume only one $C, which is at the end of the search path, as find_*() does.
			my $p_of_attr_value_node = $attr_value_node->{$NPROP_PP_NREF} or return; # linked Node not in tree
			my $p_of_attr_value_si_atvl = $p_of_attr_value_node->get_surrogate_id_attribute( 1 );
			# Now we have the info we need.
			return [$attr_value_si_atvl, $p_of_attr_value_si_atvl];
		} else {
			# There is a correlated search path, and it does not have a $C.
			return $attr_value_si_atvl;
		}
	}
	# If we get here, the value we are outputting is not the child part of a correlated pair.
	my %exp_p_node_types = map { ($_ => 1) } @{$exp_node_types};
	my $layered_search_result = $node->_find_node_by_surrogate_id_within_layers( \%exp_p_node_types, $attr_value_si_atvl );
	if( $layered_search_result and $layered_search_result eq $attr_value_node ) {
		return $attr_value_si_atvl;
	}
	# If we get here, the value we are outputting is not an ancestor's sibling.
	my %remotely_addressable_types = map { ($_ => $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR}) } 
		grep { $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR} } @{$exp_node_types};
	scalar( keys %remotely_addressable_types ) >= 1 or return; # Can't remotely address, so give up.
	# If we get here, we are allowed to remotely address a Node.
	# Now make sure attr-val Node has an ancestor of the expected type.
	my @attr_value_si_chain = ();
	my %exp_anc_node_types = map { ($_ => 1) } map { @{$_} } values %remotely_addressable_types;
	my $attr_value_anc_node = $attr_value_node;
	while( $attr_value_anc_node and !$exp_anc_node_types{$attr_value_anc_node->{$NPROP_NODE_TYPE}} ) {
		my $anc_si_atvl = $attr_value_anc_node->get_surrogate_id_attribute( 1 ) or return; # part of SI not defined yet
		push( @attr_value_si_chain, $anc_si_atvl );
		$attr_value_anc_node = $attr_value_anc_node->{$NPROP_PP_NREF};
	}
	$attr_value_anc_node or return; # attr-val does not have expected ancestor
	my $anc_si_atvl = $attr_value_anc_node->get_surrogate_id_attribute( 1 ) or return; # part of SI not defined yet
	push( @attr_value_si_chain, $anc_si_atvl ); # push required ancestor itself
	my $remote_search_result = $node->_find_node_by_surrogate_id_remotely( \%remotely_addressable_types, \@attr_value_si_chain );
	$remote_search_result and $remote_search_result eq $attr_value_node or return; # can't find ourself, oops
	# If we get here, the attr-value can be remotely addressed successfully.
	return \@attr_value_si_chain;
}

######################################################################

sub assert_deferrable_constraints {
	my ($node) = @_;
	# Only "Well Known" Nodes would get this invoked by Container.assert_deferrable_constraints().
	# "Alone" Nodes only get here when Node.assert_deferrable_constraints() 
	# is invoked directly by external code.
	$node->_assert_in_node_deferrable_constraints(); # can call on Alone, Well Known
	if( $node->{$NPROP_CONTAINER} ) {
		$node->_assert_parent_ref_scope_deferrable_constraints(); # call on Well Known only
		$node->_assert_child_comp_deferrable_constraints(); # call on Well Known only
	}
}

sub _assert_in_node_deferrable_constraints {
	# All assertions that can be performed on Nodes of all statuses are done in this method.
	my ($node) = @_;
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};

	# 1: Now assert constraints associated with Node-type details given in each 
	# "Attribute List" section of Language.pod.

	# 1.1: Assert that the NODE_ID attribute is set.
	unless( defined( $node->{$NPROP_NODE_ID} ) ) {
		# This can only possibly fail at deferrable-constraint assertion time with "Alone" Nodes; 
		# it is always-enforced for "Well Known" Nodes.
		$node->_throw_error_message( 'SRT_N_ASDC_NID_VAL_NO_SET' );
	}

	# 1.2: Assert that any primary parent ("PP") attribute is set.
	unless( defined( $node->{$NPROP_PP_NREF} ) or $type_info->{$TPI_PP_PSEUDONODE} ) {
		$node->_throw_error_message( 'SRT_N_ASDC_PP_VAL_NO_SET' );
	}

	# 1.3: Assert that any surrogate id ("SI") attribute is set.
	if( my $si_atnm = $type_info->{$TPI_SI_ATNM} ) {
		my (undef, $lit, $enum, $nref) = @{$si_atnm};
		# Skip 'id', as that's redundant with test 1.1.
		if( $lit ) {
			unless( defined( $node->{$NPROP_AT_LITERALS}->{$lit} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $lit } );
			}
		}
		if( $enum ) {
			unless( defined( $node->{$NPROP_AT_ENUMS}->{$enum} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $enum } );
			}
		}
		if( $nref ) {
			unless( defined( $node->{$NPROP_AT_NREFS}->{$nref} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $nref } );
			}
		}
	}

	# 1.4: Assert that any always-mandatory ("MA") attributes are set.
	if( my $mand_attrs = $type_info->{$TPI_MA_ATNMS} ) {
		my ($lits, $enums, $nrefs) = @{$mand_attrs};
		foreach my $attr_name (@{$lits}) {
			unless( defined( $node->{$NPROP_AT_LITERALS}->{$attr_name} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
			}
		}
		foreach my $attr_name (@{$enums}) {
			unless( defined( $node->{$NPROP_AT_ENUMS}->{$attr_name} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
			}
		}
		foreach my $attr_name (@{$nrefs}) {
			unless( defined( $node->{$NPROP_AT_NREFS}->{$attr_name} ) ) {
				$node->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
			}
		}
	}

	# 2: Now assert constraints associated with Node-type details given in each 
	# "Exclusive Attribute Groups List" section of Language.pod.

	if( my $mutex_atgps = $type_info->{$TPI_MUTEX_ATGPS} ) {
		foreach my $mutex_atgp (@{$mutex_atgps}) {
			my ($mutex_name, $lits, $enums, $nrefs, $is_mandatory) = @{$mutex_atgp};
			my @valued_candidates = ();
			foreach my $attr_name (@{$lits}) {
				if( defined( $node->{$NPROP_AT_LITERALS}->{$attr_name} ) ) {
					push( @valued_candidates, $attr_name );
				}
			}
			foreach my $attr_name (@{$enums}) {
				if( defined( $node->{$NPROP_AT_ENUMS}->{$attr_name} ) ) {
					push( @valued_candidates, $attr_name );
				}
			}
			foreach my $attr_name (@{$nrefs}) {
				if( defined( $node->{$NPROP_AT_NREFS}->{$attr_name} ) ) {
					push( @valued_candidates, $attr_name );
				}
			}
			if( scalar( @valued_candidates ) > 1 ) {
				$node->_throw_error_message( 'SRT_N_ASDC_MUTEX_TOO_MANY_SET', 
					{ 'NUMVALS' => scalar( @valued_candidates ), 
					'ATNMS' => "@valued_candidates", 'MUTEX' => $mutex_name } );
			}
			if( scalar( @valued_candidates ) == 0 ) {
				if( $is_mandatory ) {
					my @possible_candidates = (@{$lits}, @{$enums}, @{$nrefs});
					$node->_throw_error_message( 'SRT_N_ASDC_MUTEX_ZERO_SET', 
						{ 'ATNMS' => "@possible_candidates", 'MUTEX' => $mutex_name } );
				}
			}
		}
	}

	# 3: Now assert constraints associated with Node-type details given in each 
	# "Local Attribute Dependencies List" section of Language.pod.

	if( my $local_atdps_list = $type_info->{$TPI_LOCAL_ATDPS} ) {
		foreach my $local_atdps_item (@{$local_atdps_list}) {
			my ($dep_on_lit_nm, $dep_on_enum_nm, $dep_on_nref_nm, $dependencies) = @{$local_atdps_item};
			my $dep_on_attr_nm = $dep_on_lit_nm || $dep_on_enum_nm || $dep_on_nref_nm;
			my $dep_on_attr_val = $dep_on_lit_nm ? $node->{$NPROP_AT_LITERALS}->{$dep_on_lit_nm} :
				$dep_on_enum_nm ? $node->{$NPROP_AT_ENUMS}->{$dep_on_enum_nm} :
				$dep_on_nref_nm ? $node->{$NPROP_AT_NREFS}->{$dep_on_nref_nm} : undef;
			foreach my $dependency (@{$dependencies}) {
				my ($lits, $enums, $nrefs, $dep_on_enum_vals, $is_mandatory) = @{$dependency};
				my @valued_dependents = ();
				foreach my $attr_name (@{$lits}) {
					if( defined( $node->{$NPROP_AT_LITERALS}->{$attr_name} ) ) {
						push( @valued_dependents, $attr_name );
					}
				}
				foreach my $attr_name (@{$enums}) {
					if( defined( $node->{$NPROP_AT_ENUMS}->{$attr_name} ) ) {
						push( @valued_dependents, $attr_name );
					}
				}
				foreach my $attr_name (@{$nrefs}) {
					if( defined( $node->{$NPROP_AT_NREFS}->{$attr_name} ) ) {
						push( @valued_dependents, $attr_name );
					}
				}
				if( !defined( $dep_on_attr_val ) ) {
					# The dependency is undef/null, so all dependents must be undef/null.
					if( scalar( @valued_dependents ) > 0 ) {
						$node->_throw_error_message( 'SRT_N_ASDC_LATDP_DEP_ON_IS_NULL', 
							{ 'DEP_ON' => $dep_on_attr_nm, 'NUMVALS' => scalar( @valued_dependents ), 
							'ATNMS' => "@valued_dependents" } );
					}
					# If we get here, the tests have passed concerning this $dependency.
				} elsif( scalar( @{$dep_on_enum_vals} ) > 0 and 
						!scalar( grep { $_ eq $dep_on_attr_val } @{$dep_on_enum_vals} ) ) {
					# Not just any dependency value is acceptable for these dependents, and the
					# dependency has the wrong value for these dependents; the latter must be undef/null.
					if( scalar( @valued_dependents ) > 0 ) {
						$node->_throw_error_message( 'SRT_N_ASDC_LATDP_DEP_ON_HAS_WRONG_VAL', 
							{ 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
							'NUMVALS' => scalar( @valued_dependents ), 'ATNMS' => "@valued_dependents" } );
					}
					# If we get here, the tests have passed concerning this $dependency.
				} else {
					# Either any dependency value is acceptable for these dependents, or the valued 
					# dependency has the right value for these dependents; one of them may be set.
					if( scalar( @valued_dependents ) > 1 ) {
						$node->_throw_error_message( 'SRT_N_ASDC_LATDP_TOO_MANY_SET', 
							{ 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
							'NUMVALS' => scalar( @valued_dependents ), 'ATNMS' => "@valued_dependents" } );
					}
					if( scalar( @valued_dependents ) == 0 ) {
						if( $is_mandatory ) {
							my @possible_candidates = (@{$lits}, @{$enums}, @{$nrefs});
							$node->_throw_error_message( 'SRT_N_ASDC_LATDP_ZERO_SET', 
								{ 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
								'ATNMS' => "@possible_candidates" } );
						}
					}
					# If we get here, the tests have passed concerning this $dependency.
				}
			}
		}
	}

	# This is the end of the tests that can be performed on "Alone" Nodes.
}

sub _assert_parent_ref_scope_deferrable_constraints {
	# Assertions in this method can only be performed on Nodes in "Well Known" status.
	my ($node) = @_;
	my $type_info = $NODE_TYPES{$node->{$NPROP_NODE_TYPE}};

	# Assert that all non-PP Node-ref attributes of the current Node point to Nodes that 
	# are actually within the visible scope of the current Node.

	if( my $at_nrefs = $type_info->{$TPI_AT_NREFS} ) {
		foreach my $attr_name (keys %{$at_nrefs}) {
			my $given_p_node = $node->{$NPROP_AT_NREFS}->{$attr_name};
			if( defined( $given_p_node ) ) {
				my $given_p_node_si = $node->get_relative_surrogate_id( $attr_name );
				my $fetched_p_node = $node->find_node_by_surrogate_id( $attr_name, $given_p_node_si );
				unless( $fetched_p_node and $fetched_p_node eq $given_p_node ) {
					my $given_p_node_type = $given_p_node->{$NPROP_NODE_TYPE};
					my $given_p_node_id = $given_p_node->{$NPROP_NODE_ID};
					my $given_p_node_sidch = $given_p_node->get_surrogate_id_chain();
					$node->_throw_error_message( 'SRT_N_ASDC_NREF_AT_NONEX_SID', 
						{ 'ATNM' => $attr_name, 'EXPNTYPES' => $at_nrefs->{$attr_name}, 
						'PNTYPE' => $given_p_node_type, 'PNID' => $given_p_node_id, 
						'PSIDCH' => $given_p_node_sidch, 'PSID' => $given_p_node_si, } );
				}
			}
		}
	}

	# This is the end of the searching tests.
}

sub _assert_child_comp_deferrable_constraints {
	# Assertions in this method can only be performed on Nodes in "Well Known" status.
	my ($node_or_class, $pseudonode_name, $container) = @_;
	my $type_info = ref($node_or_class) ? 
		$NODE_TYPES{$node_or_class->{$NPROP_NODE_TYPE}} : 
		$PSEUDONODE_TYPES{$pseudonode_name};

	# First, gather a child list.

	my @parent_node_types = ();
	my @child_nodes = ();
	if( ref($node_or_class) ) {
		my @parent_nodes = ($node_or_class);
		my $curr_node = $node_or_class;
		while( my $wr_atnm = $NODE_TYPES{$curr_node->{$NPROP_NODE_TYPE}}->{$TPI_WR_ATNM} ) {
			if( $curr_node = $curr_node->{$NPROP_AT_NREFS}->{$wr_atnm} ) {
				unshift( @parent_nodes, $curr_node );
			} else {
				last; # avoid undef warnings in while expr due to unset $curr_node
			}
		}
		foreach my $parent_node (@parent_nodes) {
			push( @parent_node_types, $parent_node->{$NPROP_NODE_TYPE} );
			push( @child_nodes, @{$parent_node->{$NPROP_PRIM_CHILD_NREFS}} );
		}
	} else {
		push( @parent_node_types, $pseudonode_name );
		@child_nodes = @{$container->{$CPROP_PSEUDONODES}->{$pseudonode_name}};
	}

	# 1: Now assert that the surrogate id (SI) of each child Node is distinct.

	my %type_child_si = map { (%{$TYPE_CHILD_SI_ATNMS{$_}||{}}) } @parent_node_types;
	# Note: $TYPE_CHILD_SI_ATNMS only contains keys for [pseudo-|]Node types that can have primary-child Nodes.
	if( scalar( keys %type_child_si ) ) {
		my %examined_children = ();
		foreach my $child_node (@child_nodes) {
			my $child_node_type = $child_node->{$NPROP_NODE_TYPE};
			if( my $si_atnm = $type_child_si{$child_node_type} ) {
				my (undef, $lit, $enum, $nref) = @{$si_atnm};
				my $hash_key = 
					$lit ? $child_node->{$NPROP_AT_LITERALS}->{$lit} : 
					$enum ? $child_node->{$NPROP_AT_ENUMS}->{$enum} : 
					$nref ? $child_node->{$NPROP_AT_NREFS}->{$nref} : 
					$child_node->{$NPROP_NODE_ID};
				defined( $hash_key ) or next; # An error, but let a different test flag it.
				ref($hash_key) and next; # some comps by target lit/enum are known to be false errors; todo, see if any legit errors
				if( exists( $examined_children{$hash_key} ) ) {
					# Multiple Nodes have the same primary-parent and surrogate id.
					my $child_node_id = $child_node->{$NPROP_NODE_ID};
					my $matched_child_node = $examined_children{$hash_key};
					my $matched_child_node_type = $matched_child_node->{$NPROP_NODE_TYPE};
					my $matched_child_node_id = $matched_child_node->{$NPROP_NODE_ID};
					if( ref($node_or_class) ) {
						$node_or_class->_throw_error_message( 'SRT_N_ASDC_SI_NON_DISTINCT', 
							{ 'VALUE' => $hash_key, 
							'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
							'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
					} else {
						$node_or_class->_throw_error_message( 'SRT_N_ASDC_SI_NON_DISTINCT_PSN', 
							{ 'PSNTYPE' => $pseudonode_name, 'VALUE' => $hash_key, 
							'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
							'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
					}
				}
				$examined_children{$hash_key} = $child_node;
			}
		}
	}

	# 2: Now assert constraints associated with Node-type details given in each 
	# "Child Quantity List" section of Language.pod.

	if( my $child_quants = $type_info->{$TPI_CHILD_QUANTS} ) {
		foreach my $child_quant (@{$child_quants}) {
			my ($child_node_type, $range_min, $range_max) = @{$child_quant};
			my $child_count = 0;
			foreach my $child_node (@child_nodes) {
				$child_node->{$NPROP_NODE_TYPE} eq $child_node_type or next;
				$child_count ++;
			}
			if( $child_count < $range_min ) { 
				if( ref($node_or_class) ) {
					$node_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_FEW_SET', 
						{ 'COUNT' => $child_count, 'CNTYPE' => $child_node_type, 'EXPNUM' => $range_min } );
				} else {
					$node_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_FEW_SET_PSN', 
						{ 'COUNT' => $child_count, 'PSNTYPE' => $pseudonode_name, 'EXPNUM' => $range_min } );
				}
			}
			if( defined( $range_max ) and $child_count > $range_max ) {
				# SHORT CUT: We know that with all of our existing config data, 
				# there are no pseudo-Nodes that have a maximum limit for children.
				$node_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_MANY_SET', 
					{ 'COUNT' => $child_count, 'CNTYPE' => $child_node_type, 'EXPNUM' => $range_max } );
			}
		}
	}

	# 3: Now assert constraints associated with Node-type details given in each 
	# "Distinct Child Groups List" section of Language.pod.

	if( my $mudi_atgps = $type_info->{$TPI_MUDI_ATGPS} ) {
		foreach my $mudi_atgp (@{$mudi_atgps}) {
			my ($mudi_name, $mudi_atgp_subsets) = @{$mudi_atgp};
			my %examined_children = ();
			foreach my $mudi_atgp_subset (@{$mudi_atgp_subsets}) {
				my ($child_node_type, $lits, $enums, $nrefs) = @{$mudi_atgp_subset};
				CHILD: foreach my $child_node (@child_nodes) {
					$child_node->{$NPROP_NODE_TYPE} eq $child_node_type or next CHILD;
					my $hash_key = ',';
					foreach my $attr_name (@{$lits}) {
						my $val = $child_node->{$NPROP_AT_LITERALS}->{$attr_name};
						defined( $val ) or next CHILD; # null values are always distinct
						$val =~ s|,|<comma>|g; # avoid problems from literals containing delim chars
						$hash_key .= $val.',';
					}
					foreach my $attr_name (@{$enums}) {
						my $val = $child_node->{$NPROP_AT_ENUMS}->{$attr_name};
						defined( $val ) or next CHILD; # null values are always distinct
						$hash_key .= $val.',';
					}
					foreach my $attr_name (@{$nrefs}) {
						my $val = $child_node->{$NPROP_AT_NREFS}->{$attr_name};
						defined( $val ) or next CHILD; # null values are always distinct
						$hash_key .= $val.','; # stringifies to likes of 'HASH(NNN)'
					}
					if( exists( $examined_children{$hash_key} ) ) {
						# Multiple Nodes in same group have the same hash key, which 
						# means they are identical by means of the compared attributes.
						my $child_node_id = $child_node->{$NPROP_NODE_ID};
						my $matched_child_node = $examined_children{$hash_key};
						my $matched_child_node_type = $matched_child_node->{$NPROP_NODE_TYPE};
						my $matched_child_node_id = $matched_child_node->{$NPROP_NODE_ID};
						# SHORT CUT: We know that with all of our existing config data, 
						# there are no pseudo-Nodes with TPI_MUDI_ATGPS, only Nodes.
						$node_or_class->_throw_error_message( 'SRT_N_ASDC_MUDI_NON_DISTINCT', 
							{ 'VALUES' => $hash_key, 'MUDI' => $mudi_name, 
							'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
							'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
					}
					$examined_children{$hash_key} = $child_node;
				}
			}
		}
	}

	# TODO: more tests that examine multiple nodes together ...

	# This is the end of the tests that can be performed only on "Well Known" Nodes.
}

######################################################################

sub get_all_properties {
	return $_[0]->_get_all_properties( $_[1] );
}

sub _get_all_properties {
	my ($node, $links_as_si) = @_;
	my $at_nrefs_in = $node->{$NPROP_AT_NREFS};
	return {
		$NAMED_NODE_TYPE => $node->{$NPROP_NODE_TYPE},
		$NAMED_ATTRS => {
			$ATTR_ID => $node->{$NPROP_NODE_ID},
			# Note: We do not output $ATTR_PP => $NPROP_PP_NREF since it is redundant.
			%{$node->{$NPROP_AT_LITERALS}},
			%{$node->{$NPROP_AT_ENUMS}},
			(map { ( $_ => (
					$links_as_si ? 
					$node->get_relative_surrogate_id( $_ ) : 
					$at_nrefs_in->{$_}->{$NPROP_NODE_ID}
				) ) } 
				keys %{$at_nrefs_in}),
		},
		$NAMED_CHILDREN => [map { $_->_get_all_properties( $links_as_si ) } @{$node->{$NPROP_PRIM_CHILD_NREFS}}],
	};
}

sub get_all_properties_as_perl_str {
	return $_[0]->_serialize_as_perl( $_[0]->_get_all_properties( $_[1] ) );
}

sub get_all_properties_as_xml_str {
	return '<?xml version="1.0" encoding="UTF-8"?>'."\n".
		$_[0]->_serialize_as_xml( $_[0]->_get_all_properties( $_[1] ) );
}

######################################################################

sub build_node {
	my ($node, @args) = @_;
	my $container = $node->get_container() or 
		$node->_throw_error_message( 'SRT_N_BUILD_ND_NOT_IN_CONT' );
	return $container->build_node( @args );
}

sub build_child_node {
	my ($node, $node_type, $attrs) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS};
	}
	my $container = $node->get_container() or 
		$node->_throw_error_message( 'SRT_N_BUILD_CH_ND_NOT_IN_CONT' );
	return $container->_build_node_is_child_or_not( $node_type, $attrs, $node );
}

sub build_child_nodes {
	my ($node, $list) = @_;
	$list or return;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$node->build_child_node( ref($element) eq 'ARRAY' ? @{$element} : $element );
	}
}

sub build_child_node_tree {
	my ($node, $node_type, $attrs, $children) = @_;
	if( ref($node_type) eq 'HASH' ) {
		($node_type, $attrs, $children) = @{$node_type}{$NAMED_NODE_TYPE, $NAMED_ATTRS, $NAMED_CHILDREN};
	}
	my $new_node = $node->build_child_node( $node_type, $attrs );
	$new_node->build_child_node_trees( $children );
	return $new_node;
}

sub build_child_node_trees {
	my ($node, $list) = @_;
	$list or return;
	unless( ref($list) eq 'ARRAY' ) {
		$list = [ $list ];
	}
	foreach my $element (@{$list}) {
		$node->build_child_node_tree( ref($element) eq 'ARRAY' ? @{$element} : $element );
	}
}

######################################################################
######################################################################

1;
__END__

=head1 SYNOPSIS

I<The previous SYNOPSIS was removed; a new one will be written later.>

=head1 DESCRIPTION

The SQL::Routine (SRT) Perl 5 module provides a container object that allows
you to create specifications for any type of database task or activity (eg:
queries, DML, DDL, connection management) that look like ordinary routines
(procedures or functions) to your programs; all routine arguments are named.

SQL::Routine is trivially easy to install, since it is written in pure Perl and
its whole dependency chain consists of just 1 other pure Perl module.

Typical usage of this module involves creating or loading a single
SQL::Routine::Container object when your program starts up; this Container
would hold a complete representation of each database catalog that your program
uses (including details of all schema objects), plus complete representations
of all database invocations by your program; your program then typically just
reads from the Container while active to help determine its actions.

SQL::Routine can broadly represent, as an abstract syntax tree (a
cross-referenced hierarchy of nodes), code for any programming language, but
many of its concepts are only applicable to relational databases, particularly
SQL understanding databases.  It is reasonable to expect that a SQL:2003
compliant database should be able to implement nearly all SQL::Routine concepts
in its SQL stored procedures and functions, though SQL:2003 specifies some of
these concepts as optional features rather than core features.

This module has a multi-layered API that lets you choose between writing fairly
verbose code that performs faster, or fairly terse code that performs slower.

SQL::Routine is intended to be used by an application in place of using actual
SQL strings (including support for placeholders).  You define any desired
actions by stuffing atomic values into SQL::Routine objects, and then pass
those objects to a compatible bridging engine that will compile and execute
those objects against one or more actual databases.  Said bridge would be
responsible for generating any SQL or Perl code necessary to implement the
given SRT routine specification, and returning the result of its execution. 

The 'Rosetta' database portability library (a Perl 5 module) is a database
bridge that takes its instructions as SQL::Routine objects.  There may be other
modules that use SQL::Routine for that or other purposes.

SQL::Routine is also intended to be used as an intermediate representation of
schema definitions or other SQL that is being translated from one database
product to another.

This module is loosely similar to SQL::Statement, and is intended to be used in
all of the same ways.  But SQL::Routine is a lot more powerful and capable than
that module, as I most recently understand it, and is suitable for many uses
that the other module isn't.

SQL::Routine does not parse or generate any code on its own, nor does it talk
to any databases; it is up to external code that uses it to do this.

=head1 MATTERS OF PORTABILITY AND FEATURES

SQL::Routines are intended to represent all kinds of SQL, both DML and DDL,
both ANSI standard and RDBMS vendor extensions.  Unlike basically all of the
other SQL generating/parsing modules I know about, which are limited to basic
DML and only support table definition DDL, this class supports arbitrarily
complex select statements, with composite keys and unions, and calls to stored
functions; this class can also define views and stored procedures and triggers.
Some of the existing modules, even though they construct complete SQL, will
take/require fragments of SQL as input (such as "where" clauses)  By contrast,
SQL::Routine takes no SQL fragments.  All of its inputs are atomic, which
means it is also easier to analyse the objects for implementing a wider range
of functionality than previously expected; for example, it is much easier to
analyse any select statement and generate update/insert/delete statements for
the virtual rows fetched with it (a process known as updateable views).

Considering that each database product has its own dialect of SQL which it
implements, you would have to code SQL differently depending on which database
you are using.  One common difference is the syntax for specifying an outer
join in a select query.  Another common difference is how to specify that a
table column is an integer or a boolean or a character string.  Moreover, each
database has a distinct feature set, so you may be able to do tasks with one
database that you can't do with another.  In fact, some databases don't support
SQL at all, but have similar features that are accessible thorough alternate
interfaces. SQL::Routine is designed to represent a normalized superset of
all database features that one may reasonably want to use.  "Superset" means
that if even one database supports a feature, you will be able to invoke it
with this class. You can also reference some features which no database
currently implements, but it would be reasonable for one to do so later.
"Normalized" means that if multiple databases support the same feature but have
different syntax for referencing it, there will be exactly one way of referring
to it with SQL::Routine.  So by using this class, you will never have to
change your database-using code when moving between databases, as long as both
of them support the features you are using (or they are emulated).  That said,
it is generally expected that if a database is missing a specific feature that
is easy to emulate, then code which evaluates SQL::Routines will emulate it
(for example, emulating "left()" with "substr()"); in such cases, it is
expected that when you use such features they will work with any database.  For
example, if you want a model-specified BOOLEAN data type, you will always get
it, whether it is implemented  on a per-database-basis as a "boolean" or an
"int(1)" or a "number(1,0)".  Or a model-specified "STR_CHAR" data type you will
always get it, whether it is called "text" or "varchar2" or "sql_varchar".

SQL::Routine is intended to be just a stateless container for database
query or schema information.  It does not talk to any databases by itself and
it does not generate or parse any SQL; rather, it is intended that other third
party modules or code of your choice will handle this task.  In fact,
SQL::Routine is designed so that many existing database related modules
could be updated to use it internally for storing state information, including
SQL generating or translating modules, and schema management modules, and
modules which implement object persistence in a database.  Conceptually
speaking, the DBI module itself could be updated to take SQL::Routine
objects as arguments to its "prepare" method, as an alternative (optional) to
the SQL strings it currently takes.  Code which implements the things that
SQL::Routine describes can do this in any way that they want, which can
mean either generating and executing SQL, or generating Perl code that does the
same task and evaling it, should they want to (the latter can be a means of
emulation).  This class should make all of that easy.

SQL::Routine is especially suited for use with applications or modules that
make use of data dictionaries to control what they do.  It is common in
applications that they interpret their data dictionaries and generate SQL to
accomplish some of their work, which means making sure generated SQL is in the
right dialect or syntax, and making sure literal values are escaped correctly.
By using this module, applications can simply copy appropriate individual
elements in their data dictionaries to SQL::Routine properties, including
column names, table names, function names, literal values, host parameter names,
and they don't have to do any string parsing or assembling.

Now, I can only imagine why all of the other SQL generating/parsing modules
that I know about have excluded privileged support for more advanced database
features like stored procedures.  Either the authors didn't have a need for it,
or they figured that any other prospective users wouldn't need it, or they
found it too difficult to implement so far and maybe planned to do it later.  As
for me, I can see tremendous value in various advanced features, and so I have
included privileged support for them in SQL::Routine.  You simply have to
work on projects of a significant size to get an idea that these features would
provide a large speed, reliability, and security savings for you.  Look at many
large corporate or government systems, such as those which have hundreds of
tables or millions of records, and that may have complicated business logic
which governs whether data is consistent/valid or not.  Within reasonable
limits, the more work you can get the database to do internally, the better.  I
believe that if these features can also be represented in a database-neutral
format, such as what SQL::Routine attempts to do, then users can get the
full power of a database without being locked into a single vendor due to all
their investment in vendor-specific SQL stored procedure code.  If customers
can move a lot more easily, it will help encourage database vendors to keep
improving their products or lower prices to keep their customers, and users in
general would benefit.  So I do have reasons for trying to tackle the advanced
database features in SQL::Routine.

=head1 CLASSES IN THIS MODULE

This module is implemented by several object-oriented Perl 5 packages, each of
which is referred to as a class.  They are: B<SQL::Routine> (the module's
name-sake), B<SQL::Routine::Container> (aka B<Container>, aka B<Model>),
and B<SQL::Routine::Node> (aka B<Node>).

I<While all 3 of the above classes are implemented in one module for
convenience, you should consider all 3 names as being "in use"; do not create
any modules or packages yourself that have the same names.>

The Container and Node classes do most of the work and are what you mainly use.
The name-sake class mainly exists to guide CPAN in indexing the whole module,
but it also provides a set of stateless utility methods and constants that the
other two classes inherit, and it provides a few wrapper functions over the
other classes for your convenience; you never instantiate an object of
SQL::Routine itself.

=head1 STRUCTURE

The internal structure of a SQL::Routine object is conceptually a cross
between an XML DOM and an object-relational database, with a specific schema.
This module is implemented with two main classes that work together, Containers
and Nodes. The Container object is an environment or context in which Node
objects usually live.  A typical application will only need to create one
Container object (returned by the module's 'new_container' function), and then
a set of Nodes which live within that Container.  The Nodes are related
sometimes with single or multiple cardinality to each other.

SQL::Routine is expressly designed so that its data is easy to convert
between different representations, mainly in-memory data structures linked by
references, and multi-table record sets stored in relational databases, and
node sets in XML documents.  A Container corresponds to an XML document or a
complete database, and each Node corresponds to an XML node or a database
record.  Each Node has a specific node_type (a case-sensitive string), which
corresponds to a database table or an XML tag name.  See the
SQL::Routine::Language documentation file to see which ones exist.  The
node_type is set when the Node is created and it can not be changed later.

A Node has a specific set of allowed attributes that are determined by the
node_type, each of which corresponds to a database table column or an XML node
attribute.  Every Node has a unique 'id' attribute (a positive integer) by which
it is primarily referenced; that attribute corresponds to the database table's
single-column primary key, with the added distinction that every primary key
value in each table is distinct from every primary key value in every other
table.  Each other Node attribute is either a scalar value of some data type, or
an enumerated value, or a reference to another Node of a specific node_type,
which has a foreign-key constraint on it; those 3 attribute types are referred
to respectively as "literal", "enumerated", and "Node-ref".  Foreign-key
constraints are enforced by this module, so you will have to add Nodes in the
appropriate order, just as when adding records to a database.  Any Node which is
referenced in an attribute (cited in a foreign-key constraint) of another is a
parent of the other; as a corollary, the second Node is a child of the first. 
The order of child Nodes under a parent is the same as that in which the
parent-child relationship was assigned, unless you have afterwards used the
move_before_sibling() method to change this.

The order of child Nodes under a parent is often significant, so it is
important to preserve this sequence explicitly if you store a Node set in an
RDBMS, since databases do not consider record order to be significant or worth
remembering; you would add extra columns to store sequence numbers.  You do not
have to do any extra work when storing Nodes in XML, however, because XML does
consider node order to be significant and will preserve it.

When the terms "parent" and "child" are used by SQL::Routine in regards to the
relationships between Nodes, they are used within the context that a given Node
can have multiple parent Nodes; a given Node X is the parent of another given
Node Y because a Node-ref attribute of Node Y points to Node X.  Another term,
"primary parent", refers to the parent Node of a given Node Z that is referenced
by Z's "pp" Node-ref attribute, which most Node types have.  When SQL::Routines
are converted to a purely hierarchical or tree representation, such as to XML,
the primary parent Node becomes the single parent XML node.  For example, the
XML parent of a 'routine_var' Node is always a 'routine' Node, even though a
'scalar_domain' Node may also be referenced.  Nodes of a few types, such as
'view_expr', can have primary parent Nodes that are of the same Node type, and
can form trees of their own type; however, Nodes of most types can only have
Nodes of other types as their primary parents.

Some Node types do not have a "pp" attribute and Nodes of those types never have
primary parent Nodes; rather, all Nodes of those types will always have a
specific pseudo-Node as their primary parents; pseudo-Node primary parents are
not referenced in any attribute, and they can not be changed.  All 6
pseudo-Nodes have no attributes, even 'id', and only one of each exists; they
are created by default with the Container they are part of, forming the top 2
levels of the Node tree, and can not be removed.  They are: 'root' (the single
level-1 Node which is parent to the other pseudo-Nodes but no normal Nodes),
'elements' (parent to 'scalar_data_type' and 'row_data_type' Nodes),
'blueprints' (parent to 'catalog' and 'application' Nodes), 'tools' (parent to
'data_storage_product' and 'data_link_product' Nodes), 'sites' (parent to
'catalog_instance' and 'application_instance' Nodes), and 'circumventions'
(parent to 'sql_fragment' nodes).  All other Node types have normal Nodes as
primary parents.

You should look at the POD-only file named SQL::Routine::Language, which
comes with this distribution.  It serves to document all of the possible Node
types, with attributes, constraints, and allowed relationships with other Node
types.  As the SQL::Routine class itself has very few properties and
methods, all being highly generic (much akin to an XML DOM), the POD of this PM
file will only describe how to use said methods, and will not list all the
allowed inputs or constraints to said methods.  With only simple guidance in
Routine.pm, you should be able to interpret Language.pod to get all the
nitty gritty details.  You should also look at the tutorial or example files
which will be in the distribution when ready.  You could also learn something
from the code in or with other modules which sub-class or use this one.

=head1 FAULT TOLERANCE AND MULTI-THREADING SUPPORT

I<Disclaimer: The following claims assume that only this module's published API
is used, and that you do not set object properties directly or call private
methods, which Perl does not prevent.  It also assumes that the module is bug
free, and that any errors or warnings which appear while the code is running
are thrown explicitly by this module as part of its normal functioning.>

SQL::Routine is designed to ensure that the objects it produces are always
internally consistent, and that the data they contain is always well-formed,
regardless of the circumstances in which it is used.  You should be able to 
fetch data from the objects at any time and that data will be self-consistent 
and well-formed.  

This will not change regardless of what kind of bad input data you provide to
object methods or module functions.  Providing bad input data will cause the
module to throw an exception; if you catch this and the program continues
running (such as to chide the user and have them try entering correct input),
then the objects will remain un-corrupted and able to accept new input or give
proper output.  In most cases, the object will be in the same state as it was 
before the public method was called with the bad input.

This module does not use package variables at all, besides constants like
$VERSION, and all symbols ($@%) declared at file level are strictly constant
value declarations.  No object should ever step on another.

This module will allow a Node to be created piecemeal, such as when it is
storing details gathered one at a time from the user, and during this time some
mandatory Node properties may not be set, or pending links from this node to
others may not be validated.  However, until a Node has its required properties
set and/or its Node links are validated, no references will be made to this
Node from other Nodes; from their point of view it doesn't exist, and hence the
other Nodes are all consistent.

SQL::Routine is explicitly not thread-aware (thread-safe); it contains no
code to synchronize access to its objects' properties, such as semaphores or
locks or mutexes.  To internalize such things in an effective manner would have
made the code a lot more complex than it is now, without any clear benefits.  
However, this module can (and should) be used in multi-threaded environments 
where the application/caller code takes care of synchronizing access to its 
objects, especially if the application uses coarse-grained read or write locks.

The author's expectation is that this module will be mainly used in
circumstances where the majority of actions are reads, and there are very few
writes, such as with a data dictionary; perhaps all the writes on an object may
be when it is first created.  An application thread would obtain a read
lock/semaphore on a Container object during the period for which it needs to
ensure read consistency; it would block write lock attempts but not other read
locks.  It would obtain a write lock during the (usually short) period it needs
to change something, which blocks all other lock attempts (for read or write).

An example of this is a web server environment where each page request is being
handled by a distinct thread, and all the threads share one SQL::Routine
object; normally the object is instantiated when the server starts, and the
worker threads then read from it for guidance in using a common database.
Occasionally a thread will want to change the object, such as to correspond to
a simultaneous change to the database schema, or to the web application's data
dictionary that maps the database to application screens.  Under this
situation, the application's definitive data dictionary (stored partly or
wholly in a SQL::Routine) can occupy one place in RAM visible to all
threads, and each thread won't have to keep looking somewhere else such as in
the database or a file to keep up with the definitive copy.  (Of course, any
*changes* to the in-memory data dictionary should see a corresponding update to
a non-volatile copy, like in an on-disk database or file.)

I<Note that, while a nice thing to do may be to manage a course-grained lock in
SQL::Routine, with the caller invoking lock_to_read() or lock_to_write() or
unlock() methods on it, Perl's thread-E<gt>lock() mechanism is purely context
based; the moment lock_to_...() returns, the object has unlocked again.  Of
course, if you know a clean way around this, I would be happy to hear it.>

=head1 NODE EVOLUTION STATES

A SQL::Routine Node object always exists in one of 2 official ordered
states (which can conceptually be divided further into more states).  For now
we can call them "Alone" (1) and "Well Known" (2).  The set of legal operations
you can perform on a Node are different depending on its state, and a Node can
only transition between adjacent-numbered states one at a time.

When a new Node is created, using new_node(), it starts out "Alone"; it does
*not* live in a Container, and it is illegal to have any actual (Perl)
references between it and any other Node.  Nodes in this state can be built
(have their Node Id and other attributes set or changed) piecemeal with the
least processing overhead, and can be moved or exist independently of anything
else that SQL::Routine manages.  An "Alone" Node does not need to have its
Node Id set.  Any Node attributes which are conceptually references to other
Nodes are stored and read as Id numbers when the Node is "Alone"; also, no
confirmation has yet taken place that the referenced Nodes actually exist yet.
A Node may only be individually deleted when it is "Alone"; in this state it
will be garbage collected like any Perl variable when your own reference to it
goes away.

When you invoke the put_in_container() method on an "Alone" Node, giving it a
Container object as an argument, the Node will transition to the "Well Known"
state; you can move from "Well Known" to "Alone" using the complementary
take_from_container() method.  An "Well Known" Node lives in a Container, and
any attributes which refer to other Nodes now must be actual references, where
the existence of the other Node in the same Container is confirmed.  If any
conceptual references are set in a Node while it is "Alone", these will be
converted into actual references by put_in_container(), which will fail if any
can't be found; any other Nodes that this one references will now link back to
it in their own child lists.  The method take_from_container() will replace
references with Node Ids, and remove the parent-to-child references.  A Node
can only link to a Node in the same Container as itself.

Testing for the existence of mandatory Node attribute values is separate from 
the official Node state and can be invoked on a Node at any time.  None of the 
official Node states themselves will assert that any mandatory attributes are 
populated.  This testing is separate partly to make it easy for you to build 
Nodes piecemeal, though there are other practical reasons for it.

Note that all typical Node attributes can be read, set, replaced, or cleared at
any time regardless of the Node state; you can set them all either when the
Node is "Alone" or when it is "Well Known", as is your choice.  However, the
Node Id must always have a value when the Node is in a Container; if you want
to make a Node "Well Known" as early as possible, you simply have to set its
Node Id first.

=head1 NODE IDENTITY ATTRIBUTES

Every Node in a Container has a positive integer 'id' attribute whose value is
distinct for every Node in the Container, without regard for the Node type.
These 'id' attributes are used internally by SQL::Routine when linking child and
parent Nodes, but they have no use at all in any SQL statement strings that are
generated for a typical database engine.  Rather, SQL::Routine defines a second,
"surrogate id" ("SI") attribute for most Node types whose value actually is used
in SQL statement strings, and corresponds to the SQL:2003 concept of a "SQL
identifier" (such as a table name or a table column name).  This attribute name
varies by the Node type, but always looks like "si_*"; at least half of the
time, the exact name is "si_name".  If the SI attribute of a given Node is a
literal or enumerated attribute, then its value is used directly for SQL
strings; if it is a Node-ref attribute, then the SI attribute of the Node that
it points to is used likewise for SQL strings in place of the given Node (this 
will recurse until we hold a Node whose SI attribute is not a Node-ref).  In 
this way, SQL::Routine stores the "SQL identifier" value of each Node exactly 
once, and if it is edited then all SQL references to it automatically update.

I<To make SQL::Routine easier to use in the common cases, this module will treat
all Node types as having a surrogate id attribute.  In the few cases where a
Node type has no distinct attribute for it (such as "view_expr" Nodes), this
module will automatically use the 'id' (Node Id) attribute instead.>

When the surrogate identifier attribute of a single Node is referenced on its
own, this corresponds to the SQL:2003 concept of an "unqualified identifier". 
Under trivial circumstances, a Node can only be referenced by another Node using
the former's unqualified identifier if either the first Node is a member of the
second Node's primary-parent chain, or the first Node is a sibling of any member
of said pp chain, or the first node has a pseudo-Node primary parent.

SQL::Routine implements context sensitive constraints for what values a given
Node's surrogate identifier can have, and in what contexts other Nodes must be
located wherein it is valid for them to link to the given Node and be its
children; these go beyond the earlier-applied, more basic constraints that
restrict parent-child connections based on the Node types and/or presence in the
same Container of the Nodes involved.  The rules for SI values are similar to
the rules in typical programming languages concerning the declaration of
variables and the scope in which they are visible to be referenced.  One
constraint is that all Nodes which share the same primary parent Node or
pseudo-Node must have distinct SI values with respect to each other, regardless
of Node type (eg, all columns and indexes in a table must have distinct names).
Another constraint is described for general circumstances that in order for one
given Node to reference another as its parent Node, that other Node must be
either belong to the given Node's primary-parent chain, or it must be a direct
sibling of either the given Node or a Node in its primary-parent chain, or it
must be a primary-child of one of the primary parent Node's parent Nodes.

I<NOTE THAT FURTHER DOCUMENTATION ABOUT LINKING BY SURROGATE IDS IS PENDING.>

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.  

All SQL::Routine functions and methods are either "getters" (which read and
return or generate values but do not change the state of anything) or "setters"
(which change the state of something but do not return anything on success);
none do getting or setting conditionally based on their arguments.  While this
means there are more methods in total, I see this arrangement as being more
stable and reliable, plus each method is simpler and easier to understand or
use; argument lists and possible return values are also less variable and more
predictable.

All "setter" functions or methods which are supposed to change the state of
something will throw an exception on failure (usually from being given bad
arguments); on success, they officially have no return values.  A thrown
exception will always include details of what went wrong (and where and how) in
a machine-readable (and generally human readable) format, so that calling code
which catches them can recover gracefully.  The methods are all structured so
that they check all preconditions prior to changing any state information, and
so one can assume that upon throwing an exception, the Node and Container
objects are in a consistent or recoverable state at worst, and are completely
unchanged at best.

All "getter" functions or methods will officially return the value or construct
that was asked for; if said value doesn't (yet or ever) exist, then this means
the Perl "undefined" value.  When given bad arguments, generally this module's
"information" functions will return the undefined value, and all the other
functions/methods will throw an exception like the "setter" functions do.

Generally speaking, if SQL::Routine throws an exception, it means one of
two things: 1. Your own code is not invoking it correctly, meaning you have
something to fix; 2. You have decided to let it validate some of your input
data for you (which is quite appropriate).  

Note also that SQL::Routine is quite strict in its own argument checking,
both for internal simplicity and robustness, and so that code which *reads* 
data from it can be simpler.  If you want your own program to be more liberal
in what input it accepts, then you will have to bear the burden of cleaning up
or interpreting that input, or delegating such work elsewhere.  (Or perhaps 
someone may want to make a wrapper module to do this?)

=head1 CONSTRUCTOR WRAPPER FUNCTIONS

These functions are stateless and can be invoked off of either the module name,
or any package name in this module, or any object created by this module; they
are thin wrappers over other methods and exist strictly for convenience.

=head2 new_container()

	my $model = SQL::Routine->new_container();
	my $model2 = SQL::Routine::Container->new_container();
	my $model3 = SQL::Routine::Node->new_container();
	my $model4 = $model->new_container();
	my $model5 = $node->new_container();

This function wraps SQL::Routine::Container->new().

=head2 new_node( NODE_TYPE )

	my $node = SQL::Routine->new_node( 'table' );
	my $node2 = SQL::Routine::Container->new_node( 'table' );
	my $node3 = SQL::Routine::Node->new_node( 'table' );
	my $node4 = $model->new_node( 'table' );
	my $node5 = $node->new_node( 'table' );

This function wraps SQL::Routine::Node->new( NODE_TYPE ).

=head1 CONTAINER CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either the Container
class name or an existing Container object, with the same result.

=head2 new()

	my $model = SQL::Routine::Container->new();
	my $model2 = $model->new();

This "getter" function/method will create and return a single
SQL::Routine::Container (or subclass) object.

=head1 CONTAINER OBJECT METHODS

These methods are stateful and may only be invoked off of Container objects.

=head2 destroy()

	$model->destroy();

This "setter" method will destroy the Container object that it is invoked from,
and it will also destroy all of the Nodes inside that Container.  This method
exists because all Container objects (having 1 or more Node) contain circular
references between the Container and all of its Nodes.  You need to invoke this
method when you are done with a Container, or you will leak the memory it uses
when your external references to it go out of scope.  This method can be
invoked at any time and will not throw any exceptions.  When it has completed,
all external references to the Container or any of its Nodes will each point to
an empty (but still blessed) Perl hash.  I<See the CAVEATS documentation.>

=head2 auto_assert_deferrable_constraints([ NEW_VALUE ])

This method returns this Container's "auto assert deferrable constraints"
boolean property; if NEW_VALUE is defined, it will first set that property to
it.  When this flag is true, SQL::Routine's build_*() methods will
automatically invoke assert_deferrable_constraints() on the newly created Node,
if it is in this Container, prior to returning it.  The use of this method
helps isolate bad input bugs faster by flagging them closer to when they were
created; it is especially useful with the build*tree() methods.

=head2 auto_set_node_ids([ NEW_VALUE ])

This method returns this Container's "auto set node ids" boolean property; if
NEW_VALUE is defined, it will first set that property to it.  When this flag is
true, SQL::Routine will automatically generate and set a Node Id for a Node
that lacks one as soon as there is an attempt to put that Node in this
Container.  When this flag is false, a missing Node Id will cause an exception
to be raised instead.

=head2 may_match_surrogate_node_ids([ NEW_VALUE ])

This method returns this Container's "may match surrogate node ids" boolean
property; if NEW_VALUE is defined, it will first set that property to it.  When
this flag is true, SQL::Routine will accept a wider range of input values when
setting Node ref attribute values, beyond Node object references and integers
representing Node ids to look up; if other types of values are provided,
SQL::Routine will try to look up Nodes based on other attributes than the Id,
usually 'si_name', before giving up on finding a Node to link.

=head2 get_child_nodes([ NODE_TYPE ])

	my $ra_node_list = $model->get_child_nodes();
	my $ra_node_list = $model->get_child_nodes( 'catalog' );

This "getter" method returns a list of this Container's primary-child Nodes, in
a new array ref.  A Container's primary-child Nodes are defined as being all
Nodes in the Container whose Node Type defines them as always having a
pseudo-Node parent.  If the optional argument NODE_TYPE is defined, then only
child Nodes of that Node Type are returned; otherwise, all child Nodes are
returned.  All Nodes are returned in the same order they were added.

=head2 find_node_by_id( NODE_ID )

	my $node = $model->find_node_by_id( 1 );

This "getter" method searches for a member Node of this Container whose Node Id
matches the NODE_ID argument; if one is found then it is returned by reference;
if none is found, then undef is returned.  Since SQL::Routine guarantees that
all Nodes in a Container have a distinct Node Id, there will never be more than
one Node returned.  The speed of this search is also very fast, and takes the
same amount of time regardless of how many Nodes are in the Container.

=head2 find_child_node_by_surrogate_id( TARGET_ATTR_VALUE )

	my $data_type_node = $model->find_child_node_by_surrogate_id( 'str100' );

This "getter" method searches for a Node in this Container whose Surrogate Node
Id matches the TARGET_ATTR_VALUE argument; if one is found then it is returned
by reference; if none is found, then undef is returned.  The TARGET_ATTR_VALUE
argument is treated as an array-ref; if it is in fact not one, that single value
is used as a single-element array.  The search is multi-generational, one
generation more childwards per array element.  If the first array element is
undef, then we assume it follows the format that Node.get_surrogate_id_chain()
outputs; the first 3 elements are [undef,'root',<l2-psn>] and the 4th element
matches a Node that has a pseudo-Node parent.  If the first array element is not
undef, we treat it as the aforementioned 4th element.  If a valid <l2-psn> is
extracted, then only child Nodes of that pseudo-Node are searched; otherwise,
the child Nodes of all pseudo-Nodes are searched.

=head2 get_next_free_node_id()

	my $node_id = $model->get_next_free_node_id();

This "getter" method returns an integer which is valid for use as the Node ID
of a new Node that is going to be put in this Container.  Its value is 1 higher
than the highest Node ID for any Node that is already in the Container, or had
been before.  You can use this method like a sequence generator to produce Node
Ids for you rather than you producing them in some other way.  An example
situation when this method might be useful is if you are building a
SQL::Routine by scanning the schema of an existing database.

=head2 deferrable_constraints_are_tested()

	my $is_all_ok = $model->deferrable_constraints_are_tested();

This "getter" method will return the boolean "deferrable constraints are
tested" property of this Container.  This property is true when all "Well
Known" Nodes in this Container are known to be free of all data errors, both
individually and collectively.  This property is initially set to true when a
Container is new and empty; it is also set to true by
Container.assert_deferrable_constraints() when all of its tests complete without
finding any problems.  This property is set to false when any changes are made
to a "Well Known" Node in this Container, which includes moving the Node in to
or out of "Well Known" status.

=head2 assert_deferrable_constraints()

	$model->assert_deferrable_constraints();

This "getter" method implements several types of deferrable data validation, to
make sure that every "Well Known" Node in this Container is ready to be used,
both individually and collectively; it throws an exception if it can find
anything wrong.  Note that a failure with any one Node will cause the testing
of the whole set to abort, as the offending Node throws an exception which this
method doesn't catch; any untested Nodes could also have failed, so you will
have to re-run this method after fixing the problem.  This method will
short-circuit and not perform any tests if this Container's "deferrable
constraints are tested" property is true, so to avoid unnecessary repeated
tests due to redundant external invocations; this allows you to put validation
checks for safety everywhere in your program while avoiding a corresponding
performance hit.

=head1 NODE CONSTRUCTOR FUNCTIONS AND METHODS

This function/method is stateless and can be invoked off of either the Node
class name or an existing Node object, with the same result.

=head2 new( NODE_TYPE )

	my $node = SQL::Routine::Node->new( 'table' );
	my $node2 = $node->new( 'table' );

This "getter" function/method will create and return a single
SQL::Routine::Node (or subclass) object whose Node Type is given in the
NODE_TYPE (enum) argument, and all of whose other properties are defaulted to
an "empty" state.  A Node's type can only be set on instantiation and can not
be changed afterwards; only specific values are allowed, which you can see in
the SQL::Routine::Language documentation file.  This new Node does not yet
live in a Container, and will have to be put in one later before you can make
full use of it.  However, you can read or set or clear any or all of this new
Node's attributes (including the Node Id) prior to putting it in a Container,
making it easy to build one piecemeal before it is actually "used".  A Node can
not have any actual Perl references between it and other Nodes until it is in a
Container, and as such you can delete it simply by letting your own reference
to it be garbage collected.

=head1 NODE OBJECT METHODS

These methods are stateful and may only be invoked off of Node objects.  For
some of these, it doesn't matter whether the Node is in a Container or not. 
For others, this condition must be true or false for the method to be invoked,
or it will throw an exception (like for bad input).

=head2 delete_node()

This "setter" method will destroy the Node object that it is invoked from, if
it can.  You are only allowed to delete Nodes that are not inside Containers,
and which don't have child Nodes; failing this, you must remove the children
and then take this Node from its Container first.  Technically, this method
doesn't actually do anything (pure-Perl version) other than validate that you
are allowed to delete; when said conditions are met, the Node will be garbage
collected as soon as you lose your reference to it.

=head2 get_node_type()

	my $type = $node->get_node_type();

This "getter" method returns the Node Type scalar (enum) property of this Node.
 You can not change this property on an existing Node, but you can set it on a
new one.

=head2 get_node_id()

This "getter" method will return the integral Node Id property of this Node, 
if it has one.

=head2 clear_node_id()

This "setter" method will erase this Node's Id property if it can.  A Node's Id
may only be cleared if the Node is not in a Container.

=head2 set_node_id( NEW_ID )

This "setter" method will set or replace this Node's Id property if it can.  If 
this Node is in a Container, then the replacement will fail if some other Node 
with the same Node Type and Node Id already exists in the same Container.

=head2 get_primary_parent_attribute()

	my $parent = $node->get_primary_parent_attribute();

This "getter" method returns the primary parent Node of the current Node, if
there is one.

=head2 clear_primary_parent_attribute()

This "setter" method will clear this Node's primary parent attribute value, if
it has one.

=head2 set_primary_parent_attribute( ATTR_VALUE )

This "setter" method will set or replace this Node's primary parent attribute
value, if it has one, giving it the new value specified in ATTR_VALUE.

=head2 get_literal_attribute( ATTR_NAME )

This "getter" method will return the value for this Node's literal attribute named
in the ATTR_NAME argument.

=head2 get_literal_attributes()

This "getter" method will fetch all of this Node's literal attributes, 
returning them in a Hash ref.

=head2 clear_literal_attribute( ATTR_NAME )

This "setter" method will clear this Node's literal attribute named in
the ATTR_NAME argument.

=head2 clear_literal_attributes()

This "setter" method will clear all of this Node's literal attributes.

=head2 set_literal_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's literal attribute named in
the ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_literal_attributes( ATTRS )

This "setter" method will set or replace multiple Node literal attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_literal_attribute() for each key/value
pair.

=head2 get_enumerated_attribute( ATTR_NAME )

This "getter" method will return the value for this Node's enumerated attribute
named in the ATTR_NAME argument.

=head2 get_enumerated_attributes()

This "getter" method will fetch all of this Node's enumerated attributes,
returning them in a Hash ref.

=head2 clear_enumerated_attribute( ATTR_NAME )

This "setter" method will clear this Node's enumerated attribute named in the
ATTR_NAME argument.

=head2 clear_enumerated_attributes()

This "setter" method will clear all of this Node's enumerated attributes.

=head2 set_enumerated_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's enumerated attribute named in
the ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_enumerated_attributes( ATTRS )

This "setter" method will set or replace multiple Node enumerated attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_enumerated_attribute() for each key/value
pair.

=head2 get_node_ref_attribute( ATTR_NAME[, GET_TARGET_SI] )

This "getter" method will return the value for this Node's node attribute named
in the ATTR_NAME argument, if it is set, or undef if it isn't.  If the current
Node is not in a Container, then the returned value is a Node Id number.  If the
current Node is in a Container, then the returned value is a Node ref by
default; if the optional boolean argument GET_TARGET_SI is true, then this
method will instead lookup (recursively) and return the target Node's literal or
enumerated surrogate id value (a single value, not a chain).

=head2 get_node_ref_attributes([ GET_TARGET_SI ])

This "getter" method will fetch all of this Node's node attributes, returning
them in a Hash ref.  Each attribute value is returned in the format specified by
get_node_ref_attribute( <attr-name>, GET_TARGET_SI ).

=head2 clear_node_ref_attribute( ATTR_NAME )

This "setter" method will clear this Node's node attribute named in the
ATTR_NAME argument; the other Node being referred to will also have its child
list reciprocal link to the current Node cleared.

=head2 clear_node_ref_attributes()

This "setter" method will clear all of this Node's node attributes; see 
the clear_node_ref_attribute() documentation for the semantics.

=head2 set_node_ref_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's node attribute named in the
ATTR_NAME argument, giving it the new value specified in ATTR_VALUE (if it is
different).  If the attribute was previously valued, this method will first
invoke clear_node_ref_attribute() on it.  When setting a new value, if the
current Node is in a Container, then it will also add the current Node to the
other Node's child list.  ATTR_VALUE may either be a perl reference to a Node,
or a Node Id value, or a Surrogate Node Id value (either a single value or an id
chain array ref); the last one will only work if this Node is in a Container
that matches Nodes by surrogate ids.

=head2 set_node_ref_attributes( ATTRS )

This "setter" method will set or replace multiple Node node attributes,
whose names and values are specified by keys and values of the ATTRS hash ref
argument; this method will invoke set_node_ref_attribute() for each key/value
pair.

=head2 get_surrogate_id_attribute([ GET_TARGET_SI ])

This "getter" method will return the value for this Node's surrogate id
attribute.  The GET_TARGET_SI argument is relevant only for Node-ref attributes;
its effects are explained by get_node_ref_attribute().

=head2 clear_surrogate_id_attribute()

This "setter" method will clear this Node's surrogate id attribute value.

=head2 set_surrogate_id_attribute( ATTR_VALUE )

This "setter" method will set or replace this Node's surrogate id attribute
value, giving it the new value specified in ATTR_VALUE.

=head2 get_attribute( ATTR_NAME[, GET_TARGET_SI] )

	my $curr_val = $node->get_attribute( 'si_name' );

This "getter" method will return the value for this Node's attribute named in
the ATTR_NAME argument.  The GET_TARGET_SI argument is relevant only for
Node-ref attributes; its effects are explained by get_node_ref_attribute().

=head2 get_attributes([ GET_TARGET_SI ])

	my $rh_attrs = $node->get_attributes();

This "getter" method will fetch all of this Node's attributes, returning them
in a Hash ref.  The GET_TARGET_SI argument is relevant only for Node-ref
attributes; its effects are explained by get_node_ref_attribute().

=head2 clear_attribute( ATTR_NAME )

This "setter" method will clear this Node's attribute named in the ATTR_NAME
argument.

=head2 clear_attributes()

This "setter" method will clear all of this Node's attributes.

=head2 set_attribute( ATTR_NAME, ATTR_VALUE )

This "setter" method will set or replace this Node's attribute named in the
ATTR_NAME argument, giving it the new value specified in ATTR_VALUE.

=head2 set_attributes( ATTRS )

	$node->set_attributes( $rh_attrs );

This "setter" method will set or replace multiple Node attributes, whose names
and values are specified by keys and values of the ATTRS hash ref argument;
this method will invoke set_attribute() for each key/value pair.

=head2 get_container()

	my $model = $node->get_container();

This "getter" method returns the Container object which this Node lives in, if
any.

=head2 put_in_container( NEW_CONTAINER )

This "setter" method will put the current Node into the Container given as the
NEW_CONTAINER argument if it can, which moves the Node from "Alone" to "Well
Known" status.

=head2 take_from_container()

This "setter" method will take the current Node from its Container if it can,
which moves the Node from "Well Known" to "Alone" status.

=head2 move_before_sibling( SIBLING[, PARENT] )

This "setter" method allows you to change the order of child Nodes under a
common parent Node; specifically, it moves the current Node to a position just
above/before the sibling Node specified in the SIBLING Node ref argument, if it
can.  You can only invoke it on a Node that is in a Container, since that is the
only time it exists in its parent's child list at all.  Since a Node can have
multiple parent Nodes (and the sibling likewise), the optional PARENT argument
lets you specify which parent's child list you want to move in; if you do not
provide an PARENT value, then the current Node's primary parent Node (or
pseudo-Node) is used, if possible.  This method will throw an exception if the
current Node and the specified sibling or parent Nodes are not appropriately
related to each other (parent <-> child).  If you want to move the current Node
to follow the sibling instead, then invoke this method on the sibling.

=head2 get_child_nodes([ NODE_TYPE ])

	my $ra_node_list = $table_node->get_child_nodes();
	my $ra_node_list = $table_node->get_child_nodes( 'table_field' );

This "getter" method returns a list of this Node's primary-child Nodes, in a new
array ref.  If the optional argument NODE_TYPE is defined, then only child Nodes
of that Node Type are returned; otherwise, all child Nodes are returned.  All
Nodes are returned in the same order they were added.

=head2 add_child_node( NEW_CHILD )

	$node->add_child_node( $child );

This "setter" method allows you to add a new primary-child Node to this Node,
which is provided as the single NEW_CHILD Node ref argument.  The new child Node
is appended to the list of existing child Nodes, and the current Node becomes
the new or first primary parent Node of NEW_CHILD.

=head2 add_child_nodes( LIST )

	$model->add_child_nodes( [$child1,$child2] );
	$model->add_child_nodes( $child );

This "setter" method takes an array ref in its single LIST argument, and calls
add_child_node() for each element found in it.

=head2 get_referencing_nodes([ NODE_TYPE ])

	my $ra_node_list = $row_data_type_node->get_referencing_nodes();
	my $ra_node_list = $row_data_type_node->get_referencing_nodes( 'table' );

This "getter" method returns a list of this Node's link-child Nodes (which are
other Nodes that refer to this one in a non-PP nref attribute) in a new array
ref.  If the optional argument NODE_TYPE is defined, then only child Nodes of
that Node Type are returned; otherwise, all child Nodes are returned.  All Nodes
are returned in the same order they were added.

=head2 get_surrogate_id_chain()

This "getter" method can only be invoked in a Node in a container, and it
returns the current Node's surrogate id chain as an array ref.  This method's
return value is conceptually like what get_relative_surrogate_id() returns
except that it is defined in an absolute context rather than a relative context,
making it less suitable for serializing models that are subsequently
reorganized; it is also much longer.

=head2 find_node_by_surrogate_id( SELF_ATTR_NAME, TARGET_ATTR_VALUE )

	my $table_node = $table_index_node->find_node_by_surrogate_id( 'f_table', 'person' );

This "getter" method may only be called on Nodes that are in a Container, and
the first argument SELF_ATTR_NAME must match a valid Node-ref attribute name of
the current Node (but not the 'pp' attribute); it throws an exception if either
condition is not met.  This method searches for a member Node of this Node's
host Container whose type makes it legally linkable by the SELF_ATTR_NAME
attribute and whose Surrogate Node Id matches the TARGET_ATTR_VALUE argument
(which may be either a scalar or a Perl array ref); if one is found then it is
returned by reference; if none is found, or multiple matching Nodes were found
within the same scope, then undef is returned.  The search is context sensitive
and scoped; it starts by examining the Nodes that are closest to this Node's
location in its Container's Node tree and then spreads outwards, looking within
just the locations that are supposed to be visible to this Node.  Variations on
this search method come into play for Node types that are connected to the
concepts of "wrapper attribute", "ancestor attribute correlation", and "remotely
addressable types".  Note that it is illegal to use the return value of
get_surrogate_id_chain() as a TARGET_ATTR_VALUE with this method; you can give
the return value of get_relative_surrogate_id(), however.

=head2 find_child_node_by_surrogate_id( TARGET_ATTR_VALUE )

	my $table_index_node = $table_node->find_child_node_by_surrogate_id( 'fk_father' );

This "getter" method may only be called on Nodes that are in a Container, or it
throws an exception.  This method searches for a primary-child Node of the
current Node whose Surrogate Node Id matches the TARGET_ATTR_VALUE argument; if
one is found then it is returned by reference; if none is found, then undef is
returned.  The TARGET_ATTR_VALUE argument is treated as an array-ref; if it is
in fact not one, that single value is used as a single-element array.  The
search is multi-generational, one generation more childwards per array element;
the first element matches a child of the invoked Node, the next element the
child of the first matched child, and so on.  If said array ref has undef as its
first element, then this method behaves the same as
Container.find_child_node_by_surrogate_id( TARGET_ATTR_VALUE ).

=head2 get_relative_surrogate_id( SELF_ATTR_NAME )

	my $table_si_value = $table_index_node->get_relative_surrogate_id( 'f_table' );
	my $view_src_col_si_value = $view_expr_node->get_relative_surrogate_id( 'name' );

This "getter" method may only be called on Nodes that are in a Container, and
the first argument SELF_ATTR_NAME must match a valid Node-ref attribute name of
the current Node (but not the 'pp' attribute); it throws an exception if either
condition is not met.  This method returns a Surrogate Node Id value (which may
be either a scalar or a Perl array ref) which is appropriate for passing to
find_node_by_surrogate_id() as its TARGET_ATTR_VALUE such that the current
attribute value would be "found" by it, assuming the current attribute value is
valid; if none can be determined, then undef is returned.  This method's return
value is conceptually like what get_surrogate_id_chain() returns except that it
is defined in a relative context rather than an absolute context, making it more
suitable for serializing models that are subsequently reorganized; it is also
much shorter.

=head2 assert_deferrable_constraints()

This "getter" method implements several types of deferrable data validation, to
make sure that this Node is ready to be used; it throws an exception if it can
find anything wrong.  This method can be used on any Node regardless of its
current node evolution state, but that state does affect which tests are
performed; "Well Known" Nodes get all the tests, while "Alone" Nodes skip some.

=head1 CONTAINER OR NODE METHODS FOR DEBUGGING

The following 3 "getter" methods can be invoked either on Container or Node
objects, and will return a tree-arranged structure having the contents of a
Node and all its children (to the Nth generation).  The previous statement
assumes that all the 'children' are in the same Container, which means that a
Node's parent is aware of it; if a child is not in the Container, the
assumption is that said Node is still being constructed, and neither it nor its
children will be included in the output.  If you invoke the 3 methods on a
Node, then that Node will be the root of the returned structure. If you invoke
them on a Container, then a few pseudo-Nodes will be output with all the normal
Nodes in the Container as their children.

=head2 get_all_properties([ LINKS_AS_SI ])

	$rh_node_properties = $container->get_all_properties();
	$rh_node_properties = $container->get_all_properties( 1 );
	$rh_node_properties = $node->get_all_properties();
	$rh_node_properties = $node->get_all_properties( 1 );

This method returns a deep copy of all of the properties of this object as
non-blessed Perl data structures.  These data structures are also arranged in a
tree, but they do not have any circular references.  For each Node, all
attributes are output, including 'id', except for the 'pp' attribute, which is
redundant; the value of the 'pp' attribute can be determined from an output
Node's context, as it is equal to the 'id' of the parent Node.  The main
purpose, currently, of get_all_properties() is to make it easier to debug or
test this class; it makes it easier to see at a glance whether the other class
methods are doing what you expect.  The output of this method should also be
easy to serialize or unserialize to strings of Perl code or xml or other things,
should you want to compare your results easily by string compare; see
"get_all_properties_as_perl_str()" and "get_all_properties_as_xml_str()".  If
the optional boolean argument LINKS_AS_SI is true, then each Node ref attribute
will be output as the target Node's surrogate id value, as returned by
get_relative_surrogate_id(), if it has a valued surrogate id attribute; if the
argument is false, or a Node doesn't have a valued surrogate id attribute, then
its Node id will be output by default.  The output can alternately be passed as
a parameter to build_container() so that the method creates a clone of the
original Container, where applicable; iff the output was generated using
LINKS_AS_SI, then build_container() will need to be given a true MATCH_SURR_IDS
argument (its other boolean args can all be false).

=head2 get_all_properties_as_perl_str([ LINKS_AS_SI ])

	$perl_code_str = $container->get_all_properties_as_perl_str();
	$perl_code_str = $container->get_all_properties_as_perl_str( 1 );
	$perl_code_str = $node->get_all_properties_as_perl_str();
	$perl_code_str = $node->get_all_properties_as_perl_str( 1 );

This method is a wrapper for get_all_properties( LINKS_AS_SI ) that serializes
its output into a pretty-printed string of Perl code, suitable for humans to
read.  You should be able to eval this string and produce the original
structure.

=head2 get_all_properties_as_xml_str([ LINKS_AS_SI ])

	$xml_doc_str = $container->get_all_properties_as_xml_str();
	$xml_doc_str = $container->get_all_properties_as_xml_str( 1 );
	$xml_doc_str = $node->get_all_properties_as_xml_str();
	$xml_doc_str = $node->get_all_properties_as_xml_str( 1 );

This method is a wrapper for get_all_properties( LINKS_AS_SI ) that serializes
its output into a pretty-printed string of XML, suitable for humans to read.

=head1 CONTAINER OR NODE FUNCTIONS AND METHODS FOR RAPID DEVELOPMENT

The following 7 "setter" functions and methods should assist more rapid
development of code that uses SQL::Routine, at the cost that the code would run
a bit slower (SQL::Routine has to search for info behind the scenes that it
would otherwise get from you).  These methods are implemented as wrappers over
other SQL::Routine methods, and allow you to accomplish with one method call
what otherwise requires about 4-10 method calls, meaning your code base is
significantly smaller (unless you implement your own simplifying wrapper
functions, which is recommended in some situations).

For convenience, these methods can take both positional and named arguments; if
the first actual positional argument is a Perl hash-ref, then the method
assumes it contains all the arguments in named format; otherwise, the method
assumes all of the actual positional arguments are the arguments.  All of the 
argument names are uppercased strings that are identical to what is shown in 
the positional-oriented argument list documentation.

Note that when a subroutine is referred to as a "function", it is stateless and
can be invoked off of either a class name or class object; when a subroutine is
called a "method", it can only be invoked off of Container or Node objects.

=head2 build_lonely_node( NODE_TYPE[, ATTRS] )

	my $nodeP = SQL::Routine->build_lonely_node( 'catalog', { 'id' => 1, } ); 
	my $nodeN = SQL::Routine->build_lonely_node( 
		{ 'NODE_TYPE' => 'catalog', 'ATTRS' => { 'id' => 1, } } ); 

This function will create and return a new Node that is "Alone" (not in a
Container), whose type is specified in NODE_TYPE, and also set its attributes.
The ATTRS argument is processed by Node.set_attributes() if it is provided; a
Node id can also be provided this way, or the Node id won't be set.  If ATTRS
is defined but not a Hash ref, then this method will build a new one having a
single element, where the value is ATTRS and the key is either 'id' or the new
Node's surrogate id attribute name, depending on whether the value looks like a
valid Node id.

=head2 build_node( NODE_TYPE[, ATTRS] )

This method is like build_lonely_node() except that it must be invoked off of a
Container, or a Node that is in a Container, and the newly created Node will be
put in that Container.  This method will throw an exception if it is invoked on
a Node that is not in a Container.

=head2 build_child_node( NODE_TYPE[, ATTRS] )

This method is like build_node() except that it will set the new Node's primary
parent to be the Node that this method was invoked on, using add_child_node();
if this method was invoked on a Container, then it will work only for new Nodes
that would have a pseudo-Node as their primary parent.  When creating a Node
with this method, you do not set any PP candidates in ATTRS (if a 'pp' attribute
is given in ATTRS, it will be ignored).

=head2 build_child_nodes( LIST )

This method takes an array ref in its single LIST argument, and calls
build_child_node() for each element found in it; if LIST is not an array ref,
then one is constructed with LIST as its single element.  This method does not
return anything.

=head2 build_child_node_tree( NODE_TYPE[, ATTRS][, CHILDREN] )

This method is like build_child_node() except that it will recursively create
all of the child Nodes of the new Node as well; CHILDREN is a Perl array-ref
(or, if defined, it will become the single element of a new array-ref), and
build_child_node_tree() will be called for each of its elements after their
parent has been fully created.  In the context of SQL::Routine, a "Node tree"
or "tree" consists of one arbitrary Node and all of its "descendants".  If
invoked on a Container object, this method will recognize any pseudo-Node names
given in 'NODE_TYPE' and simply move on to creating the child Nodes of that
pseudo-Node, rather than throwing an error exception for an invalid Node type. 
Therefore, you can populate a whole Container with one call to this method. 
This method returns the root Node that it creates, if NODE_TYPE was a valid
Node type; it returns the Container instead if NODE_TYPE is a pseudo-Node name.

=head2 build_child_node_trees( LIST )

This method takes an array ref in its single LIST argument, and calls
build_child_node_tree() for each element found in it; if LIST is not an array
ref, then one is constructed with LIST as its single element.  This method does
not return anything.

=head2 build_container( LIST[, AUTO_ASSERT[, AUTO_IDS[, MATCH_SURR_IDS]]] )

This function is like build_child_node_trees( LIST ) except that it will also
create and return a new Container object that holds the newly built Nodes.  If
any of the optional boolean arguments [AUTO_ASSERT, AUTO_IDS, MATCH_SURR_IDS]
are true, then the corresponding flag properties of the new Container will be
set to true prior to creating any Nodes.  This function is the exact opposite of
Container.get_all_properties(); you should be able to take the Hash-ref output
of Container.get_all_properties(), give it to build_container(), and end up with
a clone of the original Container.

=head1 INFORMATION FUNCTIONS AND METHODS

These "getter" functions/methods are all intended for use by programs that want
to dynamically interface with SQL::Routine, especially those programs that
will generate a user interface for manual editing of data stored in or accessed
through SQL::Routine constructs.  It will allow such programs to continue
working without many changes while SQL::Routine itself continues to evolve.
In a manner of speaking, these functions/methods let a caller program query as
to what 'schema' or 'business logic' drive this class.  These functions/methods
are all deterministic and stateless; they can be used in any context and will
always give the same answers from the same arguments, and no object properties
are used.  You can invoke them from any kind of object that SQL::Routine
implements, or straight off of the class name itself, like a 'static' method.  
All of these functions return the undefined value if they match nothing.

=head2 valid_enumerated_types([ ENUM_TYPE ])

This function by default returns a list of the valid enumerated types that
SQL::Routine recognizes; if the optional ENUM_TYPE argument is given, it
just returns true if that matches a valid type, and false otherwise.

=head2 valid_enumerated_type_values( ENUM_TYPE[, ENUM_VALUE] )

This function by default returns a list of the values that SQL::Routine
recognizes for the enumerated type given in the ENUM_TYPE argument; if the
optional ENUM_VALUE argument is given, it just returns true if that matches an
allowed value, and false otherwise.

=head2 valid_node_types([ NODE_TYPE ])

This function by default returns a list of the valid Node Types that
SQL::Routine recognizes; if the optional NODE_TYPE argument is given, it
just returns true if that matches a valid type, and false otherwise.

=head2 node_types_with_pseudonode_parents([ NODE_TYPE ])

This function by default returns a Hash ref where the keys are the names of the
Node Types whose primary parents can only be pseudo-Nodes, and where the values
name the pseudo-Nodes they are the children of; if the optional NODE_TYPE
argument is given, it just returns the pseudo-Node for that Node Type.

=head2 node_types_with_primary_parent_attributes([ NODE_TYPE ])

This function by default returns a Hash ref where the keys are the names of the
Node Types that have a primary parent ("pp") attribute, and where the values are
the Node Types that values for that attribute must be; if the optional NODE_TYPE
argument is given, it just returns the valid Node Types for the primary parent
attribute of that Node Type.  Since there may be multiple valid primary parent
Node Types for the same Node Type, an array ref is returned that enumerates the
valid types; often there is just one element; if the array ref has no elements,
then all Node Types are valid.

=head2 valid_node_type_literal_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
literal attributes that SQL::Routine recognizes for the Node Type given in
the NODE_TYPE argument, and where the values are the literal data types that
values for those attributes must be; if the optional ATTR_NAME argument is
given, it just returns the literal data type for the named attribute.

=head2 valid_node_type_enumerated_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
enumerated attributes that SQL::Routine recognizes for the Node Type given
in the NODE_TYPE argument, and where the values are the enumerated data types
that values for those attributes must be; if the optional ATTR_NAME argument is
given, it just returns the enumerated data type for the named attribute.

=head2 valid_node_type_node_ref_attributes( NODE_TYPE[, ATTR_NAME] )

This function by default returns a Hash ref where the keys are the names of the
node attributes that SQL::Routine recognizes for the Node Type given in the
NODE_TYPE argument, and where the values are the Node Types that values for
those attributes must be; if the optional ATTR_NAME argument is given, it just
returns the Node Type for the named attribute.  Since there may be multiple
valid Node Types for the same attribute, an array ref is returned that
enumerates the valid types; often there is just one element; if the array ref
has no elements, then all Node Types are valid.

=head2 valid_node_type_surrogate_id_attributes([ NODE_TYPE ])

This function by default returns a Hash ref where the keys are the names of the
Node Types that have a surrogate id attribute, and where the values are the
names of that attribute; if the optional NODE_TYPE argument is given, it just
returns the surrogate id attribute for that Node Type.  Note that a few Node
types don't have distinct surrogate id attributes; for those, this method will
return 'id' as the surrogate id attribute name.

=head1 BUGS

This module is currently in pre-alpha development status, meaning that some
parts of it will be changed in the near future, perhaps in incompatible ways;
however, I believe that any further incompatible changes will be small.  The
current state is analogous to 'developer releases' of operating systems; it is
reasonable to being writing code that uses this module now, but you should be
prepared to maintain it later in keeping with API changes.  This module also
does not yet have full code coverage in its tests, though the most commonly
used areas are covered.  All of this said, I plan to move this module into
alpha development status within the next few releases, once I start using it in
a production environment myself.

=head1 CAVEATS

All SQL::Routine::Container objects contain circular references by design
(or more specifically, when 1 or more Node is in one).  When you are done with
a Container object, you should explicitly call its "destroy()" method prior to
letting your references to it go out of scope, or you will leak the memory it
used.  Note that some early versions of SQL::Routine had wrapped the actual
Container object in a second object that was auto-destroyed when it went out of
scope, but this cludge was later removed due to adding worse problems than it
solved, such as Containers being destroyed too early.

You can not use surrogate id values that look like valid Node ids (that are
positive integers) since some methods won't do what you expect when given such
values.  Nodes having such surrogate id values won't be matched by values
passed to set_node_ref_attribute(), directly or indirectly.  That method only
tries to lookup a Node by its surrogate id if its argument doesn't look like a
Node ref or a Node id.  Similarly, the build*() methods will decide whether to
interpret a defined but non-Node-ref ATTRS argument as a Node id or a surrogate
id based on its looking like a valid Node id or not.  You should rarely
encounter this caveat, though, since you would never use a number as a "SQL
identifier" in normal cases, and that is only technically possible with a
"delimited SQL identifier".

=head1 SEE ALSO

L<perl(1)>, L<SQL::Routine::L::en>, L<SQL::Routine::Language>,
L<SQL::Routine::API_C>, L<Locale::KeyedText>, L<Rosetta>,
L<Rosetta::Engine::Generic>, L<Rosetta::Utility::SQLBuilder>,
L<Rosetta::Utility::SQLParser>, L<DBI>, L<SQL::Statement>, L<SQL::Translator>,
L<SQL::YASP>, L<SQL::Generator>, L<SQL::Schema>, L<SQL::Abstract>,
L<SQL::Snippet>, L<SQL::Catalog>, L<DB::Ent>, L<DBIx::Abstract>,
L<DBIx::AnyDBD>, L<DBIx::DBSchema>, L<DBIx::Namespace>, L<DBIx::SearchBuilder>,
L<TripleStore>, L<Data::Table>, and various other modules.

=cut
