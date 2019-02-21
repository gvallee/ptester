#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved.
#

# A set of function to interact with LSF

package Runner::LSF;

use strict;
use warnings "all";

use Exporter qw(import);

our @EXPORT_OK = qw (wait_for_completion
			set_verbosity);

my $job_cmd = "bjobs";
my $resume_cmd = "bresume";

# Wait for the completion of a job repling only of the LSF command line tools.
# @param[in]    Job name (not job ID)
# @param[in]    Time between checks (in seconds)
sub wait_for_completion ($$)
{
	my ($job_name, $timeout) = @_;
	my $_output;
	my $_i = 0;

	do {
		sleep $timeout if ($_i > 0);
		my $cmd = "$job_cmd -J $job_name 2>&1 | sed -n 2p";
		chomp ($_output = `$cmd`);

		# If the job is suspended, we try to resume it
		if ($_output =~ /PSUSP/)
		{
			my @words = split (' ', $_output);
			my $jobid = $words[0];
			chomp ($jobid);
			$cmd = "$resume_cmd $jobid";
			system ($cmd);
		}

		$_i = $_i + 1;

	} while (defined ($_output) && $_output ne "" && $_output ne "No unfinished job found");
}

1;
