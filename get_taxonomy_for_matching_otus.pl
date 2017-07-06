#!/usr/bin/env perl

use strict;
use warnings;

sub get_tax_str;

my $usage = "$0 <otu_table> <bls file> <out file>\n";

my $otu_tbl = shift or die $usage;
my $bls_file = shift or die $usage;
my $out_file = shift or die $usage;

# read in the otu table; store the OTU id and the taxonomy string
my %tax_hash = ();
open my $OTU, "<", $otu_tbl or die $!;

# skip the header line
my $header = <$OTU>;

my @vals = ();
my $is_header = 1;
foreach my $line ( <$OTU> ) {
	chomp $line;

	# skip comment lines
	if ( $line =~ m/^#/ ) {next;}

	# skip header line
	if ( $is_header ) {
		$is_header = 0;
		next;
	}
	
	@vals = split(/\t/, $line);
	
	my $id = $vals[0];
	my $tax = $vals[scalar(@vals) - 1];

	#print "id: $id\n";
	#print "tax: $tax\n";

	$tax_hash{$id} = $tax;
}

# read in the blast file
open my $BLS, "<", $bls_file or die $!;

open my $OUT, ">", $out_file or die $!;

# for everything in the bls file find and output the taxonomy info
foreach my $line ( <$BLS> ) {
	chomp $line;
	
	@vals = split(/\t/, $line);

	if ( $tax_hash{$vals[0]} ) {
		my $tax_str = get_tax_str($tax_hash{$vals[0]});
		print $OUT $vals[0], "\t", $tax_str, "\n", 
	}
	else {
		my $warning = $vals[0] . " not found in tax hash";
		warn $warning;
	}
}

sub get_tax_str {
	my ($full_str) = @_;

	my @vals = split(/; /, $full_str);

	my $i = 0;
	foreach my $v ( @vals ) {
		if ( $v =~ m/\w__(\w+)/ ) {
			$vals[$i] = $1;
		}
		$i++;
	}

	my $str = join("\t", @vals);
	#print $str, "\n";

	return($str);
}
