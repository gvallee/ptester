#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved.
#

package PRRTE::Compiler;

use strict;
use warnings "all";

use Exporter qw(import);
use File::Basename;

our @EXPORT_OK = qw(
			compile_libevent
			compile_hwloc
			compile_libpmix
			compile_prrte
			autotools_software_install
			unpack_software
		   );

# Unpackage a given software package. This functions aims at abstracting
# how to deal with different formats (e.g., tar.gz) and will be expended
# based on current needs. The function also tries to figure out the name
# of the directory that was generated when unpacking the software.
# @parma[in]    Absolute path to the package (tarball) to unpacked
# @parma[in]    Destination directory where to unpack the package
# @return       Absolute path to the source code, i.e., the destination directory in addition of the directory from the software package.
sub unpack_software ($$)
{
	my ($src_tarball, $dest_dir) = @_;

	require "Utils/Exec.pm";
	my $cmd = "cd $dest_dir; cp $src_tarball .";
	Utils::Exec::run_cmd ($cmd);

	my $tarball_filename = File::Basename::basename ($src_tarball);
	$cmd = "cd $dest_dir; tar xzf $tarball_filename";
	Utils::Exec::run_cmd ($cmd);

	$cmd = "cd $dest_dir; rm -rf $tarball_filename";
	Utils::Exec::run_cmd ($cmd);
	
	my $src_dir = substr ($tarball_filename, 0, index ($tarball_filename, ".tar.gz"));

	return $src_dir;
}

# Convenient function to unpack, configure and compile a autotools-based software package
# @param[in]    Reference to a hash containing all the information about the package.
#               Using a hash allows us to customize the information that is passed in without
#               changing the API and keep a simple signature.
sub autotools_software_install ($)
{
	my ($config_ref) = @_;
	my %config = %$config_ref;

	my $install_dir = $config{'install_dir'};
	my $scratchdir = $config{'scratchdir'};
	my $software_tarball = $config{'tarball'};
	my $src_dir = $config{'src_dir'};
	my $m4_tarball = $config{'m4_tarball'};
	my $autoconf_tarball = $config{'autoconf_tarball'};
	my $automake_tarball = $config{'automake_tarball'};
	my $libtool_tarball = $config{'libtool_tarball'};
	my $configure_args = $config{'configure_args'};
	my %env;

	# Update the environment to make sure we use the autotools and others as we compile them
	require "Utils/Env.pm";
	%env = Utils::Env::env_add (\%env, "PATH", "$install_dir/bin");
	%env = Utils::Env::env_add (\%env, "LD_LIBRARY_PATH", "$install_dir/lib");

	require "Utils/Compiler.pm";
	require "Utils/Exec.pm";

	if (defined $m4_tarball)
	{
		my $m4_src_dir = unpack_software ($m4_tarball, $scratchdir);
		die "ERROR: Cannot unpack m4 from $m4_tarball" if (!defined ($m4_src_dir));
		$m4_src_dir = "$scratchdir/$m4_src_dir";
		Utils::Compiler::compile_generic_with_env ($m4_src_dir, $m4_src_dir, $install_dir, undef, \%env);
	}

	if (defined $autoconf_tarball)
	{
		my $autoconf_src_dir = unpack_software ($autoconf_tarball, $scratchdir);
		die "ERROR: Cannot unpack autoconf from $autoconf_tarball" if (!defined ($autoconf_src_dir));
		$autoconf_src_dir = "$scratchdir/$autoconf_src_dir";
		Utils::Compiler::compile_generic_with_env ($autoconf_src_dir, $autoconf_src_dir, $install_dir, undef, \%env);
	}

	if (defined $automake_tarball)
	{
		my $automake_src_dir = unpack_software ($automake_tarball, $scratchdir);
		die "ERROR: Cannot unpack autoconf from $automake_tarball" if (!defined ($automake_src_dir));
		$automake_src_dir = "$scratchdir/$automake_src_dir";
		Utils::Compiler::compile_generic_with_env ($automake_src_dir, $automake_src_dir, $install_dir, undef, \%env);
	}

	if (defined $libtool_tarball)
	{
		my $libtool_src_dir = unpack_software ($libtool_tarball, $scratchdir);
		die "ERROR: Cannot unpack libtool from $libtool_src_dir" if (!defined ($libtool_src_dir));
		$libtool_src_dir = "$scratchdir/$libtool_src_dir";
		Utils::Compiler::compile_generic_with_env ($libtool_src_dir, $libtool_src_dir, $install_dir, undef, \%env);
	}

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
		Utils::Exec::_run_cmd ($cmd);
		$src_dir = $target_src_dir;
	}
	my $target_build_dir = "$scratchdir/build";
	mkdir ($target_build_dir) if (! -e $target_build_dir);
	Utils::Compiler::compile_generic_with_env ($src_dir, $target_build_dir, $install_dir, $configure_args, \%env);
}

# High-level function to compile libevent
# @param[in]    Absolute path to the libevent's sources
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    Reference to a hash containing all the details of the target environment
sub compile_libevent ($$$$)
{
	my ($libevent_src_dir, $libevent_build_dir, $libevent_install_dir, $env_ref) = @_;

	Utils::Compiler::prepare_build_dirs_generic ($libevent_src_dir, $libevent_build_dir, $libevent_install_dir);
	Utils::Compiler::compile_generic_with_env ($libevent_src_dir, $libevent_build_dir, $libevent_install_dir, undef, $env_ref);
}

# High-level function to compile hwloc
# @param[in]    Absolute path to the hwloc's sources
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    Reference to a hash containing all the details of the target environment
sub compile_hwloc ($$$$)
{
	my ($hwloc_src_dir, $hwloc_build_dir, $hwloc_install_dir, $env_ref) = @_;

	Utils::Compiler::prepare_build_dirs_generic ($hwloc_src_dir, $hwloc_build_dir, $hwloc_install_dir);
	Utils::Compiler::compile_generic_with_env ($hwloc_src_dir, $hwloc_build_dir, $hwloc_install_dir, undef, $env_ref);
}

# High-level function to compile libevent
# @param[in]    Absolute path to the libpmix's sources
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    Reference to a hash containing all the details of the target environment
sub compile_libpmix ($$$$$)
{
	my ($libpmix_src_dir, $libpmix_build_dir, $libpmix_install_dir, $libevent_install_dir, $env_ref) = @_;
	my $configure_args = "--with-libevent=$libevent_install_dir";

	Utils::Compiler::prepare_build_dirs_generic ($libpmix_src_dir, $libpmix_build_dir, $libpmix_install_dir);
	Utils::Compiler::compile_generic_with_env ($libpmix_src_dir, $libpmix_build_dir, $libpmix_install_dir, $configure_args, $env_ref);
}

# High-level function to compile libevent
# @param[in]    Absolute path to the PRRTE's sources
# @param[in]    Absolute path to the target build directory
# @param[in]    Absolute path to the target install directory
# @param[in]    Reference to a hash containing all the details of the target environment
sub compile_prrte ($$$$$$$)
{
	my ($prrte_src_dir, $prrte_build_dir, $prrte_install_dir, $libevent_install_dir, $hwloc_install_dir, $libpmix_install_dir, $env_ref) = @_;
	my $configure_args = "--with-libevent=$libevent_install_dir --with-hwloc=$hwloc_install_dir --with-pmix=$libpmix_install_dir";

	Utils::Compiler::prepare_build_dirs_generic ($prrte_src_dir, $prrte_build_dir, $prrte_install_dir);
	Utils::Compiler::compile_generic_with_env ($prrte_src_dir, $prrte_build_dir, $prrte_install_dir, $configure_args, $env_ref);
}

1;
