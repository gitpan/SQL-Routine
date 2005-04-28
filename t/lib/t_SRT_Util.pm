#!perl
use 5.008001; use utf8; use strict; use warnings;

# This module is used when testing SQL::Routine.
# It contains some utility methods used by the various SRT_*.t scripts.

package # hide this class name from PAUSE indexer
t_SRT_Util;

######################################################################

sub message {
	my (undef, $detail) = @_;
	print "# $detail\n";
}

######################################################################

sub error_to_string {
	my (undef, $message) = @_;
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

######################################################################

1;
