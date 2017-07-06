# A set of R functions I frequently use

get_kelly_colors = function(n=20, rand=F, seed=10) {
  MAX = 20  # there are 20 colors here
  
  colors = c(rgb(255,179,0,max=255),
             rgb(128,62,117,max=255),
             rgb(255,104,0,max=255),
             rgb(166,189,215,max=255),
             rgb(193,0,32,max=255),
             rgb(206,162,98,max=255),
             rgb(129,112,102,max=255),
             rgb(0,125,52,max=255),
             rgb(246,118,142,max=255),
             rgb(0,83,138,max=255),
             rgb(225,122,92,max=255),
             rgb(83,55,122,max=255),
             rgb(255,142,0,max=255),
             rgb(179,40,81,max=255),
             rgb(244,200,0,max=255),
             rgb(127,24,13,max=255),
             rgb(147,170,0,max=255),
             rgb(89,51,21,max=255),
             rgb(241,58,19,max=255),
             rgb(35,44,22,max=255)
  )
  
  if ( rand == T) {
    set.seed(seed)
    to_keep = sample(1:MAX, n)
  }
  else {
    to_keep = 1:n
  }
  
  return(colors[to_keep])
}


get_primary_colors = function(n=26) {
  require(colorRamps)
  # there are 26 optional colors here
  
  MAX = 26  # the number of primary.colors
  if ( n > MAX) {
    stop("Trying to get more than 26 colors.  n must be < 26")
  }
  
  return(primary.colors()[1:n])
}


# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot
# objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

##########
# capitalize the first word in the list of values
# eg 
# name = c("zip code", "state", "final count")
# sappy(name, simpleCap)
# RESULT: ("Zip code", "State", "Final count")
simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
      sep="", collapse=" ")
}
