#!/usr/bin/evn Rscript

### Description
# Make a heatmap of counts to show that samples 
# are extremely different

### R Libraries
require("getopt", quietly=T)
require("GMD")

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
  "tbl", "t", 1, "character",
  "meta", "m", 1, "character",
  "rdata", "r", 1, "character",
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
	#load the rData object
	load(opt$rdata)

	# create the col

	png(opt$out)
	heatmap.3(log10(dat$Tab+1),
		labRow=F, xlab="Samples", ylab="OTUs",
		ColSideColors=dat$Map$Plant_species)
	dev.off()
}

# run the main function to execute the program
main()
