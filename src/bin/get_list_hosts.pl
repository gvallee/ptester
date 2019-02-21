#!/usr/bin/perl
#

#
# Copyright(c)  2018-2019       UT-Battelle, LLC
#                               All rights reserved
#

# Script extracting the list of unique hostnames once LSF allocates 
# resources to the job. The list is extracted and formatted from
# a environment variable.
# The list of hosts is always stored in a 'DVM_HOSTS.txt' file.

use strict;
use warnings "all";

my $raw_hostfile = $ENV{'LSB_DJOB_HOSTFILE'};

open (my $input_fh, '<', $raw_hostfile) or die "ERROR: Cannot open $raw_hostfile";
my $ignore_file_line = <$input_fh>;
my @all_hosts = <$input_fh>;
close ($input_fh);

my @hosts;
my $host_size = -1;

# the first host is the local host and we do not care about it.
my $i;
for ($i = 1; $i < scalar (@all_hosts); $i = $i + 1)
{
	if (scalar (@hosts) == 0 || $hosts[$host_size] ne $all_hosts[$i])
	{
		push (@hosts, $all_hosts[$i]);
		$host_size = $host_size + 1;
	}
}

my $hostfile = "./DVM_HOSTS.txt";
open (my $fh, '>', $hostfile) or die "ERROR: Cannot opern $hostfile";
foreach my $host (@hosts)
{
	print $fh "$host";
}
close ($fh);
