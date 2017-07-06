#!/usr/bin/env Rscript

### Description
# make a boxplot figures for a single OTU.  use this script when you
# want to make boxplot figures for the top OTUs that have matches
# in the culture database.

### R Libraries
require("getopt", quietly=T)
require("ggplot2", quietly=T)

source("otu_boxplot.R")

### Defualt variables
verbose = FALSE

### Parameter variables
# The params matrix
# Each row is a parameter with 4 columns: 
#   1) long value, 
#   2) short value, 
#   3) argument type where 0 = no argument, 1 = required , 2 = optional
#   4) data type (logical, integer, double, complex, character)
# When you call this script the args are named like --verbose or -v
params = matrix(c(
  "dds_file", "d", 1, "character",
  "otu_id", "i", 1, "character",
  "tax_file", "x", 1, "character",
  "out", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}


### Functions
main = function() {
	load(opt$dds_file)
	load(opt$tax_file)
	otu_boxplot(dds, opt$otu_id, tax, file = opt$out)
}

# run the main function to execute the program
main()
