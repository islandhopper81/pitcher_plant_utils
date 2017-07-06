#!/usr/bin/evn perl 

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

my $usage = "$0 <tbl> <out file> <min reads> <min samples>\n";
my $tbl_file = shift or die $usage;
my $out_file = shift or die $usage;
my $min_reads = shift or die $usage;
my $min_samples = shift or die $usage;

# read the table, filter and output
open my $IN, "<", $tbl_file or die $!;
open my $OUT, ">", $out_file or die $!;

my @vals = ();
foreach my $line ( <$IN> ) {
	chomp $line;

	if ( $line =~ m/^#/ or $line =~ m/OTU_ID/ ) {
		print $OUT $line, "\n";
		next;
	}
	
	@vals = split(/\t/, $line);

	# count the number of samples in this OTU that have
	# greater than min_reads
	my $pass = 0;
	foreach my $v ( @vals ) {
		if ( ! looks_like_number($v) ) { next; }
		if ( $v >= $min_reads ) {
			$pass++;
		}
	}

	if ( $pass >= $min_samples ) {
		print $OUT $line, "\n";
	}
}


