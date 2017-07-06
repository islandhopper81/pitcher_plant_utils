#!/usr/bin/env perl

# this script gets the best match for each query in a bls output file
# the best match is just the first line for that query.

use strict;
use warnings;

my $usage = "$0 <in bls> <out bls>\n";
my $in = shift or die $usage;
my $out = shift or die $usage;

# open the input bls file
open my $IN, "<", $in or die $!;

# open the output bls file
open my $OUT, ">", $out or die $!;

# parse the in file to find the best match
my %found = ();
my @vals = ();
foreach my $line ( <$IN> ) {
	chomp $line;

	@vals = split(/\t/, $line);

	if ( defined $found{$vals[0]} ) {
		next;
	}
	else {
		print $OUT $line, "\n";
		$found{$vals[0]} = 1;
	}
}
