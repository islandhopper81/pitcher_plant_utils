# CAP analysis on pitcher plant project

require(vegan, quietly=T)
require(AMOR, quietly=T)
require("getopt", quietly=T)

# NOTE: use non-rarefied data

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

# functions
main = function() {
  # read in the table
  data = read.table(opt$table, sep="\t", header=T, row.names=1, quote="")
  data[,ncol(data)] = NULL
  
  # read in the metadata
  meta = read.table(opt$meta, sep="\t", header=T, row.names=1, quote="")
  
  # make sure the metadata is in the same order as the data
  meta = meta[colnames(data),]
  
  # add depth to metadata
  meta[,"depth"] = apply(data, 2, sum)

  # remove any samples that are very low
  # in this case only P0
  data[,"P0"] = NULL
  meta = meta[-c(which(row.names(meta) == "P0")),]
  
  # Do CAP
  distfun <- function(x,method) vegan::vegdist(x = x, method = "bray")
  cap <- vegan::capscale(t(data) ~ Plant_species + Condition(depth),
                         data = meta ,dfun = distfun)
  cap.sum = summary(cap)
  meta <- cbind(meta, cap.sum$sites)
  percvar <- round(100 * cap$CCA$eig / cap$CCA$tot.chi,2)
  tot_percvar = round(100 * cap$CCA$eig / cap$tot.chi, 2)
  tot_percvar_mds = round(100 * cap$CA$eig / cap$tot.chi, 2)
  
  # NOTE: in this context the percvar doesn't make sense.  It will be 
  # 100% because there is only one feature that I model in the CAP
  # analysis.  So naturally 100% of the CAP variance will come from that
  # feature.
  
  # make the cap figure
  make_cap_plot(meta, x="CAP1", y="MDS1",
                c = "Plant_species",
                title = "Beta Diversity (CAP)",
                xlab = paste("CAP1 (",tot_percvar[1],"%)",sep = ""),
                ylab = paste("MDS1 (",tot_percvar_mds[1],"%)",sep = ""),
                file = "CAP.pdf")
}

make_cap_plot = function(Map, x, y, c, s=NULL, title, xlab, ylab, file=NULL) {
  minor_title = expression(italic("Sarracenia minor"))
  flava_title = expression(italic("Sarracenia flava"))

  p = ggplot(Map, aes_string(x = x, y = y, col = c)) +
    geom_point(aes_string(shape = s), size = 3) +
    xlab(xlab) +
    ylab(ylab) +
    ggtitle(title) +
    theme(axis.text = element_text(color = "black", size=16), 
          axis.title = element_text(face = "bold", size=16),
          panel.background = element_rect(color = "black", size = 1, fill = NA),
          panel.grid = element_blank(),
          legend.position="bottom",
          legend.direction="vertical",
		  legend.title = element_text(size=16),
		  legend.title.align=0.5,
		  legend.text.align = 0,
		  legend.text = element_text(size=16),
          plot.title = element_text(hjust = 0.5, face="bold", size=22),
	) +
	scale_color_manual("Plant Species",
						limits = c("hooded", "yellow"),
						labels = c(minor_title, flava_title),
						values = c("red", "lightblue"))

  if ( !is.null(file)) {
    ggsave(file, plot = p)
  } else {
    p
  }
}

main()
