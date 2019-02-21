#!/usr/bin/perl
#

#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved
#

use strict;
use warnings "all";
use Cwd qw(cwd);
use Getopt::Long;
use File::Basename;

my $verbose = 0;
my $help = 0;
my $dir = undef;

GetOptions (
	"verbose"               => \$verbose,
	"help"                  => \$help,
	"dir=s"                 => \$dir,
);

sub help ()
{
	print "Check if a directory contains core dump files.\n";
	print "This script is used to detect silent errors where no error\n";
	print "code is returned but core dumps created by sub-processes.\n";
	print "This script return 0 if no core dump is detected in the targer\n";
	print "direcotry; a non-zero value otherwise. This script can therefore\n";
	print "be used as a pass-fail test for silent errors that results in\n";
	print "creation of core dump files.\n";
	print "\n";
	print "Usage: $0 --dir <PATH> [--verbose] [--help]\n";
	print "\t--dir          Path where to check for core dumps\n";
	print "\t--help         Print this help message\n";
	print "\t--verbose      Enable the version mode\n";
}

if ($help)
{
	help();
	exit 0;
}

# Sanity checks
die "ERROR: Invalid target directory" if (!defined ($dir) || ! -e ($dir));

# We get the location of the script to figure out where the rest of the code is
my $topDir = Cwd::abs_path(File::Basename::dirname (__FILE__)) . "/../..";
my $topSrcDir = "$topDir/src";
my $libDir = "$topDir/src/lib";
push (@INC, $libDir);

# Set the verbosity mode
require "Utils/Fmt.pm";
my %vcfg;
my $ref = \%vcfg;
$ref = Utils::Fmt::set_verbosity ($ref, $verbose);

# Look for all core dump files in the target directory
my $dh;
opendir ($dh, $dir);
my @files = grep { /^core.(.*)$/ } readdir ($dh);
closedir ($dh);

# Return with the appropriate code based on the potential presence of core dump files
if (scalar (@files) == 0)
{
	Utils::Fmt::vprintln ($ref, "No coredump - Success");
	exit 0;
}
else
{
	Utils::Fmt::vprintln ($ref, "List of core dump files:");
	foreach my $file (@files)
	{
		chomp ($file);
		Utils::Fmt::vlogln ($ref, $file);
	}
	Utils::Fmt::vprintln ($ref, "Coredump(s) present - Failure");
	exit 1;
}
