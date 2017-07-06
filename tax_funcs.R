# functions for taxonomy operations--specifically for aggregating and assigning colors

aggregate_by_tax = function(data, tax, level, MAX = 8, mk_other = TRUE) {
    # MAX is the number of possible colors (ie max number of values)

  if ( ! level %in% colnames(tax)) {
    level = colnames(tax)[level]
  }

  agg = aggregate(data, tax[level], FUN=sum)
  row.names(agg) = agg[,level]
  agg[,level] = NULL

  # I changed data to agg (not completely sure if this is correct)
  if ( mk_other == TRUE & nrow(agg) > MAX ) {
    agg = make_other_category(agg, MAX)
  }
    #print("agg")
    #print(agg) 

  return(agg)
}

get_phy_colors = function(tbl) {
  # the table should already be aggregated by level
  # and it should already have the other category if necessary

  require(RColorBrewer)
  colors = brewer.pal(nrow(tbl), "Dark2")
  names(colors) = row.names(tbl)

  return(colors)
}

make_other_category = function(tbl, tax, MAX = 8) {
  if ( nrow(tbl) < MAX ) {
    return(tbl)
  }

  sums = sort(apply(tbl, 1, sum), decreasing = T)

    # lt stands for less than 
  lt_max = sums[MAX:length(sums)]

  tbl_other = tbl[row.names(tbl) %in% names(lt_max),]
  tbl["Other",] = apply(tbl_other, 2, sum)

  tbl = tbl[! row.names(tbl) %in% names(lt_max),]

  return(tbl)
}

make_other_category2 = function(tbl, vals) {
  # this is a function that creates the other category based on the names
  # that are provided in the vals parameter.  For example, if you have 3
  # taxa that you want to combine into the other category you can use
  # this function

  if ( length(vals) == 0 ) {
    return(tbl)
  }

  tbl_other = tbl[vals,]
  if ( "Other" %in% row.names(tbl) ) {
    tbl["Other",] = apply(tbl_other, 2, sum) + tbl["Other",]
  } else {
    tbl["Other",] = apply(tbl_other, 2, sum)
  }

  # remove the ones that are now in Other
  tbl = tbl[! row.names(tbl) %in% vals,]

  return(tbl)
}

