#!/usr/bin/evn Rscript

### Description
# does analysis and builds figures for the rarefaction test.
# I wanted to see how rarefying at different levels effected
# alpha diversity.

library(ggplot2)
require("getopt", quietly=T)
source("Rutil.R")

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


data = read.table(opt$tbl, header=T, sep="\t")
data$rare_level = as.factor(data$rare_level)

meta = read.table(opt$meta, header=T, sep="\t", quote="")

# remove P0 sample
data = data[data$sample != "P0",]
meta = meta[! row.names(meta) %in% c("P0"),]
data_m = merge(data, meta, by.x = "sample", by.y = "SampleID")

flava_title = expression(italic("Sarracenia flava"))
minor_title = expression(italic("Sarracenia minor"))

# get all the metrics
metrics = unique(data_m$metric)

for ( m in metrics ) {
	print(m)

	plot_file = paste(opt$out, "_", m, ".pdf", sep="")

	data_tmp = data_m[data_m$metric == m,]
	print(head(data_tmp))

	y_lab_metric = sapply(m, simpleCap)

	# some code to help me make the facet labels
    facet_names = list("hooded" = expression(italic("Sarracenia minor")),
                        "yellow" = expression(italic("Sarracenia flava")))
    facet_labeller = function(variable, value) {
        return(facet_names[value])
    }

	p = ggplot(data_tmp, aes(x=Plant_number, y=value, color=rare_level)) +
		geom_boxplot(outlier.size=NA) +
		geom_point(position = position_jitterdodge()) +
		facet_grid(. ~ Plant_species, space="free", scales="free", 
                labeller = facet_labeller) +
		xlab("Sample") +
		ylab(paste(y_lab_metric, " Metric", sep="")) +
		ggtitle("Alpha Diversity") +
		theme(axis.title = element_text(size=18),
				axis.text = element_text(size=16),
				axis.text.x = element_text(angle=90, hjust =1, vjust=.5),
				legend.text = element_text(size=16),
				legend.title = element_text(size=18),
				plot.title = element_text(hjust=0.5)) +
		scale_color_discrete("Rarefied to:")

	ggsave(plot_file, plot=p)
}
