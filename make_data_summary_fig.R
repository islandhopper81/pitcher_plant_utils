#!/usr/bin/evn Rscript


### Description
# make a figure showing the read counts per sample

### R Libraries
require("getopt", quietly=T)
require("ggplot2", quietly=T)

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
  "otu_table", "t", 1, "character",
  "meta", "m", 1, "character",
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
	# read in the out table
	tbl = read.table(opt$otu_table, header=T, row.names=1, sep="\t", quote="")

	# remove the taxnomy column
	tbl = tbl[,! colnames(tbl) %in% c("taxonomy")]

	# read in the metadata table
	meta = read.table(opt$meta, header=T, row.names=1, sep="\t", quote="")
	
	# remove the P0 sample
	tbl = tbl[,! colnames(tbl) %in% c("P0")]
	meta = meta[! row.names(meta) %in% c("P0"),]

	# make the summary numbers table
	sum = apply(tbl, 2, sum)

	# add the read counts to the metadata table
	sum = sum[row.names(meta)] # order the numbers based on the metadata order
	meta[,"Read_Count"] = sum

	# some code to help me make the facet labels
	facet_names = list("hooded" = expression(italic("Sarracenia minor")),
						"yellow" = expression(italic("Sarracenia flava")))
	facet_labeller = function(variable, value) {
		return(facet_names[value])
	}
	
	# make the figure
	p = ggplot(meta, aes(x=Plant_number, y=Read_Count, fill=Plant_species)) +
		geom_col() +
		facet_grid(. ~ Plant_species, scales = "free", labeller = facet_labeller) +
		xlab("Samples") +
		ylab("Read Counts") + 
		ggtitle("Read Count Summary") +
		theme(
		  plot.title = element_text(hjust=.5, size = 22),
          axis.text = element_text(size = 16),
          axis.title = element_text(size = 16),
			axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
          legend.title = element_text(size=18),
          legend.text = element_text(size = 16),
          legend.text.align = 0
          ) +
		scale_fill_manual(values = c("red", "lightblue"),
							guide=F)

	ggsave(opt$out, plot=p)	
}

# run the main function to execute the program
main()
