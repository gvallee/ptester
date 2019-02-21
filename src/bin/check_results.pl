#!/usr/bin/perl
#

#
# Copyright(c)          2018-2019       UT-Battelle, LLC
#                                       All rights reserved.
#

use strict;
use warnings "all";

use Getopt::Long;

my $input = undef;
my $expected_results = 0;
my $verbose = 0;
my $help = 0;
my $result_file = undef;
my $dir = undef;
my $platform = undef;

GetOptions (
	"inputfile=s"           => \$input,
	"expected-results=s"    => \$expected_results,
	"verbose"               => \$verbose,
	"resultfile=s"          => \$result_file,
	"platform=s"            => \$platform,
	"help"                  => \$help,
);

if ($help)
{
	print "This script checks the output and/or the return code after the execution of a PRTE/PRUN test.\n";
	print "In other words, this script tells us whether or not a test passed.\n";
	print "Note that this test supports 2 modes:\n";
	print "  - checks the output of the test and ensures that the output matches expectations,\n";
	print "  - checks the return code of the prun commands executed during the job, which is saved in a file.\n";
	print "\n";
	print "Usage: $0 [--platform=<PLATFORM_ID> [--inputfile=<JOBOUTPUTFILE> --expected-results=<NUMBER_OF_EXPECTED_RESULTS>] [--resultfile=<TARGET_DIR>] [--verbose] [--help]\n";
	print "\t--platform             Name of the platform as potentially included in the hostname of compute nodes.\n";
	print "\t--dir                  Traget directory where to do the check\n";
	print "\t--inputfile            File containing the output of the job. This option must be used in conjunction with the --expected-results option.\n";
	print "\t--expected-results	How many lines are expected from the output file (assuming each PE will produce one and only one line).\n";
	print "\t--resultfile           Instead of checking the output of the job, this option enables the mode where the script checks the return code of the prun commands, which is saved in a result file; assuming that file is in the target directory specified by the option.\n";
	print "\t--verbose              Enable the verbose mode.\n";
	print "\t--help                 Display this help message.\n";
	exit 0;
}

$input = "$result_file/result.log" if (defined ($result_file));
die "ERROR: invalid input file - $0 mydatafile.out" if (!defined ($result_file) && (!defined $input || ! -e $input));
die "ERROR: cannot find the result file" if (defined ($result_file) && ! -e $input);

my $num_results = 0;
my @valid_results;

open (my $_fh, '<', $input) or die "ERROR: Cannot access $input";
while (my $line = <$_fh>)
{
	if (!defined ($result_file))
	{
		next if (!defined $line);
		next if ($line =~ /^Running job/);
		next if ($line =~ /^DVM read/);

		chomp ($line);

		# We assume here that /bin/hostname was executed and make
		# clear hard-coded assumptions about the expected output. This is
		# to filter the content of the file which may contain job information
		# in addition of the output that is of interest to us.
		#
		# Practically, we assume two types of hostnames:
		# - a generic name such as r32n43
		# - a name based on the platform name such as 'summitdev-r45b43n43'
		if ($line =~ /^[a-z](\d+)[a-z](\d+)$/ ||
		    (defined ($platform) && $line =~ /^$platform-[a-z](\d+)[a-z](\d+)[a-z](\d+)$/))
		{
			push (@valid_results, $line);
			$num_results++;
		}
	}
	else
	{
		# Note that the result file is always named 'result.log' since
		# hard-coded in the job script that is used to launch the tests.
		#my $result_filename = "result.log";
		#open (my $fh, '<', $result_filename) or exit 1;
		#my $exit_code = <$fh>;
		#close ($fh);
		chomp ($line);
		my $exit_code = $line;
		if (defined ($exit_code))
		{
			chomp ($exit_code);
			if ($exit_code eq "0")
			{
				print "Test succeeded\n" if ($verbose);
				exit 0;
			}
			else
			{
				print "Test failed\n" if ($verbose);
				exit 1;
			}
		}
	}
}
close ($_fh);

if ($expected_results > 0)
{
	print "Results: $num_results/$expected_results\n" if ($verbose);
	exit 1 if ($num_results != $expected_results)
}

exit 0;
