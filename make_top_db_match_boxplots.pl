#!/usr/bin/env perl

# Create the boxplots for the OTUs that are the best matches to the 
# culture database.

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
use File::Temp qw(tempfile);

# Subroutines #
sub check_params;
sub _is_defined;

# Variables #
my ($up_file, $dn_file, $out_prefix, $tax_file, $dds_file, $bls_file, $count, $help, $man);

my $options_okay = GetOptions (
    "up_file|u:s" => \$up_file,
    "dn_file|d:s" => \$dn_file,
	"out_prefix|o:s" => \$out_prefix,
	"tax_file|t:s" => \$tax_file,
	"dds_file|s:s" => \$dds_file,
	"bls_file|b:s" => \$bls_file,
	"count|c:s" => \$count,
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
# read in the bls file
open my $BLS, "<", $bls_file or 
	$logger->logdie("Cannot open --bls_file ($bls_file)");

my %best_match_hash = ();
my @vals = ();
foreach my $line ( <$BLS> ) {
	chomp $line;

	@vals = split(/\t/, $line);
	$best_match_hash{$vals[0]} = $vals[1];
}

close($BLS);

close($BLS);


# sort the up and dn tables using the unix sort command.
# eventually I want to add a sort feature to the Table object
my ($up_fh, $tmp_up_file) = tempfile();
close($up_fh);
print "tmp up file: $tmp_up_file\n";
my ($dn_fh, $tmp_dn_file) = tempfile();
close($dn_fh);
my $up_cmd = "sort -n -k7 $up_file > $tmp_up_file";
my $dn_cmd = "sort -n -k7 $dn_file > $tmp_dn_file";
system($up_cmd);
system($dn_cmd);

# read in the up file
my $up_tbl = Table->new();
$up_tbl->load_from_file($tmp_up_file);

# read in the dn file
my $dn_tbl = Table->new();
$dn_tbl->load_from_file($tmp_dn_file);

# get the top $count up
my $up_row_names_aref = $up_tbl->get_row_names();
my @top_up = splice(@{$up_row_names_aref}, 0, $count);
print "Top OTUs:\n";
foreach my $otu ( @top_up) {
	print "$otu\n";
}

my $found = 0;
my @top_up_match = ();
print "Top Matching OTUs:\n";
foreach my $otu ( @{$up_row_names_aref} ) {
	if ( $found >= $count ) { last; }

	if ( $best_match_hash{$otu} ) {
		print "$otu\n";
		push @top_up_match, $otu;
		$found++;
	}
}

# get the top $count that are dn
my $dn_row_names_aref = $dn_tbl->get_row_names();
my @top_dn = splice(@{$dn_row_names_aref}, 0, $count);
print "Top dn OTUs\n";
foreach my $otu ( @top_dn) {
	print $otu . "\n";
}

$found = 0;
my @top_dn_match = ();
print "Top dn Matching OTUs\n";
foreach my $otu ( @{$dn_row_names_aref} ) {
	if ( $found >= $count ) { last; }
	
	if ( $best_match_hash{$otu} ) {
		print "$otu\n";
		push @top_dn_match, $otu;
		$found++;
	}
}

my $cmd;
foreach my $otu ( @top_up_match ) {
	$cmd = "Rscript make_otu_boxplot.R --dds_file $dds_file --otu_id $otu --tax_file $tax_file --out $out_prefix\_$otu\_ym.pdf";
	print $cmd . "\n";
	system($cmd);
}

foreach my $otu ( @top_dn_match ) {
	$cmd = "Rscript make_otu_boxplot.R --dds_file $dds_file --otu_id $otu --tax_file $tax_file --out $out_prefix\_$otu\_hm.pdf";
	print $cmd . "\n";
	system($cmd);
}

########
# Subs #
########
sub check_params {
	# check for required variables
	if ( ! defined $up_file) { 
		pod2usage(-message => "ERROR: required --up_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $dn_file ) {
		pod2usage(-message => "ERROR: required --dn_file not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $tax_file) { 
		pod2usage(-message => "ERROR: required --tax_file not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $dds_file ) {
		pod2usage(-message => "ERROR: required --dds_file not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $bls_file ) {
		pod2usage(-message => "ERROR: required --bls_file not defined\n\n",
					-exitval => 2);
	}
	

	# make sure required files are non-empty
	if ( defined $up_file and ! -e $up_file ) { 
		pod2usage(-message => "ERROR: --up_file $up_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $dn_file and ! -e $dn_file ) { 
		pod2usage(-message => "ERROR: --dn_file $dn_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $tax_file and ! -e $tax_file ) { 
		pod2usage(-message => "ERROR: --tax_file $tax_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $dds_file and ! -e $dds_file ) { 
		pod2usage(-message => "ERROR: --dds_file $dds_file is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $bls_file and ! -e $bls_file ) { 
		pod2usage(-message => "ERROR: --bls_file $bls_file is an empty file\n\n",
					-exitval => 2);
	}

	return 1;
}


__END__

# POD

=head1 NAME

[NAME].pl - makes the OTU boxplots for the most significant OTUs that match in the database

my ($up_file, $dn_file, $out_prefix, $tax_file, $dds_file, $count, $help, $man);

=head1 VERSION

This documentation refers to version 0.0.1


=head1 SYNOPSIS

    [NAME].pl
        --up_file sig_up.txt
        --dn_file sig_dn.txt
        --tax_file tax.RData
        --dds_file dds.RData
        --bls_file bls.txt
        --count 5
        --out_prefix out_dir/out
        
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
