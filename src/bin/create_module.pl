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

die "ERROR: Invalid config directory" if (!defined $tester_config_dir || ! -e $tester_config_dir);

# Based on where the script is, we figure out the path to all the required packages and scripts
my $topDir = Cwd::abs_path(File::Basename::dirname (__FILE__)) . "/../..";
my $topSrcDir = "$topDir/src";
my $libDir = "$topDir/src/lib";
push (@INC, $libDir);

require "Utils/ConfParser.pm";
my %config = Utils::ConfParser::load_config ($tester_config_dir);
my $scratchdir = $config{'scratch_dir'};
my $libevent_src_dir = $config{'libevent_dir'};
my $hwloc_src_dir =  $config{'hwloc_dir'};
my $libpmix_src_dir = $config{'pmix_dir'};
my $prrte_src_dir = $config{'prrte_dir'};
my $target_dir = $config{'target_dir'};

die "ERROR: scratch dir is not valid" if (!defined $scratchdir);
die "ERROR: target dir is not valid" if (!defined $target_dir);
die "ERROR: libevent dir is not valid" if (!defined $libevent_src_dir || ! -e $libevent_src_dir);
die "ERROR: hwloc dir is not valid" if (!defined $hwloc_src_dir || ! -e $hwloc_src_dir);
die "ERROR: PMIx dir is not valid" if (!defined $libpmix_src_dir || ! -e $libpmix_src_dir);
die "ERROR: PRRTE dir is not valid" if (!defined $prrte_src_dir || ! -e $prrte_src_dir);

require "Utils/Exec.pm";
if ($force)
{
	$cmd = "cd $scratchdir; rm -rf *";
	Utils::Exec::run_cmd ($cmd);

	$cmd = "cd $scratchdir; rm -rf *";
	Utils::Exec::run_cmd ($cmd);
}

my $libevent_build_dir = "$scratchdir/libevent/build";
my $libevent_install_dir = "$target_dir/libevent/install";
my $hwloc_build_dir = "$scratchdir/hwloc/build";
my $hwloc_install_dir = "$target_dir/hwloc/install";
my $libpmix_build_dir = "$scratchdir/pmix/build";
my $libpmix_install_dir = "$target_dir/pmix/install";
my $prrte_build_dir = "$scratchdir/prrte/build";
my $prrte_install_dir = "$target_dir/prrte/install";

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

require "Utils/Fmt.pm";
my $verbRef = Utils::Fmt::set_verbosity ($verbose);

PRRTE::Compiler::compile_libevent ($libevent_src_dir, $libevent_build_dir, $libevent_install_dir);
PRRTE::Compiler::compile_hwloc ($hwloc_src_dir, $hwloc_build_dir, $hwloc_install_dir);
PRRTE::Compiler::compile_libpmix ($libpmix_src_dir, $libpmix_build_dir, $libpmix_install_dir, $libevent_install_dir);
PRRTE::Compiler::compile_prrte ($prrte_src_dir, $prrte_build_dir, $prrte_install_dir, $libevent_install_dir, $hwloc_install_dir, $libpmix_install_dir);

print "Module(s) successfully created in $target_dir\n";
