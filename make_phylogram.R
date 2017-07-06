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
  "amor", "a", 1, "character",
  "rare", "r", 1, "integer",
  "out", "o", 1, "character",
  "level", "l", 1, "integer",
  "title", "t", 1, "character",
  "ntaxa", "n", 1, "integer",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}

# load the amor object with the measurable reads
load(opt$amor)

# get only the samples that have at least opt$rare reads
dat = subset.Dataset(
	dat,
	subset=findGoodSamples(dat$Tab, opt$rare),
	drop = T, clean = T)

# rarefy
dat.rare = rarefaction.Dataset(dat, opt$rare)
clean(dat.rare)

# collapse into phyla
phyla = collapse_by_taxonomy(dat.rare, level=opt$level)

# make phylogram
yellow = c("P0", "P2", "P3", "P5", "P6", "P7", "P9", "P10", "P12", "P14")
hooded = c("P1", "P4", "P8", "P11", "P13", "P15", "P16")

p = phylogram(phyla, ntaxa=opt$ntaxa) +
		ggtitle(opt$title) +
		scale_x_discrete(limits=c(yellow, hooded)) +
		theme(axis.text.x = element_text(vjust = .5))
ggsave(opt$out, plot=p)


