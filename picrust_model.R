#!/usr/bin/evn Rscript

### Description
# Does a deseq2 analysis on the pitcher plant data from picrust

### R Libraries
require("getopt", quietly=T)
require("DESeq2")

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
  "verbose", "v", 0, "logical"
  ), byrow=TRUE, ncol=4)
opt = getopt(params)

# define parameter specified varaibles
if (! is.null(opt$verbose)) {
  verbose = opt$verbose
}


### Functions
main = function() {
	print("Loading data and metadata")
	# read in the table
	data = read.table(opt$table, sep="\t", header=T, row.names=1, quote="")
	tax = data[,ncol(data)]
	data[,ncol(data)] = NULL

	# read in the metadata
	meta = read.table(opt$meta, sep="\t", header=T, row.names=1)

	# make sure the order of columns in the matrix and rows in the metadata match
	print("Ordering samples")
	meta = meta[colnames(data),]
	#print(row.names(meta))
	#print(colnames(data))

	# create the DESeq object
	print("Creating DESeq DataSet Object")
	dds = DESeqDataSetFromMatrix(countData = data, colData = meta, design = ~ Plant_species)

	# differential OTU abundance analysis
	print("Differential Abundance Analysis")
	dds = DESeq(dds)
	res = results(dds, alpha=0.05, contrast=c("Plant_species", "hooded", "yellow"))
	print(res)
	print(summary(res))

	# some summary numbers
	num = sum(res$padj < 0.05, na.rm=T)
	print(paste("p-adj < 0.05:", num))

	# save stuff
	save(res, file="res.RData")

	# output tables of significant stuff
	res2 = res[!is.na(res$padj),]
	sig = res2[res2$padj < 0.05,]
	up = sig[sig$log2FoldChange > 0,]
	dn = sig[sig$log2FoldChange < 0,]

	up = up[order(up$padj),]
	dn = dn[order(dn$padj),]

	write.table(up, file = "sig_up.txt", quote=F, sep="\t")
	write.table(dn, file = "sig_dn.txt", quote=F, sep="\t")
}

# run the main function to execute the program
main()
