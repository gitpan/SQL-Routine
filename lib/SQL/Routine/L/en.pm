#!perl
use 5.008001; use utf8; use strict; use warnings;

package SQL::Routine::L::en;
our $VERSION = '0.28';

######################################################################

=encoding utf8

=head1 NAME

SQL::Routine::L::en - Localization of SQL::Routine for English

=head1 DEPENDENCIES

Perl Version: 5.008001

Core Modules: I<none>

Non-Core Modules: I<This module has no enforced dependencies, but it is
designed to be used by Locale::KeyedText when that module localizes error
messages generated by SQL::Routine.>

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

my $CC = 'SQL::Routine::Container';
my $CN = 'SQL::Routine::Node';
my $ABSINTF = 'using abstract interface';

my %text_strings = (
	'SRT_C_GET_CH_NODES_BAD_TYPE' => 
		$CC.'.get_child_nodes(): invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"',

	'SRT_C_BUILD_CH_ND_NO_PSND' => 
		$CC.'.build_child_node(): invalid NODE_TYPE argument; a "{ARGNTYPE}" Node does not '.
		'have a pseudo-Node parent and can not be made a direct child of a Container',

	'SRT_C_FIND_NODE_BY_ID_NO_ARG_ID' => 
		$CC.'.find_node_by_id(): missing NODE_ID argument',

	'SRT_C_FIND_CH_ND_BY_SID_NO_ARG_VAL' => 
		$CC.'.find_child_node_by_surrogate_id(): missing TARGET_ATTR_VALUE argument',

	'SRT_N_NEW_NODE_NO_ARGS' => 
		$CN.'.new_node(): missing NODE_TYPE argument',
	'SRT_N_NEW_NODE_BAD_TYPE' => 
		$CN.'.new_node(): invalid NODE_TYPE argument; there is no Node Type named "{ARGNTYPE}"',

	'SRT_N_CLEAR_NODE_ID_IN_CONT' => 
		$CN.'.clear_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not clear the Node Id because the Node is in a Container',

	'SRT_N_SET_NODE_ID_NO_ARGS' => 
		$CN.'.set_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing NEW_ID argument',
	'SRT_N_SET_NODE_ID_BAD_ARG' => 
		$CN.'.set_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid NEW_ID argument; a Node Id may only be a positive integer; '.
		'you tried to set it to "{ARG}"',
	'SRT_N_SET_NODE_ID_DUPL_ID' => 
		$CN.'.set_node_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid NEW_ID argument; the Node Id value of "{ARG}" you tried to set '.
		'is already in use by another Node in the same Container; it must be distinct',

	'SRT_N_GET_PP_AT_NO_PP_AT' => 
		$CN.'.get_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'there is no primary parent attribute in this Node',

	'SRT_N_CLEAR_PP_AT_NO_PP_AT' => 
		$CN.'.clear_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'there is no primary parent attribute in this Node',

	'SRT_N_SET_PP_AT_NO_PP_AT' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'there is no primary parent attribute in this Node',
	'SRT_N_SET_PP_AT_NO_ARG_VAL' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument',
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
	'SRT_N_SET_PP_AT_ONE_CONT' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; a Node that is in a '.
		'Container can not be linked to one that is not',
	'SRT_N_SET_PP_AT_MISS_NID' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; the given Node '.
		'lacks a Node Id, and one is required to link to it from this one',
	'SRT_N_SET_PP_AT_NONEX_NID' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; "{ARG}" looks like a Node Id but '.
		'it does not match the Id of any "{EXPNTYPE}" Node in this Node\'s Container',
	'SRT_N_SET_PP_AT_NO_ALLOW_SID_FOR_PP' => 
		$CN.'.set_primary_parent_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; "{ARG}" looks like a Surrogate Id but '.
		'you may not use Surrogate Ids to match Nodes when setting the primary parent attribute; '.
		'ATTR_VALUE must be either a Node ref or a positive integer Node Id',

	'SRT_N_GET_LIT_AT_NO_ARGS' => 
		$CN.'.get_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_GET_LIT_AT_INVAL_NM' => 
		$CN.'.get_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no literal attribute named "{ATNM}" in this Node',

	'SRT_N_CLEAR_LIT_AT_NO_ARGS' => 
		$CN.'.clear_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_CLEAR_LIT_AT_INVAL_NM' => 
		$CN.'.clear_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no literal attribute named "{ATNM}" in this Node',

	'SRT_N_SET_LIT_AT_NO_ARGS' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_SET_LIT_AT_INVAL_NM' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no literal attribute named "{ATNM}" in this Node',
	'SRT_N_SET_LIT_AT_NO_ARG_VAL' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument when setting "{ATNM}"',
	'SRT_N_SET_LIT_AT_INVAL_V_IS_REF' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
		'a scalar value; you tried to set it to a "{ARG_REF_TYPE}" reference',
	'SRT_N_SET_LIT_AT_INVAL_V_BOOL' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
		'a boolean value, as expressed by "0" or "1"; you tried to set it to "{ARG}"',
	'SRT_N_SET_LIT_AT_INVAL_V_UINT' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
		'a non-negative integer; you tried to set it to "{ARG}"',
	'SRT_N_SET_LIT_AT_INVAL_V_SINT' => 
		$CN.'.set_literal_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; this Node\'s literal attribute named "{ATNM}" may only be '.
		'an integer; you tried to set it to "{ARG}"',

	'SRT_N_SET_LIT_ATS_NO_ARGS' => 
		$CN.'.set_literal_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTRS argument',
	'SRT_N_SET_LIT_ATS_BAD_ARGS' => 
		$CN.'.set_literal_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTRS argument; it is not a hash ref, but rather is "{ARG}',

	'SRT_N_GET_ENUM_AT_NO_ARGS' => 
		$CN.'.get_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_GET_ENUM_AT_INVAL_NM' => 
		$CN.'.get_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no enumerated attribute named "{ATNM}" in this Node',

	'SRT_N_CLEAR_ENUM_AT_NO_ARGS' => 
		$CN.'.clear_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_CLEAR_ENUM_AT_INVAL_NM' => 
		$CN.'.clear_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no enumerated attribute named "{ATNM}" in this Node',

	'SRT_N_SET_ENUM_AT_NO_ARGS' => 
		$CN.'.set_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_SET_ENUM_AT_INVAL_NM' => 
		$CN.'.set_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no enumerated attribute named "{ATNM}" in this Node',
	'SRT_N_SET_ENUM_AT_NO_ARG_VAL' => 
		$CN.'.set_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument when setting "{ATNM}"',
	'SRT_N_SET_ENUM_AT_INVAL_V' => 
		$CN.'.set_enumerated_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument; this Node\'s enumerated attribute named "{ATNM}" may only be '.
		'a "{ENUMTYPE}" value; you tried to set it to "{ARG}"',

	'SRT_N_SET_ENUM_ATS_NO_ARGS' => 
		$CN.'.set_enumerated_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTRS argument',
	'SRT_N_SET_ENUM_ATS_BAD_ARGS' => 
		$CN.'.set_enumerated_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTRS argument; it is not a hash ref, but rather is "{ARG}"',

	'SRT_N_GET_NREF_AT_NO_ARGS' => 
		$CN.'.get_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_GET_NREF_AT_INVAL_NM' => 
		$CN.'.get_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no Node attribute named "{ATNM}" in this Node',

	'SRT_N_CLEAR_NREF_AT_NO_ARGS' => 
		$CN.'.clear_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_CLEAR_NREF_AT_INVAL_NM' => 
		$CN.'.clear_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no Node attribute named "{ATNM}" in this Node',

	'SRT_N_SET_NREF_AT_NO_ARGS' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_SET_NREF_AT_INVAL_NM' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no Node attribute named "{ATNM}" in this Node',
	'SRT_N_SET_NREF_AT_NO_ARG_VAL' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument when setting "{ATNM}"',

	'SRT_N_SET_NREF_AT_WRONG_NODE_TYPE' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; the given Node is an "{ARGNTYPE}" '.
		'Node but this Node-ref attribute may only reference a "{EXPNTYPE}" Node',
	'SRT_N_SET_NREF_AT_DIFF_CONT' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; that Node is not in '.
		'the same Container as this current Node, so they can not be linked',
	'SRT_N_SET_NREF_AT_ONE_CONT' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; a Node that is in a '.
		'Container can not be linked to one that is not',
	'SRT_N_SET_NREF_AT_MISS_NID' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; the given Node '.
		'lacks a Node Id, and one is required to link to it from this one',
	'SRT_N_SET_NREF_AT_NONEX_NID' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Node Id but '.
		'it does not match the Id of any "{EXPNTYPE}" Node in this Node\'s Container',
	'SRT_N_SET_NREF_AT_NO_ALLOW_SID' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
		'either this Node is not in a Container or its Container does not allow '.
		'the use of Surrogate Ids to match Nodes when linking; '.
		'ATTR_VALUE must be either a Node ref or a positive integer Node Id',
	'SRT_N_SET_NREF_AT_NONEX_SID' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
		'it does not match the Surrogate Id of any "{EXPNTYPE}" Node in this Node\'s Container',
	'SRT_N_SET_NREF_AT_AMBIG_SID' => 
		$CN.'.set_node_ref_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_VALUE argument when setting "{ATNM}"; "{ARG}" looks like a Surrogate Id but '.
		'it is too ambiguous to match the Surrogate Id of any single "{EXPNTYPE}" Node in this Node\'s Container; '.
		'all of these Nodes are equally qualified to match, but only one is allowed to: "{CANDIDATES}"',

	'SRT_N_SET_NREF_ATS_NO_ARGS' => 
		$CN.'.set_node_ref_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTRS argument',
	'SRT_N_SET_NREF_ATS_BAD_ARGS' => 
		$CN.'.set_node_ref_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTRS argument; it is not a hash ref, but rather is "{ARG}"',

	'SRT_N_SET_SI_AT_NO_ARGS' => 
		$CN.'.set_surrogate_id_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument',

	'SRT_N_GET_AT_NO_ARGS' => 
		$CN.'.get_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_GET_AT_INVAL_NM' => 
		$CN.'.get_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no attribute named "{ATNM}" in this Node',

	'SRT_N_CLEAR_AT_NO_ARGS' => 
		$CN.'.clear_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_CLEAR_AT_INVAL_NM' => 
		$CN.'.clear_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no attribute named "{ATNM}" in this Node',

	'SRT_N_SET_AT_NO_ARGS' => 
		$CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_NAME argument',
	'SRT_N_SET_AT_NO_ARG_VAL' => 
		$CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTR_VALUE argument when setting "{ATNM}"',
	'SRT_N_SET_AT_INVAL_NM' => 
		$CN.'.set_attribute(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTR_NAME argument; there is no attribute named "{ATNM}" in this Node',

	'SRT_N_SET_ATS_NO_ARGS' => 
		$CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTRS argument',
	'SRT_N_SET_ATS_BAD_ARGS' => 
		$CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTRS argument; it is not a hash ref, but rather is "{ARG}"',
	'SRT_N_SET_ATS_NO_ARG_ELEM_VAL' => 
		$CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing ATTRS argument element value when setting key "{ATNM}"',
	'SRT_N_SET_ATS_INVAL_ELEM_NM' => 
		$CN.'.set_attributes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid ATTRS argument element key; there is no attribute named "{ATNM}" in this Node',

	'SRT_N_PI_CONT_NO_ARGS' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing NEW_CONTAINER argument',
	'SRT_N_PI_CONT_BAD_ARG' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid NEW_CONTAINER argument; it is not a Container object, but rather is "{ARG}"',
	'SRT_N_PI_CONT_HAVE_ALREADY' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node already lives in a Container; you '.
		'must take this Node from there before putting it in a different one',
	'SRT_N_PI_CONT_NO_NODE_ID' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node can not be put in a Container yet as this Node has no NODE_ID defined, '.
		'and the given Container is not configured to auto-set missing Node Ids',
	'SRT_N_PI_CONT_DUPL_ID' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node can not be put into the given Container '.
		'because it has the same Node Id value as another Node already '.
		'in the same Container; one of these Node Ids needs to be changed first',
	'SRT_N_PI_CONT_NONEX_PP_NREF' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node can not be put into the given Container '.
		'because its primary parent attribute expects to link to a "{EXPNTYPE}" Node '.
		'with a Node Id of "{EXPNID}", but no such Node exists in the given Container',
	'SRT_N_PI_CONT_NONEX_AT_NREF' => 
		$CN.'.put_in_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node can not be put into the given Container '.
		'because the Node attribute named "{ATNM}" expects to link to a "{EXPNTYPE}" Node '.
		'with a Node Id of "{EXPNID}", but no such Node exists in the given Container',

	'SRT_N_TF_CONT_HAS_CHILD' => 
		$CN.'.take_from_container(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node can not be taken from its Container yet because it has child Nodes of its own',

	'SRT_N_MOVE_PRE_SIB_NO_CONT' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'this Node is not in a Container and therefore '.
		'it is not present in any child list; it has no siblings',
	'SRT_N_MOVE_PRE_SIB_NO_S_ARG' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing SIBLING argument',
	'SRT_N_MOVE_PRE_SIB_BAD_S_ARG' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid SIBLING argument; it is not a Node object, but rather is "{ARG}"',
	'SRT_N_MOVE_PRE_SIB_S_DIFF_CONT' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid SIBLING argument; that Node is not in '.
		'the same Container (if any) as this current Node, so they can not be siblings',
	'SRT_N_MOVE_PRE_SIB_BAD_P_ARG' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid PARENT argument; it is not a Node object, but rather is "{ARG}"',
	'SRT_N_MOVE_PRE_SIB_P_DIFF_CONT' => 
		$CN.'.move_before_sibling(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid PARENT argument; that Node is not in '.
		'the same Container (if any) as this current Node, so they can not be related',
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

	'SRT_N_ADD_CH_NODE_NO_ARGS' => 
		$CN.'.add_child_node(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing NEW_CHILD argument',
	'SRT_N_ADD_CH_NODE_BAD_ARG' => 
		$CN.'.add_child_node(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid NEW_CHILD argument; it is not a Node object, but rather is "{ARG}"',

	'SRT_N_GET_REF_NODES_BAD_TYPE' => 
		$CN.'.get_referencing_nodes(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid NODE_TYPE argument; there is no Node Type named "{NTYPE}"',

	'SRT_N_GET_SID_CHAIN_NOT_IN_CONT' => 
		$CN.'.get_surrogate_id_chain(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',

	'SRT_N_FIND_ND_BY_SID_NOT_IN_CONT' => 
		$CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',
	'SRT_N_FIND_ND_BY_SID_NO_ARGS' => 
		$CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing SELF_ATTR_NAME argument',
	'SRT_N_FIND_ND_BY_SID_INVAL_NM' => 
		$CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid SELF_ATTR_NAME argument; there is no Node-ref attribute named "{ATNM}" in this Node',
	'SRT_N_FIND_ND_BY_SID_NO_ARG_VAL' => 
		$CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; '.
		'either the argument itself is undefined, or it is a Perl array ref which contains an undefined element',
	'SRT_N_FIND_ND_BY_SID_NO_REM_ADDR' => 
		$CN.'.find_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid TARGET_ATTR_VALUE argument for the Node-ref attribute named "{ATNM}"; '.
		'"{ATVL}" contains multiple elements but the allowable target Node types can only be addressed using a single element',

	'SRT_N_FIND_CH_ND_BY_SID_NOT_IN_CONT' => 
		$CN.'.find_child_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',
	'SRT_N_FIND_CH_ND_BY_SID_NO_ARG_VAL' => 
		$CN.'.find_child_node_by_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing TARGET_ATTR_VALUE argument',

	'SRT_N_GET_REL_SID_NOT_IN_CONT' => 
		$CN.'.get_relative_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',
	'SRT_N_GET_REL_SID_NO_ARGS' => 
		$CN.'.get_relative_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'missing SELF_ATTR_NAME argument',
	'SRT_N_GET_REL_SID_INVAL_NM' => 
		$CN.'.get_relative_surrogate_id(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'invalid SELF_ATTR_NAME argument; there is no Node-ref attribute named "{ATNM}" in this Node',

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

	'SRT_N_ASDC_MUDI_NON_DISTINCT' => 
		$CN.'.assert_deferrable_constraints(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'a deferrable constraint was violated; '.
		'at least two of its child Nodes have identical attribute set values ("{VALUES}") '.
		'with respect to the mutual-distinct child group "{MUDI}"; you must change '.
		'either the "{C1NTYPE}" Node with Id "{C1NID}" or the "{C2NTYPE}" Node with Id "{C2NID}"',

	'SRT_N_BUILD_ND_NOT_IN_CONT' => 
		$CN.'.build_node(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',

	'SRT_N_BUILD_CH_ND_NOT_IN_CONT' => 
		$CN.'.build_child_node(): concerning the "{NTYPE}" Node with Id "{NID}" and Surrogate Id Chain "{SIDCH}"; '.
		'you can not invoke this method on this Node because it is not in a Container',
);

######################################################################

sub get_text_by_key {
	my (undef, $msg_key) = @_;
	return $text_strings{$msg_key};
}

######################################################################

1;
__END__

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

This class is optional and you can still use SQL::Routine effectively without 
it, especially if you plan to either show users different error messages than this 
class defines, or not show them anything because you are "handling it".

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>.  

=head1 FUNCTIONS

=head2 get_text_by_key( MSG_KEY )

	my $user_text_template = SQL::Routine::L::en->get_text_by_key( 'foo' );

This function takes a Message Key string in MSG_KEY and returns the associated
user text template string, if there is one, or undef if not.

=head1 SEE ALSO

L<perl(1)>, L<Locale::KeyedText>, L<SQL::Routine>.

=cut
