#!/usr/bin/perl
#

#
# Copyright(c)  2018    UT-Battelle, LLC
#                       All rights reserved
#

# Script for the creation of a PRRTE module.

use strict;
use warnings "all";

use Getopt::Long;
use File::Basename;
use Cwd qw(cwd);

my $tester_config_dir = undef;
my $help = 0;
my $verbose = 0;
my $force = 0;
my $cmd = undef;

GetOptions (
	"help"		=> \$help,
	"force"		=> \$force,
	"verbose"	=> \$verbose,
	"configdir=s"	=> \$tester_config_dir,
);

sub help()
{
	print "Tool that will compile PRRTE and all its dependencies for the creation of a module.\n";
	print "Usage: $0 --configdir <PATH_TO_CONFIG_DIR> [--help] [--verbose] [--force]\n";
	print "\t--configdir    Path to the directory where the packager.conf file is; file that specifies all the requirements for the creation of the module.\n";
	print "\t--help         This help message.\n";
	print "\t--verbose      Enable the verbose mode.\n";
	print "\t--force        Force this tool to discard everything that was done during a previous execution.\n";
}

if ($help)
{
	help();
	exit 0;
}

die "ERROR: Invalid config directory" if (!defined $tester_config_dir || ! -e $tester_config_dir);

# Based on where the script is, we figure out the path to all the required packages and scripts
my $topDir = Cwd::abs_path(File::Basename::dirname (__FILE__)) . "/../..";
my $topSrcDir = "$topDir/src";
my $libDir = "$topDir/src/lib";
push (@INC, $libDir);

# The configuration file can be named either packager.conf or tester.conf
my $tester_config_file = undef;
$tester_config_file = "$tester_config_dir/packager.conf" if (-e "$tester_config_dir/packager.conf");
$tester_config_file = "$tester_config_dir/tester.conf" if (-e "$tester_config_dir/tester.conf");

die "ERROR: Invalid configuration" if (!defined ($tester_config_file) || ! -e $tester_config_file);

require "Utils/ConfParser.pm";
my $cfgRef = Utils::ConfParser::load_config ($tester_config_file);
die "ERROR: Impossible to load configuration from $tester_config_file" if (!defined ($cfgRef));
my %config = %$cfgRef;
my $scratchdir = $config{'scratch_dir'};
my $libevent_src_dir = $config{'libevent_dir'};
my $hwloc_src_dir =  $config{'hwloc_dir'};
my $libpmix_src_dir = $config{'pmix_dir'};
my $prrte_src_dir = $config{'prrte_dir'};
my $target_dir = $config{'target_dir'};

# Some sanity checks
die "ERROR: scratch dir is not valid" if (!defined $scratchdir);
die "ERROR: target dir is not valid" if (!defined $target_dir);
# We do not check for a valid directory for autotools since they are likely to be provided through tarballs
# However, for PMIx and PRRTE since we currently use master so we check a valid directory is specified
die "ERROR: PMIx dir is not valid" if (!defined $libpmix_src_dir || ! -e $libpmix_src_dir);
die "ERROR: PRRTE dir is not valid" if (!defined $prrte_src_dir || ! -e $prrte_src_dir);

# Initialize the verbosity mechanism
require "Utils/Fmt.pm";
my %verbosityCfg;
my $verbRef = \%verbosityCfg;
$verbRef = Utils::Fmt::set_verbosity ($verbRef, $verbose);

# Clean-up if we are in force mode
require "Utils/Exec.pm";
if ($force)
{
	$cmd = "cd $scratchdir; rm -rf *";
	Utils::Exec::run_cmd ($verbRef, $cmd);

	$cmd = "cd $target_dir; rm -rf hwloc libevent pmix prrte";
	Utils::Exec::run_cmd ($verbRef, $cmd);
}

# Figure out all the directories that we will be using
my $libevent_scratch_dir = "$scratchdir/libevent/scratch";
$config{'libevent_scratch_dir'} = $libevent_scratch_dir;
my $libevent_build_dir = "$scratchdir/libevent/build";
$config{'libevent_build_dir'} = $libevent_build_dir;
my $libevent_install_dir = "$target_dir/libevent/install";
$config{'libevent_install_dir'} = $libevent_install_dir;
my $hwloc_scratch_dir = "$scratchdir/hwloc/scratch";
$config{'hwloc_scratch_dir'} = $hwloc_scratch_dir;
my $hwloc_build_dir = "$scratchdir/hwloc/build";
$config{'hwloc_build_dir'} = $hwloc_build_dir;
my $hwloc_install_dir = "$target_dir/hwloc/install";
$config{'hwloc_install_dir'} = $hwloc_install_dir;
my $libpmix_scratch_dir = "$scratchdir/pmix/scratch";
$config{'libpmix_scratch_dir'} = $libpmix_scratch_dir;
my $libpmix_build_dir = "$scratchdir/pmix/build";
$config{'libpmix_build_dir'} = $libpmix_build_dir;
my $libpmix_install_dir = "$target_dir/pmix/install";
$config{'libpmix_install_dir'} = $libpmix_install_dir;
my $prrte_scratch_dir = "$scratchdir/prrte/scratch";
$config{'prrte_scratch_dir'} = $prrte_scratch_dir;
my $prrte_build_dir = "$scratchdir/prrte/build";
$config{'prrte_build_dir'} = $prrte_build_dir;
my $prrte_install_dir = "$target_dir/prrte/install";
$config{'prrte_install_dir'} = $prrte_install_dir;

# Make sure all these directories exist
mkdir ($scratchdir) if (! -e $scratchdir);
mkdir ($target_dir) if (! -e $target_dir);
mkdir ("$scratchdir/libevent") if (! -e "$scratchdir/libevent");
mkdir ("$scratchdir/hwloc") if (! -e "$scratchdir/hwloc");
mkdir ("$scratchdir/pmix") if (! -e "$scratchdir/pmix");
mkdir ("$scratchdir/prrte") if (! -e "$scratchdir/prrte");
mkdir ("$target_dir/libevent") if (! -e "$target_dir/libevent");
mkdir ("$target_dir/hwloc") if (! -e "$target_dir/hwloc");
mkdir ("$target_dir/pmix") if (! -e "$target_dir/pmix");
mkdir ("$target_dir/prrte") if (! -e "$target_dir/prrte");
mkdir ($libevent_build_dir) if (! -e $libevent_build_dir);
mkdir ($libevent_install_dir) if (! -e $libevent_install_dir);
mkdir ($hwloc_build_dir) if (! -e $hwloc_build_dir);
mkdir ($hwloc_install_dir) if (! -e $hwloc_install_dir);
mkdir ($libpmix_build_dir) if (! -e $libpmix_build_dir);
mkdir ($libpmix_install_dir) if (! -e $libpmix_install_dir);
mkdir ($prrte_build_dir) if (! -e $prrte_build_dir);
mkdir ($prrte_install_dir) if (! -e $prrte_install_dir);
mkdir ($libevent_scratch_dir) if (! -e $libevent_scratch_dir);
mkdir ($hwloc_scratch_dir) if (! -e $hwloc_scratch_dir);
mkdir ($libpmix_scratch_dir) if (! -e $libpmix_scratch_dir);
mkdir ($prrte_scratch_dir) if (! -e $prrte_scratch_dir);

# Finally compile all the software components. Note that if autotools are specified in the config file
# this tool will compile and install the autotools for all these components.
require "PRRTE/Compiler.pm";
PRRTE::Compiler::compile_libevent ($verbRef, \%config);
PRRTE::Compiler::compile_hwloc ($verbRef, \%config);
PRRTE::Compiler::compile_libpmix ($verbRef, \%config);
PRRTE::Compiler::compile_prrte ($verbRef, \%config);

print "Module(s) successfully created in $target_dir\n";
