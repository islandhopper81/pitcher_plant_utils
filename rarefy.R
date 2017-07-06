#!/usr/bin/evn Rscript

library(AMOR)
require("getopt", quietly=T)

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
  "tbl", "t", 1, "character",
  "rare", "r", 1, "integer",
  "out", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}


count_file = opt$tbl
counts = read.table(count_file, sep="\t", header=T, row.names=1)
counts = counts[,1:17]
counts = as.matrix(counts)

my_rare(tbl=counts, rare=opt$rare, out_file = opt$out)


# moved this code to rarefy_funcs.R
# remove the samples that have fewer than opt$rare
#tot = apply(counts, 2, sum)
#to_keep = tot > opt$rare
#counts = counts[,to_keep]

#rare = rarefaction(x=counts, sample=opt$rare)

#write.table(rare, file=opt$out, quote=F, row.names=T, col.names=T, sep="\t")

