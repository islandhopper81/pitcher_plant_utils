# a functions for making a phylogram

source("tax_funcs.R")
require("ggplot2", quietly=T)

# set ggplot theme
theme_update( plot.title = element_text(hjust=.5, size = 22),
                        axis.text = element_text(size = 16),
                        axis.title = element_text(size = 16),
                        legend.title = element_text(size=18),
                        legend.text = element_text(size = 16) 
)

my_phylogram = function(data, tax, level=NULL, meta, phy_colors=NULL, type="rel", out_file=NULL) {
  if ( ! is.null(level)) {
    if ( ! level %in% colnames(tax) ) { 
      level = colnames(tax)[level]
    }   
    data = aggregate_by_tax(data, tax, level)
  }
  
  if ( is.null(phy_colors) ) { 
    phy_colors = get_phy_colors(data)
  }
  
  # aggregate rows that are not in phy_colors into the Other category
  add_to_other = row.names(data)[! row.names(data) %in% names(phy_colors)]
  data = make_other_category2(data, vals = add_to_other)
  
  # convert the data to relative abundance
    if ( type == "rel" ) { 
    sums = apply(data, 2, sum)
    data_rel = as.data.frame(t(t(data) / sums))
    } else {
        data_rel = as.data.frame(data)
    }   
  
  # melt
  data_m = melt(as.matrix(data_rel), id.vars = "row.names")
  
  # add the plant species
  data_m = merge(data_m, meta, by.x = "Var2", by.y = "row.names")

  # create the title
  title = paste(level, "Level Phylogram")

  # some code to help me make the facet labels
    facet_names = list("hooded" = expression(italic("Sarracenia minor")),
                        "yellow" = expression(italic("Sarracenia flava")))
    facet_labeller = function(variable, value) {
        return(facet_names[value])
    }   
  
	ggplot(data_m, aes(y=value, x=Plant_number, fill = Var1)) + 
    geom_bar(stat="identity") +
    facet_grid(. ~ Plant_species, space="free", scales="free", 
                labeller = facet_labeller) +
    scale_fill_manual("Taxonomy", values = phy_colors) +
    xlab("Sample") +
    ylab("Relative Abundance") +
    ggtitle(title) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
		plot.title = element_text(hjust=0.5))

	if ( ! is.null(out_file) ) {
		ggsave(out_file)
	}

}

