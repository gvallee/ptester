#!/usr/bin/perl
#

#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved
#

# Script that submits a single PRRTE/DVM test.

use strict;
use warnings "all";

use Getopt::Long;
use Cwd qw(cwd);
use File::Basename;

my $verbose = 0;
my $help = 0;
my $project = undef;
my $nnodes = undef;
my $configlog = undef;
my $np = undef;
my $queue = "batch";
my $resultfile = 0;
my $output_dir = undef;

my $cmd = undef;

GetOptions (
	"project=s"	=> \$project,
	"nnodes=s"	=> \$nnodes,
	"configlog=s"	=> \$configlog,
	"np=s"		=> \$np,
	"verbose"	=> \$verbose,
	"queue=s"	=> \$queue,
	"help"		=> \$help,
	"resultfile"	=> \$resultfile,
	"output-dir=s"  => \$output_dir,
);

if ($help)
{
	print "Usage: $0 --project <PROJECTID> --nnodes <NUMBER_NODES> --configlog <FILENAME> --np <NP> --output-dir <OUTPUT_DIR> [--queue <LSF_QUEUE>] [--verbose] [--help] [--resultfile]\n";
	print "\t--project	The LSF project to run the test\n";
	print "\t--nnodes       How many nodes should be used for the test\n";
	print "\t--configlog    Name of the file (not full path) where useful configuration data will be stored\n";
	print "\t--np           Total number of PEs to run\n";
	print "\t--output-dir   Full path to the directory where test's intermediate and output files will be stored\n";
	print "\t--queue        Name of the LSF queue to use to submit jobs\n";
	print "\t--verbose      Enable the verbose mode\n";
	print "\t--help         Print this help message\n";
	print "\t--resultfile   Instead of analyzing the output of the commands executed on the compute nodes, check the return code and the presence of coredumps.\n";
	exit 0;
}

die "ERROR: undefined project" if (!defined ($project));
die "ERROR: invalid number of nodes" if (!defined ($nnodes) || $nnodes <= 0);
die "ERROR: invalid config log" if (!defined ($configlog));
die "ERROR: invalid number of PEs" if (!defined ($np) || $np <= 0);
die "ERROR: invalid output directory" if (!defined ($output_dir));

# Based on where the script is, we figure out the path to all the required packages and scripts
my $topDir = Cwd::abs_path(dirname (__FILE__)) . "/../..";
my $topSrcDir = "$topDir/src";
my $libDir = "$topDir/src/lib";
my $binDir = "$topDir/src/bin";
push (@INC, $libDir);

require "Runner/LSF.pm";
require "Utils/Exec.pm";
require "Utils/Fmt.pm";

my %verboseCfg;
my $refVerbCfg = \%verboseCfg;
$refVerbCfg = Utils::Fmt::set_verbosity ($refVerbCfg, $verbose);

sub _generate_lsf_script ($$$$$)
{
	my ($_lsfscript, $_project, $_nnodes, $_configlog, $_np) = @_;
	my $_cmd;

	my $_formatted_configlog_path = $_configlog;
	$_formatted_configlog_path =~ s/\//\\\//g;

	$_cmd = "sed -i 's/PROJECT/$_project/g' $_lsfscript";
	Utils::Exec::run_cmd ($refVerbCfg, $_cmd);
	$_cmd = "sed -i 's/NNODES/$_nnodes/g' $_lsfscript";
        Utils::Exec::run_cmd ($refVerbCfg, $_cmd);
	$_cmd = "sed -i 's/CONFIGLOG/$_formatted_configlog_path/g' $_lsfscript";
        Utils::Exec::run_cmd ($refVerbCfg, $_cmd);
	$_cmd = "sed -i 's/NP/$_np/g' $_lsfscript";
        Utils::Exec::run_cmd ($refVerbCfg, $_cmd);
}

# Update the name of the config log to get the full path
$configlog = "$output_dir/$configlog";

# Clean-up the output directory
mkdir ($output_dir) if (! -e $output_dir);
$cmd = "cd $output_dir; rm -f dvm_simple.err dvm_simple.out lsf_script_dvm_simple.sh";
Utils::Exec::run_cmd ($refVerbCfg, $cmd);

# Copy the lsf script template
my $lsf_script = "$output_dir/lsf_script_prrte_simple.sh";
my $template_lsf_script = "$topDir/etc/lsf_script_prrte_simple.tmpl";
$cmd = "cp -f $template_lsf_script $lsf_script";
Utils::Exec::run_or_die ($refVerbCfg, $cmd);

# Update the lsf script template
_generate_lsf_script ($lsf_script, $project, $nnodes, $configlog, $np);

# Submit the job
$cmd = "bsub $lsf_script";
Utils::Exec::run_or_die ($refVerbCfg, $cmd);

# Wait for the job to finish
Runner::LSF::wait_for_completion ("dvm_simple", 5);

# Check the results
if ($resultfile == 0)
{
	$cmd = "cd $output_dir; $binDir/check_results.pl --inputfile $output_dir/dvm_simple.out --expected-results $np";
}
else
{
	$cmd = "cd $output_dir; $binDir/check_results.pl --resultfile $output_dir";
}
$cmd .= " --verbose" if ($verbose);
my $rc = Utils::Exec::run_cmd ($refVerbCfg, $cmd);

exit 1 if ($rc != 0);

# Check whether a core dump was created or not
$cmd = "cd $output_dir; $binDir/check4coredumps.pl --dir $output_dir";
$cmd .= " --verbose" if ($verbose);
$rc = Utils::Exec::run_cmd ($refVerbCfg, $cmd);

exit 1 if ($rc != 0);
