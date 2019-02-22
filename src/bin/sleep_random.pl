#!/usr/bin/perl
#

#
# Copyright(c)  2019    UT-Battelle, LLC
#                       All rights reserved
#

use strict;
use warnings "all";

my $sleep_time = int(rand(60*5)); # Up to 5 minutes sleep time

print "Sleeping for $sleep_time seconds...\n";

sleep ($sleep_time);
