

library(ggplot2)


data = read.table("/lustre/scr/y/o/yourston/pitcher_plant/mttoolbox_otus/rarefy_alpha_div_test.txt", header=T)


metric = "PD_whole_tree"
#metric = "chao1"
data = data[data$rare_level == 50000,]
data = data[data$metric == metric,]
data = data[data$rep == 1,]


meta = read.table("/lustre/scr/y/o/yourston/pitcher_plant/metadata.txt", header=T)


merged = merge(data, meta, by.x = "sample", by.y = "SampleID")

# t-test
hooded_vals = merged[merged$Plant_species == "hooded", "value"]
yellow_vals = merged[merged$Plant_species == "yellow", "value"]
t = t.test(hooded_vals, yellow_vals)
t.pval = round(t$p.value, digits=3)
t.pval.str = paste("p-val=", t.pval, sep="")

# make plot
flava_title = expression(italic("Sarracenia flava")) #yellow
minor_title = expression(italic("Sarracenia minor")) #hooded

p = ggplot(merged, aes(x=Plant_species, y= value, color=Plant_species)) +
  geom_boxplot() + 
  geom_jitter(size=3) + 
  ggtitle("Alpha Diversity") + 
  ylab("PD whole tree metric") + 
  xlab("Plant Species") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_x_discrete(limits = c("hooded", "yellow"),
					labels = c(minor_title, flava_title)) +
  scale_color_manual(limits = c("hooded", "yellow"),
						values = c("red", "lightblue"),
						guide=F) +
  theme_bw() +
    theme(plot.title = element_text(hjust=.5, size = 22),
          axis.text = element_text(size = 16),
          axis.title = element_text(size = 16),
          legend.title = element_text(size=18),
          legend.text = element_text(size = 16),
          legend.text.align = 0
          ) +
  annotate("text", x=2.3, y=11.5, label=t.pval.str, size=6)


ggsave("alpha_div_test.pdf", plot=p)
