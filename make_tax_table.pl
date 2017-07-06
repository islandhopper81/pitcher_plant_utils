#!/usr/bin/evn perl

use strict;
use warnings;

my $usage = "$0 <otu_tbl> <out>\n";

my $otu_tbl = shift or die $usage;
my $out = shift or die $usage;

open my $IN, "<", $otu_tbl or die $!;
open my $OUT, ">", $out or die $!;

# create the headers in the output file
my @headers = ("OTU_ID", "Root", "Kingom", "Phylum", "Class", "Order", "Family");
print $OUT (join("\t", @headers), "\n");

my $first = 1;
foreach my $line ( <$IN> ) {
	chomp $line;

	# skip comment lines
	if ( $line =~ m/^#/ ) {next;}

	# skip the header line
	if ( $first == 1 ) {$first = 0; next;}

	# disregard the OTU counts
	my @vals = split(/\t/, $line);
	$line = join("\t", $vals[0], $vals[scalar(@vals) - 1]);

	@vals = split(/; /, $line);

	for ( my $i = 0; $i < scalar @vals; $i++ ) {
		$vals[$i] = remove_suffix($vals[$i]);
	}

	# make sure all the values are filled
	# if they are not call them unclassified
	my $na = "unclassified";
	my $count = scalar @vals;
	my $tot_vals = 6; # there are 7 total values including the OTU id
	if ( $count != $tot_vals ) {
		my $len = $tot_vals - $count;
		my @nas = ();

		for ( my $j = 0; $j < $len; $j++ ) {
			push @nas, $na;
		}

		@vals = (@vals, @nas);
	}
	

	print $OUT (join("\t", @vals), "\n");
}

sub remove_suffix {
	my ($val) = @_;

	my $new = $val;
	if ( $val =~ m/\w__(.*)/ ) {
		$new = $1;
	}

	if ( length($new) == 0 ) {
		$new = "unclassified";
	}

	return($new);
}
