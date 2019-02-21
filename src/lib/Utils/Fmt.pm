#
# Copyright(c)          2019    UT-Battelle, LLC
#                               All rights reserved.
#

# This package provides useful primitives to display messages,
# including the capability of enabling/disabling a verbosity mode
# across Perl scripts and packages.

package Utils::Fmt;

use strict;
use warnings "all";

our @EXPORT_OK = qw(
		set_verbosity
		vprint
		vlog
		vlogln
                   );

# Set the verbosity mode: 0 disable the verbosity mode;
# any other value enables it.
# @param[in]    Reference to a hash representing the verbosity configuration (opaque handle, can be a non-initialized hash reference - but not undefined)
# @param[in]    Requested verbosity mode (0: disabled; any other value: enabled).
# @return       Hash reference representing the new verbosity configuration; undef if case of error.
sub set_verbosity ($$)
{
	my ($ref, $v) = @_;

	if (defined ($ref))
	{
		my %config = %$ref;
		$config{'verbose'} = $v;
		return \%config
	}

	return undef;
}

# Function to print a message followed by a line return. The message will be displayed (or not) based on the verbosity configuration that is passed in.
# @param[in]    Reference to a hash representing the verbosity configuration (opaque handle, can be a non-initialized hash reference - but not undefined)
# @param[in]	Message to display.
sub vprintln ($$)
{
	my ($ref, $msg) = @_;

	return if (!defined ($ref));

	my %cfg = %$ref;
	print "$msg\n" if ($cfg{'verbose'});
}

# Function to print a message followed wihtout a line return. The message will be displayed (or not) based on the verbosity configuration that is passed in.
# @param[in]    Reference to a hash representing the verbosity configuration (opaque handle, can be a non-initialized hash reference - but not undefined)
# @param[in]    Message to display.
sub vprint ($$)
{
	my ($ref, $msg) = @_;

	return if (!defined ($ref));

	my %cfg = %$ref;
	print "$msg " if ($cfg{'verbose'});
}

# Function to print a message followed by a line return. The message will be displayed (or not) based on the verbosity configuration that is passed in.
# A log message differs from a normal message because of the prefix to the message (a '*' character).
# @param[in]    Reference to a hash representing the verbosity configuration (opaque handle, can be a non-initialized hash reference - but not undefined)
# @param[in]    Message to display.
sub vlogln ($$)
{
	my ($ref, $msg) = @_;

	return if (!defined ($ref));

	my %cfg = %$ref;
	print "* $msg\n" if ($cfg{'verbose'});
}

# Function to print a message without a line return. The message will be displayed (or not) based on the verbosity configuration that is passed in.
# A log message differs from a normal message because of the prefix to the message (a '*' character).
# @param[in]    Reference to a hash representing the verbosity configuration (opaque handle, can be a non-initialized hash reference - but not undefined)
# @param[in]    Message to display.
sub vlog ($$)
{
	my ($ref, $msg) = @_;

	return if (!defined ($ref));

	my %cfg = %$ref;
	print "* $msg " if ($cfg{'verbose'});
}


1;

