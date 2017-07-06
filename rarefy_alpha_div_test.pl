#!/usr/bin/env perl

# rarefies many times and then calculates alpha diversity
# for each iteration

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
use File::Temp qw(tempfile);
use Data::Dumper;

# Subroutines #
sub check_params;
sub _is_defined;

# Variables #
my ($tbl_file, $iters_file, $out_dir, $rare_exe, $tree_file, $rep_count, $help, $man);

my $options_okay = GetOptions (
    "tbl_file:s" => \$tbl_file,
    "iters_file:s" => \$iters_file,
	"out_dir:s" => \$out_dir,
	"rare_exe:s" => \$rare_exe,
	"tree_file:s" => \$tree_file,
	"rep_count:i" => \$rep_count,
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
# read in the iters_file
$logger->info("Reading iters file");
open my $IT, "<", $iters_file or
	$logger->logdie("Cannot open iters_file: $iters_file");

my @iters = ();
foreach my $line ( <$IT> ) {
	chomp $line;
	push @iters, $line;
}

close($IT);

# make an output dir foreach iter
$logger->info("Making output dirs");
foreach my $iter ( @iters ) {
	if ( ! -d "$out_dir/$iter" ) {
		system("mkdir $out_dir/$iter");
	}
}

# to the rarefaction for each iter
$logger->info("Rarefaction");
my $cmd;
foreach my $iter ( @iters ) {
	for ( my $i = 1; $i <= $rep_count; $i++ ) {
		$cmd = "Rscript $rare_exe --tbl $tbl_file --rare $iter --out $out_dir/$iter/rare_rep$i.txt";
		$logger->debug("Running: $cmd");
		system($cmd);
	}
}

# reformat the headers
$logger->info("Reformat headers");
foreach my $iter ( @iters ) {
	for ( my $i = 1; $i <= $rep_count; $i++ ) {
		my $in = "$out_dir/$iter/rare_rep$i.txt";
		open my $IN, "<", $in or
			$logger->logdie("Cannot open rare file: $in");

		my ($fh, $filename) = tempfile();
	
		my $is_first = 1;
		foreach my $line ( <$IN> ) {
			if ( $is_first == 1 ) {
				print $fh "OTU_ID\t", $line;
				$is_first = 0;
			}
			else {
				print $fh $line;
			}
		}

		close($IN);

		system("mv $filename $in");
	}
}

# convert the iter files to biom format
$logger->info("Convert to biom format");
my $in_file;
my $out_file;
foreach my $iter ( @iters ) {
	for ( my $i = 1; $i <= $rep_count; $i++ ) {
		$in_file = "$out_dir/$iter/rare_rep$i.txt";
		$out_file = "$out_dir/$iter/rare_rep$i.biom";

		if ( -e $out_file ) {
			system("rm $out_file");
		}

		$cmd = "biom convert -i $in_file -o $out_file --table-type=\"OTU table\" --to-hdf5";
		$logger->debug("Running: $cmd");
		system($cmd);
	}
}

# get the alpha diversity for each iter
$logger->info("Calc alpha diversity");
foreach my $iter ( @iters ) {
	for ( my $i = 1; $i <= $rep_count; $i++ ) {
		$in_file = "$out_dir/$iter/rare_rep$i.biom";
		$out_file = "$out_dir/$iter/alpha_div_rep$i.txt";
	
		$cmd = "alpha_diversity.py -i $in_file -o $out_file -m PD_whole_tree,chao1,shannon,simpson -t $tree_file";
		$logger->debug("Running: $cmd");
		system($cmd);
	}
}

# combine results into single table
$logger->info("Combining results");
my $final_tbl = "rarefy_alpha_div_test.txt";
open my $OUT, ">", $final_tbl or
	$logger->logdie("Cannot open file $final_tbl for writing");
print $OUT "sample\tmetric\trare_level\trep\tvalue\n";
my @vals = ();
foreach my $iter ( @iters ) {
	for ( my $i = 1; $i <= $rep_count; $i++ ) {
		$in_file = "$out_dir/$iter/alpha_div_rep$i.txt";
		open my $IN, "<", $in_file or
			$logger->logdie("Cannot open alpha_div file $in_file for reading");

		# skip the header
		my $header = <$IN>;
		chomp $header;
		my @header_vals = split(/\t/, $header);
		shift @header_vals;

		foreach my $line ( <$IN> ) {
			chomp $line;
			@vals = split(/\t/, $line);

			my $j = 1;
			foreach my $h ( @header_vals ) {
				print $OUT $vals[0], "\t", $h, "\t", $iter, "\t", $i, "\t", $vals[$j], "\n";
				$j++;
			}
		}
	}
}

$logger->info("FINISHED");


########
# Subs #
########
sub check_params {
	# check for required variables
	if ( ! defined $tbl_file) { 
		pod2usage(-message => "ERROR: required --tbl_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $iters_file ) {
		pod2usage(-message => "ERROR: required --iters_file not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $out_dir) {
		pod2usage(-message => "ERROR: required --out_dir not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $rare_exe) {
		pod2usage(-message => "ERROR: required --rare_exe not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $tree_file) {
		pod2usage(-message => "ERROR: required --tree_file not defined\n\n",
					-exitval => 2);
	}
	

	# make sure required files are non-empty
	if ( defined $tbl_file and ! -e $tbl_file ) { 
		pod2usage(-message => "ERROR: --tbl_file $tbl_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $iters_file and ! -e $iters_file ) {
		pod2usage(-message => "ERROR: --iters_file $iters_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $tree_file and ! -e $tree_file ) {
		pod2usage(-message => "ERROR: --tree_file $tree_file is an empty file\n\n",
					-exitval => 2);
	}

	# make sure required directories exist
	if ( ! -d $out_dir ) { 
		pod2usage(-message => "ERROR: --out_dir is not a directory\n\n",
					-exitval => 2); 
	}
	
	return 1;
}


__END__

# POD

=head1 NAME

[NAME].pl - [DESCRIPTION]


=head1 VERSION

This documentation refers to version 0.0.1


=head1 SYNOPSIS

    [NAME].pl
        -f my_file.txt
        -v 10
        
        [--help]
        [--man]
        [--debug]
        [--verbose]
        [--quiet]
        [--logfile logfile.log]

    --file | -f     Path to an input file
    --var | -v      Path to an input variable
    --help | -h     Prints USAGE statement
    --man           Prints the man page
    --debug	        Prints Log4perl DEBUG+ messages
    --verbose       Prints Log4perl INFO+ messages
    --quiet	        Suppress printing ERROR+ Log4perl messages
    --logfile       File to save Log4perl messages


=head1 ARGUMENTS
    
=head2 --file | -f

Path to an input file
    
=head2 --var | -v

Path to an input variable   
 
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
