#!/usr/bin/evn Rscript

library(AMOR)
require("getopt", quietly=T)
library(ggplot2)

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
  "pcoa", "p", 1, "character",
  "meta", "m", 1, "character",
  "x_var", "x", 1, "double",
  "y_var", "y", 1, "double",
  "out", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}

# read in the pcoa tbl
pcoa = read.table(opt$pcoa, header=T, row.names=1, sep="\t")

# save only pc 1 and 2
pcoa = pcoa[,c(1,2)]

# read in the metadata
meta = read.table(opt$meta, header=T, row.names=1, sep="\t")

# combine pcoa and meta
data = merge(pcoa, meta, by.x="row.names", by.y="row.names")
#summary(data)

# make the figure
ggplot(data, aes(x=X1, y=X2, color=Plant_species, label=Row.names)) +
	geom_point() +
	geom_text(hjust = 0, nudge_x=0.005, show.legend=F) +
	expand_limits(x=.4) +
	xlab(paste("PCoA 1 (", opt$x_var, "%)", sep="")) +
	ylab(paste("PCoA 2 (", opt$y_var, "%)", sep="")) +
	ggtitle("Pitcher Plant PCoA") +
	scale_color_discrete("Plant Species") +
	theme(legend.text = element_text(size=16),
			legend.title = element_text(size=18),
			axis.text = element_text(size=16),
			axis.title = element_text(size=18),
			plot.title = element_text(size=20))
	
ggsave(opt$out)
