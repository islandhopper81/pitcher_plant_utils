#!/usr/bin/evn Rscript

### Description
# Does a deseq2 analysis on the pitcher plant data

### R Libraries
require("getopt", quietly=T)
require("DESeq2", quietly = T)
require("ggplot2", quietly = T)
require("reshape2", quietly = T)

source("otu_boxplot.R")
source("tax_funcs.R")
source("phylogram_funcs.R")

# set ggplot theme
theme_update( plot.title = element_text(hjust=.5, size = 22),
                        axis.text = element_text(size = 16),
                        axis.title = element_text(size = 16),
                        legend.title = element_text(size=18),
                        legend.text = element_text(size = 16)
)

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
  "meta", "m", 1, "character",
  "tax", "x", 1, "character",
	"tax_level", "l", 1, "character",
  "out", "o", 1, "character",
  "otu_dds", "u", 2, "character",
  "fam_dds", "f", 2, "character",
	"type", "y", 2, "character",
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}
if ( is.null(opt$type) ) {
	type = "rel"
} else {
	type = opt$type
}

# some important variables
#wd = "/Users/Scott/Projects/pitcher_plants/modeling/deseq2/"


### Functions
main = function() {
  #setwd(wd)
  
	print("Loading data and metadata")
	# read in the table
	data = read.table(opt$table, sep="\t", header=T, row.names=1, quote="")
	data[,ncol(data)] = NULL

	# read in the metadata
	meta = read.table(opt$meta, sep="\t", header=T, row.names=1)
	
	# read the taxonomy table
	tax = read.table(opt$tax, sep="\t", header=T, row.names=1, quote="")

	# make sure the order of columns in the matrix and rows in the metadata match
	print("Ordering samples")
	meta = meta[colnames(data),]

	# remove the P0 sample
	meta = meta[! row.names(meta) %in% c("P0"),]
	data = data[,! colnames(data) %in% c("P0")]
	
	# get the tax colors 
	tmp = aggregate_by_tax(data, tax, opt$tax_level)
	phy_colors = get_phy_colors(tmp)
	save(tax, file = paste(opt$out, "_", "tax.RData", sep=""))
	
	# OTU Model
	print("OTU Model")
	load_dds = T
	if ( is.null(opt$otu_dds) ) {
		load_dds = F
	}
	#print(load_dds)
	otu_model(data, meta, tax, phy_colors = phy_colors,
	          load_dds = load_dds, dds_file = opt$otu_dds)

	# Family level model
	print("Family Model")
	load_dds = T
	if ( is.null(opt$fam_dds) ) {
		load_dds = F
	}
	family_model(data, meta, tax, phy_colors = phy_colors,
	             load_dds = load_dds, dds_file = opt$fam_dds)
}

family_model = function(data, meta, tax, phy_colors = NULL,
                        load_dds = T, dds_file = "fam_dds.RData") {
  # aggregate by family
  data = aggregate_by_tax(data, tax, level = "Family", mk_other = F)
  print("Creating DESeq DataSet Object")
  if ( load_dds == T ) {
    load(dds_file)
  } else {
    # make the dds object
    dds = DESeqDataSetFromMatrix(countData = data, 
                                 colData = meta, 
                                 design = ~ Plant_species)
    
    # differential OTU abundance analysis
    print("Differential Abundance Analysis")
    dds = DESeq(dds)
  }
  
  res = results(dds, alpha=0.05)
  print(res)
  print(summary(res))
  
  # some summary numbers
  num = sum(res$padj < 0.05, na.rm=T)
  print(paste("p-adj < 0.05:", num))
	
	# get the up results
	up = res$padj < 0.05 & res$log2FoldChange > 0
	up[is.na(up)] = FALSE
	up_names = row.names(up)
	up_tbl = res[up,]

	# get the down results
	dn = res$padj < 0.05 & res$log2FoldChange < 0
	dn[is.na(dn)] = FALSE
	dn_names = row.names(dn)
	dn_tbl = res[dn,]

	# save some of the output objects
	if ( ! load_dds == T ) {
		dds_file = paste(opt$out, "_fam_dds.RData", sep="")
		res_file = paste(opt$out, "_fam_res.RData", sep="")
		save(dds, file = dds_file)
		save(res, file = res_file)	
	}
	
	# save the up and down tables	
	up_tbl_file = paste(opt$out, "_fam_sig_up.txt", sep="")
	dn_tbl_file = paste(opt$out, "_fam_sig_dn.txt", sep="")
	write.table(up_tbl, file = up_tbl_file, quote=F, sep="\t")
	write.table(dn_tbl, file = dn_tbl_file, quote=F, sep="\t")

  
  # make some individual plots
  # these plots use pseudocounts from DESeq
  # these examples are the top three most significant
	top_3_up = get_top_sig(up_tbl, x=3)
	top_3_dn = get_top_sig(dn_tbl, x=3)
	for ( t in top_3_up ) {
		otu_boxplot(dds, t, tax, file = paste(opt$out, "_", t, ".pdf", sep=""))
	}
	for ( t in top_3_dn ) {
		otu_boxplot(dds, t, tax, file = paste(opt$out, "_", t, ".pdf", sep=""))
	}
  
  # plot histogram of p-values
	p_val_file = paste(opt$out, "_fam_pval_plot.pdf", sep="")
  plot_p_vals(res, p_val_file)
  
  # plot the effect sizes
  ef_file = paste(opt$out, "_fam_effect_sizes.pdf", sep="")
  plot_effect_size(res, file=ef_file, title="Enriched Families")
  
  # create the phylogram for the families that are up
  up_names = get_sig_names(res, direction = "up")
  up_data = data[up_names,]
  up_tax = unique(tax[tax$Family %in% up_names,])
  p = my_phylogram(up_data, up_tax, opt$tax_level, meta, phy_colors = phy_colors, type = type)
	phylo_file = paste(opt$out, "_fam_up_phylogram.pdf", sep="")
  ggsave(phylo_file, plot = p)
	
	# save the up names
	up_names_file = paste(opt$out, "_fam_sig_up_names.txt", sep="")
	write.table(up_names, file = up_names_file, quote=F, sep="\t", row.names=F, col.names=F)
  
  # create the phylogram for the families that are down
  dn_names = get_sig_names(res, direction = "down")
  dn_names = dn_names[dn_names != "unclassified"]  # remove the unclassified family
  dn_data = data[dn_names,]
  dn_tax = unique(tax[tax$Family %in% dn_names,])
  p = my_phylogram(dn_data, dn_tax, opt$tax_level, meta, phy_colors = phy_colors, type = type)
	phylo_file = paste(opt$out, "_fam_dn_phylogram.pdf", sep = "")
  ggsave(phylo_file, plot = p)

	# save the dn names
	dn_names_file = paste(opt$out, "_fam_sig_dn_names.txt", sep="")
	write.table(dn_names, file = dn_names_file, quote=F, sep="\t", row.names=F, col.names=F)
	
}

otu_model = function(data, meta, tax, phy_colors = NULL,
                     load_dds = T, dds_file = "otu_dds.RData") {
  # create the DESeq object
  print("Creating DESeq DataSet Object")
  if ( load_dds == T ) {
    print("Loading model")
    load(dds_file)
  } else {
    # make the dds object
    print("Building model")
    dds = DESeqDataSetFromMatrix(countData = data, 
                                 colData = meta, 
                                 design = ~ Plant_species)
    
    # differential OTU abundance analysis
    print("Differential Abundance Analysis")
    dds = DESeq(dds)
  }
  
  # create the DESeq results object (ie table)
  res = results(dds, alpha=0.05)
  #print(res)
  print(summary(res))
  
  # some summary numbers
  num = sum(res$padj < 0.05, na.rm=T)
  print(paste("p-adj < 0.05:", num))
	
	# get the up results
	up = res$padj < 0.05 & res$log2FoldChange > 0
	up[is.na(up)] = FALSE
	up_names = row.names(up)
	up_tbl = res[up,]

	# get the down results
	dn = res$padj < 0.05 & res$log2FoldChange < 0
	dn[is.na(dn)] = FALSE
	dn_names = row.names(dn)
	dn_tbl = res[dn,]

	# save some of the output objects
	if ( ! load_dds == T ) {
		dds_file = paste(opt$out, "_otu_dds.RData", sep="")
		res_file = paste(opt$out, "_otu_res.RData", sep="")
		save(dds, file = dds_file)
		save(res, file = res_file)
	}

	# save the up and down tables	
	up_tbl_file = paste(opt$out, "_otu_sig_up.txt", sep="")
	dn_tbl_file = paste(opt$out, "_otu_sig_dn.txt", sep="")
	write.table(up_tbl, file = up_tbl_file, quote=F, sep="\t")
	write.table(dn_tbl, file = dn_tbl_file, quote=F, sep="\t")
  
  # make some individual plots
  # these plots use pseudocounts from DESeq
  # these examples are the top 5 most significant for minor (hooded)
	top_5_dn = get_top_sig(dn_tbl, x=5)
	for ( t in top_5_dn ) {
		otu_boxplot(dds, t, tax, file = paste(opt$out, "_", t, ".pdf", sep=""))
	}
  
  # these examples are the top 5 most significant for flava (yellow)
	top_5_up = get_top_sig(up_tbl, x=5)
	for ( t in top_5_up ) {
		otu_boxplot(dds, t, tax, file = paste(opt$out, "_", t, ".pdf", sep=""))
	}
  
  # plot histogram of p-values
	p_val_file = paste(opt$out, "_otu_pval_plot.pdf", sep="")
  plot_p_vals(res, p_val_file)
  
  # plot the effect sizes
	ef_file = paste(opt$out, "_otu_effect_sizes.pdf", sep="")
  plot_effect_size(res, file=ef_file)
  
  # create the full relative abundance phylogram
  p = my_phylogram(data, tax, opt$tax_level, meta, phy_colors = phy_colors, type = type)
  ggsave(paste(opt$out, "_", "phylogram.pdf", sep=""), plot = p)
  
  # create the phylogram for the OTUs that are up
	#print("Create UP phylogram")
  up_names = get_sig_names(res, direction = "up")
  up_data = data[up_names,]
  up_tax = tax[up_names,]
  p = my_phylogram(up_data, up_tax, opt$tax_level, meta, phy_colors = phy_colors, type = type)
	phylo_file = paste(opt$out, "_otu_up_phylogram.pdf", sep="")
  ggsave(phylo_file, plot = p)
	
	# save the up names
	up_names_file = paste(opt$out, "_otu_sig_up_names.txt", sep="")
	write.table(up_names, file = up_names_file, quote=F, sep="\t", row.names=F, col.names=F)
  
  # make some individual plots
  # these plots use pseudocounts from DESeq
  
  # create the phylogram for the OTUs that are down
	#print("Create DN phylogram")
  dn_names = get_sig_names(res, direction = "down")
  dn_data = data[dn_names,]
  dn_tax = tax[dn_names,]
  p = my_phylogram(dn_data, dn_tax, opt$tax_level, meta, phy_colors = phy_colors, type = type)
	phylo_file = paste(opt$out, "_otu_dn_phylogram.pdf", sep="")
  ggsave(phylo_file, plot = p)
	
	# save the dn names
	dn_names_file = paste(opt$out, "_otu_sig_dn_names.txt", sep="")
	write.table(dn_names, file = dn_names_file, quote=F, sep="\t", row.names=F, col.names=F)
}

get_sig_names = function(res, alpha = 0.05, direction = "up") {
  if ( direction == "up" ) {
    names = row.names(res[which(res$padj < 0.05 & res$log2FoldChange > 0),])
  } else if ( direction == "down" ) {
    names = row.names(res[which(res$padj < 0.05 & res$log2FoldChange < 0),])
  } else {
    stop("bad direction parameter in get_sig_names")
  }
  
  return(names)
}

plot_effect_size = function(res, file=NULL, title="Enriched OTUs") {
  # set the up points (flava -- yellow) as lightblue
  # set the down points (minor -- hooded) as red
  res_tmp = as.data.frame(res)
  res_tmp$Enrichment = factor(rep("Not Significant", nrow(res_tmp)), levels = c("Sarracenia flava", "Sarracenia minor", "Not Significant"))
  up = res$padj < 0.05 & res$log2FoldChange > 0
  up[is.na(up)] = FALSE
  dn = res$padj < 0.05 & res$log2FoldChange < 0
  dn[is.na(dn)] = FALSE
  res_tmp[up,"Enrichment"] = "Sarracenia flava"
  res_tmp[dn,"Enrichment"] = "Sarracenia minor"

	# set a size variable to make the colored points larger
	res_tmp[,"size"] = "small"
	res_tmp[up,"size"] = "large"
	res_tmp[dn,"size"] = "large"
  
  flava_title = expression(italic("Sarracenia flava"))
  minor_title = expression(italic("Sarracenia minor"))
  
  flava_n = paste("n=", table(up)[[2]], sep="")
  minor_n = paste("n=", table(dn)[[2]], sep="")
  
  
  p = ggplot(res_tmp, aes(x=1, y=log2FoldChange)) + 
    geom_boxplot(outlier.size=NA) +
    geom_jitter(aes(color=Enrichment, size=size), width = .35)+ 
    ggtitle(title) + 
    ylab("Log2 Fold Change") +
    scale_color_manual("Enrichment", 
                       limits = c("Sarracenia flava", "Sarracenia minor", "Not Significant"),
                       labels = c(flava_title, minor_title, "Not Significant"),
                       values=c("lightblue","red", "gray91")) +
		scale_size_manual(guide=F,
							values = c(3,1)) +
    theme_bw() +
    theme(axis.text.x = element_blank(),
          axis.title.x = element_blank(),
          axis.ticks.x = element_blank(),
          plot.title = element_text(hjust=.5, size = 22),
          axis.text = element_text(size = 16),
          axis.title = element_text(size = 16),
          legend.title = element_text(size=18),
          legend.text = element_text(size = 16),
          legend.text.align = 0
          ) +
    annotate("text", x=1.45, y=max(res_tmp$log2FoldChange), 
             label=flava_n, color="lightblue", size=6) +
    annotate("text", x=1.45, y=min(res_tmp$log2FoldChange), 
             label=minor_n, color="red", size=6) +
    xlim(.5, 1.5)

  if ( is.null(file) ) {
    p
  } else {
    ggsave(file, plot = p)
  }
  
  return(p)
}

plot_p_vals = function(res, file=NULL) {
  p = ggplot(as.data.frame(res), aes(x=pvalue)) +
    geom_histogram() +
    xlab("P-Value") + 
    ylab("Count") +
    ggtitle("OTU Model P-Value Histogram")
  
  if ( is.null(file) ) {
    p
  } else {
    ggsave(file, plot = p)
  }
  
  return(p)
}

get_top_sig = function(tbl, x=3) {
	tbl = tbl[order(tbl$padj),]
	names = row.names(tbl)[1:x]
	return(names)
}

# run the main function to execute the program
main()
