#!/usr/bin/evn Rscript

### Description
# create a plot to show the picrust modeling output

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
  "up", "u", 1, "character",
  "dn", "d", 1, "character",
  "level", "l", 1, "integer",
  "out_file", "o", 1, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}

# set the ggplot themes
theme_update( plot.title = element_text(hjust=.5, size = 22),
                        axis.text = element_text(size = 16),
                        axis.title = element_text(size = 16),
                        legend.title = element_text(size=18),
                        legend.text = element_text(size = 16) 
)


### Functions
main = function() {
	print("Read in the up and down files")
	up = read.table(opt$up, header=T, sep="\t", quote="")
	dn = read.table(opt$dn, header=T, sep="\t", quote="")
	up[,"direction"] = "up"
	dn[,"direction"] = "dn"

	data = rbind(up, dn)

	# take the absolute value of the log2foldchange
	data$log2FoldChange = abs(data$log2FoldChange)

	# add the pathway levels
	data = add_pathway_levels(data)

	# change the Overivew pathway to Overview/General
	require(plyr, quietly=T)
	data$Pathway2 = revalue(data$Pathway2, c("Overview"="Overview/General"))

	# remove some pathways that are not interesting and/or don't make sense
	to_remove = c("Endocrine system", "Nervous system", "Immune system", "Cancers")
	data = data[!data$Pathway2 %in% to_remove,]

	# set the plant species titles
	flava_title = expression(italic("Sarracenia flava"))
	minor_title = expression(italic("Sarracenia minor"))

	ggplot(data, aes(y=log2FoldChange, x=Pathway2, color=direction)) +
		geom_point(position = position_jitterdodge(jitter.width=.10)) +
		ggtitle("PICRUSt Enriched KEGG Pathways") +
		xlab("Pathway") +
		ylab("Fold Change (log2)") +
		scale_color_manual("Plant Species",
			labels = c(minor_title, flava_title),
			values = c("lightblue", "red")) +
		theme(plot.title = element_text(hjust = 0.5),
				axis.text.x = element_text(angle=90, hjust = 1, vjust = 0.5),
				legend.text.align = 0,
				panel.background = element_rect(fill = 'white'),
				panel.grid.major = element_line(color='gray'),
				panel.grid.minor = element_blank(),
				panel.border = element_rect(fill=NA, color='black', size=1),
				legend.key = element_rect(fill="white"))

	ggsave(opt$out_file, width=10)

}

add_pathway_levels = function(data) {
	pathways = as.character(data$pathway)

	vals_list = strsplit(pathways, split=";")

	vals_mat = t(do.call(cbind, vals_list))

	vals_df = as.data.frame(vals_mat)

	colnames(vals_df) = c("Pathway1", "Pathway2", "Pathway3")

	data = cbind(data, vals_df)

	return(data)
}

# run the main function to execute the program
main()
