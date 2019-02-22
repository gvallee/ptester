#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved.
#

# Package providing a set of convenient functions to compile various software.
# One of the first motivation was to automate most of the steps required to
# compile an autotools-based software.

package Utils::Compiler;

use strict;
use warnings "all";

use Exporter qw(import);

our @EXPORT_OK = qw(
			prepare_build_dirs_generic
			compile_generic_with_env
			install_autotools
			autotools_software_install
		   );

# Make sure that all the directories are ready for configuring,
# building and installing a new software. We assum here that
# the source directory, the build directory and the install
# directory are separate directories.
# @param[in]    Source directory
# @parma[in]    Target build directory
# @param[in]    Target install directory
sub prepare_build_dirs_generic ($$$$)
{
	my ($verboseCfg, $src_dir, $build_dir, $install_dir) = @_;

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
# @param[in]    Reference to a hash containing all the information about the verbosity configuration specific to this run.
# @param[in]    Absolute path to the source directory
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    List of configure parameters
# @param[in]    Reference to a hash representing the target environment variables.
sub configure_generic_with_env ($$$$$$)
{
	my ($verboseCfg, $src_dir, $build_dir, $install_dir, $args, $env_ref) = @_;
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
		Utils::Exec::run_or_die ($verboseCfg, $_cmd);
	}

	$_cmd = "cd $build_dir; ";
	$_cmd_prefix = get_cmd_prefix_from_env ($env_ref) if (defined ($env_ref));
	$_cmd .= "$_cmd_prefix " if (defined ($_cmd_prefix));
	$_cmd .= "$src_dir/configure";
	$_cmd .= " --prefix $install_dir" if (defined ($install_dir) && -e $install_dir);
	$_cmd .= " $args" if (defined ($args));

	Utils::Exec::run_or_die ($verboseCfg, $_cmd);
}

# Compile a specific package and specify the target environment.
# This will run configure and make.
# @param[in]    Reference to a hash containing all the information about the verbosity configuration specific to this run.
# @param[in]    Absolute path to the source directory
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    List of configure parameters
# @param[in]    Reference to a hash representing the target environment variables.
sub compile_generic_with_env ($$$$$$)
{
	my ($verboseCfg, $src_dir, $build_dir, $install_dir, $configure_args, $env_ref) = @_;
	my $_cmd;
	my $_cmd_prefix;

	# Some sanity checks
	die "ERROR: undefined source directory" if (!defined ($src_dir));
	die "ERROR: undefined build directory" if (!defined ($build_dir));
	die "ERROR: undefined install directory" if (!defined ($install_dir));

	require "Utils/Exec.pm";
	configure_generic_with_env ($verboseCfg, $src_dir, $build_dir, $install_dir, $configure_args, $env_ref);

	$_cmd = "cd $build_dir; ";
	$_cmd_prefix = undef;
	$_cmd_prefix = get_cmd_prefix_from_env ($env_ref) if (defined ($env_ref));
	$_cmd .= " $_cmd_prefix" if (defined ($_cmd_prefix));
	$_cmd .= " make -j8 install";
	Utils::Exec::run_or_die ($verboseCfg, $_cmd);
}

sub _update_configure_config ($$$)
{
        my ($verboseCfg, $topDir, $targetDir) = @_;

        my $config_guess_file = "$topDir/etc/libtool_config.guess";
        my $config_sub_file = "$topDir/etc/libtool_config.sub";
        my $cmd;

        my $defaultTargetConfigDir = "$targetDir/libltdl/config/";
        my $build_aux_dir = "$targetDir/build-aux";
        $defaultTargetConfigDir = "$targetDir/build-aux" if (-e $build_aux_dir);

	require "Utils/Exec.pm";
        if (-e $config_guess_file)
        {
                $cmd = "cp -f $config_guess_file $defaultTargetConfigDir/config.guess";
                Utils::Exec::run_or_die ($verboseCfg, $cmd);
        }

        if (-e $config_sub_file)
        {
                $cmd = "cp -f $config_sub_file $defaultTargetConfigDir/config.sub";
                Utils::Exec::run_or_die ($verboseCfg, $cmd);
        }
}


# Convenient function to unpack, configure and compile autotools.
# @param[in]    Reference to a hash containing all the information about the verbosity configuration specific to this run.
# @param[in]    Reference to a hash containing all the information about the package.
#               Using a hash allows us to customize the information that is passed in without
#               changing the API and keep a simple signature.
sub install_autotools ($$)
{
        my ($verboseCfg, $config_ref) = @_;
        my %config = %$config_ref;

        my $install_dir = $config{'install_dir'};
        my $scratchdir = $config{'scratch_dir'};
        my $software_tarball = $config{'tarball'};
        my $src_dir = $config{'src_dir'};
        my $m4_tarball = $config{'m4_tarball'};
        my $autoconf_tarball = $config{'autoconf_tarball'};
        my $automake_tarball = $config{'automake_tarball'};
        my $libtool_tarball = $config{'libtool_tarball'};
        my $configure_args = $config{'configure_args'};
        my $topDir = $config{'topdir'};
        my %env;

	# Some sanity checks
	die "ERROR: installation directory not defined" if (!defined ($install_dir));
	die "ERROR: scratch directory not defined" if (!defined ($scratchdir));

        # Update the environment to make sure we use the autotools and others as we compile them
        %env = env_add (\%env, "PATH", "$install_dir/bin");
        %env = env_add (\%env, "LD_LIBRARY_PATH", "$install_dir/lib");

        if (defined $m4_tarball)
        {
                my $m4_src_dir = unpack_software ($m4_tarball, $scratchdir);
                die "ERROR: Cannot unpack m4 from $m4_tarball" if (!defined ($m4_src_dir));
                $m4_src_dir = "$scratchdir/$m4_src_dir";
                compile_generic_with_env ($verboseCfg, $m4_src_dir, $m4_src_dir, $install_dir, undef, \%env);
        }

        if (defined $autoconf_tarball)
        {
                my $autoconf_src_dir = unpack_software ($verboseCfg, $autoconf_tarball, $scratchdir);
                die "ERROR: Cannot unpack autoconf from $autoconf_tarball" if (!defined ($autoconf_src_dir));

                # Many of the architectures we have to deal with are not supported by the default config.guess and config.sub
                _update_configure_config ($verboseCfg, $topDir, "$scratchdir/$autoconf_src_dir");

                # Now really compile the code
                $autoconf_src_dir = "$scratchdir/$autoconf_src_dir";
                compile_generic_with_env ($verboseCfg, $autoconf_src_dir, $autoconf_src_dir, $install_dir, undef, \%env);
        }

        if (defined $automake_tarball)
        {
                my $automake_src_dir = unpack_software ($verboseCfg, $automake_tarball, $scratchdir);
                die "ERROR: Cannot unpack autoconf from $automake_tarball" if (!defined ($automake_src_dir));
                $automake_src_dir = "$scratchdir/$automake_src_dir";
                compile_generic_with_env ($verboseCfg, $automake_src_dir, $automake_src_dir, $install_dir, undef, \%env);
        }

        if (defined $libtool_tarball)
        {
                my $libtool_src_dir = unpack_software ($verboseCfg, $libtool_tarball, $scratchdir);
                die "ERROR: Cannot unpack libtool from $libtool_src_dir" if (!defined ($libtool_src_dir));

                # Many of the architectures we have to deal with are not supported by the default config.guess and config.sub
                _update_configure_config ($verboseCfg, $topDir, "$scratchdir/$libtool_src_dir");

                # Now really compile the code
                $libtool_src_dir = "$scratchdir/$libtool_src_dir";
                compile_generic_with_env ($verboseCfg, $libtool_src_dir, $libtool_src_dir, $install_dir, undef, \%env);
        }

        return \%env;
}


# Convenient function to unpack, configure and compile a autotools-based software package
# @param[in]    Reference to a hash containing all the information about the verbosity configuration specific to this run.
# @param[in]    Reference to a hash containing all the information about the package.
#               Using a hash allows us to customize the information that is passed in without
#               changing the API and keep a simple signature.
sub autotools_software_install ($$)
{
        my ($verboseCfg, $config_ref) = @_;

        my $env_ref = install_autotools ($verboseCfg, $config_ref);
        my %config = %$config_ref;

        my $install_dir = $config{'install_dir'};
        my $scratchdir = $config{'scratch_dir'};
        my $software_tarball = $config{'tarball'};
        my $src_dir = $config{'src_dir'};
        my $configure_args = $config{'configure_args'};
        my %env;
        %env = %$env_ref if (defined ($env_ref));

	# Some sanity checks
	die "ERROR: undefined install directory" if (!defined ($install_dir));
	die "ERROR: undefined scrtach directory" if (!defined ($scratchdir));

        if (defined ($software_tarball))
        {
                # We work from a tarball, not a directory with sources (git clone for example)
                $src_dir = unpack_software ($software_tarball, $scratchdir);
                die "ERROR: Cannot unpack software from $software_tarball" if (!defined ($src_dir));
                $src_dir = "$scratchdir/$src_dir";
        }
        else
        {
                # If we work out of the sources available in a directory, not a tarball, we copy
                # the source code.
                die "ERROR: Working from source directory but the directory is not valid" if (!defined $src_dir || ! -e $src_dir);
                my $software_name = File::Basename::basename ($src_dir);
                my $target_src_dir = "$scratchdir/$software_name";
                mkdir ($target_src_dir) if (! -e $target_src_dir);
                my $cmd = "cd $target_src_dir; cp -rf $src_dir/* .";
		require "Utils/Exec.pm";
                Utils::Exec::_run_cmd ($verboseCfg, $cmd);
                $src_dir = $target_src_dir;
        }
        my $target_build_dir = "$scratchdir/build";
        mkdir ($target_build_dir) if (! -e $target_build_dir);
	require "Utils/Compiler.pm";
        Utils::Compiler::compile_generic_with_env ($verboseCfg, $src_dir, $target_build_dir, $install_dir, $configure_args, \%env);
}


1;
