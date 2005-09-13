#!perl
use 5.008001; use utf8; use strict; use warnings;

package SQL::Routine::L::en;
use version; our $VERSION = qv('0.38.1');

######################################################################

my $CC = 'SQL::Routine::Container';
my $CN = 'SQL::Routine::Node';
my $CG = 'SQL::Routine::Group';

my %text_strings = (
    'SRT_C_METH_VIOL_WRITE_BLOCKS' =>
        $CC.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a write block is imposed on it by at least one Container interface, '.
        'so it can not be edited or deleted',

    'SRT_C_METH_ARG_UNDEF' => 
        $CC.'.{METH}(): undefined (or missing) {ARGNM} argument',
    'SRT_C_METH_ARG_NO_ARY' => 
        $CC.'.{METH}(): invalid {ARGNM} argument; it is not an array ref, but rather is "{ARGVL}"',

    'SRT_C_METH_ARG_ARY_ELEM_UNDEF' => 
        $CC.'.{METH}(): invalid {ARGNM} array argument; undefined element',
    'SRT_C_METH_ARG_ARY_ELEM_NO_ARY' => 
        $CC.'.{METH}(): invalid {ARGNM} array argument; element not an array ref, but rather is "{ELEMVL}"',

    'SRT_C_GET_CH_NODES_BAD_TYPE' => 
        $CC.'.get_child_nodes(): invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"',

    'SRT_C_BUILD_CH_ND_NO_PSND' => 
        $CC.'.build_child_node(): invalid NODE_TYPE argument; a "{ARGNTYPE}" Node does not '.
        'have a pseudo-Node parent and can not be made a direct child of a Container',

    'SRT_C_BUILD_CH_ND_TR_NO_PSND' => 
        $CC.'.build_child_node_tree(): invalid NODE_TYPE argument; a "{ARGNTYPE}" Node does not '.
        'have a pseudo-Node parent and can not be made a direct child of a Container',

    'SRT_N_METH_VIOL_WRITE_BLOCKS' =>
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a write block is imposed on it by at least one Container interface, '.
        'so it can not be edited or deleted',
    'SRT_N_METH_VIOL_PC_ADD_BLOCKS' =>
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a primary child addition block is imposed on it by at least one Container interface, '.
        'so it can not gain primary child Nodes',
    'SRT_N_METH_VIOL_LC_ADD_BLOCKS' =>
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a referencing/link child addition block is imposed on it by at least one Container interface, '.
        'so it can not gain referencing/link child Nodes',

    'SRT_N_METH_ARG_UNDEF' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'undefined (or missing) {ARGNM} argument',
    'SRT_N_METH_ARG_NO_ARY' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} argument; it is not an array ref, but rather is "{ARGVL}"',
    'SRT_N_METH_ARG_NO_HASH' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} argument; it is not a hash ref, but rather is "{ARGVL}"',
    'SRT_N_METH_ARG_NO_NODE' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} argument; it is not a Node object, but rather is "{ARGVL}"',

    'SRT_N_METH_ARG_ARY_ELEM_UNDEF' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} array argument; undefined element',
    'SRT_N_METH_ARG_ARY_ELEM_NO_ARY' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} array argument; element not an array ref, but rather is "{ELEMVL}"',

    'SRT_N_NEW_NODE_NO_ARG_CONT' => 
        $CN.'.new_node(): missing CONTAINER argument',
    'SRT_N_NEW_NODE_BAD_CONT' => 
        $CN.'.new_node(): invalid CONTAINER argument; it is not a Container object, but rather is "{ARGNCONT}"',
    'SRT_N_NEW_NODE_NO_ARG_TYPE' => 
        $CN.'.new_node(): missing NODE_TYPE argument',
    'SRT_N_NEW_NODE_BAD_TYPE' => 
        $CN.'.new_node(): invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"',
    'SRT_N_NEW_NODE_NO_ARG_ID' => 
        $CN.'.new_node(): concerning the new "{ARGNTYPE}" Node under construction; '.
        'missing NODE_ID argument and the given Container interface is not configured to auto-set missing Node Ids',
    'SRT_N_NEW_NODE_BAD_ID' => 
        $CN.'.new_node(): concerning the new "{ARGNTYPE}" Node under construction; '.
        'invalid NODE_ID argument; a Node Id may only be a positive integer; '.
        'you tried to set it to "{ARGNID}"',
    'SRT_N_NEW_NODE_DUPL_ID' => 
        $CN.'.new_node(): concerning the new "{ARGNTYPE}" Node under construction; '.
        'invalid NODE_ID argument; the Node Id value of "{ARGNID}" you tried to set '.
        'is already in use by another Node in the same Container; it must be distinct',

    'SRT_N_DEL_NODE_HAS_CHILD' => 
        $CN.'.delete_node(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'this Node can not be deleted yet because it has child Nodes of its own; '.
        'specifically {PRIM_COUNT} primary-child Nodes plus {LINK_COUNT} link-child Nodes',

    'SRT_N_DEL_NODE_TREE_HAS_EXT_CHILD' => 
        $CN.'.delete_node_tree(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'the Node tree rooted here can not be deleted yet because one or more of '.
        'its members are referenced by other Nodes that are outside of the tree; '.
        'the "{CNTYPE}" Node with Id "{CNID}" and Surrogate Id Chain "{CSIDCH}" is a link-child of '.
        'the "{PNTYPE}" tree member Node with Id "{PNID}" and Surrogate Id Chain "{PSIDCH}".',

    'SRT_N_SET_NODE_ID_BAD_ARG' => 
        $CN.'.set_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid NEW_ID argument; a Node Id may only be a positive integer; '.
        'you tried to set it to "{ARG}"',
    'SRT_N_SET_NODE_ID_DUPL_ID' => 
        $CN.'.set_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid NEW_ID argument; the Node Id value of "{ARG}" you tried to set '.
        'is already in use by another Node in the same Container; it must be distinct',

    'SRT_N_METH_NO_PP_AT' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'there is no primary parent attribute in this Node',

    'SRT_N_SET_PP_AT_CIRC_REF' => 
        $CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; that Node is a direct '.
        'or indirect child of this current Node, so they can not be linked; '.
        'if they were linked, that would result in a circular reference chain',

    'SRT_N_SET_PP_AT_WRONG_NODE_TYPE' => 
        $CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; the given Node is an "{ARGNTYPE}" '.
        'Node but this Node-ref attribute may only reference a "{EXPNTYPE}" Node',
    'SRT_N_SET_PP_AT_DIFF_CONT' => 
        $CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; that Node is not in '.
        'the same Container as this current Node, so they can not be linked',
    'SRT_N_SET_PP_AT_NONEX_NID' => 
        $CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; "{ARG}" looks like a Node Id but '.
        'it does not match the Id of any "{EXPNTYPE}" Node in this Node\'s Container',
    'SRT_N_SET_PP_AT_NO_ALLOW_SID_FOR_PP' => 
        $CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; "{ARG}" looks like a Surrogate Id but '.
        'you may not use Surrogate Ids to match Nodes when setting the primary parent attribute; '.
        'ATTR_VALUE must be either a Node ref or a positive integer Node Id',

    'SRT_N_CLEAR_SI_AT_MAND_NID' => 
        $CN.'.clear_surrogate_id_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'you can not clear the "id" attribute because the Node Id is constantly always mandatory',

    'SRT_N_METH_ARG_NO_AT_NM' => 
        $CN.'.{METH}(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid {ARGNM} argument; there is no attribute named "{ARGVL}" in this Node',

    'SRT_N_CLEAR_AT_MAND_NID' => 
        $CN.'.clear_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'you can not clear the "id" attribute because the Node Id is constantly always mandatory',

    'SRT_N_SET_AT_NO_ARG_VAL' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'missing ATTR_VALUE argument when setting "{ATNM}"',

    'SRT_N_SET_AT_INVAL_LIT_V_IS_REF' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
        'a scalar value; you tried to set it to a "{ARG_REF_TYPE}" reference',
    'SRT_N_SET_AT_INVAL_LIT_V_BOOL' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
        'a boolean value, as expressed by "0" or "1"; you tried to set it to "{ARG}"',
    'SRT_N_SET_AT_INVAL_LIT_V_UINT' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
        'a non-negative integer; you tried to set it to "{ARG}"',
    'SRT_N_SET_AT_INVAL_LIT_V_SINT' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
        'an integer; you tried to set it to "{ARG}"',

    'SRT_N_SET_AT_INVAL_ENUM_V' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument; this Node\'s enumerated attribute named "{ATNM}" may only be '.
        'a "{ENUMTYPE}" value; you tried to set it to "{ARG}"',

    'SRT_N_SET_AT_NREF_WRONG_NODE_TYPE' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; the given Node is an "{ARGNTYPE}" '.
        'Node but this Node-ref attribute may only reference a "{EXPNTYPE}" Node',
    'SRT_N_SET_AT_NREF_DIFF_CONT' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; that Node is not in '.
        'the same Container as this current Node, so they can not be linked',
    'SRT_N_SET_AT_NREF_NONEX_NID' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Node Id but '.
        'it does not match the Id of any "{EXPNTYPE}" Node in this Node\'s Container',
    'SRT_N_SET_AT_NREF_NO_ALLOW_SID' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
        'this Node\'s host Container interface does not allow the use of Surrogate Ids to match Nodes when linking; '.
        'ATTR_VALUE must be either a Node ref or a positive integer Node Id',
    'SRT_N_SET_AT_NREF_NONEX_SID' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
        'it does not match the Surrogate Id of any "{EXPNTYPE}" Node in this Node\'s Container',
    'SRT_N_SET_AT_NREF_AMBIG_SID' => 
        $CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
        'it is too ambiguous to match the Surrogate Id of any single "{EXPNTYPE}" Node in this Node\'s Container; '.
        'all of these Nodes are equally qualified to match, but only one is allowed to: "{CANDIDATES}"',

    'SRT_N_SET_ATS_NO_ARG_ELEM_VAL' => 
        $CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'missing ATTRS argument element value when setting key "{ATNM}"',
    'SRT_N_SET_ATS_INVAL_ELEM_NM' => 
        $CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid ATTRS argument element key; there is no attribute named "{ATNM}" in this Node',

    'SRT_N_MOVE_PRE_SIB_S_DIFF_CONT' => 
        $CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid SIBLING argument; that Node is not in '.
        'the same Container as this current Node, so they can not be siblings',
    'SRT_N_MOVE_PRE_SIB_P_DIFF_CONT' => 
        $CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid PARENT argument; that Node is not in '.
        'the same Container as this current Node, so they can not be related',
    'SRT_N_MOVE_PRE_SIB_NO_P_ARG_OR_PP_OR_PS' => 
        $CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'no PARENT argument was given, and this current Node '.
        'has no primary parent Node or parent pseudo-Node for it to default to',
    'SRT_N_MOVE_PRE_SIB_P_NOT_P' => 
        $CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid PARENT argument; this current Node is not a child of that Node',
    'SRT_N_MOVE_PRE_SIB_S_NOT_S' => 
        $CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid SIBLING argument; this current Node does not share PARENT '.
        '(or its primary parent) with that Node',

    'SRT_N_GET_CH_NODES_BAD_TYPE' => 
        $CN.'.get_child_nodes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid NODE_TYPE argument; there is no Node Type named "{NTYPE}"',

    'SRT_N_GET_REF_NODES_BAD_TYPE' => 
        $CN.'.get_referencing_nodes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid NODE_TYPE argument; there is no Node Type named "{NTYPE}"',

    'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL' => 
        $CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'missing TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; '.
        'either the argument itself is undefined, or it is a Perl array ref which contains an undefined element',
    'SRT_N_FIND_ND_BY_SID_NO_REM_ADDR' => 
        $CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'invalid TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; '.
        '"{ATVL}" contains multiple elements but the allowable target Node types can only be addressed using a single element',

    'SRT_N_ASDC_NID_VAL_NO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'its Node ID must always be given a value',
    'SRT_N_ASDC_PP_VAL_NO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'its primary parent Node attribute ("pp") must always be given a value',
    'SRT_N_ASDC_SI_VAL_NO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'this Node\'s surrogate id attribute named "{ATNM}" must always be given a value',
    'SRT_N_ASDC_MA_VAL_NO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the "{ATNM}" attribute must always be given a value',

    'SRT_N_ASDC_MUTEX_TOO_MANY_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        '{NUMVALS} of its attributes ({ATNMS}) in the mutual-exclusivity group "{MUTEX}" are set; '.
        'you must change all but one of them to be undefined/null',
    'SRT_N_ASDC_MUTEX_ZERO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'none of its attributes ({ATNMS}) in the mutual-exclusivity group "{MUTEX}" are set; '.
        'you must give a value to exactly one of them',

    'SRT_N_ASDC_LATDP_DEP_ON_IS_NULL' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'the depended-on attribute "{DEP_ON}" is undef/null so all of its dependents must be too; '.
        'you must clear these {NUMVALS} attributes: {ATNMS}',
    'SRT_N_ASDC_LATDP_DEP_ON_HAS_WRONG_VAL' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which is different '.
        'than the value(s) that certain dependents require for being set; '.
        'you must clear these {NUMVALS} attributes: {ATNMS}',
    'SRT_N_ASDC_LATDP_TOO_MANY_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which means that '.
        'only one of these {NUMVALS} currently set dependent attributes may be set: {ATNMS}',
    'SRT_N_ASDC_LATDP_ZERO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'the depended-on attribute "{DEP_ON}" has a value of "{DEP_ON_VAL}", which means that '.
        'exactly one of these dependent attributes must be set: {ATNMS}',

    'SRT_N_ASDC_NREF_AT_NONEX_SID' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the Node-ref attribute "{ATNM}" is currently '.
        'linked to the "{PNTYPE}" Node with Id "{PNID}" and Surrogate Id Chain "{PSIDCH}"; '.
        'that parent Node is not within the visible scope of the current child '.
        '(when searching with the target surrogate id "{PSID}") so the child may not link to it',

    'SRT_N_ASDC_REL_ENUM_BAD_P_NTYPE' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the enumerated attribute "{CATNM}" may only be '.
        'set when the parent Node\'s type is one of "{PALLOWED}"; the type is currently "{PNTYPE}"',
    'SRT_N_ASDC_REL_ENUM_NO_P' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the enumerated attribute "{CATNM}" may not be '.
        'set because the parent Node\'s related enumerated attribute "{PATNM}" is not set',
    'SRT_N_ASDC_REL_ENUM_P_NEVER_P' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the enumerated ("{CENUMTYPE}") attribute "{CATNM}" '.
        '(having the value "{CATVL}") may not be set because the parent Node\'s related '.
        'enumerated ("{PENUMTYPE}") attribute "{PATNM}" has the value "{PATVL}", '.
        'which does not allow any children of the child attribute\'s enumerated type',
    'SRT_N_ASDC_REL_ENUM_P_C_NOT_REL' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; the enumerated ("{CENUMTYPE}") attribute "{CATNM}" '.
        'has an invalid value of "{CATVL}" when used with the parent Node\'s related '.
        'enumerated ("{PENUMTYPE}") attribute "{PATNM}" value of "{PATVL}"; '.
        'that parent only allows these child values of the child\'s enumerated type: {CALLOWED}',

    'SRT_N_ASDC_SI_NON_DISTINCT' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; at least two of its child Nodes have '.
        'an identical surrogate id value ("{VALUE}"); you must change '.
        'either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"',
    'SRT_N_ASDC_SI_NON_DISTINCT_PSN' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{PSNTYPE}" pseudo-Node; '.
        'a deferrable constraint was violated; at least two of its child Nodes have '.
        'an identical surrogate id value ("{VALUE}"); you must change '.
        'either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"',

    'SRT_N_ASDC_CH_N_TOO_FEW_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; this Node has too few ({COUNT}) '.
        'primary-child "{CNTYPE}" Nodes; you must have at least {EXPNUM} of them',
    'SRT_N_ASDC_CH_N_TOO_FEW_SET_PSN' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{PSNTYPE}" pseudo-Node; '.
        'a deferrable constraint was violated; this pseudo-Node has too few ({COUNT}) '.
        'primary-child "{CNTYPE}" Nodes; you must have at least {EXPNUM} of them',
    'SRT_N_ASDC_CH_N_TOO_MANY_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; this Node has too many ({COUNT}) '.
        'primary-child "{CNTYPE}" Nodes; you must have no more than {EXPNUM} of them',
    'SRT_N_ASDC_CH_N_TOO_MANY_SET_PSN' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{PSNTYPE}" pseudo-Node; '.
        'a deferrable constraint was violated; this pseudo-Node has too many ({COUNT}) '.
        'primary-child "{CNTYPE}" Nodes; you must have no more than {EXPNUM} of them',

    'SRT_N_ASDC_MUDI_NON_DISTINCT' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'at least two of its child Nodes have identical attribute set values ("{VALUES}") '.
        'with respect to the mutual-distinct child group "{MUDI}"; you must change '.
        'either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"',
    'SRT_N_ASDC_MUDI_NON_DISTINCT_PSN' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{PSNTYPE}" pseudo-Node; '.
        'a deferrable constraint was violated; '.
        'at least two of its child Nodes have identical attribute set values ("{VALUES}") '.
        'with respect to the mutual-distinct child group "{MUDI}"; you must change '.
        'either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"',

    'SRT_N_ASDC_MA_REL_ENUM_TOO_MANY_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'when its parent Node\'s related enumerated attribute "{PATNM}" is set, '.
        'exactly one of its related enumerated attributes ({CATNMS}) must be set; '.
        '{NUMVALS} are currently set, so you must unset all but one of those',
    'SRT_N_ASDC_MA_REL_ENUM_ZERO_SET' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'when its parent Node\'s related enumerated attribute "{PATNM}" is set, '.
        'exactly one of its related enumerated attributes ({CATNMS}) must be set; '.
        'none are currently set, so you must give a value to exactly one of them',
    'SRT_N_ASDC_MA_REL_ENUM_MISSING_VALUES' => 
        $CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
        'a deferrable constraint was violated; '.
        'when its enumerated ("{PENUMTYPE}") attribute "{PATNM}" has a value value of "{PATVL}", '.
        'this Node must have a child Node whose appropriate related enumerated attribute is set '.
        'for each of these child enumerated values, which are all missing: {CATVLS}',

    'SRT_G_NEW_GROUP_NO_ARG_CONT' => 
        $CG.'.new_group(): missing CONTAINER argument',
    'SRT_G_NEW_GROUP_BAD_CONT' => 
        $CG.'.new_group(): invalid CONTAINER argument; it is not a Container object, but rather is "{ARGNCONT}"',
);

######################################################################

sub get_text_by_key {
    my (undef, $msg_key) = @_;
    return $text_strings{$msg_key};
}

######################################################################

1;
__END__

=encoding utf8

=head1 NAME

SQL::Routine::L::en - Localization of SQL::Routine for English

=head1 VERSION

This document describes SQL::Routine::L::en version 0.38.1.

=head1 SYNOPSIS

    use Locale::KeyedText;
    use SQL::Routine;

    # do work ...

    my $translator = Locale::KeyedText->new_translator( ['SQL::Routine::L::'], ['en'] );

    # do work ...

    eval {
        # do work with SQL::Routine, which may throw an exception ...
    };
    if( my $error_message_object = $@ ) {
        # examine object here if you want and programmatically recover...

        # or otherwise do the next few lines...
        my $error_user_text = $translator->translate_message( $error_message_object );
        # display $error_user_text to user by some appropriate means
    }

    # continue working, which may involve using SQL::Routine some more ...

=head1 DESCRIPTION

The SQL::Routine::L::en Perl 5 module contains localization data for
SQL::Routine.  It is designed to be interpreted by Locale::KeyedText.

This class is optional and you can still use SQL::Routine effectively
without it, especially if you plan to either show users different error
messages than this class defines, or not show them anything because you are
"handling it".

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

    my $user_text_template = SQL::Routine::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the
associated user text template string, if there is one, or undef if not.

=head1 DEPENDENCIES

This module requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires the Perl module L<version>, which would conceptually be
built-in to Perl, but isn't, so it is on CPAN instead.

This module has no enforced dependencies on L<Locale::KeyedText>, which is
on CPAN, or on L<SQL::Routine>, which is in the current distribution, but
it is designed to be used in conjunction with them.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<SQL::Routine>.

=head1 BUGS AND LIMITATIONS

The structure of this module is trivially simple and has no known bugs.

However, the locale data that this module contains may be subject to large
changes in the future; you can determine the likeliness of this by
examining the development status and/or BUGS AND LIMITATIONS documentation
of the other module that this one is localizing; there tends to be a high
correlation in the rate of change between that module and this one.

=head1 AUTHOR

Darren R. Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the SQL::Routine database portability library.

SQL::Routine is Copyright (c) 2002-2005, Darren R. Duncan.  All rights
reserved. Address comments, suggestions, and bug reports to
C<perl@DarrenDuncan.net>, or visit L<http://www.DarrenDuncan.net/> for more
information.

SQL::Routine is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License (GPL) as published by the
Free Software Foundation (L<http://www.fsf.org/>); either version 2 of the
License, or (at your option) any later version.  You should have received a
copy of the GPL as part of the SQL::Routine distribution, in the file named
"GPL"; if not, write to the Free Software Foundation, Inc., 51 Franklin St,
Fifth Floor, Boston, MA 02110-1301, USA.

Linking SQL::Routine statically or dynamically with other modules is making
a combined work based on SQL::Routine.  Thus, the terms and conditions of
the GPL cover the whole combination.  As a special exception, the copyright
holders of SQL::Routine give you permission to link SQL::Routine with
independent modules, regardless of the license terms of these independent
modules, and to copy and distribute the resulting combined work under terms
of your choice, provided that every copy of the combined work is
accompanied by a complete copy of the source code of SQL::Routine (the
version of SQL::Routine used to produce the combined work), being
distributed under the terms of the GPL plus this exception.  An independent
module is a module which is not derived from or based on SQL::Routine, and
which is fully useable when not linked to SQL::Routine in any form.

Any versions of SQL::Routine that you modify and distribute must carry
prominent notices stating that you changed the files and the date of any
changes, in addition to preserving this original copyright notice and other
credits. SQL::Routine is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

While it is by no means required, the copyright holders of SQL::Routine
would appreciate being informed any time you create a modified version of
SQL::Routine that you are willing to distribute, because that is a
practical way of suggesting improvements to the standard version.

=cut
