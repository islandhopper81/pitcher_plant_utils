#!/usr/bin/env perl

# create the metadata file for the significant OTUs in the pitcher plant analysis

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
sub check_params;
sub _is_defined;

# Variables #
my ($sig_tbl, $db_tbl, $out, $help, $man);

my $options_okay = GetOptions (
    "sig_tbl:s" => \$sig_tbl,
    "db_tbl:s" => \$db_tbl,
	"out:s" => \$out,
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
# read in the sig table
my $SIG = Table->new();
$SIG->load_from_file($sig_tbl);

# add a column to the table for the boolean up or down value
my @direction = ();
my @direction_col = ();
foreach my $otu ( @{$SIG->get_row_names()} ) {
	if ( $SIG->get_value_at($otu, "log2FoldChange") > 0 ) {
		push @direction, "up";
		push @direction_col, "lightblue";
	}
	else {
		push @direction, "dn";
		push @direction_col, "red";
	}
}
$SIG->add_col("direction", \@direction);
$SIG->add_col("direction_col", \@direction_col);

####
# add the info about if these OTUs match something in the database.
# this consists of two columns:
# 1. which isolate is the best match (NA when there is no match)
# 2. boolean of if there is a match

# read in the blast match table
my $BLS = Table->new();
$BLS->load_from_file($db_tbl);

my @has_match = ();
my @has_match_col = ();
my @best_match = ();
foreach my $otu ( @{$SIG->get_row_names()} ) {
	if ( $BLS->has_row($otu) ) {
		my $best_match = $BLS->get_value_at($otu, "best_match");

		if ( $best_match =~ m/y/i ) {
			push @has_match, "Y";
			push @has_match_col, "darkblue";
		}
		elsif ( $best_match =~ m/h/i ) {
			push @has_match, "H";
			push @has_match_col, "darkred";
		}
		else {
			$logger->warn("Match cannot be recognized as either yellow or hooded: $best_match");
		}
		
		# record the actual best match ID
		push @best_match, $best_match;
	}
	else {
		push @has_match, "F";
		push @has_match_col, "gray";
		push @best_match, "NA";
	}
}
$SIG->add_col("has_match", \@has_match);
$SIG->add_col("has_match_col", \@has_match_col);
$SIG->add_col("best_match", \@best_match);

# now save the final table
$SIG->save($out, "\t");


########
# Subs #
########
sub check_params {
	# check for required variables
	if ( ! defined $sig_tbl) { 
		pod2usage(-message => "ERROR: required --sig_tbl not defined\n\n",
					-exitval => 2); 
	}
	if ( ! defined $db_tbl ) {
		pod2usage(-message => "ERROR: required --db_tbl not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $out ) {
		pod2usage(-message => "ERROR: required --out not defined\n\n",
					-exitval => 2);
	}


	# make sure required files are non-empty
	if ( defined $sig_tbl and ! -e $sig_tbl ) { 
		pod2usage(-message => "ERROR: --sig_tbl $sig_tbl is an empty file\n\n",
					-exitval => 2);
	}
	if ( defined $db_tbl and ! -e $db_tbl ) { 
		pod2usage(-message => "ERROR: --db_tbl $db_tbl is an empty file\n\n",
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
