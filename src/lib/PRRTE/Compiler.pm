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
# @param[in]    Reference to a hash containing all the information about the verbosity configuration specific to this run.
# @parma[in]    Absolute path to the package (tarball) to unpacked
# @parma[in]    Destination directory where to unpack the package
# @return       Absolute path to the source code, i.e., the destination directory in addition of the directory from the software package.
sub unpack_software ($$$)
{
	my ($verboseCfg, $src_tarball, $dest_dir) = @_;

	return undef if (!defined ($dest_dir) || !defined ($src_tarball));

	require "Utils/Exec.pm";
	my $cmd = "cd $dest_dir; cp $src_tarball .";
	Utils::Exec::run_or_die ($verboseCfg, $cmd);

	my $tarball_filename = File::Basename::basename ($src_tarball);
	$cmd = "cd $dest_dir; tar xzf $tarball_filename";
	Utils::Exec::run_or_die ($verboseCfg, $cmd);

	$cmd = "cd $dest_dir; rm -rf $tarball_filename";
	Utils::Exec::run_or_die ($verboseCfg, $cmd);
	
	my $src_dir = substr ($tarball_filename, 0, index ($tarball_filename, ".tar.gz"));

	return $src_dir;
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
	my $m4_tarball = $config{'m4_tarball'};
	my $autoconf_tarball = $config{'autoconf_tarball'};
	my $automake_tarball = $config{'automake_tarball'};
	my $libtool_tarball = $config{'libtool_tarball'};
	my $configure_args = $config{'configure_args'};
	my %env;

	# Some sanity checks
	die "ERROR: undefined install directory" if (!defined ($install_dir));
	die "ERROR: undefined scratch directory" if (!defined ($scratchdir));

	# Update the environment to make sure we use the autotools and others as we compile them
	require "Utils/Env.pm";
	%env = Utils::Env::env_add (\%env, "PATH", "$install_dir/bin");
	%env = Utils::Env::env_add (\%env, "LD_LIBRARY_PATH", "$install_dir/lib");

	require "Utils/Compiler.pm";
	require "Utils/Exec.pm";

	if (defined $m4_tarball)
	{
		my $m4_src_dir = unpack_software ($verboseCfg, $m4_tarball, $scratchdir);
		die "ERROR: Cannot unpack m4 from $m4_tarball" if (!defined ($m4_src_dir));
		$m4_src_dir = "$scratchdir/$m4_src_dir";
		Utils::Compiler::compile_generic_with_env ($verboseCfg, $m4_src_dir, $m4_src_dir, $install_dir, undef, \%env);
	}

	if (defined $autoconf_tarball)
	{
		my $autoconf_src_dir = unpack_software ($verboseCfg, $autoconf_tarball, $scratchdir);
		die "ERROR: Cannot unpack autoconf from $autoconf_tarball" if (!defined ($autoconf_src_dir));
		$autoconf_src_dir = "$scratchdir/$autoconf_src_dir";
		Utils::Compiler::compile_generic_with_env ($verboseCfg, $autoconf_src_dir, $autoconf_src_dir, $install_dir, undef, \%env);
	}

	if (defined $automake_tarball)
	{
		my $automake_src_dir = unpack_software ($verboseCfg, $automake_tarball, $scratchdir);
		die "ERROR: Cannot unpack autoconf from $automake_tarball" if (!defined ($automake_src_dir));
		$automake_src_dir = "$scratchdir/$automake_src_dir";
		Utils::Compiler::compile_generic_with_env ($verboseCfg, $automake_src_dir, $automake_src_dir, $install_dir, undef, \%env);
	}

	if (defined $libtool_tarball)
	{
		my $libtool_src_dir = unpack_software ($verboseCfg, $libtool_tarball, $scratchdir);
		die "ERROR: Cannot unpack libtool from $libtool_src_dir" if (!defined ($libtool_src_dir));
		$libtool_src_dir = "$scratchdir/$libtool_src_dir";
		Utils::Compiler::compile_generic_with_env ($verboseCfg, $libtool_src_dir, $libtool_src_dir, $install_dir, undef, \%env);
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

	die "ERROR: Undefined configuration" if (!defined ($config_ref));

	my %config = %$config_ref;
	
	my $env_ref = install_autotools ($verboseCfg, $config_ref);
	
	my $install_dir = $config{'install_dir'};
        my $scratchdir = $config{'scratch_dir'};
	my $software_tarball = $config{'tarball'};
	my $configure_args = $config{'configure_args'};
	my $src_dir = $config{'src_dir'};
        my %env;
	%env = %$env_ref if (defined ($env_ref));

	die "ERROR: Undefined scratch dir" if (!defined $scratchdir);

	if (defined ($software_tarball))
	{
		# We work from a tarball, not a directory with sources (git clone for example)
		$src_dir = unpack_software ($verboseCfg, $software_tarball, $scratchdir);
		die "ERROR: Cannot unpack software from $software_tarball to $scratchdir" if (!defined ($src_dir));
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
		Utils::Exec::run_or_die ($verboseCfg, $cmd);
		$src_dir = $target_src_dir;
	}
	my $target_build_dir = "$scratchdir/build";
	mkdir ($target_build_dir) if (! -e $target_build_dir);
	require "Utils/Compiler.pm";
	Utils::Compiler::compile_generic_with_env ($verboseCfg, $src_dir, $target_build_dir, $install_dir, $configure_args, \%env);
}

# High-level function to compile libevent
sub compile_libevent ($$)
{
	my ($verboseCfg, $globalConfigRef) = @_;

	return if (!defined ($globalConfigRef));
	my %globalConfig = %$globalConfigRef;

	# Some sanity checks
	die "ERROR: libevent install dir not defined" if (!defined ($globalConfig{'libevent_install_dir'}));
	die "ERROR: libevent scratch dir not defined" if (!defined ($globalConfig{'libevent_scratch_dir'}));

	# Create a configuration specific to libevent
	my %config;
	$config{'install_dir'} = $globalConfig{'libevent_install_dir'};
	$config{'scratch_dir'} = $globalConfig{'libevent_scratch_dir'};
	$config{'tarball'} = $globalConfig{'libevent_tarball'};
	$config{'configure_args'} = undef;
	$config{'m4_tarball'} = $globalConfig{'m4_tarball'};
	$config{'autoconf_tarball'} = $globalConfig{'autoconf_tarball'};
	$config{'automake_tarball'} = $globalConfig{'automake_tarball'};
	$config{'libtools_tarball'} = $globalConfig{'libtools_tarball'};
	$config{'topdir'} = $globalConfig{'topdir'};

	# Some sanity checks
	die "ERROR: Undefined install dir" if (!exists ($config{'install_dir'}) || !defined ($config{'install_dir'}));
	die "ERROR: Undefined scratch dir" if (!exists ($config{'scratch_dir'}) || !defined ($config{'scratch_dir'}));

	require "Utils/Compiler.pm";
	Utils::Compiler::prepare_build_dirs_generic ($verboseCfg, $globalConfig{'libevent_src_dir'}, $globalConfig{'libevent_build_dir'}, $globalConfig{'libevent_install_dir'});
	autotools_software_install ($verboseCfg, \%config);
}

# High-level function to compile hwloc
sub compile_hwloc ($$)
{
	my ($verboseCfg, $globalConfigRef) = @_;

	return if (!defined ($globalConfigRef));
	my %globalConfig = %$globalConfigRef;

	# Some sanity checks
	die "ERROR: hwloc install dir not defined" if (!defined ($globalConfig{'hwloc_install_dir'}));
	die "ERROR: hwloc scratch dir not defined" if (!defined ($globalConfig{'hwloc_scratch_dir'}));

	my %config;
	$config{'install_dir'} = $globalConfig{'hwloc_install_dir'};
	$config{'scratch_dir'} = $globalConfig{'hwloc_scratch_dir'};
	$config{'tarball'} = $globalConfig{'hwloc_tarball'};
	$config{'configure_args'} = undef;
	$config{'m4_tarball'} = $globalConfig{'m4_tarball'};
	$config{'autoconf_tarball'} = $globalConfig{'autoconf_tarball'};
	$config{'automake_tarball'} = $globalConfig{'automake_tarball'};
	$config{'libtools_tarball'} = $globalConfig{'libtools_tarball'};
	$config{'topdir'} = $globalConfig{'topdir'};

	require "Utils/Compiler.pm";
	Utils::Compiler::prepare_build_dirs_generic ($verboseCfg, $globalConfig{'hwloc_src_dir'}, $globalConfig{'hwloc_build_dir'}, $globalConfig{'hwloc_install_dir'});
	autotools_software_install ($verboseCfg, \%config);
}

# High-level function to compile libevent
sub compile_libpmix ($$)
{
	my ($verboseCfg, $globalConfigRef) = @_;

	return if (!defined ($globalConfigRef));
	my %globalConfig = %$globalConfigRef;

	# Some sanity checks
	die "ERROR: libpmix install dir not defined" if (!defined ($globalConfig{'libpmix_install_dir'}));
	die "ERROR: libpmix scratch dir not defined" if (!defined ($globalConfig{'libpmix_scratch_dir'}));
	die "ERROR: libevent install dir not definted" if (!defined ($globalConfig{'libevent_install_dir'}));

	my %config;
	$config{'install_dir'} = $globalConfig{'libpmix_install_dir'};
	$config{'scratch_dir'} = $globalConfig{'libpmix_scratch_dir'};
	$config{'tarball'} = undef;
	$config{'src_dir'} = $globalConfig{'pmix_dir'};
	my $configure_args = "--with-libevent=$globalConfig{'libevent_install_dir'}";
	$config{'configure_args'} = $configure_args;
	$config{'m4_tarball'} = $globalConfig{'m4_tarball'};
	$config{'autoconf_tarball'} = $globalConfig{'autoconf_tarball'};
	$config{'automake_tarball'} = $globalConfig{'automake_tarball'};
	$config{'libtools_tarball'} = $globalConfig{'libtools_tarball'};
	$config{'topdir'} = $globalConfig{'topdir'};

	require "Utils/Compiler.pm";
	Utils::Compiler::prepare_build_dirs_generic ($verboseCfg, $globalConfig{'libpmix_src_dir'}, $globalConfig{'libpmix_build_dir'}, $globalConfig{'libpmix_install_dir'});
	autotools_software_install ($verboseCfg, \%config);
}

# High-level function to compile PRRTE
sub compile_prrte ($$)
{
	my ($verboseCfg, $globalConfigRef) = @_;

	return if (!defined ($globalConfigRef));
	my %globalConfig = %$globalConfigRef;

	# Some sanity checks
	die "ERROR: prrte install dir not defined" if (!defined ($globalConfig{'prrte_install_dir'}));
	die "ERROR: prrte scratch dir not defined" if (!defined ($globalConfig{'prrte_scratch_dir'}));

	my %config;
	$config{'install_dir'} = $globalConfig{'prrte_install_dir'};
	$config{'scratch_dir'} = $globalConfig{'prrte_scratch_dir'};
	$config{'tarball'} = undef;
	$config{'src_dir'} = $globalConfig{'prrte_dir'};
	my $configure_args = "--with-libevent=$globalConfig{'libevent_install_dir'} --with-hwloc=$globalConfig{'hwloc_install_dir'} --with-pmix=$globalConfig{'libpmix_install_dir'}";
	$config{'configure_args'} = $configure_args;
	$config{'m4_tarball'} = $globalConfig{'m4_tarball'};
	$config{'autoconf_tarball'} = $globalConfig{'autoconf_tarball'};
	$config{'automake_tarball'} = $globalConfig{'automake_tarball'};
	$config{'libtools_tarball'} = $globalConfig{'libtools_tarball'};
	$config{'topdir'} = $globalConfig{'topdir'};

	require "Utils/Compiler.pm";
	Utils::Compiler::prepare_build_dirs_generic ($verboseCfg, $globalConfig{'prrte_src_dir'}, $globalConfig{'prrte_build_dir'}, $globalConfig{'prrte_install_dir'});
	autotools_software_install ($verboseCfg, \%config);
}

1;
