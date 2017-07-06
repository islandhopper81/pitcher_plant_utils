#!/usr/bin/evn Rscript

# NOTE: this template is incomplete!
# I still want to add the following things:
# 1) inline documentation
# 2) usage statement that prints inline docs

### Description
# I created a script called make_global_phylogram.R.  This scirpt can and should
# be used to create the global phylograms.  The tax parameter in this script is
# the tax RData object that is output from model_main.R.  So model_main.R should
# be ran prior to running make_global_phylogram.R.  Also, this script relies on
# several external R libraries (ie files with functions).  It must be ran from
# the folder containing those libraries.

### R Libraries
require("getopt", quietly=T)
source("tax_funcs.R")
source("phylogram_funcs.R")
source("rarefy_funcs.R")

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
  "table", "t", 1, "character",
  "tax", "x", 1, "character",
  "meta", "m", 1, "character",
  "rare", "r", 1, "double",
  "tax_level", "l", 1, "character",
  "type", "y", 1, "character",
  "out_file", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}


### Functions
main = function() {
	# read in the data -- table, metadata, taxonomy table
	data = read.table(opt$table, sep="\t", header=T, row.names=1, quote="")
	data[,ncol(data)] = NULL # remove taxonomy info
	meta = read.table(opt$meta, sep="\t", header=T, row.names=1)
#	tax = read.table(opt$tax, sep="\t", header=T, row.names=1, quote="")
	load(opt$tax)

	# order the samples
	meta = meta[colnames(data),]

	# remve sample P0
	meta = meta[! row.names(meta) %in% c("P0"),]
	data = data[,! colnames(data) %in% c("P0")]

	# rarefy to opt$rare
	rare = my_rare(tbl=data, rare=opt$rare)

	# aggregate by tax
	agg = aggregate_by_tax(rare, tax, opt$tax_level)

	# get the phylum colors
	phy_colors = get_phy_colors(agg)

	# make the phylogram
	my_phylogram(data = rare, tax=tax, level=opt$tax_level, meta=meta, phy_colors = phy_colors, 
					type = opt$type, out_file=opt$out_file)
}


# run the main function to execute the program
main()
