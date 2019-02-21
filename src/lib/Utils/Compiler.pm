#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved.
#

# Package providing a set of convenient functions to compile various software.
# One of the first motivation was to automate most of the steps required to
# compile an autotools-based software.

package Utils::Compile;

use strict;
use warnings "all";

use Exporter qw(import);

our @EXPORT_OK = qw(
			prepare_build_dirs_generic
			compile_generic_with_env
		   );

# Make sure that all the directories are ready for configuring,
# building and installing a new software. We assum here that
# the source directory, the build directory and the install
# directory are separate directories.
# @param[in]    Source directory
# @parma[in]    Target build directory
# @param[in]    Target install directory
sub prepare_build_dirs_generic ($$$)
{
	my ($src_dir, $build_dir, $install_dir) = @_;

	# We do not touch the source dir, we compile in the build dir and install in install_dir
	die "ERROR: source directory does not exist" if (!defined ($src_dir) || ! -e $src_dir);
	die "ERROR: build directory is not defined" if (!defined ($build_dir));
	die "ERROR: install directory is not defined" if (!defined ($install_dir));

	mkdir $build_dir if (! -e $build_dir);
	mkdir $install_dir if (! -e $install_dir);
}

# Generate the prefix for commands, basically to ensure that the
# environment variables are correctly set.
# @param[in]    Reference to a hash representing the environment required to execute the command.
# @return       A string that needs to be added as a command prefix to ensure the
#               environment is correctly set.
sub get_cmd_prefix_from_env ($)
{
	my ($env_ref) = @_;
	my %_env = %$env_ref;
	my $cmd_prefix = "";

	$cmd_prefix .= "export PATH=$_env{'PATH'}; " if (exists ($_env{'PATH'}));
	$cmd_prefix .= "export LD_LIBRARY_PATH=$_env{'LD_LIBRARY_PATH'}; " if (exists ($_env{'LD_LIBRARY_PATH'}));

	if ($cmd_prefix ne "")
	{
		return $cmd_prefix;
	}
	else
	{
		return undef;
	}
}

# Function to configure a generic autotools-based software, taking into account
# some specific environment variables.
# @param[in]    Absolute path to the source directory
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    List of configure parameters
# @param[in]    Reference to a hash representing the target environment variables.
sub configure_generic_with_env ($$$$$)
{
	my ($src_dir, $build_dir, $install_dir, $args, $env_ref) = @_;
	my $_cmd;
	my $_cmd_prefix;

	die "ERROR: build_dir is not defined" if (!defined ($build_dir));
	die "ERROR: install_dir is not defined" if (!defined ($install_dir));

	require "Utils/Exec.pm";

	# If the directory does not have a configure script but an autogen script, we run the autogen script first
	if (! -e "$src_dir/configure" && (-e "$src_dir/autogen.pl" || -e "$src_dir/autogen.sh"))
	{
		$_cmd = "cd $src_dir; ";
		$_cmd .= "./autogen.pl" if (-e "$src_dir/autogen.pl");
		$_cmd .= "./autogen.sh" if (-e "$src_dir/autogen.sh");
		Utils::Exec::run_cmd ($_cmd);
	}

	$_cmd = "cd $build_dir; ";
	$_cmd_prefix = get_cmd_prefix_from_env ($env_ref) if (defined ($env_ref));
	$_cmd .= "$_cmd_prefix " if (defined ($_cmd_prefix));
	$_cmd .= "$src_dir/configure";
	$_cmd .= " --prefix $install_dir" if (defined ($install_dir) && -e $install_dir);
	$_cmd .= " $args" if (defined ($args));

	Utils::Exec::run_cmd ($_cmd);
}

# Compile a specific package and specify the target environment.
# This will run configure and make.
# @param[in]    Absolute path to the source directory
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    List of configure parameters
# @param[in]    Reference to a hash representing the target environment variables.
sub compile_generic_with_env ($$$$$)
{
	my ($src_dir, $build_dir, $install_dir, $configure_args, $env_ref) = @_;
	my $_cmd;
	my $_cmd_prefix;

	require "Utils/Exec.pm";
	configure_generic_with_env ($src_dir, $build_dir, $install_dir, $configure_args, $env_ref);

	$_cmd = "cd $build_dir; ";
	$_cmd_prefix = undef;
	$_cmd_prefix = get_cmd_prefix_from_env ($env_ref) if (defined ($env_ref));
	$_cmd .= " $_cmd_prefix" if (defined ($_cmd_prefix));
	$_cmd .= " make -j8 install";
	Utils::Exec::run_cmd ($_cmd);
}

1;
