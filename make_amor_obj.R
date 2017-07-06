#!/usr/bin/evn Rscript

library(AMOR)
require("getopt", quietly=T)

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
  "out", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}


# read in the table
tbl = read.table(opt$tbl, header=T, sep="\t")
row.names(tbl) = tbl$OTU_ID
tbl$OTU_ID = NULL

# get the taxonomy info
tax = data.frame(ID=row.names(tbl), Taxonomy=tbl$taxonomy)
row.names(tax) = tax$ID
tbl$taxonomy = NULL

# read in the metadata
metadata = read.table(opt$meta, header=T, row.names=1)

# get only the samples in the tbl
metadata = metadata[colnames(tbl),]

# add depth to meta
metadata$depth = apply(tbl, 2, sum)

# make the amor object
dat = create_dataset(Tab=tbl, Map=metadata, Tax=tax)

# get the measurable otus
#dat.meas = measurable_taxa(dat, clean=T)
#dat.meas = subset.Dataset(
#	dat.meas,
#	subset=findGoodSamples(dat.meas$Tab, opt$min_reads),
#	drop = T, clean=T)

# output the table and object
save(dat, file=opt$out)
