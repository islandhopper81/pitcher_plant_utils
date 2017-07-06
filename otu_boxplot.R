# a function for making otu_boxplots.  This function is called in 
# make_otu_boxplot.R and model_main.R.  It must be found in the same
# directory as those two scripts.

otu_boxplot = function(dds, otu, tax, file=NULL) {
  require("DESeq2")
  d = plotCounts(dds, gene=otu, intgroup = "Plant_species", returnData = T)
  
  # generate the title
  if ( is.na(tax[otu, "Family"]) ) {
    title = otu
  } else {
    family_name = as.character(tax[otu, "Family"])
    title = bquote(paste(.(otu), " - ", italic(.(family_name))))
  }
  
  p = ggplot(d, aes(x=Plant_species, y=log10(count), color=Plant_species)) +
    geom_boxplot(outlier.size = NA, lwd=1) + 
    geom_jitter(position = position_jitter(width=0.3), size=2.5) + 
    ggtitle(title) + 
    xlab("Plant Species") + 
    ylab("Normalized Counts (log10)") + 
    scale_x_discrete(limit = c("hooded", "yellow"),
                     labels = c("Sarracenia minor", "Sarracenia flava")) +
    scale_color_manual(guide = F,
                       values = c("red","lightblue")) +
    theme(axis.text.x = element_text(face = "italic"),
          legend.text = element_text(face = "italic",size=16),
		  plot.title = element_text(hjust=0.5, size=18),
		  axis.text = element_text(size=16),
		  axis.title = element_text(size=16))
  
  if ( is.null(file) ) {
    p
  } else {
    # save the plot
    ggsave(filename = file, plot = p)
  }
}
