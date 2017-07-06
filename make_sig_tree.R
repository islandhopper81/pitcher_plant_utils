

library("ape")
library("phytools")
source("https://bioconductor.org/biocLite.R")
biocLite("ggtree")
library("ggplot2")
library("ggtree")

tree_file = "/Users/Scott/temp/sig_otu_seqs_aligned_pfiltered.tre"
tree = read.newick(tree_file)

meta_file = "/Users/Scott/temp/sig_meta.txt"
meta = read.table(meta_file, header=T, sep="\t")
colnames(meta)
meta = meta[,c("direction", "has_match")]

# remove OTU_195 because it didn't align in the tree
# it failed at the pynast alignment step
meta = meta[row.names(meta) != "OTU_195",]

# order by where they fall in the tree
meta = meta[tree$tip.label,]

p = ggtree(tree)
gheatmap(p, meta, offset=0, width=0.1, font.size=3, colnames_angle=-45, hjust=0) +
  scale_fill_manual(breaks=c("up", "dn", "TRUE", "FALSE"),
                    values=c("red", "gray", "black", "sky blue"))

p = ggtree(tree, layout="circular")
gheatmap(p, meta, offset=0, width=0.1, font.size=3, colnames=F, hjust=0) +
  scale_fill_manual(breaks=c("up", "dn", "TRUE", "FALSE"),
                    labels=c("Yellow", "Hooded", "DB Match", "No DB Match"),
                    values=c("red", "gray", "black", "sky blue"))

    ggtree(tree, layout="circular")

