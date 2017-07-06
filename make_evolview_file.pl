#!/usr/bin/env perl

# makes the EvolView annotation file

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Carp;
use Readonly;
use version; our $VERSION = qv('0.0.1');
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use UtilSY qw(:all);
use Table;

# Subroutines #
sub get_color_strip;
sub get_tax_colors;
sub get_kelly_colors;
sub check_params;
sub _is_defined;

# Variables #
my ($meta_file, $tax_file, $tax_level, $out, $help, $man);

my $options_okay = GetOptions (
    "meta|m:s" => \$meta_file,
    "tax|t:s" => \$tax_file,
	"tax_level|l:s" => \$tax_level,
	"out|o:s" => \$out,
    "help|h" => \$help,                  # flag
    "man" => \$man,                     # flag (print full man page)
);

# set up the logging environment
my $logger = get_logger();

# check for input errors
if ( $help ) { pod2usage(0) }
if ( $man ) { pod2usage(-verbose => 3) }
check_params();


########
# MAIN #
########

### open the output file
open my $OUT, ">", $out or 
	$logger->logdie("Cannot open --out $out\n");

### read in the meta data table
my $meta_tbl = Table->new();
$meta_tbl->load_from_file($meta_file);

### read in the taxonomy file
my $tax_tbl = Table->new();
$tax_tbl->load_from_file($tax_file);

### Color Strip section 
# this section puts shapes at the end of the nodes.
# here these shapes correspond to wither it is up in the yellow or
# in the hooded pitcher plants.  And there is another row indicating
# if the OTU has a match in the database.
my $color_strip = get_color_strip($meta_tbl);
print $OUT $color_strip;

### Group Label Section
# this section puts sections of the tree in a color based on taxnomy
my $group_label = get_group_label($tax_tbl, $tax_level);
print $OUT $group_label;



########
# Subs #
########
sub get_color_strip {
	my ($meta_tbl) = @_;
	
	$logger->info("Getting Color Strip Info");
	
	check_defined($meta_tbl, "meta_tbl");

	my $str =   "##color strips\n" . 
				"!title\tEnrichment\n" .
                "!groups\tYellow Enriched,Hooded Enriched,Sarracenia flava match,Sarracenia minor match, No match\n" .
                "!colors\tlightblue,red,darkblue,darkred,gray\n" .
                "!type\trect,rect\n" .
                "!showlegends\t1\n";
	
	foreach my $otu ( @{ $meta_tbl->get_row_names() } ) {
		$str .= $otu . 
				"\t" . 
				$meta_tbl->get_value_at($otu, "direction_col") .
				"," . 
				$meta_tbl->get_value_at($otu, "has_match_col") .
				"\n";
	}

	return($str);
}

sub get_group_label {
	my ($tax_tbl, $level) = @_;
	
	$logger->info("Getting Group Label Info");
	
	check_defined($tax_tbl, "tax_tbl");
	check_defined($level, "level");
	
	# get a list of colors for each taxa
	my $tax_cols_href = get_tax_colors($tax_tbl, $level);
	
	my $str =	"##group labels\n" .
				"!grouplabel\tstyle=3\n" .
				"!op	0.8\n";
	
	my $taxa;
	foreach my $otu ( @{ $tax_tbl->get_row_names() } ) {
		$taxa = $tax_tbl->get_value_at($otu, $level);
		$str .= $otu .
				"\t" .
				"bkcolor=" . $tax_cols_href->{$taxa} . "," .
				"text=" . $taxa . "\n";
	}
	
	return($str);
}

sub get_tax_colors {
	my ($tax_tbl, $level) = @_;
	
	check_defined($tax_tbl, "tax_tbl");
	check_defined($level, "level");
	
	my $taxa_aref = $tax_tbl->get_col($level);
	
	my %taxa_colors_hash = ();
	my $taxa_count = 0;
	
	foreach my $taxa ( @{$taxa_aref} ) {
		if ( ! defined $taxa_colors_hash{$taxa} ) {
			$taxa_colors_hash{$taxa} = 1;
			$taxa_count++;
			# note that right now I'm not assigning taxa.  I'm just getting a
			# list of taxa.  Colors will be assigned later.
		}
	}
	
	# get a list of colors
	my $colors_aref = get_kelly_colors($taxa_count);
	
	my $i = 0;
	foreach my $taxa ( keys %taxa_colors_hash ) {
		$taxa_colors_hash{$taxa} = $colors_aref->[$i];
		$i++;
	}
	
	return(\%taxa_colors_hash);
}

sub get_kelly_colors {
	my ($num) = @_;
	
	check_defined($num, "num");
	
	# the original set of Kelly Colors are 22 colors of maximum contrast
	# I got these hex codes from this website:
	# https://en.wikipedia.org/wiki/Help:Distinguishable_colors
	
	my $MAX = 24;
	
	if ( $num > $MAX ) {
		$logger->logdie("Too many colors (MAX = $MAX)");
	}
	
	# I omited a few colors:
	# white -- because that's my background color
	# Red (#FF0010) -- because it's already a color in the figure
	# Sky (#5EF1F2) -- because it's already a color in the figure
	
	my @kelly_cols = (
		"#F0A3FF",
		"#0075DC",
		"#993F00",
		"#4C005C",
		"#191919",
		"#005C31",
		"#2BCE48",
		"#FFCC99",
		"#808080",
		"#94FFB5",
		"#8F7C00",
		"#9DCC00",
		"#C20088",
		"#003380",
		"#FFA405",
		"#FFA8BB",
		"#426600",
		"#00998F",
		"#E0FF66",
		"#740AFF",
		"#990000",
		"#FFFF80",
		"#FFFF00",
		"#FF5005"
	);
	
	my @cols = splice @kelly_cols, 0, $num;
	
	return(\@cols);
}



sub check_params {
	# check for required variables
	if ( ! defined $meta_file) { 
		pod2usage(-message => "ERROR: required --meta not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $tax_file ) {
		pod2usage(-message => "ERROR: required --tax not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $out ) {
		pod2usage(-message => "ERROR: required --out not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $tax_level ) {
		pod2usage(-message => "ERROR: required --tax_level not defined\n\n",
					-exitval => 2);
	}

	# make sure required files are non-empty
	if ( defined $meta_file and ! -e $meta_file ) { 
		pod2usage(-message => "ERROR: --meta $meta_file is an empty file\n\n",
					-exitval => 2);
	}
	
	if ( defined $tax_file and ! -e $tax_file ) { 
		pod2usage(-message => "ERROR: --tax $tax_file is an empty file\n\n",
					-exitval => 2);
	}
	
	return 1;
}


__END__

# POD

=head1 NAME

make_evolview_file.pl - creates an EvolView annotation file


=head1 VERSION

This documentation refers to version 0.0.1


=head1 SYNOPSIS

    make_evolview_file.pl
        --meta metadata.txt
        --tax tax.txt
        --out evolview_ann.txt
        
        [--help]
        [--man]
        [--debug]
        [--verbose]
        [--quiet]
        [--logfile logfile.log]

    --meta | -m     Path to OTU metadata file
    --tax | -t      Path to OTU taxonomy table
    --out | -o      Path to output file
    --help | -h     Prints USAGE statement
    --man           Prints the man page
    --debug	        Prints Log4perl DEBUG+ messages
    --verbose       Prints Log4perl INFO+ messages
    --quiet	        Suppress printing ERROR+ Log4perl messages
    --logfile       File to save Log4perl messages


=head1 ARGUMENTS
    
=head2 --meta | -m

Path to significant OTU metadata file.  This file must be a tab delimited 
file where the first column is the OTU ID.  This file should have the following
header:

baseMean    log2FoldChange  lfcSE   stat    pvalue  padj    direction
direction_col   has_match   has_match_col   best_match
    
=head2 --tax | -t

Path to OTU taxonomy table.  This is a tab delimited file where the first
column is the OTU ID.  The remaining columns correspond to the following
headers:

Root    Kingom  Phylum  Class   Order   Family

=head2 --out | -o

Path to the output file   
 
=head2 [--help | -h]
    
An optional parameter to print a usage statement.

=head2 [--man]

An optional parameter to print he entire man page (i.e. all documentation)

=head2 [--debug]

Prints Log4perl DEBUG+ messages.  The plus here means it prints DEBUG
level and greater messages.

=head2 [--verbose]

Prints Log4perl INFO+ messages.  The plus here means it prints INFO level
and greater messages.

=head2 [--quiet]

Suppresses print ERROR+ Log4perl messages.  The plus here means it suppresses
ERROR level and greater messages that are automatically printed.

=head2 [--logfile]

File to save Log4perl messages.  Note that messages will also be printed to
STDERR.
    

=head1 DESCRIPTION

[FULL DESCRIPTION]

=head1 CONFIGURATION AND ENVIRONMENT
    
No special configurations or environment variables needed
    
    
=head1 DEPENDANCIES

version
Getopt::Long
Pod::Usage
Carp
Readonly
version
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
UtilSY qw(:all)

=head1 AUTHOR

Scott Yourstone     scott.yourstone81@gmail.com
    
    
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Scott Yourstone
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut
