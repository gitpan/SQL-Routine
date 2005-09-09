#!perl
use 5.008001; use utf8; use strict; use warnings;

package SQL::Routine;
use version; our $VERSION = qv('0.70.0');

use Scalar::Util;
use only 'Locale::KeyedText' => '1.6.0-';

######################################################################
######################################################################

# Names of properties for objects of the SQL::Routine::Container (interface) class are declared here:
my $CPROP_STORAGE = 'storage'; # the SQL::Routine::ContainerStorage object that we shelter
    # This is a strong Perl ref so a ContainerStorage will persist as long as any Container interface of it.
my $CPROP_AUTO_ASS_DEF_CON = 'auto_ass_def_con'; # boolean - false by def
    # When this flag is true, SQL::Routine's build_*() methods will
    # automatically invoke assert_deferrable_constraints() on each Node newly created 
    # by way of this Container interface (or child Node interfaces), prior to returning it.  The use of this method
    # helps isolate bad input bugs faster by flagging them closer to when they were
    # created; it is especially useful with the build*tree() methods.
my $CPROP_AUTO_SET_NIDS = 'auto_set_nids'; # boolean - false by def
    # When this flag is true, SQL::Routine will automatically generate and set a Node Id for 
    # a Node being created for this Container interface when there is no explicit Id given as a Node.new() argument.
    # When this flag is false, a missing Node Id argument will cause an exception to be raised instead.
my $CPROP_MAY_MATCH_SNIDS = 'may_match_snids'; # boolean - false by def
    # When this flag is true, SQL::Routine will accept a wider range of input values when setting 
    # Node ref attribute values, beyond Node object references and integers representing Node ids to 
    # look up; if other types of values are provided, SQL::Routine will try to look up Nodes based 
    # on their Surrogate Id attribute, usually 'si_name', before giving up on finding a Node to link.
my $CPROP_EXPLICIT_GROUPS = 'explicit_groups'; # hash ("Group",Group) - 
    # A list of refs to any Groups associated with this Container interface that were explicitly defined by users.
    # These Perl refs are weak-refs so an explicit Group disappears when all external refs go away.
my $CPROP_DEFAULT_GROUP = 'default_group'; # the SQL::Routine::Group object imposing default mutex for edited Nodes
    # This is a strong Perl ref so a Container's default Group lasts for as long as the Container does; 
    # only the default Group has a weak Perl ref to its Container, to avoid circular refs; other groups have strong refs back.
    # Note that this Group may never be exposed to the public like the explicit Groups, or they may mess with it.

# Names of properties for objects of the SQL::Routine::ContainerStorage class are declared here:
my $CSPROP_ALL_NODES = 'all_nodes'; # hash of NodeStorage refs - find any NodeStorage by its node_id quickly
my $CSPROP_PSEUDONODES = 'pseudonodes'; # hash of arrays of NodeStorage refs
    # This property is for remembering the insert order of Nodes having hardwired pseudonode parents
my $CSPROP_NEXT_FREE_NID = 'next_free_nid'; # uint - next free node id
    # Value is one higher than the highest NodeStorage ID that is or was in use by a NodeStorage in this ContainerStorage.
    # This value can never be decremented during a ContainerStorage's life, or edited by external code.
my $CSPROP_EDIT_COUNT = 'edit_count'; # uint - count of distinct edits to this ContainerStorage's NodeStorage set
    # Value is zero for brand new ContainerStorage, is inc by 1 for each time a NodeStorage is edited, added, deleted.
    # Actual value isn't important; simply whether it has changed or not between two arbitrary 
    # samplings is what's important; the sampler knows something changed since they last sampled.
    # This value can never be decremented during a ContainerStorage's life, or edited by external code.
my $CSPROP_DEF_CON_TESTED = 'def_con_tested'; # sint - what 'edit_count' was when def con last success
    # When this property is equal to the 'edit_count' property, there have been no changes to the Nodes 
    # in this ContainerStorage since the last time assert_deferrable_constraints() passed its tests, 
    # and so the current Nodes are still valid.  It is used internally by 
    # assert_deferrable_constraints() to make code faster by avoiding un-necessary 
    # repeated tests from multiple external ContainerStorage.assert_deferrable_constraints() calls.
    # It is set to negative-one (-1) on a new empty ContainerStorage, and is only ever updated 
    # by ContainerStorage.assert_deferrable_constraints() following a pass of the full test suite.
    # This value can never be edited by external code.
#my $CSPROP_CURR_NODE = 'curr_node'; # ref to a NodeStorage; used when "streaming" to or from XML
    # I may instead make a new inner class for this, and there can be several of these 
    # per container, such as if multiple streams are working in different areas at once.
# To do: have attribute to indicate an edit in progress 
    # or that there was a failure resulting in inconsistent data;
    # this may be set by a method which partly implements a data change 
    # which is not backed out of, before that function throws an exception;
    # this property may best just be inside the thrown Locale::KeyedText object;
    # OTOH, if users have coarse-grained locks on Containers for threads, we could have a property,
    # since a call to an editing method would check and clear that before the thread releases lock

# Names of properties for objects of the SQL::Routine::Node (interface) class are declared here:
my $NPROP_STORAGE = 'storage'; # the SQL::Routine::NodeStorage object that we interface for
    # This Perl ref is a weak-ref so wrapper doesn't prevent auto-destruct of a NodeStorage by its existence
my $NPROP_CONTAINER = 'container'; # ref to Container interface this Node interface lives in
    # This is a strong Perl ref so a model will last as long as any external ref to a Container or Node or Group interface.

# Names of properties for objects of the SQL::Routine::NodeStorage class are declared here:
    # The C version will have the following comprise fields in a NodeStorage struct;
    # all fields will be integers or memory references or enums; none will be strings.
my $NSPROP_CONSTOR = 'constor'; # ref to ContainerStorage this NodeStorage lives in
    # These Perl refs are weak-refs since they point 'upwards' to 'parent' objects.
    # C version of this would be a pointer to a ContainerStorage struct
my $NSPROP_NODE_TYPE = 'node_type'; # str (enum) - what type of NodeStorage this is, can not change once set
    # The NodeStorage type is the only property which absolutely can not change, and is set when object created.
    # (All other NodeStorage properties start out undefined or false, and are set separately from object creation.)
    # C version of this will be an enumerated value.
my $NSPROP_NODE_ID = 'node_id'; # uint - unique identifier attribute for this node within container+type
    # C version of this will be an unsigned integer.
    # This property corresponds to a NodeStorage attribute named 'id'.
my $NSPROP_PP_NSREF = 'pp_nsref'; # NodeStorage - special NodeStorage attr which points to primary-parent NodeStorage in the same ContainerStorage
    # These Perl refs are weak-refs since they point 'upwards' to 'parent' objects.
    # C version of this will be a NodeStorage pointer.
    # This property is analagous to a non-existing AT_NSREFS element whose name is "pp".
    # When converting to XML, this "pp" attribute won't become an XML attr (redundant)
my $NSPROP_AT_LITERALS = 'at_literals'; # hash (enum,lit) - attrs of NodeStorage which are non-enum, non-id literal values
    # C version of this will be an array (pointer) of Literal structs.
    # We already know what all the attributes can be for each node type, so the size of the array 
    # will be fixed and known in advance, allowing it to be all allocated with one malloc() call.
    # Each attribute struct would be at a specific array index; 
    # C macros/constants will give names to the indices, like with the hash keys for the above.
my $NSPROP_AT_ENUMS = 'at_enums'; # hash (enum,enum) - attrs of NodeStorage which are enumerated values
    # C version of this will be an array (pointer) of enumerated values.
my $NSPROP_AT_NSREFS = 'at_nsrefs'; # hash (enum,NodeStorage) - attrs of NodeStorage which point to other Nodes in the same ContainerStorage
    # These Perl refs are weak-refs since they point 'upwards' to 'parent' objects.
    # C version of this will be an array (pointer) of NodeStorage pointers.
my $NSPROP_PRIM_CHILD_NSREFS = 'prim_child_nsrefs'; # array - list of refs to other Nodes having actual refs to this one
    # We use this to reciprocate actual refs from the PP_NSREF property of other Nodes to us.
    # When converting to XML, only child Nodes linked through PRIM_CHILD_NSREFS are rendered.
    # Every NodeStorage in this list is guaranteed to appear in this list exactly once.
my $NSPROP_LINK_CHILD_NSREFS = 'link_child_nsrefs'; # array - list of refs to other Nodes having actual refs to this one
    # We use this to reciprocate actual refs from the AT_NSREFS property of other Nodes to us.
    # When converting to XML, only child Nodes linked through PRIM_CHILD_NSREFS are rendered.
    # C version will be a double-linked list with each element representing a NodeStorage struct.
    # Each NodeStorage in this list may possibly appear in this list more than once.
    # It is important to ensure that if a NodeStorage links to us multiple times (via multiple AT_NSREFS) 
    # then we include the other NodeStorage in our child list just as many times; eg: 2 here means 2 back; 
    # however, when rendering to XML, we only render a NodeStorage once, and not as many times as linked; 
    # it is also possible that we may never be put in this situation from real-world usage.
    # Note that in the above situation, a normalized child list would have the above two links sitting 
    # adjacent to each other; however, calls to set_attribute() won't do this, but rather 
    # append new links to the end of the list.  In the interest of simplicity, any method that wants to 
    # change the order of a child list should also normalize any multiple same-child occurrances.
my $NSPROP_ATT_WRITE_BLOCKS = 'att_write_blocks'; # hash ("Group",Group) - 
    # A list of refs to any Groups imposing a 'write block' on us.
    # These Perl refs are weak-refs; a Group's impositions disappear when all external refs to it go away.
    # Note that 0..3 of this and the following properties may link to the same Group, if its corresponding IS...BLOCK prop is true.
my $NSPROP_ATT_PC_ADD_BLOCKS = 'att_pc_add_blocks'; # hash ("Group",Group) - 
    # A list of refs to any Groups imposing a 'child addition block' on us.
    # These Perl refs are weak-refs; a Group's impositions disappear when all external refs to it go away.
my $NSPROP_ATT_LC_ADD_BLOCKS = 'att_lc_add_blocks'; # hash ("Group",Group) - 
    # A list of refs to any Groups imposing a 'reference addition block' on us.
    # These Perl refs are weak-refs; a Group's impositions disappear when all external refs to it go away.
my $NSPROP_ATT_MUTEX = 'att_mutex'; # Group - 
    # Ref to a Group imposing a 'mutex' on us.
    # This Perl ref is a weak-ref; a Group's impositions disappear when all external refs to it go away.

# Names of properties for objects of the SQL::Routine::Group (interface) class are declared here:
    # Note that there is no SQL::Routine::GroupStorage class; a Group is always specific to a Container interface.
my $GPROP_CONTAINER = 'container'; # ref to Container interface this Group interface lives in
    # This is a strong Perl ref so a model will last as long as any external ref to a Container or Node or Group interface; 
    # the sole exception to this is when the Group is used as a Container interface's "default mutex"; then this is a 
    # weak ref because the Container's link to us is a strong ref only in that case; the default mutex has no external refs.
my $GPROP_MEMBER_NSREFS = 'member_nsrefs'; # hash ("NodeStorage", NodeStorage) - explicit member Nodes of this Group
    # These are the actual Nodes that belong to this Group, which the Container interface wants to work with as a whole for awhile.
    # These Perl refs are weak-refs to not prevent auto-destruct of the NodeStorages.
my $GPROP_IS_WRITE_BLOCK = 'is_write_block'; # boolean - 
    # When this is true, no Container interface (not even ours) may edit or delete our member Nodes.  
my $GPROP_IS_PC_ADD_BLOCK = 'is_pc_add_block'; # boolean -
    # When this is true, no Container interface (not even ours) may add primary-child Nodes to our member Nodes.  
my $GPROP_IS_LC_ADD_BLOCK = 'is_lc_add_block'; # boolean -
    # When this is true, no Container interface (not even ours) may add link-child Nodes to our member Nodes.  
my $GPROP_IS_MUTEX = 'is_mutex'; # boolean -
    # When this is true, no Container interface besides may see our member Nodes.  

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
        INTO
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

# For each pair of related enumerated types, this says which specific values in 
# one type go with which specific values of another type in a parent-child 
# relationship.  Level 1 is the parent enum type name; level 2 is the child enum 
# type name; level 3 is a parent type value; level 4 is the child type value.
my %P_C_REL_ENUMS = (
    'standard_routine' => {
        'standard_routine_context' => {
            'CATALOG_OPEN' => { map { ($_ => 1) } qw( CONN_CX ) },
            'CATALOG_CLOSE' => { map { ($_ => 1) } qw( CONN_CX ) },
            'CATALOG_PING' => { map { ($_ => 1) } qw( CONN_CX ) },
            'CATALOG_ATTACH' => { map { ($_ => 1) } qw( CONN_CX ) },
            'CATALOG_DETACH' => { map { ($_ => 1) } qw( CONN_CX ) },
            'SCHEMA_LIST' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_INFO' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_CREATE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_DELETE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_CLONE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_LIST' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_INFO' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_CREATE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_DELETE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_CLONE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_LIST' => { map { ($_ => 1) } qw(  ) },
            'SEQU_INFO' => { map { ($_ => 1) } qw(  ) },
            'SEQU_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'SEQU_CREATE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_DELETE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_CLONE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_LIST' => { map { ($_ => 1) } qw(  ) },
            'TABLE_INFO' => { map { ($_ => 1) } qw(  ) },
            'TABLE_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'TABLE_CREATE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_DELETE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_CLONE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_LIST' => { map { ($_ => 1) } qw(  ) },
            'VIEW_INFO' => { map { ($_ => 1) } qw(  ) },
            'VIEW_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'VIEW_CREATE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_DELETE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_CLONE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_LIST' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_INFO' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_CREATE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_DELETE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_CLONE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'USER_LIST' => { map { ($_ => 1) } qw(  ) },
            'USER_INFO' => { map { ($_ => 1) } qw(  ) },
            'USER_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'USER_CREATE' => { map { ($_ => 1) } qw(  ) },
            'USER_DELETE' => { map { ($_ => 1) } qw(  ) },
            'USER_CLONE' => { map { ($_ => 1) } qw(  ) },
            'USER_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'USER_GRANT' => { map { ($_ => 1) } qw(  ) },
            'USER_REVOKE' => { map { ($_ => 1) } qw(  ) },
            'REC_FETCH' => { map { ($_ => 1) } qw(  ) },
            'REC_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'REC_INSERT' => { map { ($_ => 1) } qw(  ) },
            'REC_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'REC_DELETE' => { map { ($_ => 1) } qw(  ) },
            'REC_REPLACE' => { map { ($_ => 1) } qw(  ) },
            'REC_CLONE' => { map { ($_ => 1) } qw(  ) },
            'REC_LOCK' => { map { ($_ => 1) } qw(  ) },
            'REC_UNLOCK' => { map { ($_ => 1) } qw(  ) },
            'CURSOR_OPEN' => { map { ($_ => 1) } qw( CURSOR_CX ) },
            'CURSOR_CLOSE' => { map { ($_ => 1) } qw( CURSOR_CX ) },
            'CURSOR_FETCH' => { map { ($_ => 1) } qw( CURSOR_CX ) },
            'SELECT' => { map { ($_ => 1) } qw( CONN_CX ) },
            'INSERT' => { map { ($_ => 1) } qw( CONN_CX ) },
            'UPDATE' => { map { ($_ => 1) } qw( CONN_CX ) },
            'DELETE' => { map { ($_ => 1) } qw( CONN_CX ) },
            'COMMIT' => { map { ($_ => 1) } qw( CONN_CX ) },
            'ROLLBACK' => { map { ($_ => 1) } qw( CONN_CX ) },
            'LOCK' => { map { ($_ => 1) } qw(  ) },
            'UNLOCK' => { map { ($_ => 1) } qw(  ) },
            'PLAIN' => { map { ($_ => 1) } qw(  ) },
            'THROW' => { map { ($_ => 1) } qw(  ) },
            'TRY' => { map { ($_ => 1) } qw(  ) },
            'CATCH' => { map { ($_ => 1) } qw(  ) },
            'IF' => { map { ($_ => 1) } qw(  ) },
            'ELSEIF' => { map { ($_ => 1) } qw(  ) },
            'ELSE' => { map { ($_ => 1) } qw(  ) },
            'SWITCH' => { map { ($_ => 1) } qw(  ) },
            'CASE' => { map { ($_ => 1) } qw(  ) },
            'OTHERWISE' => { map { ($_ => 1) } qw(  ) },
            'FOREACH' => { map { ($_ => 1) } qw(  ) },
            'FOR' => { map { ($_ => 1) } qw(  ) },
            'WHILE' => { map { ($_ => 1) } qw(  ) },
            'UNTIL' => { map { ($_ => 1) } qw(  ) },
            'MAP' => { map { ($_ => 1) } qw(  ) },
            'GREP' => { map { ($_ => 1) } qw(  ) },
            'REGEXP' => { map { ($_ => 1) } qw(  ) },
            'LOOP' => { map { ($_ => 1) } qw(  ) },
            'CONDITION' => { map { ($_ => 1) } qw(  ) },
            'LOGIC' => { map { ($_ => 1) } qw(  ) },
        },
        'standard_routine_arg' => {
            'CATALOG_LIST' => { map { ($_ => 1) } qw( RECURSIVE ) },
            'CATALOG_INFO' => { map { ($_ => 1) } qw( LINK_BP RECURSIVE ) },
            'CATALOG_VERIFY' => { map { ($_ => 1) } qw( LINK_BP RECURSIVE ) },
            'CATALOG_CREATE' => { map { ($_ => 1) } qw( LINK_BP RECURSIVE ) },
            'CATALOG_DELETE' => { map { ($_ => 1) } qw( LINK_BP ) },
            'CATALOG_CLONE' => { map { ($_ => 1) } qw( SOURCE_LINK_BP DEST_LINK_BP ) },
            'CATALOG_MOVE' => { map { ($_ => 1) } qw( SOURCE_LINK_BP DEST_LINK_BP ) },
            'CATALOG_OPEN' => { map { ($_ => 1) } qw( LOGIN_NAME LOGIN_PASS ) },
            'CATALOG_ATTACH' => { map { ($_ => 1) } qw( LINK_BP ) },
            'CATALOG_DETACH' => { map { ($_ => 1) } qw( LINK_BP ) },
            'SCHEMA_LIST' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_INFO' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_CREATE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_DELETE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_CLONE' => { map { ($_ => 1) } qw(  ) },
            'SCHEMA_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_LIST' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_INFO' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_CREATE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_DELETE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_CLONE' => { map { ($_ => 1) } qw(  ) },
            'DOMAIN_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_LIST' => { map { ($_ => 1) } qw(  ) },
            'SEQU_INFO' => { map { ($_ => 1) } qw(  ) },
            'SEQU_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'SEQU_CREATE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_DELETE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_CLONE' => { map { ($_ => 1) } qw(  ) },
            'SEQU_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_LIST' => { map { ($_ => 1) } qw(  ) },
            'TABLE_INFO' => { map { ($_ => 1) } qw(  ) },
            'TABLE_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'TABLE_CREATE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_DELETE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_CLONE' => { map { ($_ => 1) } qw(  ) },
            'TABLE_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_LIST' => { map { ($_ => 1) } qw(  ) },
            'VIEW_INFO' => { map { ($_ => 1) } qw(  ) },
            'VIEW_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'VIEW_CREATE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_DELETE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_CLONE' => { map { ($_ => 1) } qw(  ) },
            'VIEW_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_LIST' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_INFO' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_CREATE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_DELETE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_CLONE' => { map { ($_ => 1) } qw(  ) },
            'ROUTINE_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'USER_LIST' => { map { ($_ => 1) } qw(  ) },
            'USER_INFO' => { map { ($_ => 1) } qw(  ) },
            'USER_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'USER_CREATE' => { map { ($_ => 1) } qw(  ) },
            'USER_DELETE' => { map { ($_ => 1) } qw(  ) },
            'USER_CLONE' => { map { ($_ => 1) } qw(  ) },
            'USER_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'USER_GRANT' => { map { ($_ => 1) } qw(  ) },
            'USER_REVOKE' => { map { ($_ => 1) } qw(  ) },
            'REC_FETCH' => { map { ($_ => 1) } qw(  ) },
            'REC_VERIFY' => { map { ($_ => 1) } qw(  ) },
            'REC_INSERT' => { map { ($_ => 1) } qw(  ) },
            'REC_UPDATE' => { map { ($_ => 1) } qw(  ) },
            'REC_DELETE' => { map { ($_ => 1) } qw(  ) },
            'REC_REPLACE' => { map { ($_ => 1) } qw(  ) },
            'REC_CLONE' => { map { ($_ => 1) } qw(  ) },
            'REC_LOCK' => { map { ($_ => 1) } qw(  ) },
            'REC_UNLOCK' => { map { ($_ => 1) } qw(  ) },
            'RETURN' => { map { ($_ => 1) } qw( RETURN_VALUE ) },
            'CURSOR_FETCH' => { map { ($_ => 1) } qw( INTO ) },
            'SELECT' => { map { ($_ => 1) } qw( SELECT_DEFN INTO ) },
            'INSERT' => { map { ($_ => 1) } qw( INSERT_DEFN ) },
            'UPDATE' => { map { ($_ => 1) } qw( UPDATE_DEFN ) },
            'DELETE' => { map { ($_ => 1) } qw( DELETE_DEFN ) },
            'LOCK' => { map { ($_ => 1) } qw(  ) },
            'UNLOCK' => { map { ($_ => 1) } qw(  ) },
            'PLAIN' => { map { ($_ => 1) } qw(  ) },
            'THROW' => { map { ($_ => 1) } qw(  ) },
            'TRY' => { map { ($_ => 1) } qw(  ) },
            'CATCH' => { map { ($_ => 1) } qw(  ) },
            'IF' => { map { ($_ => 1) } qw(  ) },
            'ELSEIF' => { map { ($_ => 1) } qw(  ) },
            'ELSE' => { map { ($_ => 1) } qw(  ) },
            'SWITCH' => { map { ($_ => 1) } qw(  ) },
            'CASE' => { map { ($_ => 1) } qw(  ) },
            'OTHERWISE' => { map { ($_ => 1) } qw(  ) },
            'FOREACH' => { map { ($_ => 1) } qw(  ) },
            'FOR' => { map { ($_ => 1) } qw(  ) },
            'WHILE' => { map { ($_ => 1) } qw(  ) },
            'UNTIL' => { map { ($_ => 1) } qw(  ) },
            'MAP' => { map { ($_ => 1) } qw(  ) },
            'GREP' => { map { ($_ => 1) } qw(  ) },
            'REGEXP' => { map { ($_ => 1) } qw(  ) },
            'LOOP' => { map { ($_ => 1) } qw(  ) },
            'CONDITION' => { map { ($_ => 1) } qw(  ) },
            'LOGIC' => { map { ($_ => 1) } qw(  ) },
            'CAST' => { map { ($_ => 1) } qw( CAST_TARGET CAST_OPERAND ) },
            'NOT' => { map { ($_ => 1) } qw( FACTOR ) },
            'AND' => { map { ($_ => 1) } qw( FACTORS ) },
            'OR' => { map { ($_ => 1) } qw( FACTORS ) },
            'XOR' => { map { ($_ => 1) } qw( FACTORS ) },
            'EQ' => { map { ($_ => 1) } qw( LHS RHS ) },
            'NE' => { map { ($_ => 1) } qw( LHS RHS ) },
            'LT' => { map { ($_ => 1) } qw( LHS RHS ) },
            'GT' => { map { ($_ => 1) } qw( LHS RHS ) },
            'LE' => { map { ($_ => 1) } qw( LHS RHS ) },
            'GE' => { map { ($_ => 1) } qw( LHS RHS ) },
            'IS_NULL' => { map { ($_ => 1) } qw( ARG ) },
            'NOT_NULL' => { map { ($_ => 1) } qw( ARG ) },
            'COALESCE' => { map { ($_ => 1) } qw( TERMS ) },
            'SWITCH' => { map { ($_ => 1) } qw( LOOK_IN CASES DEFAULT ) },
            'LIKE' => { map { ($_ => 1) } qw( LOOK_IN LOOK_FOR FIXED_LEFT FIXED_RIGHT ) },
            'ADD' => { map { ($_ => 1) } qw( TERMS ) },
            'SUB' => { map { ($_ => 1) } qw( START REMOVE ) },
            'MUL' => { map { ($_ => 1) } qw( FACTORS ) },
            'DIV' => { map { ($_ => 1) } qw( DIVIDEND DIVISOR ) },
            'DIVI' => { map { ($_ => 1) } qw( DIVIDEND DIVISOR ) },
            'MOD' => { map { ($_ => 1) } qw( DIVIDEND DIVISOR ) },
            'ROUND' => { map { ($_ => 1) } qw( START PLACES ) },
            'ABS' => { map { ($_ => 1) } qw( OPERAND ) },
            'POWER' => { map { ($_ => 1) } qw( RADIX EXPONENT ) },
            'LOG' => { map { ($_ => 1) } qw( START RADIX ) },
            'SCONCAT' => { map { ($_ => 1) } qw( FACTORS ) },
            'SLENGTH' => { map { ($_ => 1) } qw( SOURCE ) },
            'SINDEX' => { map { ($_ => 1) } qw( LOOK_IN LOOK_FOR START_POS ) },
            'SUBSTR' => { map { ($_ => 1) } qw( LOOK_IN START_POS STR_LEN ) },
            'SREPEAT' => { map { ($_ => 1) } qw( FACTOR REPEAT ) },
            'STRIM' => { map { ($_ => 1) } qw( SOURCE ) },
            'SPAD' => { map { ($_ => 1) } qw( SOURCE ) },
            'SPADL' => { map { ($_ => 1) } qw( SOURCE ) },
            'LC' => { map { ($_ => 1) } qw( SOURCE ) },
            'UC' => { map { ($_ => 1) } qw( SOURCE ) },
            'MIN' => { map { ($_ => 1) } qw( FACTOR ) },
            'MAX' => { map { ($_ => 1) } qw( FACTOR ) },
            'SUM' => { map { ($_ => 1) } qw( FACTOR ) },
            'AVG' => { map { ($_ => 1) } qw( FACTOR ) },
            'CONCAT' => { map { ($_ => 1) } qw( FACTOR ) },
            'EVERY' => { map { ($_ => 1) } qw( FACTOR ) },
            'ANY' => { map { ($_ => 1) } qw( FACTOR ) },
            'EXISTS' => { map { ($_ => 1) } qw( FACTOR ) },
            'GB_SETS' => { map { ($_ => 1) } qw( FACTORS ) },
            'GB_RLUP' => { map { ($_ => 1) } qw( FACTORS ) },
            'GB_CUBE' => { map { ($_ => 1) } qw( FACTORS ) },
        },
    },
);

# This goes with %P_C_REL_ENUMS and says which of the child values specified 
# there are optional; any values listed there but not here are mandatory.
# Every hash key in the top 2 levels of %P_C_REL_ENUMS has a matching hash key 
# here; every level 3 hash key there may not have a match here, however.
my %OPT_P_C_REL_ENUMS = (
    'standard_routine' => {
        'standard_routine_cxt' => {
        },
        'standard_routine_arg' => {
            'CATALOG_LIST' => { map { ($_ => 1) } qw( RECURSIVE ) },
            'CATALOG_INFO' => { map { ($_ => 1) } qw( RECURSIVE ) },
            'CATALOG_VERIFY' => { map { ($_ => 1) } qw( RECURSIVE ) },
            'CATALOG_CREATE' => { map { ($_ => 1) } qw( RECURSIVE ) },
            'CATALOG_OPEN' => { map { ($_ => 1) } qw( LOGIN_NAME LOGIN_PASS ) },
            'RETURN' => { map { ($_ => 1) } qw( RETURN_VALUE ) },
            'LIKE' => { map { ($_ => 1) } qw( FIXED_LEFT FIXED_RIGHT ) },
        },
    },
);

# Names of hash keys in %NODE_TYPES elements:
my $TPI_AT_SEQUENCE = 'at_sequence'; # Array of all 'attribute' names in canon order
my $TPI_PP_PSEUDONODE = 'pp_pseudonode'; # If set, Nodes of this type have a hard-coded pseudo-parent
my $TPI_PP_NSREF    = 'pp_nsref'; # An array ref whose values are enums and each matches a single %NODE_TYPES key.
my $TPI_AT_LITERALS = 'at_literals'; # Hash - Keys are attr names a Node can have which have literal values
    # Values are enums and say what literal data type the attribute has, like int or bool or str
my $TPI_AT_ENUMS    = 'at_enums'; # Hash - Keys are attr names a Node can have which are enumerated values
    # Values are enums and match a %ENUMERATED_TYPES key
my $TPI_AT_NSREFS   = 'at_nsrefs'; # Hash - Keys are attr names a Node can have which are Node Ref/Id values
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
my $TPI_REL_P_ENUMS = 'rel_p_enums'; # Hash of enum attrs dependent on other enum attrs in parent Nodes
    # Each hash key is an enum attr name in current Node; value is a hash where:
    # each hash value is an enum attr name in parent Node, and the key is the Node type for the parent where that's true.
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
my $TPI_MA_REL_C_ENUMS = 'ma_rel_c_enums'; # Hash of enum attrs that may have mandatory related child Node attrs
    # Each hash key is an enum attr name in current Node; value is a hash where:
    # each hash value is an array of enum attr names in child Node, and the key is the Node type for the child that applies to.

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
        $TPI_MUDI_ATGPS => [
            ['ak_storage_product_code',[
                ['data_storage_product',[],[],['product_code']],
            ]],
            ['ak_link_product_code',[
                ['data_link_product',[],[],['product_code']],
            ]],
        ],
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
        $TPI_PP_NSREF => ['scalar_data_type'],
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
        $TPI_PP_NSREF => ['row_data_type'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
            'scalar_data_type' => ['scalar_data_type'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
        $TPI_MA_ATNMS => [[],[],['scalar_data_type']],
    },
    'external_cursor' => {
        $TPI_AT_SEQUENCE => [qw( 
            id si_name
        )],
        $TPI_PP_PSEUDONODE => $SQLRT_L2_ELEM_PSND,
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
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
        $TPI_PP_NSREF => ['catalog'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
    },
    'catalog_link' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name target
        )],
        $TPI_PP_NSREF => ['catalog','application'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
            'target' => ['catalog'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
        $TPI_MA_ATNMS => [[],[],['target']],
    },
    'schema' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name owner 
        )],
        $TPI_PP_NSREF => ['catalog'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
            'owner' => ['owner'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
        $TPI_MA_ATNMS => [[],[],['owner']],
    },
    'role' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name
        )],
        $TPI_PP_NSREF => ['catalog'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
    },
    'privilege_on' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_priv_on
        )],
        $TPI_PP_NSREF => ['role'],
        $TPI_AT_NSREFS => {
            'si_priv_on' => ['schema','scalar_domain','row_domain','sequence','table','view','routine'],
        },
        $TPI_SI_ATNM => [undef,undef,undef,'si_priv_on'],
    },
    'privilege_for' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_priv_type
        )],
        $TPI_PP_NSREF => ['privilege_on'],
        $TPI_AT_ENUMS => {
            'si_priv_type' => 'privilege_type',
        },
        $TPI_SI_ATNM => [undef,undef,'si_priv_type',undef],
    },
    'scalar_domain' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name data_type
        )],
        $TPI_PP_NSREF => ['schema','application'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['schema','application'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['schema','application'],
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
        $TPI_PP_NSREF => ['schema','application'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['table'],
        $TPI_AT_LITERALS => {
            'mandatory' => 'bool',
            'default_val' => 'misc',
            'auto_inc' => 'bool',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['table'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_ENUMS => {
            'index_type' => 'table_index_type',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['table_index'],
        $TPI_AT_NSREFS => {
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
            distinct_rows may_write ins_p_routine_item
        )],
        $TPI_PP_NSREF => ['view','routine_var','routine_stmt','schema','application'],
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
        $TPI_AT_NSREFS => {
            'row_data_type' => ['row_data_type','row_domain'],
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
        $TPI_PP_NSREF => ['view'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_ENUMS => {
            'cont_type' => 'container_type',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
            'may_write' => 'bool',
        },
        $TPI_AT_NSREFS => {
            'match' => ['table','view','view_arg','routine_arg','routine_var'],
            'catalog_link' => ['catalog_link'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
    },
    'view_src_arg' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_match_view_arg
        )],
        $TPI_PP_NSREF => ['view_src'],
        $TPI_AT_NSREFS => {
            'si_match_view_arg' => ['view_arg'],
        },
        $TPI_SI_ATNM => [undef,undef,undef,'si_match_view_arg'],
    },
    'view_src_field' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_match_field
        )],
        $TPI_PP_NSREF => ['view_src'],
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view'],
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view'],
        $TPI_AT_ENUMS => {
            'join_op' => 'join_operator',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view_join'],
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view'],
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['view_expr','view'],
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
        $TPI_AT_NSREFS => {
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
            'call_view_arg' => [$S,$P,{'view_expr'=>'valf_call_view'}],
            'call_uroutine_cxt' => [$S,$P,{'view_expr'=>'valf_call_uroutine'}],
            'call_uroutine_arg' => [$S,$P,{'view_expr'=>'valf_call_uroutine'}],
            'valf_src_field' => [$S,$R,$P,$C],
            'valf_result_field' => [$S,$R,$P],
        },
        $TPI_REL_P_ENUMS => {
            'call_sroutine_cxt' => {
                'view_expr' => 'valf_call_sroutine',
            },
            'call_sroutine_arg' => {
                'view_expr' => 'valf_call_sroutine',
            },
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
        $TPI_MA_REL_C_ENUMS => {
            'valf_call_sroutine' => {
                'view_expr' => ['call_sroutine_cxt','call_sroutine_arg'],
            },
        },
    },
    'routine' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name routine_type return_cont_type 
            return_scalar_data_type return_row_data_type 
            return_conn_link return_curs_ext 
            trigger_on trigger_event trigger_per_stmt
        )],
        $TPI_PP_NSREF => ['routine','schema','application'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
            'trigger_per_stmt' => 'bool',
        },
        $TPI_AT_ENUMS => {
            'routine_type' => 'routine_type',
            'return_cont_type' => 'container_type',
            'trigger_event' => 'basic_trigger_event',
        },
        $TPI_AT_NSREFS => {
            'return_scalar_data_type' => ['scalar_data_type','scalar_domain'],
            'return_row_data_type' => ['row_data_type','row_domain'],
            'return_conn_link' => ['catalog_link'],
            'return_curs_ext' => ['external_cursor'],
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
                [[],[],['return_conn_link'],['CONN'],1],
                [[],[],['return_curs_ext'],['CURSOR'],1],
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
            id pp si_name cont_type conn_link curs_ext 
        )],
        $TPI_PP_NSREF => ['routine'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_ENUMS => {
            'cont_type' => 'container_type',
        },
        $TPI_AT_NSREFS => {
            'conn_link' => ['catalog_link'],
            'curs_ext' => ['external_cursor'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
        $TPI_MA_ATNMS => [[],['cont_type'],[]],
        $TPI_MUTEX_ATGPS => [
            ['context',[],[],['conn_link','curs_ext'],1],
        ],
        $TPI_LOCAL_ATDPS => [
            [undef,'cont_type',undef,[
                [[],[],['conn_link'],['CONN'],1],
                [[],[],['curs_ext'],['CURSOR'],1],
            ]],
        ],
    },
    'routine_arg' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name cont_type scalar_data_type row_data_type
            conn_link curs_ext 
        )],
        $TPI_PP_NSREF => ['routine'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
        },
        $TPI_AT_ENUMS => {
            'cont_type' => 'container_type',
        },
        $TPI_AT_NSREFS => {
            'scalar_data_type' => ['scalar_data_type','scalar_domain'],
            'row_data_type' => ['row_data_type','row_domain'],
            'conn_link' => ['catalog_link'],
            'curs_ext' => ['external_cursor'],
        },
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
        $TPI_WR_ATNM => 'row_data_type',
        $TPI_MA_ATNMS => [[],['cont_type'],[]],
        $TPI_LOCAL_ATDPS => [
            [undef,'cont_type',undef,[
                [[],[],['scalar_data_type'],['SCALAR','SC_ARY'],1],
                [[],[],['row_data_type'],['ROW','RW_ARY'],1],
                [[],[],['conn_link'],['CONN'],1],
                [[],[],['curs_ext'],['CURSOR'],1],
            ]],
        ],
    },
    'routine_var' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp si_name cont_type scalar_data_type row_data_type
            init_lit_val is_constant conn_link curs_ext curs_for_update 
        )],
        $TPI_PP_NSREF => ['routine'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
            'init_lit_val' => 'misc',
            'is_constant' => 'bool',
            'curs_for_update' => 'bool',
        },
        $TPI_AT_ENUMS => {
            'cont_type' => 'container_type',
        },
        $TPI_AT_NSREFS => {
            'scalar_data_type' => ['scalar_data_type','scalar_domain'],
            'row_data_type' => ['row_data_type','row_domain'],
            'conn_link' => ['catalog_link'],
            'curs_ext' => ['external_cursor'],
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
                [[],[],['curs_ext'],['CURSOR'],1],
                [['curs_for_update'],[],[],['CURSOR'],0],
            ]],
        ],
    },
    'routine_stmt' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp block_routine assign_dest call_sroutine call_uroutine catalog_link 
        )],
        $TPI_PP_NSREF => ['routine'],
        $TPI_AT_ENUMS => {
            'call_sroutine' => 'standard_routine',
        },
        $TPI_AT_NSREFS => {
            'block_routine' => ['routine'],
            'assign_dest' => ['routine_arg','routine_var'],
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
        $TPI_MA_REL_C_ENUMS => {
            'call_sroutine' => {
                'routine_expr' => ['call_sroutine_cxt','call_sroutine_arg'],
            },
        },
    },
    'routine_expr' => {
        $TPI_AT_SEQUENCE => [qw( 
            id pp call_sroutine_cxt call_sroutine_arg call_uroutine_cxt call_uroutine_arg query_dest 
            cont_type valf_literal scalar_data_type valf_p_routine_item valf_seq_next 
            valf_call_sroutine valf_call_uroutine catalog_link act_on
        )],
        $TPI_PP_NSREF => ['routine_expr','routine_stmt'],
        $TPI_AT_LITERALS => {
            'valf_literal' => 'misc',
        },
        $TPI_AT_ENUMS => {
            'call_sroutine_cxt' => 'standard_routine_context',
            'call_sroutine_arg' => 'standard_routine_arg',
            'cont_type' => 'container_type',
            'valf_call_sroutine' => 'standard_routine',
        },
        $TPI_AT_NSREFS => {
            'call_uroutine_cxt' => ['routine_context'],
            'call_uroutine_arg' => ['routine_arg'],
            'query_dest' => ['routine_arg','routine_var'],
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
            [undef,'call_sroutine_arg',undef,[
                [[],[],['query_dest'],['INTO'],1],
            ]],
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
            'call_uroutine_cxt' => [$S,$P,{'routine_stmt'=>'call_uroutine','routine_expr'=>'valf_call_uroutine'}],
            'call_uroutine_arg' => [$S,$P,{'routine_stmt'=>'call_uroutine','routine_expr'=>'valf_call_uroutine'}],
        },
        $TPI_REL_P_ENUMS => {
            'call_sroutine_cxt' => {
                'routine_stmt' => 'call_sroutine',
                'routine_expr' => 'valf_call_sroutine',
            },
            'call_sroutine_arg' => {
                'routine_stmt' => 'call_sroutine',
                'routine_expr' => 'valf_call_sroutine',
            },
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
        $TPI_MA_REL_C_ENUMS => {
            'valf_call_sroutine' => {
                'routine_expr' => ['call_sroutine_cxt','call_sroutine_arg'],
            },
        },
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
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
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
        $TPI_SI_ATNM => [undef,'si_name',undef,undef],
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
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['catalog_instance'],
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
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['catalog_link_instance','catalog_instance','application_instance'],
        $TPI_AT_LITERALS => {
            'local_dsn' => 'cstr',
            'login_name' => 'cstr',
            'login_pass' => 'cstr',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['catalog_link_instance'],
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
        $TPI_PP_NSREF => ['catalog_instance'],
        $TPI_AT_LITERALS => {
            'si_name' => 'cstr',
            'password' => 'cstr',
        },
        $TPI_AT_ENUMS => {
            'user_type' => 'user_type',
        },
        $TPI_AT_NSREFS => {
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
        $TPI_PP_NSREF => ['user'],
        $TPI_AT_NSREFS => {
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
        $TPI_AT_NSREFS => {
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
        foreach my $pp_node_type (@{$_type_info->{$TPI_PP_NSREF}}) {
            $TYPE_CHILD_SI_ATNMS{$pp_node_type} ||= {};
            $TYPE_CHILD_SI_ATNMS{$pp_node_type}->{$_node_type} = $si_atnm;
        }
    }
}

# These special attribute hash keys are used by the get_all_properties[/*]() methods, 
# and/or by the build*node*() functions and methods for RAD:
my $ATTR_ID = 'id'; # attribute name to use for the node id
my $ATTR_PP = 'pp'; # attribute name to use for the node's primary parent nref

######################################################################

sub valid_enumerated_types {
    my (undef, $type) = @_;
    $type and return exists( $ENUMERATED_TYPES{$type} );
    return {map { ($_ => 1) } keys %ENUMERATED_TYPES};
}

sub valid_enumerated_type_values {
    my (undef, $type, $value) = @_;
    $type and (exists( $ENUMERATED_TYPES{$type} ) or return);
    $value and return exists( $ENUMERATED_TYPES{$type}->{$value} );
    return {%{$ENUMERATED_TYPES{$type}}};
}

sub valid_node_types {
    my (undef, $type) = @_;
    $type and return exists( $NODE_TYPES{$type} );
    return {map { ($_ => 1) } keys %NODE_TYPES};
}

sub node_types_with_pseudonode_parents {
    my (undef, $type) = @_;
    if( $type ) {
        exists( $NODE_TYPES{$type} ) or return;
        return $NODE_TYPES{$type}->{$TPI_PP_PSEUDONODE};
    }
    return {map { ($_ => $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE}) } 
        grep { $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE} } keys %NODE_TYPES};
}

sub node_types_with_primary_parent_attributes {
    my (undef, $type) = @_;
    if( $type ) {
        exists( $NODE_TYPES{$type} ) or return;
        exists( $NODE_TYPES{$type}->{$TPI_PP_NSREF} ) or return;
        return [@{$NODE_TYPES{$type}->{$TPI_PP_NSREF}}];
    }
    return {map { ($_ => [@{$NODE_TYPES{$_}->{$TPI_PP_NSREF}}]) } 
        grep { $NODE_TYPES{$_}->{$TPI_PP_NSREF} } keys %NODE_TYPES};
}

sub valid_node_type_literal_attributes {
    my (undef, $type, $attr) = @_;
    $type and (exists( $NODE_TYPES{$type} ) or return);
    exists( $NODE_TYPES{$type}->{$TPI_AT_LITERALS} ) or return;
    $attr and return $NODE_TYPES{$type}->{$TPI_AT_LITERALS}->{$attr};
    return {%{$NODE_TYPES{$type}->{$TPI_AT_LITERALS}}};
}

sub valid_node_type_enumerated_attributes {
    my (undef, $type, $attr) = @_;
    $type and (exists( $NODE_TYPES{$type} ) or return);
    exists( $NODE_TYPES{$type}->{$TPI_AT_ENUMS} ) or return;
    $attr and return $NODE_TYPES{$type}->{$TPI_AT_ENUMS}->{$attr};
    return {%{$NODE_TYPES{$type}->{$TPI_AT_ENUMS}}};
}

sub valid_node_type_node_ref_attributes {
    my (undef, $type, $attr) = @_;
    $type and (exists( $NODE_TYPES{$type} ) or return);
    exists( $NODE_TYPES{$type}->{$TPI_AT_NSREFS} ) or return;
    my $rh = $NODE_TYPES{$type}->{$TPI_AT_NSREFS};
    $attr and return $rh->{$attr} ? [@{$rh->{$attr}}] : undef;
    return {map { ($_ => [@{$rh->{$_}}]) } keys %{$rh}};
}

sub valid_node_type_surrogate_id_attributes {
    my (undef, $type) = @_;
    $type and (exists( $NODE_TYPES{$type} ) or return);
    $type and return (grep { $_ } @{$NODE_TYPES{$type}->{$TPI_SI_ATNM}})[0];
    return {map { ($_ => (grep { $_ } @{$NODE_TYPES{$_}->{$TPI_SI_ATNM}})[0]) } keys %NODE_TYPES};
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _serialize_as_perl {
    my ($self, $node_dump, $pad) = @_;
    $pad ||= '';
    my $padc = "$pad        ";
    my ($node_type, $attrs, $children) = @{$node_dump};
    my $attr_seq = $NODE_TYPES{$node_type}->{$TPI_AT_SEQUENCE};
    return join( '', 
        $pad."[\n",
        $pad."    '".$node_type."',\n",
        (scalar(keys %{$attrs}) ? (
            $pad."    {\n",
            (map { $pad."        '".$_."' => ".(
                    ref($attrs->{$_}) eq 'ARRAY' ? 
                        "[".join( ',', map { 
                                defined($_) ? "'".$self->_s_a_p_esc($_)."'" : "undef"
                            } @{$attrs->{$_}} )."]" : 
                        "'".$self->_s_a_p_esc($attrs->{$_})."'"
                ).",\n" } grep { defined( $attrs->{$_} ) } @{$attr_seq}),
            $pad."    },\n",
        ) : ''),
        (scalar(@{$children}) ? (
            $pad."    [\n",
            (map { $self->_serialize_as_perl( $_,$padc ) } @{$children}),
            $pad."    ],\n",
        ) : ''),
        $pad."],\n",
    );
}

sub _s_a_p_esc {
    my (undef, $text) = @_;
    $text =~ s/\\/\\\\/g;
    $text =~ s/'/\\'/g;
    return $text;
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _serialize_as_xml {
    my ($self, $node_dump, $pad) = @_;
    $pad ||= '';
    my $padc = "$pad    ";
    my ($node_type, $attrs, $children) = @{$node_dump};
    my $attr_seq = $NODE_TYPES{$node_type}->{$TPI_AT_SEQUENCE};
    return join( '', 
        $pad.'<'.$node_type,
        (map { ' '.$_.'="'.(
                ref($attrs->{$_}) eq 'ARRAY' ? 
                    "[".join( ',', map { 
                            defined($_) ? $self->_s_a_x_esc($_) : ""
                        } @{$attrs->{$_}} )."]" : 
                    $self->_s_a_x_esc($attrs->{$_})
            ).'"' } grep { defined( $attrs->{$_} ) } @{$attr_seq}),
        (scalar(@{$children}) ? (
            '>'."\n",
            (map { $self->_serialize_as_xml( $_,$padc ) } @{$children}),
            $pad.'</'.$node_type.'>'."\n",
        ) : ' />'."\n"),
    );
}

sub _s_a_x_esc {
    my (undef, $text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/\"/&quot;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/</&lt;/g;
    return $text;
}

######################################################################
# This is a 'protected' method; only sub-classes should invoke it.

sub _throw_error_message {
    my ($self, $msg_key, $msg_vars) = @_;
    # Throws an exception consisting of an object.  A Container property is not 
    # used to store object so things work properly in multi-threaded environment; 
    # an exception is only supposed to affect the thread that calls it.
    ref($msg_vars) eq 'HASH' or $msg_vars = {};
    if( ref($self) and UNIVERSAL::isa( $self, 'SQL::Routine::Node' ) ) {
        $self = $self->{$NPROP_STORAGE};
    }
    if( ref($self) and UNIVERSAL::isa( $self, 'SQL::Routine::NodeStorage' ) ) {
        $msg_vars->{'NTYPE'} = $self->{$NSPROP_NODE_TYPE};
        $msg_vars->{'NID'} = $self->{$NSPROP_NODE_ID};
        if( $self->{$NSPROP_CONSTOR} ) {
            # Note: We get here for all invoking methods except for Node.new().
            $msg_vars->{'SIDCH'} = $self->_get_surrogate_id_chain();
        }
    }
    foreach my $var_key (keys %{$msg_vars}) {
        if( ref($msg_vars->{$var_key}) eq 'ARRAY' ) {
            $msg_vars->{$var_key} = 'PERL_ARRAY:['.join(',',map {$_||''} @{$msg_vars->{$var_key}}).']';
        }
    }
    die Locale::KeyedText->new_message( $msg_key, $msg_vars );
}

######################################################################
# These are convenience wrapper methods.

sub new_container {
    return SQL::Routine::Container->new();
}

sub _new_constor {
    return SQL::Routine::ContainerStorage->_new();
}

sub new_node {
    my (undef, $container, $node_type, $node_id) = @_;
    return SQL::Routine::Node->new( $container, $node_type, $node_id );
}

sub _new_nodstor {
    my (undef, $constor, $node_type, $node_id) = @_;
    return SQL::Routine::NodeStorage->_new( $constor, $node_type, $node_id );
}

sub new_group {
    my (undef, $container) = @_;
    return SQL::Routine::Group->new( $container );
}

######################################################################

sub build_container {
    my ($self, $children, $auto_assert, $auto_ids, $match_surr_ids) = @_;
    my $container = $self->new_container();
    $auto_assert and $container->auto_assert_deferrable_constraints( 1 );
    $auto_ids and $container->auto_set_node_ids( 1 );
    $match_surr_ids and $container->may_match_surrogate_node_ids( 1 );
    $container->build_child_node_trees( $children );
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
    my $constor = $class->_new_constor();
    $container->{$CPROP_STORAGE} = $constor;
    $container->{$CPROP_AUTO_ASS_DEF_CON} = 0;
    $container->{$CPROP_AUTO_SET_NIDS} = 0;
    $container->{$CPROP_MAY_MATCH_SNIDS} = 0;
    $container->{$CPROP_EXPLICIT_GROUPS} = {};
    $class->new_group( $container ); # SQL::Routine::Group.new() will initialize our CPROP_DEFAULT_GROUP
    return $container;
}

######################################################################

sub new_interface {
    my ($container) = @_;
    my $new_container = bless( {}, ref($container) );
    $new_container->{$CPROP_STORAGE} = $container->{$CPROP_STORAGE};
    $new_container->{$CPROP_AUTO_ASS_DEF_CON} = 0;
    $new_container->{$CPROP_AUTO_SET_NIDS} = 0;
    $new_container->{$CPROP_MAY_MATCH_SNIDS} = 0;
    $new_container->{$CPROP_EXPLICIT_GROUPS} = {};
    $container->new_group( $new_container ); # SQL::Routine::Group.new() will initialize our CPROP_DEFAULT_GROUP
    return $new_container;
}

######################################################################

sub get_self_id {
    my ($container) = @_;
    return "@{[$container->{$CPROP_STORAGE}]}";
}

######################################################################

sub _ns_to_ni {
    my ($container, $nodstor) = @_;
    ref($container) eq 'SQL::Routine::Container' or die "invocant of _ns_to_ni() is no Cont\n";
    defined($nodstor) or return;
    if( ref($nodstor) eq 'ARRAY' ) {
        return [map { $container->_ns_to_ni_item( $_ ) } @{$nodstor}];
    }
    if( ref($nodstor) eq 'HASH' ) {
        return {map { ($_ => $container->_ns_to_ni_item( $nodstor->{$_} )) } @{$nodstor}};
    }
    return $container->_ns_to_ni_item( $nodstor );
}

sub _ns_to_ni_item {
    my ($container, $nodstor) = @_;
    defined($nodstor) or return;
    ref($nodstor) eq 'SQL::Routine::NodeStorage' or return $nodstor;
    my $new_node = bless( {}, 'SQL::Routine::Node' );
    $new_node->{$NPROP_STORAGE} = $nodstor;
    Scalar::Util::weaken( $new_node->{$NPROP_STORAGE} );
    $new_node->{$NPROP_CONTAINER} = $container;
    return $new_node;
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

sub delete_node_tree {
    my ($container) = @_;
    my $constor = $container->{$CPROP_STORAGE};
    # First check that all NodeStorages have no locks on them.
    foreach my $nodstor (values %{$constor->{$CSPROP_ALL_NODES}}) {
        (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
            $container->_throw_error_message( 'SRT_C_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'delete_node_tree', 
                'NTYPE' => $nodstor->{$NSPROP_NODE_TYPE}, 'NID' => $nodstor->{$NSPROP_NODE_ID}, 
                'SIDCH' => $nodstor->_get_surrogate_id_chain() } );
    }
    # If we get here, we may delete all the Nodes.
    %{$constor->{$CSPROP_ALL_NODES}} = ();
    my $pseudonodes = $constor->{$CSPROP_PSEUDONODES};
    foreach my $pseudonode_name (@L2_PSEUDONODE_LIST) {
        @{$pseudonodes->{$_}} = ();
    }
    $constor->{$CSPROP_EDIT_COUNT} ++; # All Nodes are gone.
        # Turn on tests because a tree having zero Nodes may violate deferrable constraints.
}

######################################################################

sub get_child_nodes {
    my ($container, $node_type) = @_;
    my $pseudonodes = $container->{$CPROP_STORAGE}->{$CSPROP_PSEUDONODES};
    if( defined( $node_type ) ) {
        unless( $NODE_TYPES{$node_type} ) {
            $container->_throw_error_message( 'SRT_C_GET_CH_NODES_BAD_TYPE', { 'ARGNTYPE' => $node_type } );
        }
        my $pp_pseudonode = $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} or return [];
        return $container->_ns_to_ni( [grep { $_->{$NSPROP_NODE_TYPE} eq $node_type } @{$pseudonodes->{$pp_pseudonode}}] );
    } else {
        return $container->_ns_to_ni( [map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST] );
    }
}

######################################################################

sub find_node_by_id {
    my ($container, $node_id) = @_;
    defined( $node_id ) or $container->_throw_error_message( 
        'SRT_C_METH_ARG_UNDEF', { 'METH' => 'find_node_by_id', 'ARGNM' => 'NODE_ID' } );
    return $container->_ns_to_ni( $container->{$CPROP_STORAGE}->{$CSPROP_ALL_NODES}->{$node_id} );
}

######################################################################

sub find_child_node_by_surrogate_id {
    my ($container, $target_attr_value) = @_;
    defined( $target_attr_value ) or $container->_throw_error_message( 
        'SRT_C_METH_ARG_UNDEF', { 'METH' => 'find_child_node_by_surrogate_id', 'ARGNM' => 'TARGET_ATTR_VALUE' } );
    ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
    return $container->_ns_to_ni( $container->{$CPROP_STORAGE}->_find_child_node_by_surrogate_id( $container, $target_attr_value ) );
}

######################################################################

sub get_next_free_node_id {
    my ($container) = @_;
    return $container->{$CPROP_STORAGE}->{$CSPROP_NEXT_FREE_NID};
}

######################################################################

sub get_edit_count {
    my ($container) = @_;
    return $container->{$CPROP_STORAGE}->{$CSPROP_EDIT_COUNT};
}

######################################################################

sub deferrable_constraints_are_tested {
    my ($container) = @_;
    my $constor = $container->{$CPROP_STORAGE};
    return $constor->{$CSPROP_DEF_CON_TESTED} == $constor->{$CSPROP_EDIT_COUNT} ? 1 : 0;
}

sub assert_deferrable_constraints {
    my ($container) = @_;
    $container->{$CPROP_STORAGE}->_assert_deferrable_constraints( $container );
}

######################################################################

sub get_all_properties {
    my ($container, $links_as_si, $want_shortest) = @_;
    return $container->{$CPROP_STORAGE}->_get_all_properties( $container, $links_as_si, $want_shortest );
}

sub get_all_properties_as_perl_str {
    my ($container, $links_as_si, $want_shortest) = @_;
    return $container->_serialize_as_perl( $container->get_all_properties( $links_as_si, $want_shortest ) );
}

sub get_all_properties_as_xml_str {
    my ($container, $links_as_si, $want_shortest) = @_;
    return '<?xml version="1.0" encoding="UTF-8"?>'."\n".
        $container->_serialize_as_xml( $container->get_all_properties( $links_as_si, $want_shortest ) );
}

######################################################################

sub build_node {
    my ($container, $node_type, $attrs) = @_;
    return $container->_build_node_is_child_or_not( $node_type, $attrs );
}

sub _build_node_is_child_or_not {
    my ($container, $node_type, $attrs, $pp_node) = @_;

    # This input validation is the same as what Node.new() does, and throws the same error keys.
    # It is also done here to head off a bootstrap problem that affects SI_ATNM determination below.  
    defined( $node_type ) or $container->_throw_error_message( 'SRT_N_NEW_NODE_NO_ARG_TYPE' );
    my $type_info = $NODE_TYPES{$node_type};
    unless( $type_info ) {
        $container->_throw_error_message( 'SRT_N_NEW_NODE_BAD_TYPE', { 'ARGNTYPE' => $node_type } );
    }

    # Now normalize $attrs into a nice orderly hash.
    if( ref($attrs) eq 'HASH' ) {
        $attrs = {%{$attrs}}; # copy this, to preserve caller environment
    } elsif( defined($attrs) ) {
        if( $attrs =~ m/^\d+$/ and $attrs > 0 ) { # looks like a node id
            $attrs = { $ATTR_ID => $attrs };
        } else { # does not look like node id
            $attrs = { (grep { $_ } @{$type_info->{$TPI_SI_ATNM}})[0] => $attrs };
        }
    } else {
        $attrs = {};
    }

    # Now create the Node and set its attributes.
    my $node_id = delete( $attrs->{$ATTR_ID} );
    my $node = $container->new_node( $container, $node_type, $node_id );
    my $pp_in_attrs = delete( $attrs->{$ATTR_PP} ); # ensure won't override any $pp_node
    if( $pp_node ) {
        $pp_node->add_child_node( $node );
    } else {
        $pp_in_attrs and $node->set_primary_parent_attribute( $pp_in_attrs );
    }
    if( my $node_surr_id = delete( $attrs->{(grep { $_ } @{$type_info->{$TPI_SI_ATNM}})[0]} ) ) {
        $node->set_surrogate_id_attribute( $node_surr_id );
    }
    $node->set_attributes( $attrs );

    # Apply auto-asserted deferrable constraints.
    if( $container->{$CPROP_AUTO_ASS_DEF_CON} ) {
        eval {
            $node->assert_deferrable_constraints(); # check that this Node's own attrs are correct
        };
        if( my $exception = $@ ) {
            my $msg_key = $exception->get_message_key();
            unless( $msg_key eq 'SRT_N_ASDC_CH_N_TOO_FEW_SET' or 
                    $msg_key eq 'SRT_N_ASDC_CH_N_TOO_FEW_SET_PSN' or 
                    $msg_key eq 'SRT_N_ASDC_MA_REL_ENUM_MISSING_VALUES' ) {
                die $exception; # don't trap any other types of exceptions
            }
        }
    }

    return $node;
}

sub build_child_node {
    my ($container, $node_type, $attrs) = @_;
    if( $node_type eq $SQLRT_L1_ROOT_PSND or grep { $_ eq $node_type } @L2_PSEUDONODE_LIST ) {
        return $container;
    } else { # $node_type is not a valid pseudo-Node
        my $node = $container->_build_node_is_child_or_not( $node_type, $attrs );
        unless( $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} ) {
            $node->delete_node(); # so the new Node doesn't persist
            $container->_throw_error_message( 'SRT_C_BUILD_CH_ND_NO_PSND', { 'ARGNTYPE' => $node_type } );
        }
        return $node;
    }
}

sub build_child_nodes {
    my ($container, $children) = @_;
    defined( $children ) or $container->_throw_error_message( 
        'SRT_C_METH_ARG_UNDEF', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN' } );
    ref($children) eq 'ARRAY' or $container->_throw_error_message( 
        'SRT_C_METH_ARG_NO_ARY', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN', 'ARGVL' => $children } );
    foreach my $child (@{$children}) {
        defined( $child ) or $container->_throw_error_message( 
            'SRT_C_METH_ARG_ARY_ELEM_UNDEF', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN' } );
        ref($child) eq 'ARRAY' or $container->_throw_error_message( 
            'SRT_C_METH_ARG_ARY_ELEM_NO_ARY', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN', 'ELEMVL' => $child } );
        $container->build_child_node( @{$child} );
    }
}

sub build_child_node_tree {
    my ($container, $node_type, $attrs, $children) = @_;
    if( $node_type eq $SQLRT_L1_ROOT_PSND or grep { $_ eq $node_type } @L2_PSEUDONODE_LIST ) {
        defined( $children ) and $container->build_child_node_trees( $children );
        return $container;
    } else { # $node_type is not a valid pseudo-Node
        my $node = $container->_build_node_is_child_or_not( $node_type, $attrs );
        unless( $NODE_TYPES{$node_type}->{$TPI_PP_PSEUDONODE} ) {
            $node->delete_node(); # so the new Node doesn't persist
            $container->_throw_error_message( 'SRT_C_BUILD_CH_ND_TR_NO_PSND', { 'ARGNTYPE' => $node_type } );
        }
        defined( $children ) and $node->build_child_node_trees( $children );
        return $node;
    }
}

sub build_child_node_trees {
    my ($container, $children) = @_;
    defined( $children ) or $container->_throw_error_message( 
        'SRT_C_METH_ARG_UNDEF', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN' } );
    ref($children) eq 'ARRAY' or $container->_throw_error_message( 
        'SRT_C_METH_ARG_NO_ARY', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN', 'ARGVL' => $children } );
    foreach my $child (@{$children}) {
        defined( $child ) or $container->_throw_error_message( 
            'SRT_C_METH_ARG_ARY_ELEM_UNDEF', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN' } );
        ref($child) eq 'ARRAY' or $container->_throw_error_message( 
            'SRT_C_METH_ARG_ARY_ELEM_NO_ARY', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN', 'ELEMVL' => $child } );
        $container->build_child_node_tree( @{$child} );
    }
}

######################################################################
######################################################################

package SQL::Routine::ContainerStorage;
use base qw( SQL::Routine );

######################################################################

sub _new {
    my ($class) = @_;
    my $constor = bless( {}, ref($class) || $class );
    $constor->{$CSPROP_ALL_NODES} = {};
    $constor->{$CSPROP_PSEUDONODES} = { map { ($_ => []) } @L2_PSEUDONODE_LIST };
    $constor->{$CSPROP_NEXT_FREE_NID} = 1;
    $constor->{$CSPROP_EDIT_COUNT} = 0;
    $constor->{$CSPROP_DEF_CON_TESTED} = -1;
    return $constor;
}

######################################################################

sub _find_child_node_by_surrogate_id {
    my ($constor, $container, $target_attr_value) = @_;
    my ($l2_psn, $chain_first, @chain_rest);
    unless( defined( $target_attr_value->[0] ) ) {
        # The given surrogate id chain starts with [undef,'root',<l2-psn>,<chain-of-node-si>].
        (undef, undef, $l2_psn, $chain_first, @chain_rest) = @{$target_attr_value};
    } else {
        # The given surrogate id chain starts with [<chain-of-node-si>].
        ($chain_first, @chain_rest) = @{$target_attr_value};
    }
    my $pseudonodes = $constor->{$CSPROP_PSEUDONODES};
    my @nodestors_to_search;
    if( $l2_psn and grep { $l2_psn eq $_ } @L2_PSEUDONODE_LIST ) {
        # Search only children of a specific pseudo-Node.
        @nodestors_to_search = @{$pseudonodes->{$l2_psn}};
    } else {
        # Search children of all pseudo-Nodes.
        @nodestors_to_search = map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST;
    }
    foreach my $child (@nodestors_to_search) {
        if( my $si_atvl = $child->_get_surrogate_id_attribute( $container, 1 ) ) {
            if( $si_atvl eq $chain_first ) {
                return @chain_rest ? $child->_find_child_node_by_surrogate_id( $container, \@chain_rest ) : $child;
            }
        }
    }
    return;
}

######################################################################

sub _assert_deferrable_constraints {
    my ($constor, $container) = @_;
    if( $constor->{$CSPROP_DEF_CON_TESTED} == $constor->{$CSPROP_EDIT_COUNT} ) {
        return;
    }
    # Test nodes in the same order that they appear in the Node tree.
    foreach my $pseudonode_name (@L2_PSEUDONODE_LIST) {
        SQL::Routine::NodeStorage->_assert_child_comp_deferrable_constraints( $container, $pseudonode_name, $constor );
        foreach my $child_nodstor (@{$constor->{$CSPROP_PSEUDONODES}->{$pseudonode_name}}) {
            $constor->_assert_child_deferrable_constraints( $container, $child_nodstor );
        }
    }
    $constor->{$CSPROP_DEF_CON_TESTED} = $constor->{$CSPROP_EDIT_COUNT};
}

sub _assert_child_deferrable_constraints {
    my ($constor, $container, $nodstor) = @_;
    $nodstor->_assert_deferrable_constraints( $container );
    foreach my $child_nodstor (@{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
        $constor->_assert_child_deferrable_constraints( $container, $child_nodstor );
    }
}

######################################################################

sub _get_all_properties {
    my ($constor, $container, $links_as_si, $want_shortest) = @_;
    my $pseudonodes = $constor->{$CSPROP_PSEUDONODES};
    return [ $SQLRT_L1_ROOT_PSND, {}, [
        map { [ $_, {}, [
            map { $_->_get_all_properties( $container, $links_as_si, $want_shortest ) } @{$pseudonodes->{$_}}
        ], ], } @L2_PSEUDONODE_LIST,
    ], ];
}

######################################################################
######################################################################

package SQL::Routine::Node;
use base qw( SQL::Routine );

######################################################################

sub new {
    my ($class, $container, $node_type, $node_id) = @_;
    my $node = bless( {}, ref($class) || $class );

    defined( $container ) or $node->_throw_error_message( 'SRT_N_NEW_NODE_NO_ARG_CONT' );
    unless( ref($container) and UNIVERSAL::isa( $container, 'SQL::Routine::Container' ) ) {
        $node->_throw_error_message( 'SRT_N_NEW_NODE_BAD_CONT', { 'ARGNCONT' => $container } );
    }
    my $constor = $container->{$CPROP_STORAGE};

    defined( $node_type ) or $node->_throw_error_message( 'SRT_N_NEW_NODE_NO_ARG_TYPE' );
    my $type_info = $NODE_TYPES{$node_type};
    unless( $type_info ) {
        $node->_throw_error_message( 'SRT_N_NEW_NODE_BAD_TYPE', { 'ARGNTYPE' => $node_type } );
    }

    if( defined( $node_id ) ) {
        unless( $node_id =~ m/^\d+$/ and $node_id > 0 ) {
            $node->_throw_error_message( 'SRT_N_NEW_NODE_BAD_ID', { 'ARGNTYPE' => $node_type, 'ARGNID' => $node_id } );
        }
        if( $constor->{$CSPROP_ALL_NODES}->{$node_id} ) {
            $node->_throw_error_message( 'SRT_N_NEW_NODE_DUPL_ID', { 'ARGNTYPE' => $node_type, 'ARGNID' => $node_id } );
        }
    } elsif( $container->{$CPROP_AUTO_SET_NIDS} ) {
        $node_id = $constor->{$CSPROP_NEXT_FREE_NID};
    } else {
        $node->_throw_error_message( 'SRT_N_NEW_NODE_NO_ARG_ID', { 'ARGNTYPE' => $node_type } );
    }

    my $nodstor = $class->_new_nodstor( $constor, $node_type, $node_id );

    $node->{$NPROP_STORAGE} = $nodstor;
    Scalar::Util::weaken( $node->{$NPROP_STORAGE} );
    $node->{$NPROP_CONTAINER} = $container;

    return $node;
}

######################################################################

sub new_interface {
    my ($node) = @_;
    my $container = $node->{$NPROP_CONTAINER};
    my $new_container = bless( {}, ref($container) );
    $new_container->{$CPROP_STORAGE} = $container->{$CPROP_STORAGE};
    my $new_node = bless( {}, ref($node) );
    $new_node->{$NPROP_STORAGE} = $node->{$NPROP_STORAGE};
    Scalar::Util::weaken( $new_node->{$NPROP_STORAGE} );
    $new_node->{$NPROP_CONTAINER} = $new_container;
    return $new_node;
}

######################################################################

sub get_self_id {
    my ($node) = @_;
    return "@{[$node->{$NPROP_STORAGE}]}";
}

######################################################################

sub _ns_to_ni {
    my ($node, $nodstor) = @_;
    ref($node) eq 'SQL::Routine::Node' or die "invocant of _ns_to_ni() is no Node\n";
    defined($nodstor) or return;
    if( ref($nodstor) eq 'ARRAY' ) {
        return [map { $node->_ns_to_ni_item( $_ ) } @{$nodstor}];
    }
    if( ref($nodstor) eq 'HASH' ) {
        return {map { ($_ => $node->_ns_to_ni_item( $nodstor->{$_} )) } @{$nodstor}};
    }
    return $node->_ns_to_ni_item( $nodstor );
}

sub _ns_to_ni_item {
    my ($node, $nodstor) = @_;
    defined($nodstor) or return;
    ref($nodstor) eq 'SQL::Routine::NodeStorage' or return $nodstor;
    my $new_node = bless( {}, 'SQL::Routine::Node' );
    $new_node->{$NPROP_STORAGE} = $nodstor;
    Scalar::Util::weaken( $new_node->{$NPROP_STORAGE} );
    $new_node->{$NPROP_CONTAINER} = $node->{$NPROP_CONTAINER};
    return $new_node;
}

######################################################################

sub delete_node {
    my ($node) = @_;
    return $node->{$NPROP_STORAGE}->_delete_node( $node->{$NPROP_CONTAINER} );
}

######################################################################

sub delete_node_tree {
    my ($node) = @_;
    return $node->{$NPROP_STORAGE}->_delete_node_tree( $node->{$NPROP_CONTAINER} );
}

######################################################################

sub get_container {
    my ($node) = @_;
    return $node->{$NPROP_CONTAINER};
}

######################################################################

sub get_node_type {
    my ($node) = @_;
    return $node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE};
}

######################################################################

sub get_node_id {
    my ($node) = @_;
    return $node->{$NPROP_STORAGE}->_get_node_id( $node->{$NPROP_CONTAINER} );
}

sub set_node_id {
    my ($node, $new_id) = @_;
    defined( $new_id ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'set_node_id', 'ARGNM' => 'NEW_ID' } );
    return $node->{$NPROP_STORAGE}->_set_node_id( $node->{$NPROP_CONTAINER}, $new_id );
}

######################################################################

sub get_primary_parent_attribute {
    my ($node) = @_;
    $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} or $node->_throw_error_message( 
        'SRT_N_METH_NO_PP_AT', { 'METH' => 'get_primary_parent_attribute' } );
    return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_get_primary_parent_attribute( $node->{$NPROP_CONTAINER} ) );
}

sub clear_primary_parent_attribute {
    my ($node) = @_;
    $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} or $node->_throw_error_message( 
        'SRT_N_METH_NO_PP_AT', { 'METH' => 'clear_primary_parent_attribute' } );
    $node->{$NPROP_STORAGE}->_clear_primary_parent_attribute( $node->{$NPROP_CONTAINER} );
}

sub set_primary_parent_attribute {
    my ($node, $attr_value) = @_;
    my $exp_node_types = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} or $node->_throw_error_message( 
        'SRT_N_METH_NO_PP_AT', { 'METH' => 'set_primary_parent_attribute' } );
    defined( $attr_value ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'set_primary_parent_attribute', 'ARGNM' => 'ATTR_VALUE' } );
    if( ref($attr_value) eq ref($node) ) {
        $attr_value = $attr_value->{$NPROP_STORAGE}; # unwrap any Node object into its NodeStorage; no-op if arg not a Node
    }
    $node->{$NPROP_STORAGE}->_set_primary_parent_attribute( $node->{$NPROP_CONTAINER}, $exp_node_types, $attr_value );
}

######################################################################

sub get_surrogate_id_attribute {
    my ($node, $get_target_si) = @_;
    return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_get_surrogate_id_attribute( $node->{$NPROP_CONTAINER}, $get_target_si ) );
}

sub clear_surrogate_id_attribute {
    my ($node) = @_;
    my ($id, $lit, $enum, $nref) = @{$NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_SI_ATNM}};
    $id and return $node->_throw_error_message( 'SRT_N_CLEAR_SI_AT_MAND_NID' );
    $lit and return $node->{$NPROP_STORAGE}->_clear_literal_attribute( $node->{$NPROP_CONTAINER}, $lit );
    $enum and return $node->{$NPROP_STORAGE}->_clear_enumerated_attribute( $node->{$NPROP_CONTAINER}, $enum );
    $nref and return $node->{$NPROP_STORAGE}->_clear_node_ref_attribute( $node->{$NPROP_CONTAINER}, $nref );
}

sub set_surrogate_id_attribute {
    my ($node, $attr_value) = @_;
    defined( $attr_value ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'set_surrogate_id_attribute', 'ARGNM' => 'ATTR_VALUE' } );
    if( ref($attr_value) eq ref($node) ) {
        $attr_value = $attr_value->{$NPROP_STORAGE}; # unwrap any Node object into its NodeStorage; no-op if arg not a Node
    }
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    my ($id, $lit, $enum, $nref) = @{$type_info->{$TPI_SI_ATNM}};
    $id and return $node->{$NPROP_STORAGE}->_set_node_id( $node->{$NPROP_CONTAINER}, $attr_value );
    $lit and return $node->{$NPROP_STORAGE}->_set_literal_attribute( $node->{$NPROP_CONTAINER}, $lit, $type_info->{$TPI_AT_LITERALS}->{$lit}, $attr_value );
    $enum and return $node->{$NPROP_STORAGE}->_set_enumerated_attribute( $node->{$NPROP_CONTAINER}, $enum, $type_info->{$TPI_AT_ENUMS}->{$enum}, $attr_value );
    $nref and return $node->{$NPROP_STORAGE}->_set_node_ref_attribute( $node->{$NPROP_CONTAINER}, $nref, $type_info->{$TPI_AT_NSREFS}->{$nref}, $attr_value );
}

######################################################################

sub get_attribute {
    my ($node, $attr_name, $get_target_si) = @_;
    defined( $attr_name ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'get_attribute', 'ARGNM' => 'ATTR_NAME' } );
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    $attr_name eq $ATTR_ID and return $node->{$NPROP_STORAGE}->_get_node_id( $node->{$NPROP_CONTAINER} );
    $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NSREF} and 
        return $node->{$NPROP_STORAGE}->_get_primary_parent_attribute( $node->{$NPROP_CONTAINER} );
    $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} and 
        return $node->{$NPROP_STORAGE}->_get_literal_attribute( $node->{$NPROP_CONTAINER}, $attr_name );
    $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} and 
        return $node->{$NPROP_STORAGE}->_get_enumerated_attribute( $node->{$NPROP_CONTAINER}, $attr_name );
    $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$attr_name} and 
        return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_get_node_ref_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $get_target_si ) );
    $node->_throw_error_message( 'SRT_N_METH_ARG_NO_AT_NM', 
        { 'METH' => 'get_attribute', 'ARGNM' => 'ATTR_NAME', 'ARGVL' => $attr_name } );
}

sub get_attributes {
    my ($node, $get_target_si) = @_;
    my $container = $node->{$NPROP_CONTAINER};
    my $at_nsrefs = $node->{$NPROP_STORAGE}->{$NSPROP_AT_NSREFS};
    return {
        $ATTR_ID => $node->get_node_id(),
        ($NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} ? 
            ($ATTR_PP => $node->{$NPROP_STORAGE}->_get_primary_parent_attribute( $node->{$NPROP_CONTAINER} )) : ()),
        %{$node->{$NPROP_STORAGE}->{$NSPROP_AT_LITERALS}},
        %{$node->{$NPROP_STORAGE}->{$NSPROP_AT_ENUMS}},
        ($get_target_si ? 
            (map { ($_ => $at_nsrefs->{$_}->_get_surrogate_id_attribute( $container, $get_target_si )) } keys %{$at_nsrefs}) : 
            ($node->_ns_to_ni( $at_nsrefs ))),
    };
}

sub clear_attribute {
    my ($node, $attr_name) = @_;
    defined( $attr_name ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'clear_attribute', 'ARGNM' => 'ATTR_NAME' } );
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    $attr_name eq $ATTR_ID and $node->_throw_error_message( 'SRT_N_CLEAR_AT_MAND_NID' );
    $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NSREF} and 
        return $node->{$NPROP_STORAGE}->_clear_primary_parent_attribute( $node->{$NPROP_CONTAINER} );
    $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} and 
        return $node->{$NPROP_STORAGE}->_clear_literal_attribute( $node->{$NPROP_CONTAINER}, $attr_name );
    $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} and 
        return $node->{$NPROP_STORAGE}->_clear_enumerated_attribute( $node->{$NPROP_CONTAINER}, $attr_name );
    $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$attr_name} and 
        return $node->{$NPROP_STORAGE}->_clear_node_ref_attribute( $node->{$NPROP_CONTAINER}, $attr_name );
    $node->_throw_error_message( 'SRT_N_METH_ARG_NO_AT_NM', 
        { 'METH' => 'clear_attribute', 'ARGNM' => 'ATTR_NAME', 'ARGVL' => $attr_name } );
}

sub clear_attributes {
    my ($node) = @_;
    $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} and 
        $node->{$NPROP_STORAGE}->_clear_primary_parent_attribute( $node->{$NPROP_CONTAINER} );
    $node->{$NPROP_STORAGE}->_clear_literal_attributes( $node->{$NPROP_CONTAINER} );
    $node->{$NPROP_STORAGE}->_clear_enumerated_attributes( $node->{$NPROP_CONTAINER} );
    $node->{$NPROP_STORAGE}->_clear_node_ref_attributes( $node->{$NPROP_CONTAINER} );
}

sub set_attribute {
    my ($node, $attr_name, $attr_value) = @_;
    defined( $attr_name ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'set_attribute', 'ARGNM' => 'ATTR_NAME' } );
    defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_AT_NO_ARG_VAL', { 'ATNM' => $attr_name } );
    if( ref($attr_value) eq ref($node) ) {
        $attr_value = $attr_value->{$NPROP_STORAGE}; # unwrap any Node object into its NodeStorage; no-op if arg not a Node
    }
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    if( $attr_name eq $ATTR_ID ) {
        return $node->{$NPROP_STORAGE}->_set_node_id( $node->{$NPROP_CONTAINER}, $attr_value );
    }
    if( my $exp_node_types = $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NSREF} ) {
        return $node->{$NPROP_STORAGE}->_set_primary_parent_attribute( $node->{$NPROP_CONTAINER}, $exp_node_types, $attr_value );
    }
    if( my $exp_lit_type = $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} ) {
        return $node->{$NPROP_STORAGE}->_set_literal_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_lit_type, $attr_value );
    }
    if( my $exp_enum_type = $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} ) {
        return $node->{$NPROP_STORAGE}->_set_enumerated_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_enum_type, $attr_value );
    }
    if( my $exp_node_types = $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$attr_name} ) {
        return $node->{$NPROP_STORAGE}->_set_node_ref_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_node_types, $attr_value );
    }
    $node->_throw_error_message( 'SRT_N_METH_ARG_NO_AT_NM', 
        { 'METH' => 'set_attribute', 'ARGNM' => 'ATTR_NAME', 'ARGVL' => $attr_name } );
}

sub set_attributes {
    my ($node, $attrs) = @_;
    defined( $attrs ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'set_attributes', 'ARGNM' => 'ATTRS' } );
    ref($attrs) eq 'HASH' or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_HASH', { 'METH' => 'set_attributes', 'ARGNM' => 'ATTRS', 'ARGVL' => $attrs } );
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    foreach my $attr_name (keys %{$attrs}) {
        my $attr_value = $attrs->{$attr_name};
        defined( $attr_value ) or $node->_throw_error_message( 'SRT_N_SET_ATS_NO_ARG_ELEM_VAL', { 'ATNM' => $attr_name } );
        if( ref($attr_value) eq ref($node) ) {
            $attr_value = $attr_value->{$NPROP_STORAGE}; # unwrap any Node object into its NodeStorage; no-op if arg not a Node
        }
        if( $attr_name eq $ATTR_ID ) {
            $node->{$NPROP_STORAGE}->_set_node_id( $node->{$NPROP_CONTAINER}, $attr_value );
            next;
        }
        if( my $exp_node_types = $attr_name eq $ATTR_PP && $type_info->{$TPI_PP_NSREF} ) {
            $node->{$NPROP_STORAGE}->_set_primary_parent_attribute( $node->{$NPROP_CONTAINER}, $exp_node_types, $attr_value );
            next;
        }
        if( my $exp_lit_type = $type_info->{$TPI_AT_LITERALS} && $type_info->{$TPI_AT_LITERALS}->{$attr_name} ) {
            $node->{$NPROP_STORAGE}->_set_literal_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_lit_type, $attr_value );
            next;
        }
        if( my $exp_enum_type = $type_info->{$TPI_AT_ENUMS} && $type_info->{$TPI_AT_ENUMS}->{$attr_name} ) {
            $node->{$NPROP_STORAGE}->_set_enumerated_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_enum_type, $attr_value );
            next;
        }
        if( my $exp_node_types = $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$attr_name} ) {
            $node->{$NPROP_STORAGE}->_set_node_ref_attribute( $node->{$NPROP_CONTAINER}, $attr_name, $exp_node_types, $attr_value );
            next;
        }
        $node->_throw_error_message( 'SRT_N_SET_ATS_INVAL_ELEM_NM', { 'ATNM' => $attr_name } );
    }
}

######################################################################

sub move_before_sibling {
    my ($node, $sibling, $parent) = @_;
    my $nodstor = $node->{$NPROP_STORAGE};
    my $constor = $nodstor->{$NSPROP_CONSTOR};
    my $pp_pseudonode = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE};

    # First make sure we have 3 actual Nodes that are all in the same Container.

    defined( $sibling ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'move_before_sibling', 'ARGNM' => 'SIBLING' } );
    ref($sibling) eq ref($node) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_NODE', { 'METH' => 'move_before_sibling', 'ARGNM' => 'SIBLING', 'ARGVL' => $sibling } );
    my $sibling_nodstor = $sibling->{$NPROP_STORAGE};
    unless( $sibling_nodstor->{$NSPROP_CONSTOR} eq $constor ) {
        $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_S_DIFF_CONT' );
    }

    my $parent_nodstor = undef;
    if( defined( $parent ) ) {
        ref($parent) eq ref($node) or $node->_throw_error_message( 
            'SRT_N_METH_ARG_NO_NODE', { 'METH' => 'move_before_sibling', 'ARGNM' => 'PARENT', 'ARGVL' => $parent } );
        $parent_nodstor = $parent->{$NPROP_STORAGE};
        unless( $parent_nodstor->{$NSPROP_CONSTOR} eq $constor ) {
            $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_P_DIFF_CONT' );
        }
    } else {
        unless( $parent_nodstor = $nodstor->{$NSPROP_PP_NSREF} ) {
            $pp_pseudonode or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_NO_P_ARG_OR_PP_OR_PS' );
        }
    }

    # Now get the Node list we're going to search through.

    my $ra_search_list = $parent_nodstor ? 
        ($parent_nodstor eq $nodstor->{$NSPROP_PP_NSREF} ? 
            $parent_nodstor->{$NSPROP_PRIM_CHILD_NSREFS} : 
            $parent_nodstor->{$NSPROP_LINK_CHILD_NSREFS}) : 
        $constor->{$CSPROP_PSEUDONODES}->{$pp_pseudonode};

    # Now confirm the given Nodes are our parent and sibling.
    # For efficiency we also prepare to reorder the Nodes at the same time.

    my @curr_node_refs = ();
    my @sib_node_refs = ();
    my @refs_before_both = ();
    my @refs_after_both = ();

    my $others_go_before = 1;
    foreach my $child_nodstor (@{$ra_search_list}) {
        if( $child_nodstor eq $nodstor ) {
            push( @curr_node_refs, $child_nodstor );
        } elsif( $child_nodstor eq $sibling_nodstor ) {
            push( @sib_node_refs, $child_nodstor );
            $others_go_before = 0;
        } elsif( $others_go_before ) {
            push( @refs_before_both, $child_nodstor );
        } else {
            push( @refs_after_both, $child_nodstor );
        }
    }

    scalar( @curr_node_refs ) or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_P_NOT_P' );
    scalar( @sib_node_refs ) or $node->_throw_error_message( 'SRT_N_MOVE_PRE_SIB_S_NOT_S' );

    # Now confirm there are no blocks imposed against this action.

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'move_before_sibling' } );
    (keys %{$sibling_nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $sibling_nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'move_before_sibling' } );
    if( $parent_nodstor ) {
        if( $parent_nodstor eq $nodstor->{$NSPROP_PP_NSREF} ) {
            (keys %{$parent_nodstor->{$NSPROP_ATT_PC_ADD_BLOCKS}}) == 0 or 
                $parent_nodstor->_throw_error_message( 'SRT_N_METH_VIOL_PC_ADD_BLOCKS', { 'METH' => 'move_before_sibling' } );
        } else {
            (keys %{$parent_nodstor->{$NSPROP_ATT_LC_ADD_BLOCKS}}) == 0 or 
                $parent_nodstor->_throw_error_message( 'SRT_N_METH_VIOL_LC_ADD_BLOCKS', { 'METH' => 'move_before_sibling' } );
        }
    }

    # Everything checks out, so now we perform the reordering.

    @{$ra_search_list} = (@refs_before_both, @curr_node_refs, @sib_node_refs, @refs_after_both);
    $constor->{$CSPROP_EDIT_COUNT} ++; # Node relation chg.
}

######################################################################

sub get_child_nodes {
    my ($node, $node_type) = @_;
    my $nodstor = $node->{$NPROP_STORAGE};
    if( defined( $node_type ) ) {
        unless( $NODE_TYPES{$node_type} ) {
            $node->_throw_error_message( 'SRT_N_GET_CH_NODES_BAD_TYPE' );
        }
        return $node->_ns_to_ni( [grep { $_->{$NSPROP_NODE_TYPE} eq $node_type } @{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}] );
    } else {
        return $node->_ns_to_ni( [@{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}] );
    }
}

sub add_child_node {
    my ($node, $child) = @_;
    defined( $child ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'add_child_node', 'ARGNM' => 'CHILD' } );
    ref($child) eq ref($node) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_NODE', { 'METH' => 'add_child_node', 'ARGNM' => 'CHILD', 'ARGVL' => $child } );
    $child = $child->{$NPROP_STORAGE}; # unwrap any Node object into its NodeStorage; no-op if arg not a Node
    my $exp_node_types = $NODE_TYPES{$child->{$NSPROP_NODE_TYPE}}->{$TPI_PP_NSREF} or $child->_throw_error_message( 
        'SRT_N_METH_NO_PP_AT', { 'METH' => 'set_primary_parent_attribute' } );
    $child->_set_primary_parent_attribute( $node->{$NPROP_CONTAINER}, $exp_node_types, $node->{$NPROP_STORAGE} );
        # will die if not same Container or the change would result in a circular reference
}

sub add_child_nodes {
    my ($node, $children) = @_;
    defined( $children ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'add_child_nodes', 'ARGNM' => 'CHILDREN' } );
    ref($children) eq 'ARRAY' or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_ARY', { 'METH' => 'add_child_nodes', 'ARGNM' => 'CHILDREN', 'ARGVL' => $children } );
    foreach my $child (@{$children}) {
        $node->add_child_node( $child );
    }
}

######################################################################

sub get_referencing_nodes {
    my ($node, $node_type) = @_;
    my $nodstor = $node->{$NPROP_STORAGE};
    if( defined( $node_type ) ) {
        unless( $NODE_TYPES{$node_type} ) {
            $node->_throw_error_message( 'SRT_N_GET_REF_NODES_BAD_TYPE' );
        }
        return $node->_ns_to_ni( [grep { $_->{$NSPROP_NODE_TYPE} eq $node_type } @{$nodstor->{$NSPROP_LINK_CHILD_NSREFS}}] );
    } else {
        return $node->_ns_to_ni( [@{$nodstor->{$NSPROP_LINK_CHILD_NSREFS}}] );
    }
}

######################################################################

sub get_surrogate_id_chain {
    my ($node) = @_;
    return $node->{$NPROP_STORAGE}->_get_surrogate_id_chain( $node->{$NPROP_CONTAINER} );
}

######################################################################

sub find_node_by_surrogate_id {
    my ($node, $self_attr_name, $target_attr_value) = @_;
    defined( $self_attr_name ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'find_node_by_surrogate_id', 'ARGNM' => 'SELF_ATTR_NAME' } );
    my $type_info = $NODE_TYPES{$node->{$NPROP_STORAGE}->{$NSPROP_NODE_TYPE}};
    my $exp_node_types = $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$self_attr_name} or 
        $node->_throw_error_message( 'SRT_N_METH_ARG_NO_NREF_AT_NM', 
        { 'METH' => 'find_node_by_surrogate_id', 'ARGNM' => 'SELF_ATTR_NAME', 'ARGVL' => $self_attr_name } );
    defined( $target_attr_value ) or $node->_throw_error_message( 
        'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
    ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
    scalar( @{$target_attr_value} ) >= 1 or $node->_throw_error_message( 
        'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
    foreach my $child (@{$target_attr_value}) {
        defined( $child ) or $node->_throw_error_message( 
            'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL', { 'ATNM' => $self_attr_name } );
    }
    return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_find_node_by_surrogate_id( 
        $node->{$NPROP_CONTAINER}, $self_attr_name, $target_attr_value ) );
}

######################################################################

sub find_child_node_by_surrogate_id {
    my ($node, $target_attr_value) = @_;
    defined( $target_attr_value ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'find_child_node_by_surrogate_id', 'ARGNM' => 'TARGET_ATTR_VALUE' } );
    ref($target_attr_value) eq 'ARRAY' or $target_attr_value = [$target_attr_value];
    return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_find_child_node_by_surrogate_id( 
        $node->{$NPROP_CONTAINER}, $target_attr_value ) );
}

######################################################################

sub get_relative_surrogate_id {
    my ($node, $self_attr_name, $want_shortest) = @_;
    my $nodstor = $node->{$NPROP_STORAGE};
    defined( $self_attr_name ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'get_relative_surrogate_id', 'ARGNM' => 'SELF_ATTR_NAME' } );
    my $type_info = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}};
    my $exp_node_types = $type_info->{$TPI_AT_NSREFS} && $type_info->{$TPI_AT_NSREFS}->{$self_attr_name} or 
        $node->_throw_error_message( 'SRT_N_METH_ARG_NO_NREF_AT_NM', 
        { 'METH' => 'get_relative_surrogate_id', 'ARGNM' => 'SELF_ATTR_NAME', 'ARGVL' => $self_attr_name } );
    return $node->_ns_to_ni( $node->{$NPROP_STORAGE}->_get_relative_surrogate_id( 
        $node->{$NPROP_CONTAINER}, $self_attr_name, $want_shortest ) );
}

######################################################################

sub assert_deferrable_constraints {
    my ($node) = @_;
    $node->{$NPROP_STORAGE}->_assert_deferrable_constraints( $node->{$NPROP_CONTAINER} );
}

######################################################################

sub get_all_properties {
    my ($node, $links_as_si, $want_shortest) = @_;
    return $node->{$NPROP_STORAGE}->_get_all_properties( $node->{$NPROP_CONTAINER} );
}

sub get_all_properties_as_perl_str {
    my ($node, $links_as_si, $want_shortest) = @_;
    return $node->_serialize_as_perl( $node->get_all_properties( $links_as_si, $want_shortest ) );
}

sub get_all_properties_as_xml_str {
    my ($node, $links_as_si, $want_shortest) = @_;
    return '<?xml version="1.0" encoding="UTF-8"?>'."\n".
        $node->_serialize_as_xml( $node->get_all_properties( $links_as_si, $want_shortest ) );
}

######################################################################

sub build_node {
    my ($node, $node_type, $attrs) = @_;
    return $node->{$NPROP_CONTAINER}->_build_node_is_child_or_not( $node_type, $attrs );
}

sub build_child_node {
    my ($node, $node_type, $attrs) = @_;
    return $node->{$NPROP_CONTAINER}->_build_node_is_child_or_not( $node_type, $attrs, $node );
}

sub build_child_nodes {
    my ($node, $children) = @_;
    defined( $children ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN' } );
    ref($children) eq 'ARRAY' or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_ARY', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN', 'ARGVL' => $children } );
    foreach my $child (@{$children}) {
        defined( $child ) or $node->_throw_error_message( 
            'SRT_N_METH_ARG_ARY_ELEM_UNDEF', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN' } );
        ref($child) eq 'ARRAY' or $node->_throw_error_message( 
            'SRT_N_METH_ARG_ARY_ELEM_NO_ARY', { 'METH' => 'build_child_nodes', 'ARGNM' => 'CHILDREN', 'ELEMVL' => $child } );
        $node->build_child_node( @{$child} );
    }
}

sub build_child_node_tree {
    my ($node, $node_type, $attrs, $children) = @_;
    my $new_node = $node->{$NPROP_CONTAINER}->_build_node_is_child_or_not( $node_type, $attrs, $node );
    defined( $children ) and $new_node->build_child_node_trees( $children );
    return $new_node;
}

sub build_child_node_trees {
    my ($node, $children) = @_;
    defined( $children ) or $node->_throw_error_message( 
        'SRT_N_METH_ARG_UNDEF', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN' } );
    ref($children) eq 'ARRAY' or $node->_throw_error_message( 
        'SRT_N_METH_ARG_NO_ARY', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN', 'ARGVL' => $children } );
    foreach my $child (@{$children}) {
        defined( $child ) or $node->_throw_error_message( 
            'SRT_N_METH_ARG_ARY_ELEM_UNDEF', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN' } );
        ref($child) eq 'ARRAY' or $node->_throw_error_message( 
            'SRT_N_METH_ARG_ARY_ELEM_NO_ARY', { 'METH' => 'build_child_node_trees', 'ARGNM' => 'CHILDREN', 'ELEMVL' => $child } );
        $node->build_child_node_tree( @{$child} );
    }
}

######################################################################
######################################################################

package SQL::Routine::NodeStorage;
use base qw( SQL::Routine );

######################################################################

sub _new {
    my ($class, $constor, $node_type, $node_id) = @_;
    my $nodstor = bless( {}, ref($class) || $class );

    $nodstor->{$NSPROP_CONSTOR} = $constor;
    Scalar::Util::weaken( $nodstor->{$NSPROP_CONSTOR} ); # avoid strong circular references
    $nodstor->{$NSPROP_NODE_TYPE} = $node_type;
    $nodstor->{$NSPROP_NODE_ID} = $node_id;
    $nodstor->{$NSPROP_PP_NSREF} = undef;
    $nodstor->{$NSPROP_AT_LITERALS} = {};
    $nodstor->{$NSPROP_AT_ENUMS} = {};
    $nodstor->{$NSPROP_AT_NSREFS} = {};
    $nodstor->{$NSPROP_PRIM_CHILD_NSREFS} = [];
    $nodstor->{$NSPROP_LINK_CHILD_NSREFS} = [];
    $nodstor->{$NSPROP_ATT_WRITE_BLOCKS} = {};
    $nodstor->{$NSPROP_ATT_PC_ADD_BLOCKS} = {};
    $nodstor->{$NSPROP_ATT_LC_ADD_BLOCKS} = {};
    $nodstor->{$NSPROP_ATT_MUTEX} = undef;

    $constor->{$CSPROP_ALL_NODES}->{$node_id} = $nodstor;

    # Now get our parent pseudo-Node to link back to us, if there is one.
    my $type_info = $NODE_TYPES{$node_type};
    if( my $pp_pseudonode = $type_info->{$TPI_PP_PSEUDONODE} ) {
        push( @{$constor->{$CSPROP_PSEUDONODES}->{$pp_pseudonode}}, $nodstor );
    }

    # Now adjust our "next free node id" counter if appropriate
    if( $node_id >= $constor->{$CSPROP_NEXT_FREE_NID} ) {
        $constor->{$CSPROP_NEXT_FREE_NID} = 1 + $node_id;
    }

    $constor->{$CSPROP_EDIT_COUNT} ++; # A Node has arrived.
        # Turn on tests because this Node's presence affects *other* Nodes.

    return $nodstor;
}

######################################################################

sub _delete_node {
    my ($nodstor, $container) = @_;
    my $constor = $container->{$CPROP_STORAGE};

    if( @{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}} > 0 or @{$nodstor->{$NSPROP_LINK_CHILD_NSREFS}} > 0 ) {
        $nodstor->_throw_error_message( 'SRT_N_DEL_NODE_HAS_CHILD', 
            { 'PRIM_COUNT' => scalar( @{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}} ), 
            'LINK_COUNT' => scalar( @{$nodstor->{$NSPROP_LINK_CHILD_NSREFS}} ) } );
    }

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'delete_node' } );

    # Remove our parent Nodes' links back to us.
    if( my $pp_pseudonode = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE} ) {
        my $siblings = $constor->{$CSPROP_PSEUDONODES}->{$pp_pseudonode};
        @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove the occurance
    } elsif( my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF} ) {
        my $siblings = $pp_nodstor->{$NSPROP_PRIM_CHILD_NSREFS};
        @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove the occurance
    }
    foreach my $attr_value (values %{$nodstor->{$NSPROP_AT_NSREFS}}) {
        my $siblings = $attr_value->{$NSPROP_LINK_CHILD_NSREFS};
        @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove all occurances
    }

    # Remove primary Container link to us.
    delete( $constor->{$CSPROP_ALL_NODES}->{$nodstor->{$NSPROP_NODE_ID}} );

    # Note: We do not need to explicitly remove any links held by the invocant 
    # NodeStorage to its ContainerStorage or parent NodeStorages because they will be garbage 
    # collected along with the invocant NodeStorage once this method returns; 
    # the invocant Node interface will be garbage collected when reference the reference to it held by 
    # the external invoker code goes out of scope.

    $constor->{$CSPROP_EDIT_COUNT} ++; # A Node is gone.
        # Turn on tests because this Node's absence affects *other* Nodes.
}

######################################################################

sub _delete_node_tree {
    my ($nodstor, $container) = @_;
    my $constor = $container->{$CPROP_STORAGE};

    # Now build a list of all primary-descendant NodeStorages (includes self), 
    # which are the deletion candidates.
    my %candidates = ();
    $nodstor->_delete_node_tree__add_to_candidates( \%candidates );

    # Now assert that all primary-descendant NodeStorages (includes self) may be deleted, 
    # and lack children outside the candidates.
    foreach my $candidate (values %candidates) {
        foreach my $link_child_nodstor (@{$candidate->{$NSPROP_LINK_CHILD_NSREFS}}) {
            unless( $candidates{$link_child_nodstor} ) {
                $nodstor->_throw_error_message( 'SRT_N_DEL_NODE_TREE_HAS_EXT_CHILD', 
                    { 'PNTYPE' => $candidate->{$NSPROP_NODE_TYPE}, 
                    'PNID' => $candidate->{$NSPROP_NODE_ID}, 
                    'PSIDCH' => $candidate->_get_surrogate_id_chain( $container ), 
                    'CNTYPE' => $link_child_nodstor->{$NSPROP_NODE_TYPE}, 
                    'CNID' => $link_child_nodstor->{$NSPROP_NODE_ID}, 
                    'CSIDCH' => $link_child_nodstor->_get_surrogate_id_chain( $container ) } );
            }
        }
    }

    # Now assert that no Nodes have blocks imposed on them.
    foreach my $candidate (values %candidates) {
        (keys %{$candidate->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
            $candidate->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'delete_node' } );
    }

    # If we get here, then all of the candidate NodeStorages may be deleted.

    # Now remove the single prim-child ref to the tree's root NodeStorage.
    if( my $pp_pseudonode = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE} ) {
        my $siblings = $constor->{$CSPROP_PSEUDONODES}->{$pp_pseudonode};
        @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove the occurance
    } elsif( my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF} ) {
        my $siblings = $pp_nodstor->{$NSPROP_PRIM_CHILD_NSREFS};
        @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove the occurance
    }

    # Now remove all of the link-child refs to the candidates that are in non-candidate NodeStorages.
    # Also remove all candidates from their Container's all-nodes list.
    my $cont_all_nodes = $constor->{$CSPROP_ALL_NODES};
    foreach my $candidate (values %candidates) {
        foreach my $attr_value (values %{$candidate->{$NSPROP_AT_NSREFS}}) {
            $candidates{$attr_value} and next; # just do this slower unlinking process if parent not being deleted
            my $siblings = $attr_value->{$NSPROP_LINK_CHILD_NSREFS};
            @{$siblings} = grep { $_ ne $candidate } @{$siblings}; # remove all occurances
        }
        delete( $cont_all_nodes->{$candidate->{$NSPROP_NODE_ID}} );
    }

    # Note: We do not need to explicitly remove any links held by the invocant 
    # NodeStorage to its ContainerStorage or parent NodeStorages because they will be garbage 
    # collected along with the invocant NodeStorage once this method returns; 
    # the invocant Node interface will be garbage collected when reference the reference to it held by 
    # the external invoker code goes out of scope.

    $constor->{$CSPROP_EDIT_COUNT} ++; # Several Nodes are gone.
        # Turn on tests because this Node's absence affects *other* Nodes.
}

sub _delete_node_tree__add_to_candidates {
    my ($nodstor, $candidates) = @_;
    $candidates->{$nodstor} = $nodstor; # key is stringified version of Node ref, value is actual Node ref
    foreach my $prim_child_nodstor (@{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
        $prim_child_nodstor->_delete_node_tree__add_to_candidates( $candidates );
    }
}

######################################################################

sub _get_node_id {
    my ($nodstor, $container) = @_;
    return $nodstor->{$NSPROP_NODE_ID};
}

sub _set_node_id {
    my ($nodstor, $container, $new_id) = @_;
    my $constor = $container->{$CPROP_STORAGE};

    unless( $new_id =~ m/^\d+$/ and $new_id > 0 ) {
        $nodstor->_throw_error_message( 'SRT_N_SET_NODE_ID_BAD_ARG', { 'ARG' => $new_id } );
    }

    my $old_id = $nodstor->{$NSPROP_NODE_ID};

    if( $new_id == $old_id ) {
        return; # no-op; new id same as old
    }
    my $rh_cal = $constor->{$CSPROP_ALL_NODES};

    if( $rh_cal->{$new_id} ) {
        $nodstor->_throw_error_message( 'SRT_N_SET_NODE_ID_DUPL_ID', { 'ARG' => $new_id } );
    }

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'set_node_id' } );

    # The following seq should leave state consistent or recoverable if the thread dies
    $rh_cal->{$new_id} = $nodstor; # temp reserve new+old
    $nodstor->{$NSPROP_NODE_ID} = $new_id; # change self from old to new
    delete( $rh_cal->{$old_id} ); # now only new reserved
    $constor->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.

    # Now adjust our "next free node id" counter if appropriate
    if( $new_id >= $constor->{$CSPROP_NEXT_FREE_NID} ) {
        $constor->{$CSPROP_NEXT_FREE_NID} = 1 + $new_id;
    }
}

######################################################################

sub _get_primary_parent_attribute {
    my ($nodstor, $container) = @_;
    return $nodstor->{$NSPROP_PP_NSREF};
}

sub _clear_primary_parent_attribute {
    my ($nodstor, $container) = @_;
    my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF} or return; # no-op; attr not set
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_primary_parent_attribute' } );
    # The attribute value is a Node object, so clear its link back.
    my $siblings = $pp_nodstor->{$NSPROP_PRIM_CHILD_NSREFS};
    @{$siblings} = grep { $_ ne $nodstor } @{$siblings}; # remove the occurance
    $nodstor->{$NSPROP_PP_NSREF} = undef; # removes link to primary-parent, if any
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _set_primary_parent_attribute {
    my ($nodstor, $container, $exp_node_types, $attr_value) = @_;

    if( ref($attr_value) eq ref($nodstor) ) {
        # We were given a Node object for a new attribute value.
        unless( grep { $attr_value->{$NSPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_PP_AT_WRONG_NODE_TYPE', 
                { 'EXPNTYPE' => $exp_node_types, 'ARGNTYPE' => $attr_value->{$NSPROP_NODE_TYPE} } );
        }
        unless( $attr_value->{$NSPROP_CONSTOR} eq $nodstor->{$NSPROP_CONSTOR} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_PP_AT_DIFF_CONT' );
        }
        # If we get here, both Nodes are in the same Container and can link
    } elsif( $attr_value =~ m/^\d+$/ and $attr_value > 0 ) {
        # We were given a Node Id for a new attribute value.
        my $searched_attr_value = $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_ALL_NODES}->{$attr_value};
        unless( $searched_attr_value and grep { $searched_attr_value->{$NSPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_PP_AT_NONEX_NID', 
                { 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types } );
        }
        $attr_value = $searched_attr_value;
    } else {
        # We were given a Surrogate Node Id for a new attribute value.
        $nodstor->_throw_error_message( 'SRT_N_SET_PP_AT_NO_ALLOW_SID_FOR_PP' );
    }

    if( $nodstor->{$NSPROP_PP_NSREF} and $attr_value eq $nodstor->{$NSPROP_PP_NSREF} ) {
        return; # no-op; new attribute value same as old
    }

    # Attempt is to link two Nodes in the same Container; it would be okay, except 
    # that we still have to check for circular primary parent Node references.
    my $pp_nodstor = $attr_value;
    do { # Also make sure we aren't trying to link to ourself.
        if( $pp_nodstor eq $nodstor ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_PP_AT_CIRC_REF' );
        }
    } while( $pp_nodstor = $pp_nodstor->{$NSPROP_PP_NSREF} );
    # For simplicity, we assume circular refs via Node-ref attrs other than 'pp' are impossible.

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'set_primary_parent_attribute' } );
    (keys %{$attr_value->{$NSPROP_ATT_PC_ADD_BLOCKS}}) == 0 or 
        $attr_value->_throw_error_message( 'SRT_N_METH_VIOL_PC_ADD_BLOCKS', { 'METH' => 'set_primary_parent_attribute' } );

    $nodstor->_clear_primary_parent_attribute( $container ); # clears any existing link through this attribute
    $nodstor->{$NSPROP_PP_NSREF} = $attr_value;
    Scalar::Util::weaken( $nodstor->{$NSPROP_PP_NSREF} ); # avoid strong circular references
    # The attribute value is a Node object, so that Node should link back now.
    push( @{$attr_value->{$NSPROP_PRIM_CHILD_NSREFS}}, $nodstor );
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

######################################################################

sub _get_literal_attribute {
    my ($nodstor, $container, $attr_name) = @_;
    return $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name};
}

sub _clear_literal_attribute {
    my ($nodstor, $container, $attr_name) = @_;
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attribute' } );
    delete( $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name} );
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _clear_literal_attributes {
    my ($nodstor, $container) = @_;
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attributes' } );
    $nodstor->{$NSPROP_AT_LITERALS} = {};
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _set_literal_attribute {
    my ($nodstor, $container, $attr_name, $exp_lit_type, $attr_value) = @_;

    if( ref($attr_value) ) {
        $nodstor->_throw_error_message( 'SRT_N_SET_AT_INVAL_LIT_V_IS_REF', 
            { 'ATNM' => $attr_name, 'ARG_REF_TYPE' => ref($attr_value) } );
    }

    my $node_type = $nodstor->{$NSPROP_NODE_TYPE};

    if( $exp_lit_type eq 'bool' ) {
        unless( $attr_value eq '0' or $attr_value eq '1' ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_INVAL_LIT_V_BOOL', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value } );
        }

    } elsif( $exp_lit_type eq 'uint' ) {
        unless( $attr_value =~ m/^\d+$/ and $attr_value > 0 ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_INVAL_LIT_V_UINT', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value } );
        }

    } elsif( $exp_lit_type eq 'sint' ) {
        unless( $attr_value =~ m/^-?\d+$/ ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_INVAL_LIT_V_SINT', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value } );
        }

    } else {} # $exp_lit_type eq 'cstr' or 'misc'; no change to value needed

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'set_attribute' } );

    $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name} = $attr_value;
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

######################################################################

sub _get_enumerated_attribute {
    my ($nodstor, $container, $attr_name) = @_;
    return $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name};
}

sub _clear_enumerated_attribute {
    my ($nodstor, $container, $attr_name) = @_;
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attribute' } );
    delete( $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name} );
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _clear_enumerated_attributes {
    my ($nodstor, $container) = @_;
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attributes' } );
    $nodstor->{$NSPROP_AT_ENUMS} = {};
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _set_enumerated_attribute {
    my ($nodstor, $container, $attr_name, $exp_enum_type, $attr_value) = @_;

    unless( $ENUMERATED_TYPES{$exp_enum_type}->{$attr_value} ) {
        $nodstor->_throw_error_message( 'SRT_N_SET_AT_INVAL_ENUM_V', { 'ATNM' => $attr_name, 
            'ENUMTYPE' => $exp_enum_type, 'ARG' => $attr_value } );
    }

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'set_attribute' } );

    $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name} = $attr_value;
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

######################################################################

sub _get_node_ref_attribute {
    my ($nodstor, $container, $attr_name, $get_target_si) = @_;
    my $attr_val = $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name};
    if( $get_target_si and defined($attr_val) ) {
        return $attr_val->_get_surrogate_id_attribute( $container, $get_target_si );
    } else {
        return $attr_val;
    }
}

sub _clear_node_ref_attribute {
    my ($nodstor, $container, $attr_name) = @_;
    my $attr_value = $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} or return; # no-op; attr not set
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attribute' } );
    # The attribute value is a Node object, so clear its link back.
    my $ra_children_of_parent = $attr_value->{$NSPROP_LINK_CHILD_NSREFS};
    foreach my $i (0..$#{$ra_children_of_parent}) {
        if( $ra_children_of_parent->[$i] eq $nodstor ) {
            # remove first instance of $nodstor from it's parent's child list
            splice( @{$ra_children_of_parent}, $i, 1 );
            last;
        }
    }
    delete( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ); # removes link to link-parent, if any
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _clear_node_ref_attributes {
    my ($nodstor, $container) = @_;
    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'clear_attributes' } );
    foreach my $attr_name (keys %{$nodstor->{$NSPROP_AT_NSREFS}}) {
        $nodstor->_clear_node_ref_attribute( $container, $attr_name );
    }
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

sub _set_node_ref_attribute {
    my ($nodstor, $container, $attr_name, $exp_node_types, $attr_value) = @_;

    if( ref($attr_value) eq ref($nodstor) ) {
        # We were given a Node object for a new attribute value.
        unless( grep { $attr_value->{$NSPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_WRONG_NODE_TYPE', { 'ATNM' => $attr_name, 
                'EXPNTYPE' => $exp_node_types, 'ARGNTYPE' => $attr_value->{$NSPROP_NODE_TYPE} } );
        }
        unless( $attr_value->{$NSPROP_CONSTOR} eq $nodstor->{$NSPROP_CONSTOR} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_DIFF_CONT', { 'ATNM' => $attr_name } );
        }
        # If we get here, both Nodes are in the same Container and can link
    } elsif( $attr_value =~ m/^\d+$/ and $attr_value > 0 ) {
        # We were given a Node Id for a new attribute value.
        my $searched_attr_value = $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_ALL_NODES}->{$attr_value};
        unless( $searched_attr_value and grep { $searched_attr_value->{$NSPROP_NODE_TYPE} eq $_ } @{$exp_node_types} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_NONEX_NID', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types } );
        }
        $attr_value = $searched_attr_value;
    } else {
        # We were given a Surrogate Node Id for a new attribute value.
        unless( $container->{$CPROP_MAY_MATCH_SNIDS} ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_NO_ALLOW_SID', { 'ATNM' => $attr_name, 'ARG' => $attr_value } );
        }
        my $searched_attr_values = $nodstor->_find_node_by_surrogate_id( $container, $attr_name, 
            ref($attr_value) eq 'ARRAY' ? $attr_value : [$attr_value] );
        unless( $searched_attr_values ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_NONEX_SID', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types } );
        }
        if( @{$searched_attr_values} > 1 ) {
            $nodstor->_throw_error_message( 'SRT_N_SET_AT_NREF_AMBIG_SID', 
                { 'ATNM' => $attr_name, 'ARG' => $attr_value, 'EXPNTYPE' => $exp_node_types, 
                'CANDIDATES' => [';', map { (@{$_->get_surrogate_id_chain()},';') } @{$searched_attr_values}] } );
        }
        $attr_value = $searched_attr_values->[0];
    }

    if( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} and $attr_value eq $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ) {
        return; # no-op; new attribute value same as old
    }

    (keys %{$nodstor->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
        $nodstor->_throw_error_message( 'SRT_N_METH_VIOL_WRITE_BLOCKS', { 'METH' => 'set_attribute' } );
    (keys %{$attr_value->{$NSPROP_ATT_LC_ADD_BLOCKS}}) == 0 or 
        $attr_value->_throw_error_message( 'SRT_N_METH_VIOL_LC_ADD_BLOCKS', { 'METH' => 'set_attribute' } );

    $nodstor->_clear_node_ref_attribute( $container, $attr_name ); # clears any existing link through this attribute
    $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} = $attr_value;
    Scalar::Util::weaken( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ); # avoid strong circular references
    # The attribute value is a Node object, so that Node should link back now.
    push( @{$attr_value->{$NSPROP_LINK_CHILD_NSREFS}}, $nodstor );
    $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_EDIT_COUNT} ++; # A Node was changed.
}

######################################################################

sub _get_surrogate_id_attribute {
    my ($nodstor, $container, $get_target_si) = @_;
    my ($id, $lit, $enum, $nref) = @{$NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_SI_ATNM}};
    $id and return $nodstor->_get_node_id( $container );
    $lit and return $nodstor->_get_literal_attribute( $container, $lit );
    $enum and return $nodstor->_get_enumerated_attribute( $container, $enum );
    $nref and return $nodstor->_get_node_ref_attribute( $container, $nref, $get_target_si );
}

######################################################################

sub _get_surrogate_id_chain {
    my ($nodstor, $container) = @_;
    my $si_atvl = $nodstor->_get_surrogate_id_attribute( $container, 1 ); # target SI lit/enum is being returned as a string
    if( my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF} ) {
        # Current Node has a primary-parent Node; append to its id chain.
        my $elements = $pp_nodstor->_get_surrogate_id_chain( $container );
        push( @{$elements}, $si_atvl );
        return $elements;
    } elsif( my $l2_psnd = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_PP_PSEUDONODE} ) {
        # Current Node has a primary-parent pseudo-Node; append to its id chain.
        return [undef, $SQLRT_L1_ROOT_PSND, $l2_psnd, $si_atvl];
    } else {
        # Current Node is not linked to the main Node tree yet; indicate this with non-undef first chain element.
        return [$si_atvl];
    }
}

######################################################################

sub _find_node_by_surrogate_id {
    my ($nodstor, $container, $self_attr_name, $target_attr_value) = @_;
    my $type_info = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}};
    my $exp_node_types = $type_info->{$TPI_AT_NSREFS}->{$self_attr_name};
    my %exp_p_node_types = map { ($_ => 1) } @{$exp_node_types};
    if( my $search_path = $type_info->{$TPI_ANCES_ATCORS} && $type_info->{$TPI_ANCES_ATCORS}->{$self_attr_name} ) {
        # The value we are searching for must be the child part of a correlated pair.
        return $nodstor->_find_node_by_surrogate_id_using_path( $container, \%exp_p_node_types, $target_attr_value, $search_path );
    }
    # If we get here, the value we are searching for is not the child part of a correlated pair.
    my %remotely_addressable_types = map { ($_ => $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR}) } 
        grep { $NODE_TYPES{$_}->{$TPI_REMOTE_ADDR} } @{$exp_node_types};
    my ($unqualified_value, $qualifier_l1, @rest) = @{$target_attr_value};
    if( $qualifier_l1 ) {
        # An attempt is definitely being made to remotely address a Node.
        scalar( keys %remotely_addressable_types ) >= 1 or $nodstor->_throw_error_message( 
            'SRT_N_FIND_ND_BY_SID_NO_REM_ADDR', { 'ATNM' => $self_attr_name, 'ATVL' => $target_attr_value } );
        # If we get here, we are allowed to remotely address a Node.
        return $nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, $target_attr_value );
    }
    # If we get here, we are searching with a purely unqualified target SI value.
    # First try to find the target among our ancestors' siblings.
    if( my $result = $nodstor->_find_node_by_surrogate_id_within_layers( $container, \%exp_p_node_types, $unqualified_value ) ) {
        return $result;
    }
    # If we get here, there were no ancestor sibling matches.
    if( scalar( keys %remotely_addressable_types ) >= 1 ) {
        # If we get here, we are allowed to remotely address a Node.
        return $nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, $target_attr_value );
    }
    # If we get here, all search attempts failed.
    return;
}

sub _find_node_by_surrogate_id_remotely {
    # Method assumes $exp_p_node_types only contains Node types that can be remotely addressable.
    # Within this method, values of $exp_p_node_types are arrays of expected ancestor types for the keys.
    my ($nodstor, $container, $exp_p_node_types, $target_attr_value) = @_;
    my @search_chain = reverse @{$target_attr_value};
    my %exp_anc_node_types = map { ($_ => 1) } map { @{$_} } values %{$exp_p_node_types};
    # First check if we, ourselves, are a child of an expected ancestor type; 
    # if we are, then we should search beneath our own ancestor first.
    my $self_anc_nodstor = $nodstor;
    while( $self_anc_nodstor and !$exp_anc_node_types{$self_anc_nodstor->{$NSPROP_NODE_TYPE}} ) {
        $self_anc_nodstor = $self_anc_nodstor->{$NSPROP_PP_NSREF};
    }
    if( $self_anc_nodstor ) {
        # Search beneath our own ancestor first.
        my $curr_nodstor = $nodstor;
        do {
            # $curr_node is everything from our parent to and including the remote ancestor.
            $curr_nodstor = $curr_nodstor->{$NSPROP_PP_NSREF};
            if( my $result = $curr_nodstor->_find_node_by_surrogate_id_remotely_below_here( $container, $exp_p_node_types, \@search_chain ) ) {
                return $result;
            }
        } until( $curr_nodstor eq $self_anc_nodstor );
    }
    # If we get here, we either have no qualified ancestor, or nothing was found when starting beneath it.
    # Now look beneath other allowable ancestors.
    my %psn_roots = map { ($_ => 1) } grep { $_ } map { $NODE_TYPES{$_}->{$TPI_PP_PSEUDONODE} } keys %exp_anc_node_types;
    my $pseudonodes = $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_PSEUDONODES};
    my @anc_nodstors = grep { $exp_anc_node_types{$_->{$NSPROP_NODE_TYPE}} } 
        map { @{$pseudonodes->{$_}} } grep { $psn_roots{$_} } @L2_PSEUDONODE_LIST;
    my @matched_node_list = ();
    foreach my $anc_nodstor (@anc_nodstors) {
        if( my $result = $anc_nodstor->_find_node_by_surrogate_id_remotely_below_here( $container, $exp_p_node_types, \@search_chain ) ) {
            push( @matched_node_list, @{$result} );
        }
    }
    return @matched_node_list == 0 ? undef : \@matched_node_list;
}

sub _find_node_by_surrogate_id_remotely_below_here {
    # Method assumes $exp_p_node_types only contains Node types that can be remotely addressable.
    my ($nodstor, $container, $exp_p_node_types, $search_chain_in) = @_;
    my @search_chain = @{$search_chain_in} or return; # search chain empty; no match possible
    my $si_atvl = $nodstor->_get_surrogate_id_attribute( $container, 1 ) or return;
    if( $exp_p_node_types->{$nodstor->{$NSPROP_NODE_TYPE}} ) {
        # It is illegal to remotely match a Node that is a child of a remotely matcheable type.
        # Therefore, the invocant Node must be the end of the line, win or lose; its children can not be searched.
        if( @search_chain == 1 and $si_atvl eq $search_chain[0] ) {
            # We have a single perfectly matching Node along this path.
            return [$nodstor];
        } else {
            # No match, and we can't go further anyway.
            return; 
        }
    }
    # If we get here, the invocant Node can not be returned regardless of its name; proceed to its children.
    if( @search_chain > 1 and $si_atvl eq $search_chain[0] ) {
        # There are at least 2 chain elements left, so the invocant Node may match the first one.
        shift( @search_chain );
    }
    # If we get here, there is at least 1 more unmatched search chain element.
    my @matched_node_list = ();
    foreach my $child (@{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
        if( my $result = $child->_find_node_by_surrogate_id_remotely_below_here( $container, $exp_p_node_types, \@search_chain ) ) {
            push( @matched_node_list, @{$result} );
        }
    }
    return @matched_node_list == 0 ? undef : \@matched_node_list;
}

sub _find_node_by_surrogate_id_within_layers {
    my ($nodstor, $container, $exp_p_node_types, $target_attr_value) = @_;
    my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF};

    # Now determine who our siblings are.

    my @sibling_list = ();
    if( $pp_nodstor ) {
        # We have a normal Node primary-parent, P.
        # Search among all Nodes that have P as their primary-parent Node; these are our siblings.
        @sibling_list = @{$pp_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}};
    } else {
        # Either we have a pseudo-Node primary-parent, or no parent normal Node is defined for us.
        # Search among all Nodes that have pseudo-Node primary-parents.
        my $pseudonodes = $nodstor->{$NSPROP_CONSTOR}->{$CSPROP_PSEUDONODES};
        @sibling_list = map { @{$pseudonodes->{$_}} } @L2_PSEUDONODE_LIST;
    }

    # Now search among our siblings for a match.

    foreach my $sibling_nodstor (@sibling_list) {
        $exp_p_node_types->{$sibling_nodstor->{$NSPROP_NODE_TYPE}} or next;
        if( my $si_atvl = $sibling_nodstor->_get_surrogate_id_attribute( $container, 1 ) ) {
            if( $si_atvl eq $target_attr_value ) {
                return [$sibling_nodstor];
            }
        }
    }

    # Nothing was found among our siblings.

    if( $pp_nodstor ) {
        # We are not at the tree's root, so move upwards by a generation and try again.
        return $pp_nodstor->_find_node_by_surrogate_id_within_layers( $container, $exp_p_node_types, $target_attr_value );
    } else {
        # There is no further up that we can go, so no match was found.
        return;
    }
}

sub _find_node_by_surrogate_id_using_path {
    my ($nodstor, $container, $exp_p_node_types, $target_attr_value, $search_path) = @_;
    my $curr_nodstor = $nodstor;
    my ($unqualified_value, $qualifier_l1, @rest) = @{$target_attr_value};

    # Now enumerate through the explicit search path elements, updating $curr_node in the process.

    foreach my $path_seg (@{$search_path}) {
        if( ref($path_seg) eq 'HASH' ) { # <nref-attr-pick>
            # Convert the <nref-attr-pick> into an <nref-attr> based on the current Node's Node type.
            # If the lookup returns nothing, then this is an explicit failure condition so return.
            $path_seg = $path_seg->{$curr_nodstor->{$NSPROP_NODE_TYPE}} or return;
        }
        if( $path_seg eq $S ) { # <self> is a no-op, existing for easier-to-read documentation only
            # no-op
        } elsif( $path_seg eq $P ) { # <primary-parent>
            unless( $curr_nodstor = $curr_nodstor->{$NSPROP_PP_NSREF} ) {
                return; # current Node's primary parent isn't set yet (it should be); get out
            }
        } elsif( $path_seg eq $R ) { # <root-of-kind>
            while( $curr_nodstor->{$NSPROP_PP_NSREF} and 
                    $curr_nodstor->{$NSPROP_PP_NSREF}->{$NSPROP_NODE_TYPE} eq $curr_nodstor->{$NSPROP_NODE_TYPE} ) {
                $curr_nodstor = $curr_nodstor->{$NSPROP_PP_NSREF};
            }
        } elsif( $path_seg eq $C ) { # <primary-child>
            # For simplicity we are assuming the $C is the end of the path; it's grand-child or bust.
            if( defined($qualifier_l1) ) {
                # Given value is qualified; only look within the specified contexts.
                foreach my $child_l1 (@{$curr_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
                    my $si_atvl = $child_l1->_get_surrogate_id_attribute( $container, 1 ) or next;
                    $si_atvl eq $qualifier_l1 or next;
                    foreach my $child_l2 (@{$child_l1->{$NSPROP_PRIM_CHILD_NSREFS}}) {
                        $exp_p_node_types->{$child_l2->{$NSPROP_NODE_TYPE}} or next;
                        if( my $si_atvl = $child_l2->_get_surrogate_id_attribute( $container, 1 ) ) {
                            if( $si_atvl eq $unqualified_value ) {
                                return [$child_l2];
                            }
                        }
                    }
                }
            } else { 
                # Given value is unqualified; take any ones that match.
                my @matched_node_list = ();
                foreach my $grandchild (map { @{$_->{$NSPROP_PRIM_CHILD_NSREFS}} } @{$curr_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
                    $exp_p_node_types->{$grandchild->{$NSPROP_NODE_TYPE}} or next;
                    if( my $si_atvl = $grandchild->_get_surrogate_id_attribute( $container, 1 ) ) {
                        if( $si_atvl eq $unqualified_value ) {
                            push( @matched_node_list, $grandchild );
                        }
                    }
                }
                return @matched_node_list == 0 ? undef : \@matched_node_list;
            }
            return;
        } else { # <nref-attr>; $path_seg is an attribute name
            unless( $curr_nodstor = $curr_nodstor->{$NSPROP_AT_NSREFS}->{$path_seg} ) {
                return; # the Node-ref attribute we should follow isn't set yet (it should be); get out
            }
        }
    }

    # We are at the end of the explicit search path, and the start of the implicit path.
    # Now enumerate through any wrapper attributes, if there are any, updating $curr_node in the process.

    while( my $wr_atnm = $NODE_TYPES{$curr_nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_WR_ATNM} ) {
        unless( $curr_nodstor = $curr_nodstor->{$NSPROP_AT_NSREFS}->{$wr_atnm} ) {
            return; # the Node-ref attribute we should follow isn't set yet (it should be); get out
        }
    }

    # We are at the end of the implicit search path.
    # The required Node must be one of $curr_node's children.

    foreach my $child (@{$curr_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
        $exp_p_node_types->{$child->{$NSPROP_NODE_TYPE}} or next;
        if( my $si_atvl = $child->_get_surrogate_id_attribute( $container, 1 ) ) {
            if( $si_atvl eq $unqualified_value ) {
                return [$child];
            }
        }
    }

    # Nothing was found, nothing more to search.

    return;
}

######################################################################

sub _find_child_node_by_surrogate_id {
    my ($nodstor, $container, $target_attr_value) = @_;
    if( defined( $target_attr_value->[0] ) ) {
        # The given surrogate id chain is relative to the current Node.
        my $curr_nodstor = $nodstor;
        ELEM: foreach my $chain_element (@{$target_attr_value}) {
            foreach my $child (@{$curr_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}) {
                if( my $si_atvl = $child->_get_surrogate_id_attribute( $container, 1 ) ) {
                    if( $si_atvl eq $chain_element ) {
                        $curr_nodstor = $child;
                        next ELEM;
                    }
                }
            }
            return;
        }
        return $curr_nodstor;
    } else {
        # The given surrogate id chain starts at the root of the current Node's Container.
        return $nodstor->{$NSPROP_CONSTOR}->_find_child_node_by_surrogate_id( $container, $target_attr_value );
    }
}

######################################################################

sub _get_relative_surrogate_id {
    my ($nodstor, $container, $self_attr_name, $want_shortest) = @_;
    my $type_info = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}};
    my $exp_node_types = $type_info->{$TPI_AT_NSREFS}->{$self_attr_name};
    my $attr_value = $nodstor->{$NSPROP_AT_NSREFS}->{$self_attr_name} or return;
    my $attr_value_si_atvl = $attr_value->_get_surrogate_id_attribute( $container, 1 );
    if( my $search_path = $type_info->{$TPI_ANCES_ATCORS} && $type_info->{$TPI_ANCES_ATCORS}->{$self_attr_name} ) {
        # The value we are outputting is the child part of a correlated pair.
        if( $search_path->[-1] eq $C ) {
            # For simplicity, assume only one $C, which is at the end of the search path, as find_*() does.
            my $p_of_attr_value = $attr_value->{$NSPROP_PP_NSREF} or return; # linked Node not in tree
            my $p_of_attr_value_si_atvl = $p_of_attr_value->_get_surrogate_id_attribute( $container, 1 );
            # Now we have the info we need.  However, we may optionally abbreviate output further.
            if( $want_shortest ) {
                # We want to further abbreviate output, check if $attr_value_si_atvl distinct by itself.
                my $p_of_p_of_attr_value = $p_of_attr_value->{$NSPROP_PP_NSREF} or return; # linked Node not in tree
                foreach my $ch_nodstor (map { @{$_->{$NSPROP_PRIM_CHILD_NSREFS}} } @{$p_of_p_of_attr_value->{$NSPROP_PRIM_CHILD_NSREFS}}) {
                    if( my $ch_si_atvl = $ch_nodstor->_get_surrogate_id_attribute( $container, 1 ) ) {
                        if( $ch_si_atvl eq $attr_value_si_atvl and $ch_nodstor ne $attr_value ) {
                            # The target Node has a cousin Node that has the same surrogate id, so we must qualify ours.
                            return [$attr_value_si_atvl, $p_of_attr_value_si_atvl];
                        }
                    }
                }
                # If we get here, there is no cousin with the same surrogate id, so an unqualified one is okay here.
                return $attr_value_si_atvl;
            } else {
                # We do not want to further abbreviate output, so return fully qualified version.
                return [$attr_value_si_atvl, $p_of_attr_value_si_atvl];
            }
        } else {
            # There is a correlated search path, and it does not have a $C.
            return $attr_value_si_atvl;
        }
    }
    # If we get here, the value we are outputting is not the child part of a correlated pair.
    my %exp_p_node_types = map { ($_ => 1) } @{$exp_node_types};
    my $layered_search_results = $nodstor->_find_node_by_surrogate_id_within_layers( $container, \%exp_p_node_types, $attr_value_si_atvl );
    if( $layered_search_results and $layered_search_results->[0] eq $attr_value ) {
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
    my $attr_value_anc_nodstor = $attr_value;
    while( $attr_value_anc_nodstor and !$exp_anc_node_types{$attr_value_anc_nodstor->{$NSPROP_NODE_TYPE}} ) {
        my $anc_si_atvl = $attr_value_anc_nodstor->_get_surrogate_id_attribute( $container, 1 ) or return; # part of SI not defined yet
        push( @attr_value_si_chain, $anc_si_atvl );
        $attr_value_anc_nodstor = $attr_value_anc_nodstor->{$NSPROP_PP_NSREF};
    }
    $attr_value_anc_nodstor or return; # attr-val does not have expected ancestor
    my $anc_si_atvl = $attr_value_anc_nodstor->_get_surrogate_id_attribute( $container, 1 ) or return; # part of SI not defined yet
    push( @attr_value_si_chain, $anc_si_atvl ); # push required ancestor itself
    my $remote_search_results = $nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, \@attr_value_si_chain );
    $remote_search_results and $remote_search_results->[0] eq $attr_value or return; # can't find ourself, oops
    # If we get here, the fully-qualified form of the attr-value can be remotely addressed successfully.
    if( $want_shortest ) {
        # We want to further abbreviate output.
        my ($unqualified, $l2, $l3) = @attr_value_si_chain; # for simplicity, assume no more than 3 levels
        $l2 or return $unqualified; # fully qualified version is only 1 element long
        if( @{$nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, [$unqualified] )} == 1 ) {
            # Fully unqualified version returns only one result, so it is currently unambiguous.
            return $unqualified; # 1 element
        }
        $l3 or return \@attr_value_si_chain; # fully qualified version is only 2 elements long
        if( @{$nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, [$unqualified, $l2] )} == 1 ) {
            # This partially qualified version returns only one result, so it is currently unambiguous.
            return [$unqualified, $l2]; # 2 elements
        }
        if( @{$nodstor->_find_node_by_surrogate_id_remotely( $container, \%remotely_addressable_types, [$unqualified, $l3] )} == 1 ) {
            # This partially qualified version returns only one result, so it is currently unambiguous.
            return [$unqualified, $l3]; # 2 elements
        }
        # If we get here, all shortened versions return multiple results, so return fully qualified version.
        return \@attr_value_si_chain; # 3 elements
    } else {
        # We do not want to further abbreviate output, so return fully qualified version.
        return \@attr_value_si_chain;
    }
}

######################################################################

sub _assert_deferrable_constraints {
    my ($nodstor, $container) = @_;
    $nodstor->_assert_in_node_deferrable_constraints( $container );
    $nodstor->_assert_parent_ref_scope_deferrable_constraints( $container );
    $nodstor->_assert_child_comp_deferrable_constraints( $container );
}

sub _assert_in_node_deferrable_constraints {
    my ($nodstor, $container) = @_;
    my $type_info = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}};

    # 1: Now assert constraints associated with Node-type details given in each 
    # "Attribute List" section of NodeTypes.pod.

    # 1.1: Assert that any primary parent ("PP") attribute is set.
    unless( defined( $nodstor->{$NSPROP_PP_NSREF} ) or $type_info->{$TPI_PP_PSEUDONODE} ) {
        $nodstor->_throw_error_message( 'SRT_N_ASDC_PP_VAL_NO_SET' );
    }

    # 1.2: Assert that any surrogate id ("SI") attribute is set.
    if( my $si_atnm = $type_info->{$TPI_SI_ATNM} ) {
        my (undef, $lit, $enum, $nref) = @{$si_atnm};
        # Skip 'id', as that's redundant with test 1.1.
        if( $lit ) {
            unless( defined( $nodstor->{$NSPROP_AT_LITERALS}->{$lit} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $lit } );
            }
        }
        if( $enum ) {
            unless( defined( $nodstor->{$NSPROP_AT_ENUMS}->{$enum} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $enum } );
            }
        }
        if( $nref ) {
            unless( defined( $nodstor->{$NSPROP_AT_NSREFS}->{$nref} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_SI_VAL_NO_SET', { 'ATNM' => $nref } );
            }
        }
    }

    # 1.3: Assert that any always-mandatory ("MA") attributes are set.
    if( my $mand_attrs = $type_info->{$TPI_MA_ATNMS} ) {
        my ($lits, $enums, $nrefs) = @{$mand_attrs};
        foreach my $attr_name (@{$lits}) {
            unless( defined( $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
            }
        }
        foreach my $attr_name (@{$enums}) {
            unless( defined( $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
            }
        }
        foreach my $attr_name (@{$nrefs}) {
            unless( defined( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ) ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_MA_VAL_NO_SET', { 'ATNM' => $attr_name } );
            }
        }
    }

    # 2: Now assert constraints associated with Node-type details given in each 
    # "Exclusive Attribute Groups List" section of NodeTypes.pod.

    if( my $mutex_atgps = $type_info->{$TPI_MUTEX_ATGPS} ) {
        foreach my $mutex_atgp (@{$mutex_atgps}) {
            my ($mutex_name, $lits, $enums, $nrefs, $is_mandatory) = @{$mutex_atgp};
            my @valued_candidates = ();
            foreach my $attr_name (@{$lits}) {
                if( defined( $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name} ) ) {
                    push( @valued_candidates, $attr_name );
                }
            }
            foreach my $attr_name (@{$enums}) {
                if( defined( $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name} ) ) {
                    push( @valued_candidates, $attr_name );
                }
            }
            foreach my $attr_name (@{$nrefs}) {
                if( defined( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ) ) {
                    push( @valued_candidates, $attr_name );
                }
            }
            if( scalar( @valued_candidates ) > 1 ) {
                $nodstor->_throw_error_message( 'SRT_N_ASDC_MUTEX_TOO_MANY_SET', 
                    { 'NUMVALS' => scalar( @valued_candidates ), 
                    'ATNMS' => \@valued_candidates, 'MUTEX' => $mutex_name } );
            }
            if( scalar( @valued_candidates ) == 0 ) {
                if( $is_mandatory ) {
                    my @possible_candidates = (@{$lits}, @{$enums}, @{$nrefs});
                    $nodstor->_throw_error_message( 'SRT_N_ASDC_MUTEX_ZERO_SET', 
                        { 'ATNMS' => \@possible_candidates, 'MUTEX' => $mutex_name } );
                }
            }
        }
    }

    # 3: Now assert constraints associated with Node-type details given in each 
    # "Local Attribute Dependencies List" section of NodeTypes.pod.

    if( my $local_atdps_list = $type_info->{$TPI_LOCAL_ATDPS} ) {
        foreach my $local_atdps_item (@{$local_atdps_list}) {
            my ($dep_on_lit_nm, $dep_on_enum_nm, $dep_on_nref_nm, $dependencies) = @{$local_atdps_item};
            my $dep_on_attr_nm = $dep_on_lit_nm || $dep_on_enum_nm || $dep_on_nref_nm;
            my $dep_on_attr_val = $dep_on_lit_nm ? $nodstor->{$NSPROP_AT_LITERALS}->{$dep_on_lit_nm} :
                $dep_on_enum_nm ? $nodstor->{$NSPROP_AT_ENUMS}->{$dep_on_enum_nm} :
                $dep_on_nref_nm ? $nodstor->{$NSPROP_AT_NSREFS}->{$dep_on_nref_nm} : undef;
            foreach my $dependency (@{$dependencies}) {
                my ($lits, $enums, $nrefs, $dep_on_enum_vals, $is_mandatory) = @{$dependency};
                my @valued_dependents = ();
                foreach my $attr_name (@{$lits}) {
                    if( defined( $nodstor->{$NSPROP_AT_LITERALS}->{$attr_name} ) ) {
                        push( @valued_dependents, $attr_name );
                    }
                }
                foreach my $attr_name (@{$enums}) {
                    if( defined( $nodstor->{$NSPROP_AT_ENUMS}->{$attr_name} ) ) {
                        push( @valued_dependents, $attr_name );
                    }
                }
                foreach my $attr_name (@{$nrefs}) {
                    if( defined( $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name} ) ) {
                        push( @valued_dependents, $attr_name );
                    }
                }
                if( !defined( $dep_on_attr_val ) ) {
                    # The dependency is undef/null, so all dependents must be undef/null.
                    if( scalar( @valued_dependents ) > 0 ) {
                        $nodstor->_throw_error_message( 'SRT_N_ASDC_LATDP_DEP_ON_IS_NULL', 
                            { 'DEP_ON' => $dep_on_attr_nm, 'NUMVALS' => scalar( @valued_dependents ), 
                            'ATNMS' => \@valued_dependents } );
                    }
                    # If we get here, the tests have passed concerning this $dependency.
                } elsif( scalar( @{$dep_on_enum_vals} ) > 0 and 
                        !scalar( grep { $_ eq $dep_on_attr_val } @{$dep_on_enum_vals} ) ) {
                    # Not just any dependency value is acceptable for these dependents, and the
                    # dependency has the wrong value for these dependents; the latter must be undef/null.
                    if( scalar( @valued_dependents ) > 0 ) {
                        $nodstor->_throw_error_message( 'SRT_N_ASDC_LATDP_DEP_ON_HAS_WRONG_VAL', 
                            { 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
                            'NUMVALS' => scalar( @valued_dependents ), 'ATNMS' => \@valued_dependents } );
                    }
                    # If we get here, the tests have passed concerning this $dependency.
                } else {
                    # Either any dependency value is acceptable for these dependents, or the valued 
                    # dependency has the right value for these dependents; one of them may be set.
                    if( scalar( @valued_dependents ) > 1 ) {
                        $nodstor->_throw_error_message( 'SRT_N_ASDC_LATDP_TOO_MANY_SET', 
                            { 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
                            'NUMVALS' => scalar( @valued_dependents ), 'ATNMS' => \@valued_dependents } );
                    }
                    if( scalar( @valued_dependents ) == 0 ) {
                        if( $is_mandatory ) {
                            my @possible_candidates = (@{$lits}, @{$enums}, @{$nrefs});
                            $nodstor->_throw_error_message( 'SRT_N_ASDC_LATDP_ZERO_SET', 
                                { 'DEP_ON' => $dep_on_attr_nm, 'DEP_ON_VAL' => $dep_on_attr_val, 
                                'ATNMS' => \@possible_candidates } );
                        }
                    }
                    # If we get here, the tests have passed concerning this $dependency.
                }
            }
        }
    }
}

sub _assert_parent_ref_scope_deferrable_constraints {
    my ($nodstor, $container) = @_;
    my $type_info = $NODE_TYPES{$nodstor->{$NSPROP_NODE_TYPE}};

    # 1. Now assert that all non-PP Node-ref attributes of the current Node point to Nodes that 
    # are actually within the visible scope of the current Node.  
    # Some of these applied constraints are associated with Node-type details given in each 
    # "Ancestor Attribute Correlation List" and "Remotely Addressable Types List" section of NodeTypes.pod.

    if( my $at_nsrefs = $type_info->{$TPI_AT_NSREFS} ) {
        foreach my $attr_name (keys %{$at_nsrefs}) {
            my $given_p_nodstor = $nodstor->{$NSPROP_AT_NSREFS}->{$attr_name};
            if( defined( $given_p_nodstor ) ) {
                my $given_p_node_si = $nodstor->_get_relative_surrogate_id( $container, $attr_name );
                ref($given_p_node_si) eq 'ARRAY' or $given_p_node_si = [$given_p_node_si];
                my $fetched_p_nodes = $nodstor->_find_node_by_surrogate_id( $container, $attr_name, $given_p_node_si );
                unless( $fetched_p_nodes and $fetched_p_nodes->[0] eq $given_p_nodstor ) {
                    my $given_p_node_type = $given_p_nodstor->{$NSPROP_NODE_TYPE};
                    my $given_p_node_id = $given_p_nodstor->{$NSPROP_NODE_ID};
                    my $given_p_node_sidch = $given_p_nodstor->_get_surrogate_id_chain( $container );
                    $nodstor->_throw_error_message( 'SRT_N_ASDC_NREF_AT_NONEX_SID', 
                        { 'ATNM' => $attr_name, 'EXPNTYPES' => $at_nsrefs->{$attr_name}, 
                        'PNTYPE' => $given_p_node_type, 'PNID' => $given_p_node_id, 
                        'PSIDCH' => $given_p_node_sidch, 'PSID' => $given_p_node_si, } );
                }
            }
        }
    }

    # This is the end of the searching tests.

    # 2. Now assert constraints associated with Node-type details given in each 
    # "Related Parent Enumerated Attributes List" section of NodeTypes.pod.

    if( my $rel_p_enums = $type_info->{$TPI_REL_P_ENUMS} ) {
        my $pp_nodstor = $nodstor->{$NSPROP_PP_NSREF}; # earlier assert would fail if not set
        my $pp_node_type = $pp_nodstor->{$NSPROP_NODE_TYPE};
        my $pp_type_info = $NODE_TYPES{$pp_node_type};
        foreach my $child_atnm (keys %{$rel_p_enums}) {
            my $child_attp = $type_info->{$TPI_AT_ENUMS}->{$child_atnm};
            my $child_atvl = $nodstor->{$NSPROP_AT_ENUMS}->{$child_atnm} or next; # no violations possible here if child not set
            # If we get here, the child attribute is known to be valued.
            my $parent_atnm = $rel_p_enums->{$child_atnm}->{$pp_node_type};
            unless( $parent_atnm ) {
                # Violation: child valued but parent Node is wrong Node type to ever have a related value.
                $nodstor->_throw_error_message( 'SRT_N_ASDC_REL_ENUM_BAD_P_NTYPE', 
                    { 'CATNM' => $child_atnm, 'PNTYPE' => $pp_node_type, 
                    'PALLOWED' => [keys %{$rel_p_enums->{$child_atnm}}], } );
            }
            my $parent_attp = $pp_type_info->{$TPI_AT_ENUMS}->{$parent_atnm};
            my $parent_atvl = $pp_nodstor->{$NSPROP_AT_ENUMS}->{$parent_atnm};
            unless( $parent_atvl ) {
                # Violation: child valued but parent not valued.
                $nodstor->_throw_error_message( 'SRT_N_ASDC_REL_ENUM_NO_P', 
                    { 'CATNM' => $child_atnm, 'PATNM' => $parent_atnm, } );
            }
            # If we get here, both related attributes are valued, so they must match; 
            # that is, assuming the given parent attribute type has any possible 
            # children at all of the given child attribute type.
            my $allowed_c_for_p = $P_C_REL_ENUMS{$parent_attp}->{$child_attp}->{$parent_atvl};
            unless( $allowed_c_for_p ) {
                # Violation: no child value at all of the current type may be used with parent value.
                $nodstor->_throw_error_message( 'SRT_N_ASDC_REL_ENUM_P_NEVER_P', 
                    { 'CATNM' => $child_atnm, 'CENUMTYPE' => $child_attp, 'CATVL' => $child_atvl, 
                    'PATNM' => $parent_atnm, 'PENUMTYPE' => $parent_attp, 'PATVL' => $parent_atvl, } );
            }
            # If we get here, the given parent may have children of the child's type; check if ours match.
            unless( $allowed_c_for_p->{$child_atvl} ) {
                # Violation: the given child value may not be used with parent value.
                $nodstor->_throw_error_message( 'SRT_N_ASDC_REL_ENUM_P_C_NOT_REL', 
                    { 'CATNM' => $child_atnm, 'CENUMTYPE' => $child_attp, 'CATVL' => $child_atvl, 
                    'PATNM' => $parent_atnm, 'PENUMTYPE' => $parent_attp, 'PATVL' => $parent_atvl, 
                    'CALLOWED' => [keys %{$allowed_c_for_p}], } );
            }
        }
    }
}

sub _assert_child_comp_deferrable_constraints {
    my ($nodstor_or_class, $container, $pseudonode_name, $constor) = @_;
    my $type_info = ref($nodstor_or_class) ? 
        $NODE_TYPES{$nodstor_or_class->{$NSPROP_NODE_TYPE}} : 
        $PSEUDONODE_TYPES{$pseudonode_name};

    # First, gather a child list.

    my @parent_node_types = ();
    my @child_nodstors = ();
    if( ref($nodstor_or_class) ) {
        my @parent_nodstors = ($nodstor_or_class);
        my $curr_nodstor = $nodstor_or_class;
        while( my $wr_atnm = $NODE_TYPES{$curr_nodstor->{$NSPROP_NODE_TYPE}}->{$TPI_WR_ATNM} ) {
            if( $curr_nodstor = $curr_nodstor->{$NSPROP_AT_NSREFS}->{$wr_atnm} ) {
                unshift( @parent_nodstors, $curr_nodstor );
            } else {
                last; # avoid undef warnings in while expr due to unset $curr_node
            }
        }
        foreach my $parent_nodstor (@parent_nodstors) {
            push( @parent_node_types, $parent_nodstor->{$NSPROP_NODE_TYPE} );
            push( @child_nodstors, @{$parent_nodstor->{$NSPROP_PRIM_CHILD_NSREFS}} );
        }
    } else {
        push( @parent_node_types, $pseudonode_name );
        @child_nodstors = @{$constor->{$CSPROP_PSEUDONODES}->{$pseudonode_name}};
    }

    # 1: Now assert that the surrogate id (SI) of each child Node is distinct;
    # this concerns the "Attribute List" section of NodeTypes.pod.

    my %type_child_si = map { (%{$TYPE_CHILD_SI_ATNMS{$_}||{}}) } @parent_node_types;
    # Note: $TYPE_CHILD_SI_ATNMS only contains keys for [pseudo-|]Node types that can have primary-child Nodes.
    if( scalar( keys %type_child_si ) ) {
        my %examined_children = ();
        foreach my $child_nodstor (@child_nodstors) {
            my $child_node_type = $child_nodstor->{$NSPROP_NODE_TYPE};
            if( my $si_atnm = $type_child_si{$child_node_type} ) {
                my (undef, $lit, $enum, $nref) = @{$si_atnm};
                my $hash_key = 
                    $lit ? $child_nodstor->{$NSPROP_AT_LITERALS}->{$lit} : 
                    $enum ? $child_nodstor->{$NSPROP_AT_ENUMS}->{$enum} : 
                    $nref ? $child_nodstor->{$NSPROP_AT_NSREFS}->{$nref} : 
                    $child_nodstor->{$NSPROP_NODE_ID};
                defined( $hash_key ) or next; # An error, but let a different test flag it.
                ref($hash_key) and next; # some comps by target lit/enum are known to be false errors; todo, see if any legit errors
                if( exists( $examined_children{$hash_key} ) ) {
                    # Multiple Nodes have the same primary-parent and surrogate id.
                    my $child_node_id = $child_nodstor->{$NSPROP_NODE_ID};
                    my $matched_child_nodstor = $examined_children{$hash_key};
                    my $matched_child_node_type = $matched_child_nodstor->{$NSPROP_NODE_TYPE};
                    my $matched_child_node_id = $matched_child_nodstor->{$NSPROP_NODE_ID};
                    if( ref($nodstor_or_class) ) {
                        $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_SI_NON_DISTINCT', 
                            { 'VALUE' => $hash_key, 
                            'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
                            'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
                    } else {
                        $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_SI_NON_DISTINCT_PSN', 
                            { 'PSNTYPE' => $pseudonode_name, 'VALUE' => $hash_key, 
                            'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
                            'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
                    }
                }
                $examined_children{$hash_key} = $child_nodstor;
            }
        }
    }

    # 2: Now assert constraints associated with Node-type details given in each 
    # "Child Quantity List" section of NodeTypes.pod.

    if( my $child_quants = $type_info->{$TPI_CHILD_QUANTS} ) {
        foreach my $child_quant (@{$child_quants}) {
            my ($child_node_type, $range_min, $range_max) = @{$child_quant};
            my $child_count = 0;
            foreach my $child_nodstor (@child_nodstors) {
                $child_nodstor->{$NSPROP_NODE_TYPE} eq $child_node_type or next;
                $child_count ++;
            }
            if( $child_count < $range_min ) { 
                if( ref($nodstor_or_class) ) {
                    $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_FEW_SET', 
                        { 'COUNT' => $child_count, 'CNTYPE' => $child_node_type, 'EXPNUM' => $range_min } );
                } else {
                    $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_FEW_SET_PSN', 
                        { 'PSNTYPE' => $pseudonode_name, 'COUNT' => $child_count, 
                        'CNTYPE' => $child_node_type, 'EXPNUM' => $range_min } );
                }
            }
            if( defined( $range_max ) and $child_count > $range_max ) {
                if( ref($nodstor_or_class) ) {
                    $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_MANY_SET', 
                        { 'COUNT' => $child_count, 'CNTYPE' => $child_node_type, 'EXPNUM' => $range_max } );
                } else {
                    $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_CH_N_TOO_MANY_SET_PSN', 
                        { 'PSNTYPE' => $pseudonode_name, 'COUNT' => $child_count, 
                        'CNTYPE' => $child_node_type, 'EXPNUM' => $range_max } );
                }
            }
        }
    }

    # 3: Now assert constraints associated with Node-type details given in each 
    # "Distinct Child Groups List" section of NodeTypes.pod.

    if( my $mudi_atgps = $type_info->{$TPI_MUDI_ATGPS} ) {
        foreach my $mudi_atgp (@{$mudi_atgps}) {
            my ($mudi_name, $mudi_atgp_subsets) = @{$mudi_atgp};
            my %examined_children = ();
            foreach my $mudi_atgp_subset (@{$mudi_atgp_subsets}) {
                my ($child_node_type, $lits, $enums, $nrefs) = @{$mudi_atgp_subset};
                CHILD: foreach my $child_nodstor (@child_nodstors) {
                    $child_nodstor->{$NSPROP_NODE_TYPE} eq $child_node_type or next CHILD;
                    my $hash_key = ',';
                    foreach my $attr_name (@{$lits}) {
                        my $val = $child_nodstor->{$NSPROP_AT_LITERALS}->{$attr_name};
                        defined( $val ) or next CHILD; # null values are always distinct
                        $val =~ s|,|<comma>|g; # avoid problems from literals containing delim chars
                        $hash_key .= $val.',';
                    }
                    foreach my $attr_name (@{$enums}) {
                        my $val = $child_nodstor->{$NSPROP_AT_ENUMS}->{$attr_name};
                        defined( $val ) or next CHILD; # null values are always distinct
                        $hash_key .= $val.',';
                    }
                    foreach my $attr_name (@{$nrefs}) {
                        my $val = $child_nodstor->{$NSPROP_AT_NSREFS}->{$attr_name};
                        defined( $val ) or next CHILD; # null values are always distinct
                        $hash_key .= $val.','; # stringifies to likes of 'HASH(NNN)'
                    }
                    if( exists( $examined_children{$hash_key} ) ) {
                        # Multiple Nodes in same group have the same hash key, which 
                        # means they are identical by means of the compared attributes.
                        my $child_node_id = $child_nodstor->{$NSPROP_NODE_ID};
                        my $matched_child_nodstor = $examined_children{$hash_key};
                        my $matched_child_node_type = $matched_child_nodstor->{$NSPROP_NODE_TYPE};
                        my $matched_child_node_id = $matched_child_nodstor->{$NSPROP_NODE_ID};
                        if( ref($nodstor_or_class) ) {
                            $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_MUDI_NON_DISTINCT', 
                                { 'VALUES' => $hash_key, 'MUDI' => $mudi_name, 
                                'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
                                'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
                        } else {
                            $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_MUDI_NON_DISTINCT_PSN', 
                                { 'PSNTYPE' => $pseudonode_name, 'VALUES' => $hash_key, 'MUDI' => $mudi_name, 
                                'C1NTYPE' => $child_node_type, 'C1NID' => $child_node_id, 
                                'C2NTYPE' => $matched_child_node_type, 'C2NID' => $matched_child_node_id } );
                        }
                    }
                    $examined_children{$hash_key} = $child_nodstor;
                }
            }
        }
    }

    # 4. Now assert constraints associated with Node-type details given in each 
    # "Mandatory Related Child Enumerated Attributes List" section of NodeTypes.pod.

    if( my $ma_rel_c_enums = $type_info->{$TPI_MA_REL_C_ENUMS} ) {
        foreach my $parent_atnm (keys %{$ma_rel_c_enums}) {
            my $parent_attp = $type_info->{$TPI_AT_ENUMS}->{$parent_atnm};
            my $parent_atvl = $nodstor_or_class->{$NSPROP_AT_ENUMS}->{$parent_atnm} or next; # no violations possible here if parent not set
            # If we get here, the parent attribute is known to be valued.
            # Now build a list of what child attribute values are mandatory, which we test against.
            my %exp_ma_c_values = (); # keys are child enumerated type names, values are hash-lists of their enum values.
            foreach my $child_attp (keys %{$P_C_REL_ENUMS{$parent_attp}}) {
                my $allowed_c_for_p = $P_C_REL_ENUMS{$parent_attp}->{$child_attp}->{$parent_atvl} or next;
                $exp_ma_c_values{$child_attp} = {%{$allowed_c_for_p}}; # copy values so originals not destroyed next
                my $opt_c_for_p = $OPT_P_C_REL_ENUMS{$parent_attp}->{$child_attp}->{$parent_atvl} or next;
                foreach my $opt_c_value (keys %{$opt_c_for_p}) {
                    delete( $exp_ma_c_values{$child_attp}->{$opt_c_value} ); # remove opt from list, leaving mand only
                }
            }
            # Now examine each child Node and remove %exp_ma_c_values list items 
            # as they are matched, leaving behind only un-matched items.
            foreach my $c_nodstor (@child_nodstors) {
                my $c_node_type = $c_nodstor->{$NSPROP_NODE_TYPE};
                my $c_type_info = $NODE_TYPES{$c_node_type};
                my $child_atnms = $ma_rel_c_enums->{$parent_atnm}->{$c_node_type} or next; # current Node type not applicable
                # If we get here, the child Node we're sitting on is of the correct 
                # type for this constraint to apply to.
                my @valued_candidates = ();
                foreach my $child_atnm (@{$child_atnms}) {
                    my $child_attp = $c_type_info->{$TPI_AT_ENUMS}->{$child_atnm};
                    my $child_atvl = $c_nodstor->{$NSPROP_AT_ENUMS}->{$child_atnm};
                    if( defined( $child_atvl ) ) {
                        push( @valued_candidates, $child_atnm );
                        delete( $exp_ma_c_values{$child_attp}->{$child_atvl} ); # this mand attr is populated as constraint requires
                    }
                }
                # Now assert that the related attr in child Node is set, and only one is set if multiple candidates.
                if( scalar( @valued_candidates ) > 1 ) {
                    $c_nodstor->_throw_error_message( 'SRT_N_ASDC_MA_REL_ENUM_TOO_MANY_SET', 
                        { 'PATNM' => $parent_atnm, 'CATNMS' => $child_atnms, 
                        'NUMVALS' => scalar( @valued_candidates ) } );
                }
                if( scalar( @valued_candidates ) == 0 ) {
                    $c_nodstor->_throw_error_message( 'SRT_N_ASDC_MA_REL_ENUM_ZERO_SET', 
                        { 'PATNM' => $parent_atnm, 'CATNMS' => $child_atnms } );
                }
            }
            # If we get here, then all applicable child Nodes each have their related enum attr set.
            # Now check if any mandatory child enum values are not set.
            if( my @missing_c_values = map { (keys %{$_}) } values %exp_ma_c_values ) {
                # Violation: the given parent value requires child values that are missing.
                $nodstor_or_class->_throw_error_message( 'SRT_N_ASDC_MA_REL_ENUM_MISSING_VALUES', 
                    { 'PATNM' => $parent_atnm, 'PENUMTYPE' => $parent_attp, 'PATVL' => $parent_atvl, 
                    'CATVLS' => \@missing_c_values } );
            }
        }
    }

    # TODO: more tests that examine multiple nodes together ...
}

######################################################################

sub _get_all_properties {
    my ($nodstor, $container, $links_as_si, $want_shortest) = @_;
    my $at_nsrefs_in = $nodstor->{$NSPROP_AT_NSREFS};
    return [ $nodstor->{$NSPROP_NODE_TYPE}, {
        $ATTR_ID => $nodstor->{$NSPROP_NODE_ID},
        # Note: We do not output $ATTR_PP => $NSPROP_PP_NSREF since it is redundant.
        %{$nodstor->{$NSPROP_AT_LITERALS}},
        %{$nodstor->{$NSPROP_AT_ENUMS}},
        (map { ( $_ => (
                $links_as_si ? 
                $nodstor->_get_relative_surrogate_id( $container, $_, $want_shortest ) : 
                $at_nsrefs_in->{$_}->{$NSPROP_NODE_ID}
            ) ) } 
            keys %{$at_nsrefs_in}),
    }, [
        map { $_->_get_all_properties( $container, $links_as_si, $want_shortest ) } @{$nodstor->{$NSPROP_PRIM_CHILD_NSREFS}}
    ], ];
}

######################################################################
######################################################################

package SQL::Routine::Group;
use base qw( SQL::Routine );

######################################################################

sub new {
    my ($class, $container) = @_;
    my $group = bless( {}, ref($class) || $class );

    defined( $container ) or $group->_throw_error_message( 'SRT_G_NEW_GROUP_NO_ARG_CONT' );
    unless( ref($container) and UNIVERSAL::isa( $container, 'SQL::Routine::Container' ) ) {
        $group->_throw_error_message( 'SRT_G_NEW_GROUP_BAD_CONT', { 'ARGGCONT' => $container } );
    }

    $group->{$GPROP_CONTAINER} = $container;
    $group->{$GPROP_MEMBER_NSREFS} = {};
    $group->{$GPROP_IS_WRITE_BLOCK} = 0;
    $group->{$GPROP_IS_PC_ADD_BLOCK} = 0;
    $group->{$GPROP_IS_LC_ADD_BLOCK} = 0;
    $group->{$GPROP_IS_MUTEX} = 0;

    if( !$container->{$CPROP_DEFAULT_GROUP} ) {
        # We were invoked by SQL::Routine::Container.new() and are its default mutex Group.
        # Group's ref to Container is weak, Container's ref to Group is strong.
        Scalar::Util::weaken( $group->{$GPROP_CONTAINER} );
        $container->{$CPROP_DEFAULT_GROUP} = $group;
    } else {
        # We were invoked by external code and are an explicit Group in the Container.
        # Group's ref to Container is strong, Container's ref to Group is weak.
        $container->{$CPROP_EXPLICIT_GROUPS}->{$group} = $group;
        Scalar::Util::weaken( $container->{$CPROP_EXPLICIT_GROUPS}->{$group} );
    }

    return $group;
}

######################################################################

#sub impose_write_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_WRITE_BLOCK} and return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_MUTEX} and 
#            $group->_throw_error_message( 'SRT_G_IMP_WR_BL_MUTEX_ATT' );
#    }
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_WRITE_BLOCKS}->{$group} = $group;
#        Scalar::Util::weaken( $node->{$NSPROP_ATT_WRITE_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_WRITE_BLOCK} = 1;
#}

#sub remove_write_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_WRITE_BLOCK} or return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        delete( $node->{$NSPROP_ATT_WRITE_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_WRITE_BLOCK} = 0;
#}

######################################################################

#sub impose_child_addition_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_PC_ADD_BLOCK} and return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_MUTEX} and 
#            $group->_throw_error_message( 'SRT_G_IMP_CA_BL_MUTEX_ATT' );
#    }
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_PC_ADD_BLOCKS}->{$group} = $group;
#        Scalar::Util::weaken( $node->{$NSPROP_ATT_PC_ADD_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_PC_ADD_BLOCK} = 1;
#}

#sub remove_child_addition_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_PC_ADD_BLOCK} or return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        delete( $node->{$NSPROP_ATT_PC_ADD_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_PC_ADD_BLOCK} = 0;
#}

######################################################################

#sub impose_reference_addition_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_LC_ADD_BLOCK} and return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_MUTEX} and 
#            $group->_throw_error_message( 'SRT_G_IMP_RA_BL_MUTEX_ATT' );
#    }
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_LC_ADD_BLOCKS}->{$group} = $group;
#        Scalar::Util::weaken( $node->{$NSPROP_ATT_LC_ADD_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_LC_ADD_BLOCK} = 1;
#}

#sub remove_reference_addition_block {
#    my ($group) = @_;
#    $group->{$GPROP_IS_LC_ADD_BLOCK} or return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        delete( $node->{$NSPROP_ATT_LC_ADD_BLOCKS}->{$group} );
#    }
#    $group->{$GPROP_IS_LC_ADD_BLOCK} = 0;
#}

######################################################################

#sub impose_mutex {
#    my ($group) = @_;
#    $group->{$GPROP_IS_MUTEX} and return; # no-op
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        (keys %{$node->{$NSPROP_ATT_WRITE_BLOCKS}}) == 0 or 
#            $group->_throw_error_message( 'SRT_G_IMP_MUTEX_WR_BL_ATT' );
#        (keys %{$node->{$NSPROP_ATT_PC_ADD_BLOCKS}}) == 0 or 
#            $group->_throw_error_message( 'SRT_G_IMP_MUTEX_CA_BL_ATT' );
#        (keys %{$node->{$NSPROP_ATT_LC_ADD_BLOCKS}}) == 0 or 
#            $group->_throw_error_message( 'SRT_G_IMP_MUTEX_RA_BL_ATT' );
#        $node->{$NSPROP_ATT_MUTEX} and 
#            $group->_throw_error_message( 'SRT_G_IMP_MUTEX_OTHER_MUTEX_ATT' );
#    }
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_MUTEX} = $group;
#        Scalar::Util::weaken( $node->{$NSPROP_ATT_MUTEX} );
#    }
#    $group->{$GPROP_IS_MUTEX} = 1;
#}

#sub remove_mutex {
#    my ($group) = @_;
#    $group->{$GPROP_IS_MUTEX} or return; # no-op
#    # TODO: Assert that there are no un-committed transactions involving member Nodes.
#    foreach my $node (values %{$group->{$GPROP_MEMBER_NSREFS}}) {
#        $node->{$NSPROP_ATT_MUTEX} = undef;
#    }
#    $group->{$GPROP_IS_MUTEX} = 0;
#}

######################################################################

#sub add_node {
#    my ($group, $node) = @_;
#    defined( $node ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_UNDEF', { 'METH' => 'add_node', 'ARGNM' => 'NODE' } );
#    ref($node) and UNIVERSAL::isa( $node, 'SQL::Routine::Node' ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_NO_NODE', { 'METH' => 'add_node', 'ARGNM' => 'NODE', 'ARGVL' => $node } );
#
#}

######################################################################

#sub add_node_tree {
#    my ($group, $node) = @_;
#    defined( $node ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_UNDEF', { 'METH' => 'add_node_tree', 'ARGNM' => 'NODE' } );
#    ref($node) and UNIVERSAL::isa( $node, 'SQL::Routine::Node' ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_NO_NODE', { 'METH' => 'add_node_tree', 'ARGNM' => 'NODE', 'ARGVL' => $node } );
#
#}

######################################################################

#sub remove_node {
#    my ($group, $node) = @_;
#    defined( $node ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_UNDEF', { 'METH' => 'remove_node', 'ARGNM' => 'NODE' } );
#    ref($node) and UNIVERSAL::isa( $node, 'SQL::Routine::Node' ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_NO_NODE', { 'METH' => 'remove_node', 'ARGNM' => 'NODE', 'ARGVL' => $node } );
#
#}

######################################################################

#sub remove_node_tree {
#    my ($group, $node) = @_;
#    defined( $node ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_UNDEF', { 'METH' => 'remove_node_tree', 'ARGNM' => 'NODE' } );
#    ref($node) and UNIVERSAL::isa( $node, 'SQL::Routine::Node' ) or $group->_throw_error_message( 
#        'SRT_G_METH_ARG_NO_NODE', { 'METH' => 'remove_node_tree', 'ARGNM' => 'NODE', 'ARGVL' => $node } );
#
#}

######################################################################
######################################################################

1;
__END__

=encoding utf8

=head1 NAME

SQL::Routine - Specify all database tasks with SQL routines

=head1 VERSION

This document describes SQL::Routine version 0.70.0.

=head1 SYNOPSIS

=head2 Perl Code That Builds A SQL::Routine Model

This executable code example shows how to define some simple database tasks
with SQL::Routine; it only shows a tiny fraction of what the module is capable
of, since more advanced features are not shown for brevity.

    use SQL::Routine;

    eval {
        # Create a model/container in which all SQL details are to be stored.
        # The two boolean options being set true here permit all the subsequent code to be as concise, 
        # easy to read, and most SQL-string-like as possible, at the cost of being slower to execute.
        my $model = SQL::Routine->new_container();
        $model->auto_set_node_ids( 1 );
        $model->may_match_surrogate_node_ids( 1 );

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
                [ 'routine_expr', { 'call_sroutine_cxt' => 'CONN_CX', 'cont_type' => 'CONN', 'valf_p_routine_item' => 'conn_cx', }, ],
                [ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_NAME', 'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'login_name', }, ],
                [ 'routine_expr', { 'call_sroutine_arg' => 'LOGIN_PASS', 'cont_type' => 'SCALAR', 'valf_p_routine_item' => 'login_pass', }, ],
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

        # This line will run some correctness tests on the model that were not done 
        # when the model was being populated for execution speed efficiency.
        $model->assert_deferrable_constraints();

        # This line will dump the contents of the model in pretty-printed XML format.
        # It can be helpful when debugging your programs that use SQL::Routine.
        print $model->get_all_properties_as_xml_str( 1 );
    };
    $@ and print error_to_string($@);

    # SQL::Routine throws object exceptions when it encounters bad input; this function 
    # will convert those into human readable text for display by the try/catch block.
    sub error_to_string {
        my ($message) = @_;
        if( ref($message) and UNIVERSAL::isa( $message, 'Locale::KeyedText::Message' ) ) {
            my $translator = Locale::KeyedText->new_translator( ['SQL::Routine::L::'], ['en'] );
            my $user_text = $translator->translate_message( $message );
            unless( $user_text ) {
                return 'internal error: can\'t find user text for a message: '.
                    $message->as_string().' '.$translator->as_string();
            }
            return $user_text;
        }
        return $message; # if this isn't the right kind of object
    }

Note that one key feature of SQL::Routine is that all of a model's pieces are
linked by references rather than by name as in SQL itself.  For example, the
name of the 'person' table is only stored once internally; if, after executing
all of the above code, you were to run "$tb_person->set_attribute(
'si_name', 'The Huddled Masses' );", then all of the other parts of the model
that referred to the table would not break, and an XML dump would show that all
the references now say 'The Huddled Masses'.

I<For some more (older) examples of SQL::Routine in use, see its test suite code.>

=head2 An XML Representation of That Model

This is the XML that the above get_all_properties_as_xml_str() prints out:

    <?xml version="1.0" encoding="UTF-8"?>
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

=head2 String SQL That Can Be Made From the Model

This section has examples of string-SQL that can be generated from the above
model.  The examples are conformant by default to the SQL:2003 standard flavor,
but will vary from there to make illustration simpler; some examples may contain
a hodge-podge of database vendor extensions and as a whole won't execute as is
on some database products.

These two examples for creating the same TABLE schema object, separated by a
blank line, demonstrate SQL for a database that supports DOMAIN schema objects
and SQL for a database that does not.  They both assume that uniqueness and
foreign key constraints are only enforced on not-null values.

    CREATE DOMAIN entity_id AS INTEGER(9);
    CREATE DOMAIN alt_id AS VARCHAR(20);
    CREATE DOMAIN person_name AS VARCHAR(100);
    CREATE DOMAIN person_sex AS ENUM('M','F');
    CREATE TABLE person (
        person_id entity_id NOT NULL DEFAULT 1 AUTO_INCREMENT,
        alternate_id alt_id NULL,
        name person_name NOT NULL,
        sex person_sex NULL,
        father_id entity_id NULL,
        mother_id entity_id NULL,
        CONSTRAINT PRIMARY KEY (person_id),
        CONSTRAINT UNIQUE (alternate_id),
        CONSTRAINT fk_father FOREIGN KEY (father_id) REFERENCES person (person_id),
        CONSTRAINT fk_mother FOREIGN KEY (mother_id) REFERENCES person (person_id)
    );

    CREATE TABLE person (
        person_id INTEGER(9) NOT NULL DEFAULT 1 AUTO_INCREMENT,
        alternate_id VARCHAR(20) NULL,
        name VARCHAR(100) NOT NULL,
        sex ENUM('M','F') NULL,
        father_id INTEGER(9) NULL,
        mother_id INTEGER(9) NULL,
        CONSTRAINT PRIMARY KEY (person_id),
        CONSTRAINT UNIQUE (alternate_id),
        CONSTRAINT fk_father FOREIGN KEY (father_id) REFERENCES person (person_id),
        CONSTRAINT fk_mother FOREIGN KEY (mother_id) REFERENCES person (person_id)
    );

This example is for creating the VIEW schema object:

    CREATE VIEW person_with_parents AS
    SELECT self.person_id AS self_id, self.name AS self_name,
        father.person_id AS father_id, father.name AS father_name,
        mother.person_id AS mother_id, mother.name AS mother_name
    FROM person AS self
        LEFT OUTER JOIN person AS father ON father.person_id = self.father_id
        LEFT OUTER JOIN person AS mother ON mother.person_id = self.father_id;

If the 'get_person' routine were implemented as a database schema object, this 
is what it might look like:

    CREATE FUNCTION get_person (arg_person_id INTEGER(9)) RETURNS ROW(...) AS
    BEGIN
        DECLARE person_row ROW(...);
        SELECT * INTO person_row FROM person AS s WHERE s.person_id = arg_person_id;
        RETURN person_row;
    END;

Then it could be invoked elsewhere like this:

    my_rec = get_person( '3' );

If the same routine were implemented as an application-side routine, then it 
might look like this (not actual DBI syntax):

    my $sth = $dbh->prepare( "SELECT * FROM person AS s WHERE s.person_id = :arg_person_id" );
    $sth->bind_param( 'arg_person_id', 'INTEGER(9)' );
    $sth->execute( { 'arg_person_id' => '3' } );
    my $my_rec = $sth->fetchrow_hashref();

And finally, corresponding DROP statements can be made for any of the above
database schema objects:

    DROP DOMAIN entity_id;
    DROP DOMAIN alt_id;
    DROP DOMAIN person_name;
    DROP DOMAIN person_sex;
    DROP TABLE person;
    DROP VIEW person_with_parents;
    DROP FUNCTION get_person;

I<See also the separately distributed SQL::Routine::SQLBuilder module, which is
a reference implementation of a SQL:2003 (and more) generator for SQL::Routine.>

=head1 DESCRIPTION

The SQL::Routine (SRT) Perl 5 module provides a container object that allows
you to create specifications for any type of database task or activity (eg:
queries, DML, DDL, connection management) that look like ordinary routines
(procedures or functions) to your programs; all routine arguments are named.

SQL::Routine is trivially easy to install, since it is written in pure Perl and
it has few external dependencies.

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

I<To cut down on the size of the SQL::Routine module itself, most of the POD
documentation is in these other files: L<SQL::Routine::Details>,
L<SQL::Routine::Language>, L<SQL::Routine::EnumTypes>,
L<SQL::Routine::NodeTypes>.>

=head1 CLASSES IN THIS MODULE

This module is implemented by several object-oriented Perl 5 packages, each of
which is referred to as a class.  They are: B<SQL::Routine> (the module's
name-sake), B<SQL::Routine::Container> (aka B<Container>, aka B<Model>),
B<SQL::Routine::Node> (aka B<Node>), and B<SQL::Routine::Group> (aka B<Group>). 
This module also has 2 private classes named B<SQL::Routine::ContainerStorage>
and B<SQL::Routine::NodeStorage>, which help to implement Container and Node
respectively; each of the latter is a wrapper for one of the former.

I<While all 6 of the above classes are implemented in one module for
convenience, you should consider all 6 names as being "in use"; do not create
any modules or packages yourself that have the same names.>

The Container and Node and Group classes do most of the work and are what you
mainly use.  The name-sake class mainly exists to guide CPAN in indexing the
whole module, but it also provides a set of stateless utility methods and
constants that the other two classes inherit, and it provides a few wrapper
functions over the other classes for your convenience; you never instantiate an
object of SQL::Routine itself.

Most of the SQL::Routine documentation you will see simply uses the terms
'Container' and 'Node' to refer to the pair of classes or objects which
implements each as a single unit, even if said documentation is specific to the
'Storage' variants thereof, because someone using this module shouldn't need to
know the difference.  This said, some documentation will specify a pair member
by appending the terms 'interface' and 'Storage'; "Container interface" refers
to ::Container, "ContainerStorage" refers to ::ContainerStorage, "Node
interface" refers to ::Node, "NodeStorage" refers to ::NodeStorage.

=head1 BRIEF FUNCTION AND METHOD LIST

Here is a compact list of this module's functions and methods along with their 
arguments.  For full details on each one, please see L<SQL::Routine::Details>.

CONSTRUCTOR WRAPPER FUNCTIONS:

    new_container()
    new_node( CONTAINER, NODE_TYPE[, NODE_ID] )
    new_group( CONTAINER )

CONTAINER CONSTRUCTOR FUNCTIONS:

    new()

CONTAINER OBJECT METHODS:

    new_interface()
    get_self_id()
    auto_assert_deferrable_constraints([ NEW_VALUE ])
    auto_set_node_ids([ NEW_VALUE ])
    may_match_surrogate_node_ids([ NEW_VALUE ])
    delete_node_tree()
    get_child_nodes([ NODE_TYPE ])
    find_node_by_id( NODE_ID )
    find_child_node_by_surrogate_id( TARGET_ATTR_VALUE )
    get_next_free_node_id()
    get_edit_count()
    deferrable_constraints_are_tested()
    assert_deferrable_constraints()

NODE CONSTRUCTOR FUNCTIONS:

    new( CONTAINER, NODE_TYPE[, NODE_ID] )

NODE OBJECT METHODS:

    new_interface()
    get_self_id()
    delete_node()
    delete_node_tree()
    get_container()
    get_node_type()
    get_node_id()
    set_node_id( NEW_ID )
    get_primary_parent_attribute()
    clear_primary_parent_attribute()
    set_primary_parent_attribute( ATTR_VALUE )
    get_surrogate_id_attribute([ GET_TARGET_SI ])
    clear_surrogate_id_attribute()
    set_surrogate_id_attribute( ATTR_VALUE )
    get_attribute( ATTR_NAME[, GET_TARGET_SI] )
    get_attributes([ GET_TARGET_SI ])
    clear_attribute( ATTR_NAME )
    clear_attributes()
    set_attribute( ATTR_NAME, ATTR_VALUE )
    set_attributes( ATTRS )
    move_before_sibling( SIBLING[, PARENT] )
    get_child_nodes([ NODE_TYPE ])
    add_child_node( CHILD )
    add_child_nodes( CHILDREN )
    get_referencing_nodes([ NODE_TYPE ])
    get_surrogate_id_chain()
    find_node_by_surrogate_id( SELF_ATTR_NAME, TARGET_ATTR_VALUE )
    find_child_node_by_surrogate_id( TARGET_ATTR_VALUE )
    get_relative_surrogate_id( SELF_ATTR_NAME )
    assert_deferrable_constraints()

GROUP CONSTRUCTOR FUNCTIONS:

    new( CONTAINER )

GROUP OBJECT METHODS: (TODO)

CONTAINER OR NODE METHODS FOR DEBUGGING:

    get_all_properties([ LINKS_AS_SI ])
    get_all_properties_as_perl_str([ LINKS_AS_SI ])
    get_all_properties_as_xml_str([ LINKS_AS_SI ])

CONTAINER OR NODE FUNCTIONS AND METHODS FOR RAPID DEVELOPMENT:

    build_node( NODE_TYPE[, ATTRS] )
    build_child_node( NODE_TYPE[, ATTRS] )
    build_child_nodes( CHILDREN )
    build_child_node_tree( NODE_TYPE[, ATTRS][, CHILDREN] )
    build_child_node_trees( CHILDREN )
    build_container([ CHILDREN[, AUTO_ASSERT[, AUTO_IDS[, MATCH_SURR_IDS]]] ])

INFORMATION FUNCTIONS:

    valid_enumerated_types([ ENUM_TYPE ])
    valid_enumerated_type_values( ENUM_TYPE[, ENUM_VALUE] )
    valid_node_types([ NODE_TYPE ])
    node_types_with_pseudonode_parents([ NODE_TYPE ])
    node_types_with_primary_parent_attributes([ NODE_TYPE ])
    valid_node_type_literal_attributes( NODE_TYPE[, ATTR_NAME] )
    valid_node_type_enumerated_attributes( NODE_TYPE[, ATTR_NAME] )
    valid_node_type_node_ref_attributes( NODE_TYPE[, ATTR_NAME] )
    valid_node_type_surrogate_id_attributes([ NODE_TYPE ])

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl modules L<version> and L<only>, which would
conceptually be built-in to Perl, but aren't, so they are on CPAN instead.

It also requires the Perl module L<Scalar::Util>, 
which would conceptually be built-in to Perl, but is bundled with it instead.

It also requires these modules that are on CPAN:

    Locale::KeyedText 1.6.0 (for error messages)

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<SQL::Routine::L::en>, L<SQL::Routine::Details>,
L<SQL::Routine::Language>, L<SQL::Routine::EnumTypes>,
L<SQL::Routine::NodeTypes>, L<Locale::KeyedText>, L<Rosetta>,
L<SQL::Routine::SQLBuilder>, L<SQL::Routine::SQLParser>,
L<Rosetta::Engine::Generic>, L<Rosetta::Emulator::DBI>, L<DBI>,
L<SQL::Statement>, L<SQL::Parser>, L<SQL::Translator>, L<SQL::YASP>,
L<SQL::Generator>, L<SQL::Schema>, L<SQL::Abstract>, L<SQL::Snippet>,
L<SQL::Catalog>, L<DB::Ent>, L<DBIx::Abstract>, L<DBIx::AnyDBD>,
L<DBIx::DBSchema>, L<DBIx::Namespace>, L<DBIx::SearchBuilder>, L<TripleStore>,
L<Data::Table>, and various other modules.

=head1 BUGS AND LIMITATIONS

This module is currently in alpha development status, meaning that some parts of
it will be changed in the near future, some perhaps in incompatible ways;
however, I believe that any further incompatible changes will be small.  The
current state is analogous to 'developer releases' of operating systems; it is
reasonable to being writing code that uses this module now, but you should be
prepared to maintain it later in keeping with API changes.  This module also
does not yet have full code coverage in its tests, though the most commonly used
areas are covered.

You can not use surrogate id values that look like valid Node ids (that are
positive integers) since some methods won't do what you expect when given such
values.  Nodes having such surrogate id values won't be matched by values
passed to set_attribute(), directly or indirectly.  That method only
tries to lookup a Node by its surrogate id if its argument doesn't look like a
Node ref or a Node id.  Similarly, the build*() methods will decide whether to
interpret a defined but non-Node-ref ATTRS argument as a Node id or a surrogate
id based on its looking like a valid Node id or not.  You should rarely
encounter this caveat, though, since you would never use a number as a "SQL
identifier" in normal cases, and that is only technically possible with a
"delimited SQL identifier".

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the SQL::Routine database portability library.

SQL::Routine is Copyright (c) 2002-2005, Darren R. Duncan.  All rights reserved.
Address comments, suggestions, and bug reports to C<perl@DarrenDuncan.net>, or
visit L<http://www.DarrenDuncan.net/> for more information.

SQL::Routine is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (L<http://www.fsf.org/>); either version 2 of the License, or
(at your option) any later version.  You should have received a copy of the GPL
as part of the SQL::Routine distribution, in the file named "GPL"; if not, write
to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 
02110-1301, USA.

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

=head1 ACKNOWLEDGEMENTS

Besides myself as the creator ...

* 2004.05.20 - Thanks to Jarrell Dunson (jarrell_dunson@asburyseminary.edu) for
inspiring me to add some concrete SYNOPSIS documentation examples to this
module, which demonstrate actual SQL statements that can be generated from parts
of a model, when he wrote me asking for examples of how to use this module.

* 2005.03.21 - Thanks to Stevan Little (stevan@iinteractive.com) for feedback
towards improving this module's documentation, particularly towards using a much
shorter SYNOPSIS, so that it is easier for newcomers to understand the module at
a glance, and not be intimidated by large amounts of detailed information.  Also
thanks to Stevan for introducing me to Scalar::Util::weaken(); by using it,
SQL::Routine objects can be garbage collected normally despite containing
circular references, and users no longer need to invoke destructor methods.

=cut
