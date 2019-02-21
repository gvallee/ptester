#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved
#

package Utils::Env;

use Exporter qw(import);

our @EXPORT_OK = qw(
			env_add
                   );

sub env_add ($$$)
{
	my ($ref, $env_var, $new_value) = @_;

	die "ERROR: no value defined" if (!defined ($new_value));
	die "ERROR: no env var defined" if (!defined ($env_var));
	die "ERROR: no env hash" if (!defined ($ref));
	my %_env = %$ref;

	if (exists $_env{$env_var})
	{
		if (index ($_env{env_var}, $new_value) == -1)
		{
			$_env{$env_var} = "$new_value:$_env{$env_var}"
		}
	}
	else
	{
		$_env{$env_var} = "$new_value:$ENV{$env_var}";
	}

	return %_env;
}
