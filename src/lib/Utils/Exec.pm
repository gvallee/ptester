#
# Copyright(c)     2018-2019    UT-Battelle, LLC
#                               All rights reserved.
#

# Useful package to run commands with slightly different behaviors

package Utils::Exec;

use strict;
use warnings "all";

our @EXPORT_OK = qw(run_cmd
                    run_or_die);

# Run and command and return the return code.
# @param[in]    Verbosity handle (opaque handle from Utils::Fmt::set_verbosity())
# @param[in]    Command to run
# @return       Return code from the command that was executed
sub run_cmd ($$)
{
	my ($verboseCfg, $cmd) = @_;

	require Utils::Fmt;
	Utils::Fmt::vlogln ($verboseCfg, "Executing: $cmd");
	return system ($cmd);
}

# Run and command and die if the command fails.
# @param[in]    Verbosity handle (opaque handle from Utils::Fmt::set_verbosity())
# @param[in]    Command to run
sub run_or_die ($$)
{
	my ($verboseCfg, $cmd) = @_;

	require Utils::Fmt;
	Utils::Fmt::vlogln ($verboseCfg, "Executing: $cmd");
	my $rc = system ($cmd);
	die "ERROR: $cmd failed (rc: $rc)" if ($rc);
}

1;
